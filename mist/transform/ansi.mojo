"""ANSI escape sequence constants and byte values used by text transforms."""
from std.io import write
from std.sys.info import simd_width_of

from mist.transform.unicode import _ascii_cell_width, char_width, grapheme_width, string_width


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
comptime CARRIAGE_RETURN_BYTE = UInt32(ord("\r"))
"""The byte value of the carriage return character."""

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

comptime _ESCAPE_SIMD_WIDTH = simd_width_of[DType.uint8]()
"""The number of bytes the `ESC` search examines per SIMD step."""


@always_inline
def _contains_escape[origin: ImmOrigin, //](text: StringSpan[origin]) -> Bool:
    """Reports whether `text` contains an `ESC` byte.

    A raw byte search is sound on UTF-8 of any kind, not just ASCII: every byte
    of a multi-byte codepoint is `>= 0x80`, so `0x1B` can only ever appear as
    `ESC` itself and never as part of some other character.

    Parameters:
        origin: The origin of the string.

    Args:
        text: The string to search.

    Returns:
        True if an `ESC` byte is present, False otherwise.
    """
    comptime W = _ESCAPE_SIMD_WIDTH

    var bytes = text.as_bytes()
    var length = len(bytes)
    var ptr = bytes.unsafe_ptr()
    var i = 0

    while i + W <= length:
        if ptr.unsafe_offset(i).unsafe_load[width=W]().eq(UInt8(ANSI_MARKER_BYTE)).reduce_or():
            return True
        i += W

    while i < length:
        if ptr[unsafe_offset=i] == UInt8(ANSI_MARKER_BYTE):
            return True
        i += 1

    return False


@always_inline
def _is_plain_ascii[origin: ImmOrigin, //](text: StringSpan[origin]) -> Bool:
    """Reports whether `text` is entirely ASCII and free of escape sequences.

    Transforms that satisfy this can walk the span a byte at a time instead of
    segmenting grapheme clusters, because in ASCII every byte is its own cluster
    apart from `CRLF`, and there are no sequences to step a scanner over.

    Parameters:
        origin: The origin of the string.

    Args:
        text: The string to inspect.

    Returns:
        True if every byte is ASCII and none is `ESC`, False otherwise.
    """
    comptime W = _ESCAPE_SIMD_WIDTH

    var bytes = text.as_bytes()
    var length = len(bytes)
    var ptr = bytes.unsafe_ptr()
    var i = 0

    while i + W <= length:
        var chunk = ptr.unsafe_offset(i).unsafe_load[width=W]()
        if chunk.ge(0x80).reduce_or() or chunk.eq(UInt8(ANSI_MARKER_BYTE)).reduce_or():
            return False
        i += W

    while i < length:
        var byte = ptr[unsafe_offset=i]
        if byte >= 0x80 or byte == UInt8(ANSI_MARKER_BYTE):
            return False
        i += 1

    return True


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


def _ascii_scanned_width[origin: ImmOrigin, //](text: StringSpan[origin]) -> Optional[UInt]:
    """Returns the cell width of all-ASCII `text`, skipping escape sequences.

    Styled text always contains `ESC`, so the sequence-free shortcut never fires
    on it. This covers that case instead: in all-ASCII input every byte is its
    own grapheme cluster -- a combining mark is non-ASCII by definition, so
    nothing can join, and `CRLF` measures zero either way because both halves
    are controls -- which means the scanner can run over raw bytes and the
    clusters never have to be segmented at all.

    Between sequences the scanner sits in its ground state, where the only byte
    that matters is `ESC`, so those runs are counted a SIMD register at a time
    and only the sequences themselves are walked byte by byte.

    Parameters:
        origin: The origin of the string.

    Args:
        text: The string to measure.

    Returns:
        The printable cell width, or `None` if `text` is not all ASCII.
    """
    comptime W = _ESCAPE_SIMD_WIDTH

    var bytes = text.as_bytes()
    var length = len(bytes)
    var ptr = bytes.unsafe_ptr()
    var width: UInt = 0
    var scanner = SequenceScanner()
    var index = 0

    while index < length:
        # Outside a sequence, skip ahead a register at a time until a chunk
        # holds an `ESC`; inside one, fall through to the byte-wise walk.
        if not scanner.is_active():
            while index + W <= length:
                var chunk = ptr.unsafe_offset(index).unsafe_load[width=W]()
                if chunk.ge(0x80).reduce_or():
                    return None
                if chunk.eq(UInt8(ANSI_MARKER_BYTE)).reduce_or():
                    break

                width += UInt(Int((chunk.ge(0x20) & chunk.le(0x7E)).cast[DType.uint8]().reduce_add()))
                index += W

            # The skip can land exactly on the end, and the byte-wise step below
            # would then read past the buffer.
            if index >= length:
                break

        var byte = ptr[unsafe_offset=index]
        if byte >= 0x80:
            return None

        if not scanner.step(Codepoint(byte)):
            # Control characters and DEL occupy no cells; everything else in
            # ASCII occupies exactly one.
            if byte >= 0x20 and byte <= 0x7E:
                width += 1

        index += 1

    return width


def printable_rune_width[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt:
    """Returns the cell width of the given string, ignoring escape sequences.

    Args:
        text: String to calculate the width of.

    Returns:
        The printable cell width of the string.
    """
    # Text with no `ESC` in it has no sequences to ignore, so plain ASCII can be
    # measured by counting bytes instead of segmenting graphemes.
    var ascii_width = _ascii_cell_width[reject_escape=True](text)
    if ascii_width:
        return ascii_width.value()

    # Styled text is still ASCII, just not sequence-free; it can be scanned
    # byte-wise rather than segmented.
    var scanned_width = _ascii_scanned_width(text)
    if scanned_width:
        return scanned_width.value()

    return _printable_rune_width_scanned(text)


def printable_width_within[origin: ImmOrigin, //](text: StringSpan[origin], limit: UInt) -> Optional[UInt]:
    """Returns the cell width of `text`, or `None` if it exceeds `limit`.

    Callers that only need to know whether content fits should prefer this over
    `printable_rune_width`: measuring stops as soon as the limit is passed, so a
    span far larger than the limit is not walked to the end to produce a number
    that will only be compared and discarded.

    Args:
        text: String to measure.
        limit: The greatest width that still counts as fitting.

    Returns:
        The printable cell width if it is at most `limit`, `None` otherwise.
    """
    # The ASCII scan is already a few bytes per cycle, so it runs to completion
    # rather than carrying a limit check through its inner loop.
    var ascii_width = _ascii_cell_width[reject_escape=True](text)
    if ascii_width:
        if ascii_width.value() > limit:
            return None
        return ascii_width

    var scanned_width = _ascii_scanned_width(text)
    if scanned_width:
        if scanned_width.value() > limit:
            return None
        return scanned_width

    var length: UInt = 0
    var scanner = SequenceScanner()

    for grapheme in text.graphemes():
        var printable = True
        for codepoint in grapheme.codepoints():
            if scanner.step(codepoint):
                printable = False

        if printable:
            length += grapheme_width(grapheme)
            if length > limit:
                return None

    return length


def _printable_rune_width_scanned[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt:
    """Returns the cell width of `text`, skipping escape sequences.

    This is the general path, correct for any input. `printable_rune_width`
    shortcuts plain ASCII ahead of it.

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
        # With no sequence in progress and no `ESC` in the span, there is
        # nothing for the scanner to find: every byte is ordinary content, and
        # none of the sequence-tracking state can change. The span can then be
        # appended in a single copy rather than re-encoded a codepoint at a
        # time.
        if not self.scanner.is_active() and not _contains_escape(content):
            self.forward.write(content)
            return

        for codepoint in content.codepoints():
            self.write(codepoint)

    @always_inline
    def is_scanning(self) -> Bool:
        """Reports whether the writer is partway through an escape sequence.

        Returns:
            True if a sequence is in progress and has not yet terminated.
        """
        return self.scanner.is_active()

    @always_inline
    def step(mut self, codepoint: Codepoint) -> Bool:
        """Advances the sequence scanner and classifies one codepoint.

        Callers that must know whether a codepoint is printable *before*
        deciding what to emit can classify it here and hand the answer back to
        `write_stepped`, instead of running a second scanner alongside this one
        and stepping every codepoint twice.

        Args:
            codepoint: The next codepoint of the input.

        Returns:
            True if `codepoint` belongs to an escape sequence, False if it is
            ordinary content.
        """
        return self.scanner.step(codepoint)

    def write(mut self, codepoint: Codepoint) -> None:
        """Write codepoint to the ANSI buffer.

        Args:
            codepoint: The content to write.
        """
        self.write_stepped(codepoint, is_sequence=self.step(codepoint))

    @always_inline
    def write_stepped(mut self, codepoint: Codepoint, *, is_sequence: Bool) -> None:
        """Writes a codepoint that `step` has already classified.

        Must be called in the same order as, and immediately following, the
        `step` calls that produced `is_sequence`; the sequence bookkeeping reads
        the scanner state that `step` left behind.

        Args:
            codepoint: The content to write.
            is_sequence: Whether `step` reported this codepoint as sequence content.
        """
        if not is_sequence:
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

    def take(deinit self) -> String:
        """Consumes the writer and hands back its buffer.

        Lets a caller that is finishing anyway claim the buffer outright rather
        than copying it into one of its own.

        Returns:
            The accumulated content.
        """
        return self.forward^

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
