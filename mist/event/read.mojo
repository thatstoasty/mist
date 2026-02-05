from collections import Deque
from sys import stdin

from sys.ffi import c_int, c_size_t, external_call
from mist.event.internal import InternalEvent
from mist.event.parser import parse_event
from mist.event.unix_event_source import UnixInternalEventSource

from mist.event.event import Event


@fieldwise_init
struct InternalEventReader(Movable):
    var events: Deque[InternalEvent]
    var source: UnixInternalEventSource
    var skipped_events: List[InternalEvent]

    fn poll(mut self, timeout: Optional[Int]) raises -> Bool:
        """Polls for events from the event source. This will read events from the event source
        and add them to the internal event queue.

        Args:
            timeout: An optional timeout for the poll operation. If None, this will block indefinitely until an event is received.
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

    #         if poll_timeout.elapsed() || maybe_event.is_some() {
    #             self.events.extend(self.skipped_events.drain(..));

    #             if let Some(event) = maybe_event {
    #                 self.events.push_front(event);
    #                 return Ok(true);
    #             }

    #             return Ok(false);
    #         }
    #     }
    # }

    fn try_read(mut self) raises -> Optional[InternalEvent]:
        if len(self.events) > 0:
            return self.events.popleft()
        return None

        # var event = read_events()
        # if not event:
        #     return None

    fn read(mut self) raises -> InternalEvent:
        while True:
            var event = self.try_read()
            if event:
                return event.value().copy()

            _ = self.poll(None)


@fieldwise_init
struct EventReader(Movable):
    var reader: InternalEventReader

    fn __init__(out self) raises:
        self.reader = InternalEventReader(
            events=Deque[InternalEvent](), source=UnixInternalEventSource(), skipped_events=List[InternalEvent]()
        )

    fn read(mut self) raises -> Event:
        """Reads a single event from the event reader. This will block until an event is available.

        Returns:
            An InternalEvent containing the event read from the event reader.
        """
        return self.reader.read()[Event].copy()
