"""Unix event source for terminal input handling.

This module provides functionality to read and parse terminal input events
on Unix systems. It handles:
- TTY input reading with non-blocking I/O
- SIGWINCH (window resize) signal handling
- Event parsing and buffering

## Usage

    from mist.terminal.unix_event_source import UnixInternalEventSource

    var source = UnixInternalEventSource()
    var event = source.try_read(timeout=1000)  # 1 second timeout
    if event:
        print(event.value())

## Notes

- The event source uses select() for multiplexing I/O

## TODO:
- SIGWINCH signals are handled via a Unix socket pair
- Event-stream features are not implemented (no async/waker support)
"""

from collections import Deque
from sys import stderr, stdin
from sys._libc_errno import get_errno

from sys.ffi import c_size_t
from mist.event.internal import InternalEvent
from mist.event.parser import parse_event
from mist.event.source import EventSource
from mist.multiplex.event import Event as SelectEvent
from mist.multiplex.select import SelectSelector
from mist.termios.c import read

from mist.event.event import Event, Resize


# Buffer size for TTY reads. 1024 bytes is enough based on testing
# showing max reads of ~1022 bytes on macOS/Linux.
comptime TTY_BUFFER_SIZE: Int = 1024


# ============================================================================
# Poll Timeout Helper
# ============================================================================


struct PollTimeout:
    """Helper for tracking poll timeout remaining time.

    This is a simplified version that tracks elapsed time to determine
    how much timeout remains for subsequent poll/select calls.
    """

    var timeout_micros: Optional[Int]
    """Original timeout in microseconds, or None for indefinite."""
    var start_time_ns: Int
    """Start time in nanoseconds."""

    fn __init__(out self, timeout_micros: Optional[Int]):
        """Initialize a poll timeout.

        Args:
            timeout_micros: Timeout in microseconds, or None for indefinite wait.
        """
        self.timeout_micros = timeout_micros
        self.start_time_ns = _get_time_ns()

    fn leftover(self) -> Optional[Int]:
        """Get the remaining timeout in microseconds.

        Returns:
            Remaining time in microseconds, or None for indefinite.
            Returns 0 if timeout has elapsed.
        """
        if not self.timeout_micros:
            return None

        var elapsed_ns = _get_time_ns() - self.start_time_ns
        var elapsed_micros = elapsed_ns // 1000
        var remaining = self.timeout_micros.value() - elapsed_micros

        if remaining <= 0:
            return 0
        return remaining

    fn elapsed(self) -> Bool:
        """Check if the timeout has elapsed.

        Returns:
            True if timeout has elapsed, False otherwise.
        """
        if not self.timeout_micros:
            return False

        var remaining = self.leftover()
        if not remaining:
            return False
        return remaining.value() == 0

    fn is_zero(self) -> Bool:
        """Check if the remaining timeout is zero.

        Returns:
            True if remaining time is zero, False otherwise.
        """
        var remaining = self.leftover()
        if not remaining:
            return False
        return remaining.value() == 0


fn _get_time_ns() -> Int:
    """Get current time in nanoseconds.

    Returns:
        Current time in nanoseconds since some epoch.
    """
    from time import perf_counter_ns

    return Int(perf_counter_ns())


# ============================================================================
# Parser for buffering and parsing events
# ============================================================================


struct Parser(Movable):
    """Parser for buffering terminal input and producing events.

    The Parser accumulates bytes from TTY reads and attempts to parse them
    into events. It maintains a buffer for incomplete sequences and a queue
    of parsed events.

    This exists for two reasons:
    - Mimic anes Parser interface
    - Move the advancing, parsing, ... stuff out of the try_read method
    """

    var buffer: List[UInt8]
    """Buffer for accumulating bytes of the current escape sequence."""
    var internal_events: Deque[InternalEvent]
    """Queue of parsed internal events."""

    fn __init__(out self):
        """Initialize the parser with default buffer sizes."""
        # Buffer for -> 1 <- ANSI escape sequence. 256 bytes should be enough
        # for any reasonable escape sequence.
        self.buffer = List[UInt8](capacity=256)
        # TTY_BUFFER_SIZE is 1024 bytes. Assuming average escape sequence
        # length of 8 bytes, we need capacity for ~128 events to avoid
        # reallocations when processing large amounts of data.
        self.internal_events = Deque[InternalEvent](capacity=128)

    fn advance(mut self, buffer: Span[UInt8], more: Bool):
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
                    self.internal_events.append(maybe_event.value().copy())
                    self.buffer.clear()
                # If event is None, keep the buffer and wait for more bytes
            except:
                # Event can't be parsed (not enough parameters, parameter is not a number, ...).
                # Clear the buffer and continue with another sequence.
                self.buffer.clear()

    fn next(mut self) -> Optional[InternalEvent]:
        """Get the next parsed event from the queue.

        Returns:
            The next InternalEvent if available, None otherwise.
        """
        if len(self.internal_events) > 0:
            try:
                var event = self.internal_events.popleft()
                return Optional[InternalEvent](event.copy())
            except:
                return None
        return None


# ============================================================================
# Unix Internal Event Source
# ============================================================================


struct UnixInternalEventSource(EventSource, Movable):
    """Event source for reading terminal input on Unix systems.

    This struct manages:
    - TTY file descriptor for reading input
    - Parser for buffering and parsing escape sequences
    - Signal handling for window resize events (SIGWINCH)

    Uses select() for multiplexing I/O between the TTY and signal pipe.
    """

    var parser: Parser
    """Parser for buffering and converting bytes to events."""
    var tty_buffer: InlineArray[UInt8, TTY_BUFFER_SIZE]
    """Buffer for reading from TTY."""
    var tty: FileDescriptor
    """TTY file descriptor."""
    var selector: SelectSelector
    """Selector for multiplexing TTY using `select`."""
    # Note: SIGWINCH handling via Unix socket pair is not implemented here
    # as it requires signal handling infrastructure not yet available.
    # For now, resize events can be detected by polling terminal size.

    fn __init__(out self, tty: FileDescriptor):
        """Initialize the event source with a specific file descriptor.

        Args:
            tty: The file descriptor to use for reading input.
        """
        self.parser = Parser()
        self.tty_buffer = InlineArray[UInt8, TTY_BUFFER_SIZE](uninitialized=True)
        self.tty = tty
        self.selector = SelectSelector()
        self.selector.register(self.tty, SelectEvent.READ)

    fn __init__(out self) raises:
        """Initialize the event source using stdin as the TTY.

        Raises:
            Error: If stdin is not a terminal.
        """
        if not stdin.isatty():
            raise Error("stdin is not a terminal")
        self = Self(stdin)

    fn try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
        """Try to read an event with an optional timeout.

        This method polls for input and parses events. It handles:
        - Buffered events from previous reads
        - New TTY input
        - Interrupted system calls (retries automatically)

        Args:
            timeout: Timeout in microseconds, or None for indefinite wait.

        Raises:
            Error: If an unrecoverable I/O error occurs.

        Returns:
            An InternalEvent if one is available, None if timeout elapsed.
        """
        var poll_timeout = PollTimeout(timeout)
        while poll_timeout.leftover().or_else(-1) <= 0:
            # Check if there are buffered events from the last read
            if buffered_event := self.parser.next():
                return buffered_event

            # First checks if the file descriptor is ready.
            # If so, checks if the response is either `SelectEvent.READ` or `SelectEvent.READ_WRITE`
            var status = self.selector.select().get(self.tty.value)
            if not status:
                continue

            # We just checked that the optional is not None, so we can safely check the value.
            if not status.unsafe_value() & SelectEvent.READ:
                continue

            # TTY is ready for reading
            while True:
                var read_count = self._read_complete()
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

    fn _read_complete(mut self) raises -> Int:
        """Read from TTY until buffer is full or would block.

        Similar to std::io::Read::read_to_end, except this function
        only fills the given buffer and does not read beyond that.

        Returns:
            Number of bytes read, or 0 if would block.
        """
        while True:
            var bytes_read = read(
                self.tty.value,
                self.tty_buffer.unsafe_ptr().bitcast[NoneType](),
                c_size_t(TTY_BUFFER_SIZE),
            )

            if bytes_read >= 0:
                return Int(bytes_read)

            # Error case
            var errno = get_errno()
            # EAGAIN/EWOULDBLOCK - no data available (non-blocking)
            if errno == errno.EWOULDBLOCK:  # EWOULDBLOCK = EAGAIN on Linux
                return 0
            # EINTR - interrupted, retry
            elif errno == errno.EINTR:
                continue
            else:
                raise Error("read() failed with errno: ", errno.value)
