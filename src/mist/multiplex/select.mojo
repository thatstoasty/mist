from sys.ffi import external_call, os_is_windows, os_is_macos
from collections import Optional, Set, BitSet
from sys import exit, stdin

from mist.termios.c import c_void, c_int
import mist.termios.c
from mist.multiplex.selector import Selector
from mist.multiplex.event import Event


@fieldwise_init
@register_passable("trivial")
struct TimeValue(Movable, Copyable, ExplicitlyCopyable):
    """C struct timeval equivalent in Mojo.
    Represents a time value with seconds and microseconds.
    This is used in the POSIX `select` function to specify a timeout.
    """

    var seconds: Int64
    """Seconds part of the time value."""
    var microseconds: Int64
    """Microseconds part of the time value."""


# TODO (Mikhail): Perhaps tune the size of the bitset to a reasonable
# maximum number of file descriptors. On some platforms, it's technically infinity.
# But how many files will reasonably be open at the same time?
alias FileDescriptorBitSet = BitSet[1024]
"""BitSet for file descriptors, with a size of 1024 bits."""


# pub struct fd_set {
#         fds_bits: [c_ulong; FD_SETSIZE as usize / ULONG_SIZE],
#     }

# alias FD_SETSIZE = 1024

# struct FileDescriptorSet[size: UInt = FD_SETSIZE]:
#     var fds_bits: InlineArray[UInt32, FD_SETSIZE // ULONG_SIZE]


fn _select(
    nfds: c_int,
    readfds: Pointer[mut=True, FileDescriptorBitSet],
    writefds: Pointer[mut=True, FileDescriptorBitSet],
    exceptfds: Pointer[mut=True, FileDescriptorBitSet],
    timeout: Pointer[mut=True, TimeValue],
) -> c_int:
    """Libc POSIX `select` function.

    Args:
        nfds: The highest-numbered file descriptor in any of the three sets, plus 1.
        readfds: A pointer to the set of file descriptors to read from.
        writefds: A pointer to the set of file descriptors to write to.
        exceptfds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a TimeValue struct to set a timeout.

    Returns:
        The number of file descriptors in the sets or -1 in case of failure.

    #### C Function:
    ```c
    int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man2/select.2.html
    """
    return external_call[
        "select",
        c_int,  # FnName, RetType
    ](nfds, readfds, writefds, exceptfds, timeout)


fn select(
    highest_fd: c_int,
    mut read_fds: FileDescriptorBitSet,
    mut write_fds: FileDescriptorBitSet,
    mut except_fds: FileDescriptorBitSet,
    mut timeout: TimeValue,
) raises -> None:
    """Libc POSIX `select` function.

    Args:
        highest_fd: The highest-numbered file descriptor in any of the three sets, plus 1.
        read_fds: A pointer to the set of file descriptors to read from.
        write_fds: A pointer to the set of file descriptors to write to.
        except_fds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a TimeValue struct to set a timeout.

    #### C Function Signature:
    ```c
    int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
    ```

    #### Reference
    https://man7.org/linux/man-pages/man2/select.2.html.
    """
    var result = _select(
        highest_fd,
        Pointer(to=read_fds),
        Pointer(to=write_fds),
        Pointer(to=except_fds),
        Pointer(to=timeout),
    )

    if result == -1:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error("[EBADF] An invalid file descriptor was given in one of the sets.")
        elif errno == c.EINTR:
            raise Error("[EINTR] A signal was caught.")
        elif errno == c.EINVAL:
            raise Error("[EINVAL] nfds is negative or exceeds the RLIMIT_NOFILE resource limit.")
        elif errno == c.ENOMEM:
            raise Error("[ENOMEM] Unable to allocate memory for internal tables.")
        else:
            raise Error("[UNKNOWN] Unknown error occurred.")
    elif result == 0:
        raise Error("Select has timed out while waiting for file descriptors to become ready.")


# fn stdin_select(timeout: Optional[Int] = None) raises -> Event:
#     """Perform the actual selection, until some monitored file objects are
#     ready or a timeout expires.

#     Args:
#         timeout: If timeout > 0, this specifies the maximum wait time, in seconds.
#             if timeout <= 0, the select() call won't block, and will
#             report the currently ready file objects
#             if timeout is None, select() will block until a monitored
#             file object becomes ready.

#     Returns:
#         List of (key, events) for ready file objects
#         `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
#     """
#     var readers = FileDescriptorBitSet()
#     readers.set(stdin.value)

#     var tv = TimeValue(0, 0)
#     if timeout:
#         tv.tv_sec = Int64(timeout.value())

#     select(
#         stdin.value + 1,
#         readers,
#         FileDescriptorBitSet(),
#         FileDescriptorBitSet(),
#         tv,
#     )

#     if readers.test(0):
#         return Event(0) | Event.READ

#     return Event(0)


@fieldwise_init
struct SelectSelector(Movable, Selector):
    """Selector for monitoring file descriptors using the POSIX `select` function.
    This selector allows you to register file descriptors and monitor them for
    readiness to read or write.
    It uses the `select` system call to check which file descriptors are ready
    for reading or writing, and it can handle multiple file descriptors at once.

    #### Notes:
    - This selector is suitable for use in event-driven applications where you
    need to monitor multiple file descriptors for readiness.
    - It is a low-level selector that works with file descriptors directly,
    making it suitable for use with raw sockets, pipes, and other file-like objects.
    """

    var readers: Set[Int]
    """Selector for monitoring file descriptors ready to read from using the POSIX `select` function."""
    var writers: Set[Int]
    """Selector for monitoring file descriptors ready to write to using the POSIX `select` function."""
    var _highest_fd: Int
    """The highest file descriptor number registered in the selector."""

    fn __init__(out self):
        """Initialize the SelectSelector."""
        self.readers = Set[Int]()
        self.writers = Set[Int]()
        self._highest_fd = 0

    fn register(mut self, file_descriptor: FileDescriptor, events_to_monitor: Event) -> None:
        """Register a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_monitor: Events to monitor.
        """
        if events_to_monitor & Event.READ:
            self.readers.add(file_descriptor.value)

        if events_to_monitor & Event.WRITE:
            self.writers.add(file_descriptor.value)

        if file_descriptor.value > self._highest_fd:
            self._highest_fd = file_descriptor.value

    fn unregister(mut self, file_descriptor: FileDescriptor, events_to_stop: Event) -> None:
        """Unregister a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_stop: Events to stop monitoring.

        #### Notes:
            If fileobj is registered but has since been closed this does.
        """
        # TODO (Mikhail): Perhaps change the function signature to accept
        # an event mask to indicate which sets the file descriptor should be removed from.
        if events_to_stop & Event.READ:
            try:
                self.readers.remove(file_descriptor.value)
            except:
                # Should only raise KeyError which is fine to skip.
                pass

        if events_to_stop & Event.WRITE:
            try:
                self.writers.remove(file_descriptor.value)
            except:
                # Should only raise KeyError which is fine to skip.
                pass

    fn select(mut self, timeout: Int = 0) raises -> Dict[Int, Event]:
        """Perform the actual selection, until some monitored file objects are
        ready or a timeout expires.

        Args:
            timeout: Maximum wait time, in microseconds.

        Returns:
            Dictionary of (key, events) for ready file objects
            `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.

        #### Notes:
        - If timeout > 0, this specifies the maximum wait time, in microseconds.
        - If timeout <= 0, the select() call won't block, and will report
          the currently ready file objects.
        """
        var tv = TimeValue(0, timeout)

        var readers = FileDescriptorBitSet()
        for reader in self.readers:
            readers.set(reader)

        var writers = FileDescriptorBitSet()
        for writer in self.writers:
            writers.set(writer)

        var exceptions = FileDescriptorBitSet()
        try:
            select(
                Int32(self._highest_fd + 1),
                readers,
                writers,
                exceptions,
                tv,
            )
        except e:
            if e.as_string_slice() == "Select has timed out while waiting for file descriptors to become ready.":
                return Dict[Int, Event]()  # Return empty dict if timeout occurs.
            else:
                raise

        var ready = Dict[Int, Event]()
        for i in range(readers.size):
            if readers.test(i):
                if i in ready:
                    ready[i] |= Event.READ
                else:
                    ready[i] = Event.READ

        for i in range(writers.size):
            if writers.test(i):
                if i in ready:
                    ready[i] |= Event.WRITE
                else:
                    ready[i] = Event.WRITE

        return ready^

    fn close(self) -> None:
        """Close the selector.

        This must be called to make sure that any underlying resource is freed.
        """
        pass
