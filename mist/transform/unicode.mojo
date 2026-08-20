"""Unicode codepoint and string display-width calculations."""
from std.sys.info import simd_width_of

from mist._utils import lut
from mist.transform._table import AMBIGUOUS, COMBINING, DOUBLE_WIDTH, EMOJI, NARROW, NON_PRINT, Interval


comptime VARIATION_SELECTOR_TEXT = UInt32(0xFE0E)
"""VS15, which forces the preceding character into text presentation (narrow)."""
comptime VARIATION_SELECTOR_EMOJI = UInt32(0xFE0F)
"""VS16, which forces the preceding character into emoji presentation (wide)."""
comptime REGIONAL_INDICATOR_START = UInt32(0x1F1E6)
"""The first regional indicator symbol; a pair of these forms a flag."""
comptime REGIONAL_INDICATOR_END = UInt32(0x1F1FF)
"""The last regional indicator symbol; a pair of these forms a flag."""

comptime _ESCAPE_BYTE = UInt8(0x1B)
"""The byte that introduces an ANSI escape sequence."""
comptime _ASCII_SIMD_WIDTH = simd_width_of[DType.uint8]()
"""The number of bytes the ASCII width scan examines per SIMD step."""


@always_inline
def _ascii_cell_width[origin: ImmOrigin, //, *, reject_escape: Bool](text: StringSpan[origin]) -> Optional[UInt]:
    """Returns the cell width of `text` if it is plain ASCII, `None` otherwise.

    Terminal text is overwhelmingly ASCII, and for ASCII the general
    grapheme-segmenting scan is far more machinery than the answer needs: every
    byte is its own codepoint, and the only ASCII grapheme cluster spanning more
    than one byte is `CRLF`, whose width is zero either way because both halves
    are control characters. So the width of an all-ASCII span is just the number
    of bytes in `0x20..=0x7E`, which this counts a SIMD register at a time.

    Any byte `>= 0x80` means the span needs real Unicode handling, so the scan
    gives up and the caller falls back to the grapheme path. `reject_escape`
    additionally gives up on `ESC`, for callers that must skip escape sequences
    rather than measure them.

    Parameters:
        origin: The origin of the string.
        reject_escape: Whether an `ESC` byte disqualifies the span.

    Args:
        text: The string to measure.

    Returns:
        The printable cell width, or `None` if `text` is not plain ASCII.
    """
    comptime W = _ASCII_SIMD_WIDTH
    comptime assert W <= 255, "SIMD width must fit a UInt8 lane-sum without overflow."

    var bytes = text.as_bytes()
    var length = len(bytes)
    var ptr = bytes.unsafe_ptr()
    var width: UInt = 0
    var i = 0

    while i + W <= length:
        var chunk = ptr.unsafe_offset(i).unsafe_load[width=W]()
        if chunk.ge(0x80).reduce_or():
            return None

        comptime if reject_escape:
            if chunk.eq(_ESCAPE_BYTE).reduce_or():
                return None

        width += UInt(Int((chunk.ge(0x20) & chunk.le(0x7E)).cast[DType.uint8]().reduce_add()))
        i += W

    while i < length:
        var byte = ptr[unsafe_offset=i]
        if byte >= 0x80:
            return None

        comptime if reject_escape:
            if byte == _ESCAPE_BYTE:
                return None

        if byte >= 0x20 and byte <= 0x7E:
            width += 1
        i += 1

    return width


def in_table[table: Array[Interval, ...]](codepoint: Codepoint) -> Bool:
    """Check if the rune is in the table.

    Parameters:
        table: The table to check.

    Args:
        codepoint: The codepoint to check.

    Returns:
        True if the codepoint is in the table, False otherwise.
    """
    var rune = codepoint.to_u32()
    if rune < lut[table](0).start:
        return False

    # Check if the rune is in the table using binary search.
    var bot = 0
    comptime top = len(table) - 1
    var top_n = top
    while top_n >= bot:
        var mid = (bot + top_n) >> 1
        if lut[table](mid).end < rune:
            bot = mid + 1
        elif lut[table](mid).start > rune:
            top_n = mid - 1
        else:
            return True

    return False


def char_width[east_asian_width: Bool = False, strict_emoji_neutral: Bool = True](codepoint: Codepoint) -> UInt:
    """Return width as you can see.

    Parameters:
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.

    Args:
        codepoint: The codepoint to calculate the width of.

    Returns:
        The printable width of the codepoint.
    """
    var rune = codepoint.to_u32()
    if rune < 0 or rune > 0x10FFFF:
        return 0

    comptime if not east_asian_width:
        if rune < 0x20:
            return 0
        # nonprint
        elif (rune >= 0x7F and rune <= 0x9F) or rune == 0xAD:
            return 0
        elif rune < 0x300:
            return 1
        elif in_table[NARROW](codepoint):
            return 1
        elif in_table[NON_PRINT](codepoint):
            return 0
        elif in_table[COMBINING](codepoint):
            return 0
        elif in_table[DOUBLE_WIDTH](codepoint):
            return 2
        else:
            return 1
    else:
        if in_table[NON_PRINT](codepoint):
            return 0
        elif in_table[COMBINING](codepoint):
            return 0
        elif in_table[NARROW](codepoint):
            return 1
        elif in_table[AMBIGUOUS](codepoint):
            return 2
        elif in_table[DOUBLE_WIDTH](codepoint):
            return 2
        elif in_table[AMBIGUOUS](codepoint) or in_table[EMOJI](codepoint):
            return 2

        comptime if strict_emoji_neutral:
            return 1

        if in_table[AMBIGUOUS](codepoint):
            return 2
        elif in_table[EMOJI](codepoint):
            return 2
        elif in_table[NARROW](codepoint):
            return 2

        return 1


def grapheme_width[
    origin: ImmOrigin, //, east_asian_width: Bool = False, strict_emoji_neutral: Bool = True
](grapheme: StringSpan[origin]) -> UInt:
    """Return the display width of a single grapheme cluster.

    A cluster renders as one unit, so its width is not the sum of its
    codepoints' widths. Summing would double-count ZWJ-joined emoji
    (`\\U0001F468\\u200D\\U0001F469` is one glyph, not two) and skin tone
    modifiers, both of which render inside the base character's cells.

    Parameters:
        origin: The origin of the grapheme cluster.
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.

    Args:
        grapheme: The grapheme cluster to calculate the width of.

    Returns:
        The printable width of the grapheme cluster.
    """
    var base: UInt32 = 0
    var seen: UInt = 0
    var regional_indicators: UInt = 0

    for codepoint in grapheme.codepoints():
        var rune = codepoint.to_u32()
        if seen == 0:
            base = rune
        seen += 1

        # Variation selectors override the base character's own presentation,
        # so they decide the width regardless of what the base would be.
        if rune == VARIATION_SELECTOR_EMOJI:
            return 2
        elif rune == VARIATION_SELECTOR_TEXT:
            return 1
        elif rune >= REGIONAL_INDICATOR_START and rune <= REGIONAL_INDICATOR_END:
            regional_indicators += 1

    if seen == 0:
        return 0

    # A pair of regional indicators forms a flag, which renders double-width
    # even though each indicator on its own is narrow.
    if regional_indicators >= 2:
        return 2

    # Everything else in the cluster -- combining marks, ZWJ-joined emoji,
    # skin tone modifiers -- renders within the base character's cells.
    return char_width[east_asian_width, strict_emoji_neutral](Codepoint(unsafe_unchecked_codepoint=base))


def string_width[
    origin: ImmOrigin, //, east_asian_width: Bool = False, strict_emoji_neutral: Bool = True
](content: StringSpan[origin]) -> UInt:
    """Return width as you can see.

    Plain ASCII is measured by counting bytes; anything else iterates grapheme
    clusters rather than codepoints, so a cluster that renders as a single glyph
    is measured once instead of per codepoint.

    Parameters:
        origin: The origin of the string.
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.

    Args:
        content: The string to calculate the width of.

    Returns:
        The printable width of the string.
    """
    # The East Asian algorithm classifies ASCII through the width tables rather
    # than by codepoint range, so the byte-counting shortcut does not model it.
    comptime if not east_asian_width:
        var ascii_width = _ascii_cell_width[reject_escape=False](content)
        if ascii_width:
            return ascii_width.value()

    return _string_width_graphemes[east_asian_width, strict_emoji_neutral](content)


def _string_width_graphemes[
    origin: ImmOrigin, //, east_asian_width: Bool = False, strict_emoji_neutral: Bool = True
](content: StringSpan[origin]) -> UInt:
    """Return the width of `content` by measuring each grapheme cluster.

    This is the general path, correct for any input. `string_width` shortcuts
    plain ASCII ahead of it.

    Parameters:
        origin: The origin of the string.
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.

    Args:
        content: The string to calculate the width of.

    Returns:
        The printable width of the string.
    """
    var width: UInt = 0
    for grapheme in content.graphemes():
        width += grapheme_width[east_asian_width, strict_emoji_neutral](grapheme)
    return width
