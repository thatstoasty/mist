"""Selector-parameterized terminal event readers."""

from std.collections import Deque

from mist.event.event import Event
from mist.event.event import KeyEvent
from mist.event.internal import InternalEvent
from mist.multiplex.selector import Selector

from .unix_event_source import UnixInternalEventSource


@fieldwise_init
struct InternalEventReader[
    SelectorType: Selector & ImplicitlyDestructible
](Movable):
    """Reads internal events from a selector-parameterized Unix event source."""

    var events: Deque[InternalEvent]
    """Queued internal events ready to be returned."""
    var source: UnixInternalEventSource[Self.SelectorType]
    """Event source used to read terminal events."""
    var skipped_events: List[InternalEvent]
    """Events skipped by higher-level filtering and replayed on future reads."""

    def poll(mut self, timeout: Optional[Int]) raises -> Bool:
        """Poll for events from the event source.

        Args:
            timeout: Optional timeout for the poll operation in microseconds.

        Returns:
            True if an event was received, False if the operation timed out.

        Raises:
            Error: Propagated from the underlying event source.
        """
        var poll_timeout = timeout.value() if timeout else 0
        while True:
            var maybe_event = self.source.try_read(poll_timeout)
            if not maybe_event:
                return False

            self.events.append(maybe_event.take())
            return True

    def try_read(mut self) raises -> Optional[InternalEvent]:
        """Try to read a single queued internal event.

        Returns:
            An event if one is queued, otherwise None.

        Raises:
            Error: Propagated from queue operations when relevant.
        """
        if len(self.events) > 0:
            var event = self.events.popleft()
            return Optional[InternalEvent](event^)
        return None

    def read(mut self) raises -> InternalEvent:
        """Block until a single internal event is available.

        Returns:
            The next internal event.

        Raises:
            Error: Propagated from the underlying event source.
        """
        while True:
            var event = self.try_read()
            if event:
                return event.take()

            _ = self.poll(None)


@fieldwise_init
struct EventReader[
    SelectorType: Selector & ImplicitlyDestructible
](Movable):
    """Public event reader parameterized over the selector backend."""

    var reader: InternalEventReader[Self.SelectorType]
    """Internal event reader."""

    def __init__(out self, var source: UnixInternalEventSource[Self.SelectorType]) raises:
        """Initialize the reader with an explicit event source.

        Args:
            source: The selector-parameterized event source to read from.

        Returns:
            None. Initializes `self` in place.
        """
        self.reader = InternalEventReader[Self.SelectorType](
            events=Deque[InternalEvent](), source=source^, skipped_events=List[InternalEvent]()
        )

    def __init__(out self, var selector: Self.SelectorType) raises:
        """Initialize the reader with an explicit selector backend.

        Args:
            selector: The selector backend to use for terminal polling.

        Returns:
            None. Initializes `self` in place.

        Raises:
            Error: If constructing the underlying event source fails.
        """
        var source = UnixInternalEventSource[Self.SelectorType](selector^)
        self = Self(source^)

    def read(mut self) raises -> Event:
        """Read a single public event.

        Returns:
            The next public event.

        Raises:
            Error: Propagated from the underlying event source.
        """
        var internal_event = self.reader.read()
        if not internal_event.is_event():
            raise Error("expected public event")

        ref event = internal_event.as_event()
        if event.isa[KeyEvent]():
            return Event(event[KeyEvent])
        return event.copy()
