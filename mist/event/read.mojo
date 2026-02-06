from collections import Deque
from sys import stdin

from ffi import c_int, c_size_t, external_call
from mist.event.internal import InternalEvent
from mist.event.parser import parse_event
from mist.event.unix_event_source import UnixInternalEventSource


fn read_events() raises -> Optional[InternalEvent]:
    """Reads a single event from stdin. Read is normally blocking, but the terminal
    is set to non-blocking mode, so this will return immediately if there is no
    data to read. If there is no data to read, this will return a NoMsg message.

    Returns:
        An InternalEvent containing the event read from stdin. This will be a KeyMsg if
        a key was pressed, or a NoMsg if there was no data to read.
    """
    comptime COUNT_TO_READ = 8

    # We use a stack allocation to avoid heap allocations.
    # We don't need to free stack allocated pointers, I guess?
    # Freeing it works when its a heap allocated pointer, but not stack allocated.
    # var buffer = InlineArray[Byte, COUNT_TO_READ](uninitialized=True)
    # _ = read(stdin.value, buffer.unsafe_ptr().bitcast[NoneType](), COUNT_TO_READ)
    # var event = parse_event(Span(buffer).get_immutable(), True)
    # return event^
    var reader = InternalEventReader(
        events=Deque[InternalEvent](), source=UnixInternalEventSource(), skipped_events=List[InternalEvent]()
    )
    return reader.read()


@fieldwise_init
struct InternalEventReader:
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
