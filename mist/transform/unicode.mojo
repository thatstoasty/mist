from mist._utils import lut
from mist.transform._table import AMBIGUOUS, COMBINING, DOUBLE_WIDTH, EMOJI, NARROW, NON_PRINT, Interval


@fieldwise_init
struct Condition[east_asian_width: Bool, strict_emoji_neutral: Bool](Copyable, Movable):
    """Conditions have the flag `east_asian_width` enabled if the current locale is `CJK` or not.

    Parameters:
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.
    """

    fn char_width(self, codepoint: Codepoint) -> UInt:
        """Returns the number of cells in `codepoint`.
        See http://www.unicode.org/reports/tr11/.

        Args:
            codepoint: The codepoint to calculate the width of.

        Returns:
            The printable width of the rune.
        """
        var rune = codepoint.to_u32()
        if rune < 0 or rune > 0x10FFFF:
            return 0

        @parameter
        if not Self.east_asian_width:
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

            @parameter
            if Self.strict_emoji_neutral:
                return 1

            if in_table[AMBIGUOUS](codepoint):
                return 2
            elif in_table[EMOJI](codepoint):
                return 2
            elif in_table[NARROW](codepoint):
                return 2

            return 1

    fn string_width(self, content: StringSlice) -> UInt:
        """Return width as you can see.

        Args:
            content: The string to calculate the width of.

        Returns:
            The printable width of the string.
        """
        var width: UInt = 0
        for codepoint in content.codepoints():
            width += self.char_width(codepoint)
        return width


fn in_table[table: InlineArray[Interval]](codepoint: Codepoint) -> Bool:
    """Check if the rune is in the table.

    Parameters:
        table: The table to check.

    Args:
        codepoint: The codepoint to check.

    Returns:
        True if the codepoint is in the table, False otherwise.
    """
    var rune = codepoint.to_u32()
    if rune < lut[table](0)[0]:
        return False

    # Check if the rune is in the table using binary search.
    var bot = 0
    comptime top = len(table) - 1
    var top_n = top
    while top_n >= bot:
        var mid = (bot + top_n) >> 1
        if lut[table](mid)[1] < rune:
            bot = mid + 1
        elif lut[table](mid)[0] > rune:
            top_n = mid - 1
        else:
            return True

    return False


comptime DEFAULT_CONDITION = Condition[east_asian_width=False, strict_emoji_neutral=True]()
"""The default configuration for calculating the width of runes and strings."""


fn string_width(content: StringSlice) -> UInt:
    """Return width as you can see.

    Args:
        content: The string to calculate the width of.

    Returns:
        The printable width of the string.
    """
    return materialize[DEFAULT_CONDITION]().string_width(content)


fn char_width(codepoint: Codepoint) -> UInt:
    """Return width as you can see.

    Args:
        codepoint: The codepoint to calculate the width of.

    Returns:
        The printable width of the codepoint.
    """
    return materialize[DEFAULT_CONDITION]().char_width(codepoint)
