"""Thanks to the following projects for inspiration and code snippets!

- https://github.com/Canop/xterm-query/tree/main
- https://github.com/muesli/termenv/tree/master
"""
import os
import sys
from collections import BitSet, InlineArray
from pathlib import Path

from mist.style.color import RGBColor
from mist.terminal.sgr import BEL, CSI, ESC, OSC, ST
from mist.terminal.tty import TTY
from mist.terminal.xterm import XTermColor
from mist.termios.c import FileDescriptorBitSet, _TimeValue, select
from mist.termios.tty import is_terminal_raw

from mist.style import _hue as hue


comptime EVENT_READ = 1
"""Bitwise mask for select read events."""


fn _select(
    file_descriptor: FileDescriptor,
    mut readers: FileDescriptorBitSet,
    mut writers: BitSet[1],
    mut exceptions: BitSet[1],
    timeout: Optional[Int] = None,
) raises -> Int:
    """Perform the actual selection, until some monitored file objects are
    ready or a timeout expires.

    Args:
        file_descriptor: The file descriptor to monitor.
        readers: The set of file descriptors to monitor for read events.
        writers: The set of file descriptors to monitor for write events.
        exceptions: The set of file descriptors to monitor for exceptional conditions.
        timeout: If timeout > 0, this specifies the maximum wait time, in microseconds.
            if timeout <= 0, the select() call won't block, and will
            report the currently ready file objects
            if timeout is None, select() will block until a monitored
            file object becomes ready.

    Raises:
        Error: If the program returns a failure when calling C's `select` function.

    Returns:
        List of (key, events) for ready file objects
        `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
    """
    readers.set(file_descriptor.value)

    var tv = _TimeValue(0, 0)
    if timeout:
        tv.microseconds = Int64(timeout.value())

    select(
        Int32(file_descriptor.value + 1),
        readers,
        writers,
        exceptions,
        tv,
    )

    if readers.test(file_descriptor.value):
        readers.clear(file_descriptor.value)
        return 0 | EVENT_READ

    readers.clear(file_descriptor.value)
    return 0


fn wait_for_input(file_descriptor: FileDescriptor, timeout: Int = 100000) raises -> None:
    """Waits for input from stdin.

    Args:
        file_descriptor: The file descriptor to wait for input from.
        timeout: The maximum time to wait for input in seconds. Default is 100000 microseconds.

    Raises:
        Error: If the timeout is reached without input.
    """
    var readers = FileDescriptorBitSet()
    var writers = BitSet[1]()
    var exceptions = BitSet[1]()
    while True:
        # Checks if the response is either `Event.READ` or `Event.READ_WRITE`
        if _select(file_descriptor, readers, writers, exceptions, timeout) & EVENT_READ:
            return


fn get_background_color() raises -> RGBColor:
    """Queries the terminal for the background color.

    Raises:
        Error: Terminal does not respond with a valid background color sequence.
        Error: Could not parse background color sequence as it is not a valid xterm color sequence.

    Returns:
        A tuple containing the red, green, and blue components of the background color.
    """
    return XTermColor(query_osc("11;?")).to_rgb_color()


fn has_dark_background() raises -> Bool:
    """Checks if the terminal has a dark background.

    Raises:
        Error: If the terminal does not respond with a valid background color sequence.
        Error: If the background color sequence is not a valid xterm color sequence.

    Returns:
        True if the terminal has a dark background, False otherwise.
    """
    var color = hue.Color(get_background_color().value)
    _, _, luminance = color.hsl()
    return luminance < 0.5


@fieldwise_init
@register_passable("trivial")
struct OSCParseState(Copyable, Equatable):
    """State for parsing OSC sequences."""

    var value: Int
    """The current state value."""
    comptime RESPONSE_START_SEARCH = Self(0)
    """State for searching the start of the response."""
    comptime RESPONSE_END_SEARCH = Self(1)
    """State for searching the end of the response."""
    comptime FENCE_END_SEARCH = Self(2)
    """State for searching the end of the fence."""

    fn __eq__(self, other: Self) -> Bool:
        """Equality comparison.

        Args:
            other: The other state to compare with.

        Returns:
            True if the states are equal, False otherwise.
        """
        return self.value == other.value


fn query_osc_buffer[verify: Bool = True](sequence: StringSlice, mut buffer: InlineArray[Byte]) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.
    This function will wrap `sequence` with OSC and BEL, so it should they should not be included in `sequence`.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.
        buffer: The buffer to store the response.

    Raises:
        Error: If the terminal is not in raw mode, and verify is `True`.
        Error: If STDIN is not a terminal.
        Error: If EOF is reached before fully parsing the terminal OSC response.
        Error: If the OSC response from the terminal is in an unexpected format.

    Returns:
        The response from the terminal. This response excludes the response start (ESC) and everything before
        the response end (ESC or BEL) and everything after.
    """

    @parameter
    if verify:
        # TODO (Mikhail): Reassess this later once I learn more about /dev/tty.
        # I figure we'd want to check the controlling tty, but that throws an error
        # indicating its an invalid file descriptor.
        if not is_terminal_raw(sys.stdin):
            raise Error("Terminal must be in raw mode to query OSC sequences.")

    var term = os.getenv("TERM")
    if term == "dumb":
        raise Error("Unsupported terminal. Cannot query a dumb terminal.")

    var is_screen = term.startswith("screen")

    # TODO (Mikhail): Use buffered writes to stdout to avoid the intermediate String allocation.
    # Running under GNU Screen, the commands need to be "escaped",
    # apparently.  We wrap them in a "Device Control String", which
    # will make Screen forward the contents uninterpreted.
    var query = String(OSC)
    if is_screen:
        query.write(ESC, "P")

    # Write the sequence to the query, then mark the end with BEL.
    # OSC queries must start with OSC, and can be ended with BEL or ST.
    query.write(sequence, BEL)

    # Ask for cursor position as a "fence". Almost all terminals will
    # support that command, even if they don't support returning the
    # background color, so we can detect "not supported" by the
    # Status Report being answered first.
    query.write(CSI, "6n")

    if is_screen:
        # If we are running under GNU Screen, we need to end the
        # Device Control String with a ST (String Terminator).
        query.write(ST)

    # Query the terminal by writing the sequence to stdout.
    print(query, sep="", end="")

    var total_bytes_read = 0
    var start_idx = 0  # Start of the OSC query response.
    var end_idx = 0  # End of the OSC query response.

    # Response should contain three parts:
    # The response to the OSC query that starts with OSC and ends with BEL or ST.
    # An ESC + ST.
    # And the cursor position response, which should end with 'R'.
    var stdin = sys.stdin
    if not stdin.isatty():
        raise Error("STDIN is not a terminal.")

    var state = OSCParseState.RESPONSE_START_SEARCH
    while total_bytes_read < buffer.size:
        # Wait for input from the tty.
        wait_for_input(stdin)

        var buf = Span(buffer)[total_bytes_read:]  # Unused slice of buffer.
        var bytes_read = stdin.read_bytes(buf)

        if bytes_read == 0:
            raise Error("EOF")
        elif buf[0] != ord(ESC):
            raise Error("Unexpected response from terminal. Did not start with ESC.")

        for i in range(0, bytes_read):
            ref byte = buf[i]
            if state == OSCParseState.RESPONSE_START_SEARCH:
                if byte == ord(ESC):
                    start_idx = i + 1  # Skip the ESC
                    state = OSCParseState.RESPONSE_END_SEARCH
                    continue
            elif state == OSCParseState.RESPONSE_END_SEARCH:
                if byte == ord(ESC) or byte == ord(BEL):
                    end_idx = total_bytes_read + i  # Total bytes read + i = total bytes read from all reads.
                    state = OSCParseState.FENCE_END_SEARCH
                    continue
            elif state == OSCParseState.FENCE_END_SEARCH:
                if byte == ord("R"):
                    return String(from_utf8=Span(buffer)[start_idx:end_idx])

        total_bytes_read += Int(bytes_read)

    raise Error("Failed to read the complete response from stdin. Expected 'R' at the end.")


fn query_osc[verify: Bool = True](sequence: StringSlice) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.

    Raises:
        Error: If the terminal is not in raw mode, and verify is `True`.
        Error: If STDIN is not a terminal.
        Error: If EOF is reached before fully parsing the terminal OSC response.
        Error: If the OSC response from the terminal is in an unexpected format.

    Returns:
        The response from the terminal.
    """
    var buffer = InlineArray[Byte, 256](uninitialized=True)
    return query_osc_buffer[verify](sequence, buffer)


fn query_buffer[verify: Bool = True](sequence: StringSlice, mut buffer: InlineArray[Byte]) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.
        buffer: The buffer to store the response.

    Raises:
        Error: The terminal is not in raw mode, and verify is `True`.
        Error: STDIN is not a terminal.
        Error: EOF is reached before fully parsing the terminal response.
        Error: The program returns a failure when calling C's `isatty` function.
        Error: The program returns a failure when calling C's `select` function.
        Error: Fails to read from stdin into the provided buffer.

    Returns:
        The response from the terminal.
    """

    @parameter
    if verify:
        # TODO (Mikhail): Same as above, reassess later.
        if not is_terminal_raw(sys.stdin):
            raise Error("Terminal must be in raw mode to query OSC sequences.")

    # Query the terminal by writing the sequence to stdout.
    print(sequence, sep="", end="")

    # Read the response into the provided buffer.
    var stdin = sys.stdin
    if not stdin.isatty():
        raise Error("STDIN is not a terminal.")

    wait_for_input(stdin)
    var bytes_read = stdin.read_bytes(buffer)
    if bytes_read == 0:
        raise Error("EOF")

    return String(from_utf8=Span(buffer)[0 : Int(bytes_read)])


fn query[verify: Bool = True](sequence: StringSlice) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.

    Raises:
        Error: The terminal is not in raw mode, and verify is `True`.
        Error: STDIN is not a terminal.
        Error: EOF is reached before fully parsing the terminal response.
        Error: The program returns a failure when calling C's `isatty` function.
        Error: The program returns a failure when calling C's `select` function.
        Error: Fails to read from stdin into the provided buffer.

    Returns:
        The response from the terminal.
    """
    var buffer = InlineArray[Byte, 256](uninitialized=True)
    return query_buffer[verify](sequence, buffer)


comptime TERMINAL_SIZE_SEQUENCE = CSI + "18t"
"""ANSI sequence to query the terminal size."""


fn get_terminal_size() raises -> Tuple[UInt16, UInt16]:
    """Returns the size of the terminal.

    Raises:
        Error: If the terminal does not respond with the expected format.
        Error: Fails to dispatch the terminal size query to the terminal.
        Error: Fails to convert the terminal size response to UInt.

    Returns:
        A tuple containing the number of rows and columns of the terminal.
    """
    var result = query(TERMINAL_SIZE_SEQUENCE)
    if not result.startswith("\033[8;"):
        raise Error("Unexpected response from terminal: ", repr(result))

    var parts = result.split(";")
    return (UInt16(atol(parts[1])), UInt16(atol(parts[2].split("t")[0])))


comptime CURSOR_COLOR_SEQUENCE = OSC + "12;?" + BEL
"""ANSI sequence to query the cursor color."""


fn get_cursor_color() raises -> RGBColor:
    """Queries the terminal for the cursor color.

    Raises:
        Error: Terminal does not respond with a valid cursor color sequence.
        Error: Could not parse cursor color sequence as it is not a valid xterm color sequence.

    Returns:
        An RGBColor representing the cursor color.
    """
    var result = query(CURSOR_COLOR_SEQUENCE)
    if not result.startswith("\033]12;"):
        raise Error("Unexpected response from terminal: ", repr(result))

    var parts = result.split(";")
    return XTermColor(parts[1]).to_rgb_color()
