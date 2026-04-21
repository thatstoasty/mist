from std.collections import Dict, List
from std.ffi import c_int, external_call, get_errno
from std.memory import ImmutPointer, MutPointer

from mist.multiplex.event import Event
from mist.multiplex.selector import Selector


@fieldwise_init
struct TimeSpec(ImplicitlyCopyable, TrivialRegisterPassable):
    """Represents a POSIX `timespec` value for `kevent`."""

    var tv_sec: Int64
    """Seconds component."""
    var tv_nsec: Int64
    """Nanoseconds component."""


@fieldwise_init
struct KEvent(ImplicitlyCopyable, TrivialRegisterPassable):
    """Represents Darwin's `struct kevent`."""

    var ident: UInt
    """Identifier for the event source, typically a file descriptor."""
    var filter: Int16
    """Kernel filter to apply to `ident`."""
    var flags: UInt16
    """Action and status flags for this event."""
    var fflags: UInt32
    """Filter-specific flags."""
    var data: Int
    """Filter-specific data or returned kernel error code."""
    var udata: UInt
    """Opaque user data."""


comptime EVFILT_READ = Int16(-1)
"""Watch for read readiness."""
comptime EVFILT_WRITE = Int16(-2)
"""Watch for write readiness."""
comptime EV_ADD = UInt16(0x0001)
"""Add an event to the queue."""
comptime EV_DELETE = UInt16(0x0002)
"""Delete an event from the queue."""
comptime EV_ENABLE = UInt16(0x0004)
"""Enable an event."""
comptime EV_CLEAR = UInt16(0x0020)
"""Reset state after the event is returned."""
comptime EV_ERROR = UInt16(0x4000)
"""Kernel reports an error for this event."""


def _kqueue() -> c_int:
    """Create a new kernel event queue.

    Returns:
        A kernel queue file descriptor, or `-1` if the call fails.
    """
    return external_call["kqueue", c_int]()


def _close(fd: c_int) -> c_int:
    """Close a file descriptor.

    Args:
        fd: The file descriptor to close.

    Returns:
        `0` on success, or `-1` if the call fails.
    """
    return external_call["close", c_int](fd)


def _kevent[
    change_origin: ImmutOrigin,
    event_origin: MutOrigin,
    timeout_origin: ImmutOrigin,
    //,
](
    queue: c_int,
    changelist: ImmutPointer[KEvent, change_origin],
    nchanges: c_int,
    eventlist: MutPointer[KEvent, event_origin],
    nevents: c_int,
    timeout: ImmutPointer[TimeSpec, timeout_origin],
) -> c_int:
    """Call Darwin's `kevent` function.

    Parameters:
        change_origin: Origin of the immutable changelist pointer.
        event_origin: Origin of the mutable output event list pointer.
        timeout_origin: Origin of the immutable timeout pointer.

    Args:
        queue: The kqueue file descriptor.
        changelist: Pointer to the list of changes to apply.
        nchanges: Number of entries in `changelist`.
        eventlist: Pointer to the output buffer for ready events.
        nevents: Number of entries available in `eventlist`.
        timeout: Pointer to the timeout value.

    Returns:
        The number of events placed into `eventlist`, or `-1` if the call fails.
    """
    return external_call[
        "kevent",
        c_int,
        c_int,
        ImmutPointer[KEvent, change_origin],
        c_int,
        MutPointer[KEvent, event_origin],
        c_int,
        ImmutPointer[TimeSpec, timeout_origin],
    ](queue, changelist, nchanges, eventlist, nevents, timeout)


@fieldwise_init
struct KQueueSelector(Movable, Selector):
    """Selector implementation using Darwin's `kqueue`."""

    var queue: Int
    """Kernel queue file descriptor."""
    var registrations: Dict[Int, Event]
    """Current event mask tracked for each registered file descriptor."""

    def __init__(out self) raises:
        """Create a new kqueue-backed selector.

        Returns:
            None. Initializes `self` in place.

        Raises:
            Error: If `kqueue()` fails.
        """
        self.registrations = Dict[Int, Event]()

        var queue = _kqueue()
        if queue == -1:
            var errno = get_errno()
            raise Error("kqueue() failed with errno: ", errno.value)

        self.queue = Int(queue)

    def register(mut self, file_descriptor: FileDescriptor, events_to_monitor: Event) raises -> None:
        """Register a file descriptor with the kernel queue.

        Args:
            file_descriptor: The file descriptor to monitor.
            events_to_monitor: Bitmask of readiness events to register.

        Raises:
            Error: If the kernel rejects the registration change.
        """
        if events_to_monitor & Event.READ:
            self._submit_change(file_descriptor.value, EVFILT_READ, EV_ADD | EV_ENABLE | EV_CLEAR)

        if events_to_monitor & Event.WRITE:
            self._submit_change(file_descriptor.value, EVFILT_WRITE, EV_ADD | EV_ENABLE | EV_CLEAR)

        if file_descriptor.value in self.registrations:
            self.registrations[file_descriptor.value] |= events_to_monitor
        else:
            self.registrations[file_descriptor.value] = events_to_monitor

    def unregister(mut self, file_descriptor: FileDescriptor, events_to_stop: Event) raises -> None:
        """Unregister specific readiness events for a file descriptor.

        Args:
            file_descriptor: The file descriptor to update.
            events_to_stop: Bitmask of readiness events to remove.

        Raises:
            Error: If the kernel rejects removal of an existing registration.
        """
        if events_to_stop & Event.READ:
            self._delete_change(file_descriptor.value, EVFILT_READ)

        if events_to_stop & Event.WRITE:
            self._delete_change(file_descriptor.value, EVFILT_WRITE)

        if file_descriptor.value not in self.registrations:
            return

        var remaining = Event(self.registrations[file_descriptor.value].value & ~events_to_stop.value)
        if remaining:
            self.registrations[file_descriptor.value] = remaining
        else:
            self.registrations[file_descriptor.value] = remaining

    def select(mut self, timeout: Int = 0) raises -> Dict[Int, Event]:
        """Wait for registered file descriptors to become ready.

        Args:
            timeout: Maximum wait time in microseconds. Values less than or equal
                to zero perform a non-blocking poll.

        Returns:
            A dictionary mapping ready file descriptors to their readiness mask.

        Raises:
            Error: If `kevent()` fails or returns an event-level error.
        """
        var ready = Dict[Int, Event]()
        if len(self.registrations) == 0:
            return ready^

        var timeout_spec = self._timeout_to_timespec(timeout)
        var dummy_change = KEvent(0, 0, 0, 0, 0, 0)
        var empty_event = KEvent(0, 0, 0, 0, 0, 0)

        var max_events = len(self.registrations) * 2
        var events = List[KEvent](capacity=max_events)
        for _ in range(max_events):
            events.append(empty_event)

        var result = _kevent(
            Int32(self.queue),
            Pointer(to=dummy_change),
            0,
            Pointer(to=events[0]),
            Int32(max_events),
            Pointer(to=timeout_spec),
        )

        if result == -1:
            var errno = get_errno()
            if errno == errno.EINTR:
                return Dict[Int, Event]()
            raise Error("kevent() failed with errno: ", errno.value)

        for idx in range(Int(result)):
            var event = events[idx]
            if event.flags & EV_ERROR:
                raise Error("kevent() returned an event error: ", event.data)

            var file_descriptor = Int(event.ident)
            if event.filter == EVFILT_READ:
                if file_descriptor in ready:
                    ready[file_descriptor] |= Event.READ
                else:
                    ready[file_descriptor] = Event.READ
            elif event.filter == EVFILT_WRITE:
                if file_descriptor in ready:
                    ready[file_descriptor] |= Event.WRITE
                else:
                    ready[file_descriptor] = Event.WRITE

        return ready^

    def close(self) raises -> None:
        """Close the underlying kernel queue.

        Raises:
            Error: If closing the kernel queue file descriptor fails.
        """
        if self.queue < 0:
            return

        var result = _close(Int32(self.queue))

        if result == -1:
            var errno = get_errno()
            raise Error("close(kqueue) failed with errno: ", errno.value)

    def _submit_change(mut self, file_descriptor: Int, filter: Int16, flags: UInt16) raises -> None:
        """Submit a single registration change to the kernel queue.

        Args:
            file_descriptor: The file descriptor associated with the change.
            filter: The kernel filter to update.
            flags: The kqueue action flags for the change.

        Raises:
            Error: If `kevent()` fails or the kernel reports an event error.
        """
        var change = KEvent(UInt(file_descriptor), filter, flags, 0, 0, 0)
        var event = KEvent(0, 0, 0, 0, 0, 0)
        var timeout = TimeSpec(0, 0)

        var result = _kevent(
            Int32(self.queue),
            Pointer(to=change),
            1,
            Pointer(to=event),
            1,
            Pointer(to=timeout),
        )

        if result == -1:
            var errno = get_errno()
            raise Error("kevent() registration failed with errno: ", errno.value)

        if result == 1 and event.flags & EV_ERROR and event.data != 0:
            raise Error("kevent() registration failed with kernel error: ", event.data)

    def _delete_change(mut self, file_descriptor: Int, filter: Int16) raises -> None:
        """Best-effort removal of a single kernel event registration.

        Args:
            file_descriptor: The file descriptor whose registration should be removed.
            filter: The kernel filter to unregister.

        Raises:
            Error: If unregistering fails for reasons other than a missing entry.
        """
        var change = KEvent(UInt(file_descriptor), filter, EV_DELETE, 0, 0, 0)
        var event = KEvent(0, 0, 0, 0, 0, 0)
        var timeout = TimeSpec(0, 0)

        var result = _kevent(
            Int32(self.queue),
            Pointer(to=change),
            1,
            Pointer(to=event),
            1,
            Pointer(to=timeout),
        )

        if result == -1:
            var errno = get_errno()
            if errno == errno.ENOENT:
                return
            raise Error("kevent() unregister failed with errno: ", errno.value)

        if result == 1 and event.flags & EV_ERROR and event.data != 0:
            if Int(event.data) == Int(get_errno().ENOENT.value):
                return
            raise Error("kevent() unregister failed with kernel error: ", event.data)

    def _timeout_to_timespec(self, timeout_micros: Int) -> TimeSpec:
        """Convert a microsecond timeout to `timespec`.

        Args:
            timeout_micros: Timeout in microseconds.

        Returns:
            A `TimeSpec` value representing the same duration.
        """
        if timeout_micros <= 0:
            return TimeSpec(0, 0)

        var seconds = timeout_micros // 1000000
        var remaining_micros = timeout_micros % 1000000
        return TimeSpec(Int64(seconds), Int64(remaining_micros * 1000))
