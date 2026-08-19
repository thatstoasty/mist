"""Unicode codepoint and string display-width calculations."""
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

    Iterates grapheme clusters rather than codepoints, so a cluster that
    renders as a single glyph is measured once instead of per codepoint.

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
