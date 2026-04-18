from std.collections import Deque
from std.sys import stdin
from std.ffi import c_int, c_size_t, external_call
from mist.event.internal import InternalEvent
from mist.event.parser import parse_event
from mist.event.unix_event_source import UnixInternalEventSource
from mist.event.event import Event


@fieldwise_init
struct InternalEventReader(Movable):
    """An internal event reader that reads events from a Unix event source and returns them as internal events."""
    var events: Deque[InternalEvent]
    """A queue of internal events that have been read from the event source but not yet returned by the reader."""
    var source: UnixInternalEventSource
    """The event source that the reader reads events from."""
    var skipped_events: List[InternalEvent]
    """A list of events that were read from the event source but skipped by the reader's filter. This is used to ensure that events that are skipped by the filter are not lost and can be returned by subsequent calls to poll or try_read."""

    def poll(mut self, timeout: Optional[Int]) raises -> Bool:
        """Polls for events from the event source. This will read events from the event source
        and add them to the internal event queue.

        Args:
            timeout: An optional timeout for the poll operation. If None, this will block indefinitely until an event is received.

        Returns:
            True if an event was received and added to the internal event queue, False if the poll operation timed out without receiving any events.

        Raises:
            Any errors raised by the event source while trying to read events.
        """
        # TODO: Filter events here
        # for event in self.events:
        #     if filter.eval(event):
        #         return True

        var poll_timeout = timeout.value() if timeout else 0
        while True:
            var maybe_event = self.source.try_read(poll_timeout)
            if not maybe_event:
                return False

            ref event = maybe_event.value()

            var skipped_events = self.skipped_events^
            self.skipped_events = List[InternalEvent]()
            self.events.extend(skipped_events^)
            self.events.append(event.copy())
            return True

    def try_read(mut self) raises -> Optional[InternalEvent]:
        """Tries to read a single event from the event reader. This will return None if no events are available.

        Returns:
            An Optional[InternalEvent] containing the event read from the event reader, or None if no events are available.

        Raises:
            Any errors raised by the event source while trying to read an event.
        """
        if len(self.events) > 0:
            return self.events.popleft()
        return None

    def read(mut self) raises -> InternalEvent:
        """Reads a single event from the event reader. This will block until an event is available.

        Returns:
            An InternalEvent containing the event read from the event reader.

        Raises:
            Any errors raised by the event source while trying to read an event.
        """
        while True:
            var event = self.try_read()
            if event:
                return event.value().copy()

            _ = self.poll(None)


@fieldwise_init
struct EventReader(Movable):
    """An event reader that reads events from an internal event reader and returns them as public events."""
    var reader: InternalEventReader
    """Internal event reader."""

    def __init__(out self) raises:
        self.reader = InternalEventReader(
            events=Deque[InternalEvent](), source=UnixInternalEventSource(), skipped_events=List[InternalEvent]()
        )

    def read(mut self) raises -> Event:
        """Reads a single event from the event reader. This will block until an event is available.

        Returns:
            An InternalEvent containing the event read from the event reader.
        """
        return self.reader.read()[Event].copy()
