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

- The event source uses kqueue on macOS and select() on other Unix targets

## TODO:
- SIGWINCH signals are handled via a Unix socket pair
- Event-stream features are not implemented (no async/waker support)
"""

from std.collections import Deque
from std.sys import stderr, stdin
from std.sys import CompilationTarget
from std.sys._libc_errno import get_errno

from std.ffi import c_size_t
from std.time import perf_counter_ns
from mist.event.internal import InternalEvent
from mist.event.parser import parse_event
from mist.event.source import EventSource
from mist.multiplex.event import Event as SelectEvent
from mist.multiplex.selector import Selector
from mist.termios.c import read

from mist.event.event import Event, Resize


comptime if CompilationTarget.is_macos():
    from mist.multiplex.kqueue import KQueueSelector
else:
    from mist.multiplex.select import SelectSelector


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

    def __init__(out self, timeout_micros: Optional[Int]):
        """Initialize a poll timeout.

        Args:
            timeout_micros: Timeout in microseconds, or None for indefinite wait.
        """
        self.timeout_micros = timeout_micros
        self.start_time_ns = _get_time_ns()

    def leftover(self) -> Optional[Int]:
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

    def elapsed(self) -> Bool:
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

    def is_zero(self) -> Bool:
        """Check if the remaining timeout is zero.

        Returns:
            True if remaining time is zero, False otherwise.
        """
        var remaining = self.leftover()
        if not remaining:
            return False
        return remaining.value() == 0


def _get_time_ns() -> Int:
    """Get current time in nanoseconds.

    Returns:
        Current time in nanoseconds since some epoch.
    """
    return Int(perf_counter_ns())


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
                    self.internal_events.append(maybe_event.value().copy())
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
                return Optional[InternalEvent](event.copy())
            except:
                return None
        return None


# ============================================================================
# Unix Internal Event Source
# ============================================================================


comptime if CompilationTarget.is_macos():
    struct UnixInternalEventSource(EventSource, Movable):
        """Event source for reading terminal input on Unix systems.

        This struct manages:
        - TTY file descriptor for reading input
        - Parser for buffering and parsing escape sequences
        - Signal handling for window resize events (SIGWINCH)

        Uses kqueue for multiplexing I/O on macOS.
        """

        var parser: Parser
        """Parser for buffering and converting bytes to events."""
        var tty_buffer: InlineArray[UInt8, TTY_BUFFER_SIZE]
        """Buffer for reading from TTY."""
        var tty: FileDescriptor
        """TTY file descriptor."""
        var selector: KQueueSelector
        """Selector for multiplexing TTY using `kqueue`."""
        # Note: SIGWINCH handling via Unix socket pair is not implemented here
        # as it requires signal handling infrastructure not yet available.
        # For now, resize events can be detected by polling terminal size.

        def __init__(out self, tty: FileDescriptor) raises:
            """Initialize the event source with a specific file descriptor.

            Args:
                tty: The file descriptor to use for reading input.

            Returns:
                None. Initializes `self` in place.

            Raises:
                Error: If creating or registering the internal selector fails.
            """
            self.parser = Parser()
            self.tty_buffer = InlineArray[UInt8, TTY_BUFFER_SIZE](uninitialized=True)
            self.tty = tty
            self.selector = KQueueSelector()
            self.selector.register(self.tty, SelectEvent.READ)

        def __init__(out self) raises:
            """Initialize the event source using stdin as the TTY.

            Returns:
                None. Initializes `self` in place.

            Raises:
                Error: If stdin is not a terminal.
                Error: If constructing the TTY-backed event source fails.
            """
            if not stdin.isatty():
                raise Error("stdin is not a terminal")
            self = Self(stdin)

        def try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
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
            return _try_read_from_selector(self.parser, self.tty, self.selector, self.tty_buffer, timeout)

        def _read_complete(mut self) raises -> Int:
            """Read from TTY until buffer is full or would block.

            Similar to std::io::Read::read_to_end, except this function
            only fills the given buffer and does not read beyond that.

            Returns:
                Number of bytes read, or 0 if would block.
            """
            return _read_from_tty(self.tty, self.tty_buffer)
else:
    struct UnixInternalEventSource(EventSource, Movable):
        """Event source for reading terminal input on Unix systems.

        This struct manages:
        - TTY file descriptor for reading input
        - Parser for buffering and parsing escape sequences
        - Signal handling for window resize events (SIGWINCH)

        Uses select() for multiplexing I/O on non-macOS Unix targets.
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

        def __init__(out self, tty: FileDescriptor) raises:
            """Initialize the event source with a specific file descriptor.

            Args:
                tty: The file descriptor to use for reading input.

            Returns:
                None. Initializes `self` in place.

            Raises:
                Error: If creating or registering the internal selector fails.
            """
            self.parser = Parser()
            self.tty_buffer = InlineArray[UInt8, TTY_BUFFER_SIZE](uninitialized=True)
            self.tty = tty
            self.selector = SelectSelector()
            self.selector.register(self.tty, SelectEvent.READ)

        def __init__(out self) raises:
            """Initialize the event source using stdin as the TTY.

            Returns:
                None. Initializes `self` in place.

            Raises:
                Error: If stdin is not a terminal.
                Error: If constructing the TTY-backed event source fails.
            """
            if not stdin.isatty():
                raise Error("stdin is not a terminal")
            self = Self(stdin)

        def try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
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
            return _try_read_from_selector(self.parser, self.tty, self.selector, self.tty_buffer, timeout)

        def _read_complete(mut self) raises -> Int:
            """Read from TTY until buffer is full or would block.

            Similar to std::io::Read::read_to_end, except this function
            only fills the given buffer and does not read beyond that.

            Returns:
                Number of bytes read, or 0 if would block.
            """
            return _read_from_tty(self.tty, self.tty_buffer)
