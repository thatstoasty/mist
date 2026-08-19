"""ANSI escape sequence constants and byte values used by text transforms."""
from std.io import write

from mist.transform.unicode import char_width, grapheme_width, string_width


comptime ANSI_ESCAPE = "[0m"
"""The ANSI escape sequence for resetting formatting."""
comptime ANSI_MARKER = "\x1b"
"""The ANSI escape sequence marker."""
comptime ANSI_MARKER_BYTE = UInt32(ord(ANSI_MARKER))
"""The byte value of the ANSI escape sequence marker."""
comptime SGR_COMMAND = UInt32(ord("m"))
"""The byte value of the SGR command."""
comptime SPACE = " "
"""A single space character."""
comptime NEWLINE = "\n"
"""A newline character."""
comptime TAB_BYTE = UInt32(ord("\t"))
"""The byte value of the tab character."""
comptime SPACE_BYTE = UInt32(ord(" "))
"""The byte value of the space character."""
comptime NEWLINE_BYTE = UInt32(ord("\n"))
"""The byte value of the newline character."""

comptime CSI_INTRODUCER_BYTE = UInt32(ord("["))
"""The byte that follows the marker to introduce a CSI sequence, e.g. SGR color codes."""
comptime OSC_INTRODUCER_BYTE = UInt32(ord("]"))
"""The byte that follows the marker to introduce an OSC sequence, e.g. OSC 8 hyperlinks."""
comptime DCS_INTRODUCER_BYTE = UInt32(ord("P"))
"""The byte that follows the marker to introduce a device control string."""
comptime SOS_INTRODUCER_BYTE = UInt32(ord("X"))
"""The byte that follows the marker to introduce a start-of-string sequence."""
comptime PM_INTRODUCER_BYTE = UInt32(ord("^"))
"""The byte that follows the marker to introduce a privacy message string."""
comptime APC_INTRODUCER_BYTE = UInt32(ord("_"))
"""The byte that follows the marker to introduce an application program command string."""
comptime BEL_BYTE = UInt32(ord("\x07"))
"""The byte value of the bell character, a common terminator for OSC strings."""
comptime ST_ESCAPE_BYTE = UInt32(ord("\\"))
"""The byte that follows the marker to form the string terminator (`ESC \\`)."""

comptime _SCAN_GROUND: UInt8 = 0
comptime _SCAN_ESCAPE: UInt8 = 1
comptime _SCAN_CSI: UInt8 = 2
comptime _SCAN_STRING: UInt8 = 3
comptime _SCAN_STRING_ESCAPE: UInt8 = 4


def has_suffix[lhs: ImmOrigin, rhs: ImmOrigin, //](bytes: Span[Byte, lhs], suffix: Span[Byte, rhs]) -> Bool:
    """Reports if the list ends with suffix.

    Args:
        bytes: The bytes to search.
        suffix: The suffix to search for.

    Returns:
        True if the bytes end with the suffix, False otherwise.
    """
    if len(bytes) < len(suffix):
        return False

    return bytes[len(bytes) - len(suffix) : len(bytes)] == suffix


def is_newline[origin: ImmOrigin, //](grapheme: StringSpan[origin]) -> Bool:
    """Reports if a grapheme cluster ends the current line.

    `CRLF` is a single grapheme cluster, so a bare `"\\n"` comparison would
    miss it.

    Args:
        grapheme: The grapheme cluster to check.

    Returns:
        True if the cluster is a line break, False otherwise.
    """
    return grapheme == NEWLINE or grapheme == "\r\n"


def is_terminator(c: Codepoint) -> Bool:
    """Reports if the rune is a CSI final byte, i.e. it ends a CSI sequence.

    Args:
        c: The rune to check.

    Returns:
        True if the rune is a terminator, False otherwise.
    """
    var rune = c.to_u32()
    return rune >= 0x40 and rune <= 0x7E


@fieldwise_init
struct SequenceScanner(Movable):
    """Recognizes ANSI/VT escape sequences one codepoint at a time.

    A single "next letter ends it" rule cannot describe every escape sequence
    shape: CSI sequences (`ESC [ ... final-byte`, e.g. SGR color codes) are
    letter-terminated, but string sequences (OSC/DCS/PM/APC/SOS -- OSC 8
    hyperlinks are the common case) are terminated by BEL or the `ESC \\`
    string terminator instead, so a letter appearing inside the string (e.g.
    the `h` in an `http://` URL) is not the end of the sequence. This scanner
    tracks which shape is in progress so each kind is closed correctly.

    #### Examples:
    ```mojo
    from mist.transform.ansi import SequenceScanner

    def main():
        var scanner = SequenceScanner()
        for codepoint in "\\x1b[31mred".codepoints():
            if not scanner.step(codepoint):
                print(codepoint, end="")
    ```
    """

    var state: UInt8
    """The scanner's position within a sequence, or `_SCAN_GROUND` when idle."""

    def __init__(out self):
        """Initializes a new scanner, outside of any sequence."""
        self.state = _SCAN_GROUND

    def is_active(self) -> Bool:
        """Reports whether the scanner is currently inside a sequence.

        Returns:
            True if the last `step` call landed inside a sequence.
        """
        return self.state != _SCAN_GROUND

    def step(mut self, c: Codepoint) -> Bool:
        """Advances the scanner by one codepoint.

        Args:
            c: The next codepoint of the input.

        Returns:
            True if `c` belongs to an escape sequence and so occupies no
            printable cells, False if it's ordinary content.
        """
        var rune = c.to_u32()

        if self.state == _SCAN_GROUND:
            if rune == ANSI_MARKER_BYTE:
                self.state = _SCAN_ESCAPE
                return True
            return False

        if self.state == _SCAN_ESCAPE:
            if rune == CSI_INTRODUCER_BYTE:
                self.state = _SCAN_CSI
            elif (
                rune == OSC_INTRODUCER_BYTE
                or rune == DCS_INTRODUCER_BYTE
                or rune == SOS_INTRODUCER_BYTE
                or rune == PM_INTRODUCER_BYTE
                or rune == APC_INTRODUCER_BYTE
            ):
                self.state = _SCAN_STRING
            else:
                # A bare two-byte escape (e.g. `ESC M`) ends here.
                self.state = _SCAN_GROUND
            return True

        if self.state == _SCAN_CSI:
            if is_terminator(c):
                self.state = _SCAN_GROUND
            return True

        if self.state == _SCAN_STRING:
            if rune == BEL_BYTE:
                self.state = _SCAN_GROUND
            elif rune == ANSI_MARKER_BYTE:
                self.state = _SCAN_STRING_ESCAPE
            return True

        # _SCAN_STRING_ESCAPE: only `ESC \` (the string terminator) closes the
        # sequence here; anything else is string content, so fall back to
        # scanning the string body.
        if rune == ST_ESCAPE_BYTE:
            self.state = _SCAN_GROUND
        else:
            self.state = _SCAN_STRING
        return True


def printable_rune_width[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt:
    """Returns the cell width of the given string, ignoring escape sequences.

    Args:
        text: String to calculate the width of.

    Returns:
        The printable cell width of the string.
    """
    var length: UInt = 0
    var scanner = SequenceScanner()

    for grapheme in text.graphemes():
        # Escape sequences never share a cluster with printable text: `ESC` is
        # a Control character, so it always breaks the cluster, and the bytes
        # that follow it are plain ASCII. A cluster is therefore either wholly
        # sequence or wholly content -- but the scanner is still stepped over
        # every codepoint so that non-ASCII inside a string sequence (e.g. a
        # UTF-8 URL in an OSC 8 hyperlink) is skipped rather than measured.
        var printable = True
        for codepoint in grapheme.codepoints():
            if scanner.step(codepoint):
                printable = False

        if printable:
            length += grapheme_width(grapheme)

    return length


@fieldwise_init
struct Writer(Movable, Writable):
    """A writer that handles ANSI escape sequences in the content.

    #### Examples:
    ```mojo
    from mist.transform import ansi

    def main():
        var writer = ansi.Writer()
        writer.write("Hello, World!")
        print(writer)
    ```
    """

    var forward: String
    """The buffer that stores the text content."""
    var scanner: SequenceScanner
    """Tracks whether the current codepoint is part of an ANSI escape sequence."""
    var ansi_seq: String
    """The buffer that stores the ANSI escape sequence currently being scanned."""
    var last_seq: String
    """The buffer that stores the last SGR escape sequence."""
    var seq_changed: Bool
    """Whether an SGR escape sequence is active and has not been reset."""

    def __init__(out self, var forward: String = String()):
        """Initializes a new ANSI-writer instance.

        Args:
            forward: The buffer that stores the text content.
        """
        self.forward = forward^
        self.scanner = SequenceScanner()
        self.ansi_seq = String(capacity=128)
        self.last_seq = String(capacity=128)
        self.seq_changed = False

    def write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content to the given writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.forward)

    def write[origin: ImmOrigin, //](mut self, content: StringSpan[origin]) -> None:
        """Write content to the ANSI buffer.

        Args:
            content: The content to write.
        """
        for codepoint in content.codepoints():
            self.write(codepoint)

    def write(mut self, codepoint: Codepoint) -> None:
        """Write codepoint to the ANSI buffer.

        Args:
            codepoint: The content to write.
        """
        if not self.scanner.step(codepoint):
            self.forward.write(codepoint)
            return

        self.ansi_seq.write(codepoint)
        if self.scanner.is_active():
            # Sequence still in progress; wait for it to terminate before
            # flushing, so a partial sequence never reaches `forward`.
            return

        if self.ansi_seq.startswith(ANSI_MARKER + ANSI_ESCAPE):
            # SGR reset sequence: whatever style was active no longer is.
            self.last_seq = String(capacity=self.last_seq.capacity())
            self.seq_changed = False
        elif self.ansi_seq.startswith(ANSI_MARKER + "[") and codepoint.to_u32() == SGR_COMMAND:
            # A non-reset SGR sequence: record it so it can be restored later.
            self.last_seq.write(self.ansi_seq)
            self.seq_changed = True

        self.forward.write(self.ansi_seq)
        self.ansi_seq = String(capacity=self.ansi_seq.capacity())

    def last_sequence(self) -> StringSpan[origin_of(self.last_seq)]:
        """Returns the last ANSI escape sequence.

        Returns:
            The last ANSI escape sequence.
        """
        return StringSpan(self.last_seq)

    def reset_ansi(mut self) -> None:
        """Resets the ANSI escape sequence."""
        if not self.seq_changed:
            return

        self.forward.write(ANSI_MARKER + ANSI_ESCAPE)

    def restore_ansi(mut self) -> None:
        """Restores the last ANSI escape sequence."""
        self.forward.write(self.last_seq)
