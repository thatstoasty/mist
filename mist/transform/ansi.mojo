"""ANSI escape sequence constants and byte values used by text transforms."""
from std.io import write
from std.sys.info import simd_width_of

from mist.transform.unicode import _ascii_cell_width, char_width, grapheme_width, string_width
from mist.style import CSI
from mist._utils import as_codepoint, as_byte

comptime ANSI_ESCAPE = "[0m"
"""The ANSI escape sequence for resetting formatting."""
comptime ANSI_MARKER = "\x1b"
"""The ANSI escape sequence marker."""
comptime ANSI_MARKER_CODEPOINT = as_codepoint[ANSI_MARKER]()
"""The byte value of the ANSI escape sequence marker."""
comptime ANSI_MARKER_BYTE = as_byte[ANSI_MARKER]()
"""The byte value of the ANSI escape sequence marker."""
comptime SGR_COMMAND_CODEPOINT = as_codepoint["m"]()
"""The byte value of the SGR command."""
comptime SPACE = " "
"""A single space character."""
comptime LF = "\n"
"""A newline character."""
comptime TAB_CODEPOINT = as_codepoint["\t"]()
"""The byte value of the tab character."""
comptime SPACE_CODEPOINT = as_codepoint[" "]()
"""The byte value of the space character."""
comptime LF_CODEPOINT = as_codepoint["\n"]()
"""The byte value of the newline character."""
comptime CARRIAGE_RETURN_CODEPOINT = as_codepoint["\r"]()
"""The byte value of the carriage return character."""

comptime CSI_INTRODUCER_CODEPOINT = as_codepoint["["]()
"""The byte that follows the marker to introduce a CSI sequence, e.g. SGR color codes."""
comptime OSC_INTRODUCER_CODEPOINT = as_codepoint["]"]()
"""The byte that follows the marker to introduce an OSC sequence, e.g. OSC 8 hyperlinks."""
comptime DCS_INTRODUCER_CODEPOINT = as_codepoint["P"]()
"""The byte that follows the marker to introduce a device control string."""
comptime SOS_INTRODUCER_CODEPOINT = as_codepoint["X"]()
"""The byte that follows the marker to introduce a start-of-string sequence."""
comptime PM_INTRODUCER_CODEPOINT = as_codepoint["^"]()
"""The byte that follows the marker to introduce a privacy message string."""
comptime APC_INTRODUCER_CODEPOINT = as_codepoint["_"]()
"""The byte that follows the marker to introduce an application program command string."""
comptime BEL_CODEPOINT = as_codepoint["\x07"]()
"""The byte value of the bell character, a common terminator for OSC strings."""
comptime ST_ESCAPE_CODEPOINT = as_codepoint["\\"]()
"""The byte that follows the marker to form the string terminator (`ESC \\`)."""

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
        if ptr.unsafe_offset(i).unsafe_load[width=W]().eq(ANSI_MARKER_BYTE).reduce_or():
            return True
        i += W

    while i < length:
        if ptr[unsafe_offset=i] == ANSI_MARKER_BYTE:
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
    var bytes = text.as_bytes()
    var length = len(bytes)
    var ptr = bytes.unsafe_ptr()
    var i = 0

    while i + _ESCAPE_SIMD_WIDTH <= length:
        var chunk = ptr.unsafe_offset(i).unsafe_load[width=_ESCAPE_SIMD_WIDTH]()
        if chunk.ge(0x80).reduce_or() or chunk.eq(ANSI_MARKER_BYTE).reduce_or():
            return False
        i += _ESCAPE_SIMD_WIDTH

    while i < length:
        var byte = ptr[unsafe_offset=i]
        if byte >= 0x80 or byte == ANSI_MARKER_BYTE:
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
    return grapheme == LF or grapheme == "\r\n"


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
struct SequenceScanner(Equatable, ImplicitlyCopyable, Writable):
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
    """The scanner's position within a sequence, or `Self.GROUND` when idle."""
    comptime GROUND = Self(0)
    """Outside any sequence, where the next `ESC` starts one."""
    comptime ESCAPE = Self(1)
    """Just past an `ESC`, where the next codepoint selects the sequence's shape."""
    comptime CSI = Self(2)
    """Inside a CSI sequence, e.g. an SGR color code, which a final byte ends."""
    comptime STRING = Self(3)
    """Inside an OSC/DCS/PM/APC/SOS string, which `BEL` or the string terminator ends."""
    comptime STRING_ESCAPE = Self(4)
    """Just past an `ESC` inside a string, where a `\\` terminates it and anything else is content."""

    def __init__(out self):
        """Initializes a new scanner, outside of any sequence."""
        self.state = Self.GROUND.state

    def is_active(self) -> Bool:
        """Reports whether the scanner is currently inside a sequence.

        Returns:
            True if the last `step` call landed inside a sequence.
        """
        return self != Self.GROUND

    def step(mut self, c: Codepoint) -> Bool:
        """Advances the scanner by one codepoint.

        Args:
            c: The next codepoint of the input.

        Returns:
            True if `c` belongs to an escape sequence and so occupies no
            printable cells, False if it's ordinary content.
        """
        if self == Self.GROUND:
            if c == ANSI_MARKER_CODEPOINT:
                self.state = Self.ESCAPE.state
                return True
            return False

        if self == Self.ESCAPE:
            if c == CSI_INTRODUCER_CODEPOINT:
                self.state = Self.CSI.state
            elif (
                c == OSC_INTRODUCER_CODEPOINT
                or c == DCS_INTRODUCER_CODEPOINT
                or c == SOS_INTRODUCER_CODEPOINT
                or c == PM_INTRODUCER_CODEPOINT
                or c == APC_INTRODUCER_CODEPOINT
            ):
                self.state = Self.STRING.state
            else:
                # A bare two-byte escape (e.g. `ESC M`) ends here.
                self.state = Self.GROUND.state
            return True

        if self == Self.CSI:
            if is_terminator(c):
                self.state = Self.GROUND.state
            return True

        if self == Self.STRING:
            if c == BEL_CODEPOINT:
                self.state = Self.GROUND.state
            elif c == ANSI_MARKER_CODEPOINT:
                self.state = Self.STRING_ESCAPE.state
            return True

        # Self.STRING_ESCAPE: only `ESC \` (the string terminator) closes the
        # sequence here; anything else is string content, so fall back to
        # scanning the string body.
        if c == ST_ESCAPE_CODEPOINT:
            self.state = Self.GROUND.state
        else:
            self.state = Self.STRING.state
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
            while index + _ESCAPE_SIMD_WIDTH <= length:
                var chunk = ptr.unsafe_offset(index).unsafe_load[width=_ESCAPE_SIMD_WIDTH]()
                if chunk.ge(0x80).reduce_or():
                    return None
                if chunk.eq(ANSI_MARKER_BYTE).reduce_or():
                    break

                width += UInt(Int((chunk.ge(0x20) & chunk.le(0x7E)).cast[DType.uint8]().reduce_add()))
                index += _ESCAPE_SIMD_WIDTH

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
        elif self.ansi_seq.startswith(CSI) and codepoint == SGR_COMMAND_CODEPOINT:
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
