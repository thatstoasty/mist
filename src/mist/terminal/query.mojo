"""Thanks to the following projects for inspiration and code snippets!

- https://github.com/Canop/xterm-query/tree/main
- https://github.com/muesli/termenv/tree/master
"""
from time import sleep
import os
from pathlib import Path
from memory import stack_allocation, UnsafePointer
from collections import InlineArray, BitSet
import sys

import mist._hue as hue
from mist.color import RGBColor
from mist.terminal.sgr import ESC, BEL, CSI, OSC, ST, _write_sequence_to_stdout
from mist.terminal.tty import TTY
from mist.termios.tty import is_terminal_raw
from mist.termios.terminal import is_a_tty, tty_name
from mist.termios.c import _TimeValue, select


alias EVENT_READ = 1
"""Bitwise mask for select read events."""


fn _select(file_descriptor: FileDescriptor, timeout: Optional[Int] = None) raises -> Int:
    """Perform the actual selection, until some monitored file objects are
    ready or a timeout expires.

    Args:
        file_descriptor: The file descriptor to monitor.
        timeout: If timeout > 0, this specifies the maximum wait time, in microseconds.
            if timeout <= 0, the select() call won't block, and will
            report the currently ready file objects
            if timeout is None, select() will block until a monitored
            file object becomes ready.

    Returns:
        List of (key, events) for ready file objects
        `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
    """
    var readers = BitSet[1024]()
    readers.set(file_descriptor.value)

    var tv = _TimeValue(0, 0)
    if timeout:
        tv.microseconds = Int64(timeout.value())

    var writers = BitSet[1024]()
    var exceptions = BitSet[1024]()

    select(
        file_descriptor.value + 1,
        readers,
        writers,
        exceptions,
        tv,
    )

    if readers.test(0):
        return 0 | EVENT_READ

    return 0


fn wait_for_input(file_descriptor: FileDescriptor, timeout: Int = 100000) raises -> None:
    """Waits for input from stdin.

    Args:
        file_descriptor: The file descriptor to wait for input from.
        timeout: The maximum time to wait for input in seconds. Default is 100000 microseconds.

    Raises:
        Error: If the timeout is reached without input.
    """
    while True:
        # Checks if the response is either `Event.READ` or `Event.READ_WRITE`
        if _select(file_descriptor, timeout) & EVENT_READ:
            return


fn parse_xterm_color(sequence: StringSlice) raises -> RGBColor:
    """Parses an xterm color sequence.

    Args:
        sequence: The color sequence to parse.

    Returns:
        A tuple containing the red, green, and blue components of the color.
    """
    var color = sequence.split("rgb:")[1]
    var parts = color.split("/")
    if len(parts) != 3:
        return RGBColor(0)

    fn convert_part_to_color(part: StringSlice) raises -> UInt8:
        """Converts a hex color part to an UInt8.

        Args:
            part: The hex color part to convert.

        Returns:
            An UInt8 representing the color component.
        """
        return UInt8(Int(part[2:], base=16))

    return RGBColor(
        hue.Color(
            R=convert_part_to_color(parts[0]), G=convert_part_to_color(parts[1]), B=convert_part_to_color(parts[2])
        )
    )


fn get_background_color() raises -> RGBColor:
    """Queries the terminal for the background color.

    Returns:
        A tuple containing the red, green, and blue components of the background color.
    """
    return parse_xterm_color(query_osc("11;?"))


@fieldwise_init
@register_passable("trivial")
struct OSCParseState(Movable, Copyable, ExplicitlyCopyable):
    """State for parsing OSC sequences."""

    var value: Int
    """The current state value."""
    alias RESPONSE_START_SEARCH = Self(0)
    """State for searching the start of the response."""
    alias RESPONSE_END_SEARCH = Self(1)
    """State for searching the end of the response."""
    alias FENCE_END_SEARCH = Self(2)
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
    _write_sequence_to_stdout(query)

    var total_bytes_read = 0
    var start_idx = 0  # Start of the OSC query response.
    var end_idx = 0  # End of the OSC query response.

    # Response should contain three parts:
    # The response to the OSC query that starts with OSC and ends with BEL or ST.
    # An ESC + ST.
    # And the cursor position response, which should end with 'R'.
    var stdin = sys.stdin
    if not is_a_tty(stdin):
        raise Error("STDIN is not a terminal.")

    var state = OSCParseState.RESPONSE_START_SEARCH
    while total_bytes_read < buffer.size:
        # Wait for input from the tty.
        wait_for_input(stdin)

        var buf = Span(buffer)[total_bytes_read:]  # Unused slice of buffer.
        var bytes_read = stdin.read_bytes(buf)

        # print(bytes_read, "bytes read from stdin", total_bytes_read, "total bytes read")
        # print("Buffer content:", String(bytes=Span(buffer)[total_bytes_read:total_bytes_read + bytes_read]).__repr__())
        # for i in range(bytes_read):
        #     print(repr(chr(Int(buf[i]))))

        if bytes_read == 0:
            raise Error("EOF")
        elif buf[0] != ord(ESC):
            raise Error("Unexpected response from terminal. Did not start with ESC.")

        for i in range(0, bytes_read):
            # print("State", state.value, "at index", i, "byte:", chr(Int(buf[i])).__repr__(), "total bytes read:", total_bytes_read)
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
                    # print("Found R at index", i, start_idx, total_bytes_read + end_idx)
                    return String(bytes=Span(buffer)[start_idx:end_idx])

        total_bytes_read += bytes_read

    raise Error("Failed to read the complete response from stdin. Expected 'R' at the end.")


fn query_osc[verify: Bool = True](sequence: StringSlice) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.

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

    Returns:
        The response from the terminal.
    """

    @parameter
    if verify:
        # TODO (Mikhail): Same as above, reassess later.
        if not is_terminal_raw(sys.stdin):
            raise Error("Terminal must be in raw mode to query OSC sequences.")

    # Query the terminal by writing the sequence to stdout.
    _write_sequence_to_stdout(sequence)

    # Read the response into the provided buffer.
    var stdin = sys.stdin
    if not is_a_tty(stdin):
        raise Error("STDIN is not a terminal.")

    wait_for_input(stdin)
    if stdin.read_bytes(buffer) == 0:
        raise Error("EOF")

    return String(bytes=buffer)


fn query[verify: Bool = True](sequence: StringSlice) raises -> String:
    """Queries the terminal for a specific sequence. Assumes the terminal is in raw mode.

    Parameters:
        verify: If set to True, verifies that the terminal is in raw mode before querying.

    Args:
        sequence: The sequence to query.

    Returns:
        The response from the terminal.
    """
    var buffer = InlineArray[Byte, 256](uninitialized=True)
    return query_buffer[verify](sequence, buffer)


alias TERMINAL_SIZE_SEQUENCE = CSI + "18t"
"""ANSI sequence to query the terminal size."""


fn get_terminal_size() raises -> (UInt, UInt):
    """Returns the size of the terminal.

    Returns:
        A tuple containing the number of rows and columns of the terminal.
    """
    var result = query(TERMINAL_SIZE_SEQUENCE)
    if not result.startswith("\033[8;"):
        raise Error("Unexpected response from terminal: ", result)

    var parts = result.as_string_slice().split(";")
    return (Int(parts[1]), Int(parts[2].split("t")[0]))
