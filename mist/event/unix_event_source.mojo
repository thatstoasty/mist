"""Unix event source for terminal input handling."""

from std.sys import stdin
from std.sys._libc_errno import get_errno
from std.collections import Deque
from std.ffi import c_size_t

from mist.event.internal import InternalEvent
from mist.event.source import EventSource
from mist.event.parser import parse_event
from mist.event.timeout import PollTimeout
from mist.multiplex.event import Event as SelectEvent
from mist.multiplex.selector import Selector
from mist.termios.c import read

# ============================================================================
# Parser for buffering and parsing events
# ============================================================================

comptime TTY_BUFFER_SIZE: Int = 1024
"""Buffer size for TTY reads. 1024 bytes is enough based on testing
showing max reads of ~1022 bytes on macOS/Linux."""

struct Parser(Movable):
    """Parser for buffering terminal input and producing events.

    The Parser accumulates bytes from TTY reads and attempts to parse them
    into events. It maintains a buffer for incomplete sequences and a queue
    of parsed events.
    """

    var buffer: List[UInt8]
    """Buffer for accumulating bytes of the current escape sequence."""
    var internal_events: Deque[InternalEvent]
    """Queue of parsed internal events."""

    def __init__(out self):
        """Initialize the parser with default buffer sizes."""
        # Buffer for -> 1 <- ANSI escape sequence. 256 bytes should be enough
        # for any reasonable escape sequence.
        self.buffer = List[UInt8](capacity=256)
        # TTY_BUFFER_SIZE is 1024 bytes. Assuming average escape sequence
        # length of 8 bytes, we need capacity for ~128 events to avoid
        # reallocations when processing large amounts of data.
        self.internal_events = Deque[InternalEvent](capacity=128)

    def advance(mut self, buffer: Span[UInt8, ...], more: Bool):
        """Advance the parser with new bytes.

        Processes each byte and attempts to parse complete events.
        Successfully parsed events are added to the internal event queue.

        Args:
            buffer: New bytes to process.
            more: True if more bytes are available (i.e., buffer was full).
        """
        for idx in range(len(buffer)):
            var byte = buffer[idx]
            var has_more = idx + 1 < len(buffer) or more

            self.buffer.append(byte)

            try:
                var maybe_event = parse_event(Span(self.buffer).get_immutable(), has_more)
                if maybe_event:
                    self.internal_events.append(maybe_event.take())
                    self.buffer.clear()
                # If event is None, keep the buffer and wait for more bytes
            except:
                # Event can't be parsed (not enough parameters, parameter is not a number, ...).
                # Clear the buffer and continue with another sequence.
                self.buffer.clear()

    def next(mut self) -> Optional[InternalEvent]:
        """Get the next parsed event from the queue.

        Returns:
            The next InternalEvent if available, None otherwise.
        """
        if len(self.internal_events) > 0:
            try:
                var event = self.internal_events.popleft()
                return event^
            except:
                return None
        return None


def _read_from_tty(
    tty: FileDescriptor,
    mut tty_buffer: InlineArray[UInt8, TTY_BUFFER_SIZE],
) raises -> Int:
    """Read from a TTY until data is available or the read would block.

    Args:
        tty: The terminal file descriptor to read from.
        tty_buffer: Buffer used to receive the bytes read from the terminal.

    Returns:
        Number of bytes read, or 0 if the read would block.

    Raises:
        Error: If read fails with an unrecoverable errno.
    """
    while True:
        var bytes_read = read(
            Int32(tty.value),
            tty_buffer.unsafe_ptr().bitcast[NoneType](),
            c_size_t(TTY_BUFFER_SIZE),
        )

        if bytes_read >= 0:
            return Int(bytes_read)

        var errno = get_errno()
        if errno == errno.EWOULDBLOCK:
            return 0
        elif errno == errno.EINTR:
            continue
        else:
            raise Error("read() failed with errno: ", errno.value)


def _try_read_from_selector[SelectorType: Selector](
    mut parser: Parser,
    tty: FileDescriptor,
    mut selector: SelectorType,
    mut tty_buffer: InlineArray[UInt8, TTY_BUFFER_SIZE],
    timeout: Optional[Int],
) raises -> Optional[InternalEvent]:
    """Try to read an event using the configured selector backend.

    Args:
        parser: Parser used to buffer bytes and emit internal events.
        tty: Terminal file descriptor monitored for readability.
        selector: Concrete selector backend used to wait for readiness.
        tty_buffer: Scratch buffer for reading bytes from the terminal.
        timeout: Timeout in microseconds, or None for indefinite wait.

    Returns:
        An InternalEvent if one is available, None if timeout elapsed.

    Raises:
        Error: If selector polling or TTY reads fail.
    """
    var poll_timeout = PollTimeout(timeout)
    while poll_timeout.leftover().or_else(-1) <= 0:
        if buffered_event := parser.next():
            return buffered_event^

        var status = selector.select().get(tty.value)
        if not status:
            continue

        if not status.unsafe_value() & SelectEvent.READ:
            continue

        while True:
            var read_count = _read_from_tty(tty, tty_buffer)
            if read_count > 0:
                parser.advance(
                    Span(tty_buffer)[0:read_count].get_immutable(),
                    read_count == TTY_BUFFER_SIZE,
                )

            if event := parser.next():
                return event^

            if read_count == 0:
                break
    return None


struct UnixInternalEventSource[
    SelectorType: Selector & ImplicitlyDestructible
](EventSource, Movable):
    """Event source for reading terminal input on Unix systems.

    This struct manages:
    - TTY file descriptor for reading input
    - Parser for buffering and parsing escape sequences
    - Selector-based readiness polling
    """

    var parser: Parser
    """Parser for buffering and converting bytes to events."""
    var tty_buffer: InlineArray[UInt8, TTY_BUFFER_SIZE]
    """Buffer for reading from TTY."""
    var tty: FileDescriptor
    """TTY file descriptor."""
    var selector: Self.SelectorType
    """Selector used to multiplex the TTY."""

    def __init__(out self, tty: FileDescriptor, var selector: Self.SelectorType) raises:
        """Initialize the event source with a specific file descriptor and selector.

        Args:
            tty: The file descriptor to use for reading input.
            selector: The selector backend to use for readiness polling.

        Returns:
            None. Initializes `self` in place.

        Raises:
            Error: If registering the TTY with the selector fails.
        """
        self.parser = Parser()
        self.tty_buffer = InlineArray[UInt8, TTY_BUFFER_SIZE](uninitialized=True)
        self.tty = tty
        self.selector = selector^
        self.selector.register(self.tty, SelectEvent.READ)

    def __init__(out self, var selector: Self.SelectorType) raises:
        """Initialize the event source using stdin and an explicit selector.

        Args:
            selector: The selector backend to use for readiness polling.

        Returns:
            None. Initializes `self` in place.

        Raises:
            Error: If stdin is not a terminal.
            Error: If registering the TTY with the selector fails.
        """
        if not stdin.isatty():
            raise Error("stdin is not a terminal")
        self = Self(stdin, selector^)

    def try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
        """Try to read an event with an optional timeout.

        Args:
            timeout: Timeout in microseconds, or None for indefinite wait.

        Raises:
            Error: If an unrecoverable I/O or selector error occurs.

        Returns:
            An InternalEvent if one is available, None if timeout elapsed.
        """
        var poll_timeout = PollTimeout(timeout)
        while poll_timeout.leftover().or_else(-1) <= 0:
            if buffered_event := self.parser.next():
                return buffered_event^

            var status = self.selector.select().get(self.tty.value)
            if not status:
                continue

            if not status.unsafe_value() & SelectEvent.READ:
                continue

            while True:
                var read_count = _read_from_tty(self.tty, self.tty_buffer)
                if read_count > 0:
                    self.parser.advance(
                        Span(self.tty_buffer)[0:read_count].get_immutable(),
                        read_count == TTY_BUFFER_SIZE,
                    )

                if event := self.parser.next():
                    return event^

                if read_count == 0:
                    break
        return None

    def _read_complete(mut self) raises -> Int:
        """Read from TTY until buffer is full or would block.

        Returns:
            Number of bytes read, or 0 if would block.
        """
        return _read_from_tty(self.tty, self.tty_buffer)
