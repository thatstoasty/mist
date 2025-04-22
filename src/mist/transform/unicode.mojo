from collections import InlineArray
from mist.transform._table import (
    Interval,
    narrow,
    combining,
    doublewidth,
    ambiguous,
    emoji,
    nonprint,
)


@value
struct Condition[east_asian_width: Bool, strict_emoji_neutral: Bool]:
    """Conditions have the flag `east_asian_width` enabled if the current locale is `CJK` or not.

    Parameters:
        east_asian_width: Whether to use the East Asian Width algorithm to calculate the width of runes.
        strict_emoji_neutral: Whether to treat emoji as double-width characters.
    """

    fn char_width(self, codepoint: Codepoint) -> Int:
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
        if not east_asian_width:
            if rune < 0x20:
                return 0
            # nonprint
            elif (rune >= 0x7F and rune <= 0x9F) or rune == 0xAD:
                return 0
            elif rune < 0x300:
                return 1
            elif in_table(codepoint, narrow):
                return 1
            elif in_table(codepoint, nonprint):
                return 0
            elif in_table(codepoint, combining):
                return 0
            elif in_table(codepoint, doublewidth):
                return 2
            else:
                return 1
        else:
            if in_table(codepoint, nonprint):
                return 0
            elif in_table(codepoint, combining):
                return 0
            elif in_table(codepoint, narrow):
                return 1
            elif in_table(codepoint, ambiguous):
                return 2
            elif in_table(codepoint, doublewidth):
                return 2
            elif in_table(codepoint, ambiguous) or in_table(codepoint, emoji):
                return 2

            @parameter
            if strict_emoji_neutral:
                return 1

            if in_tables(codepoint, ambiguous):
                return 2
            elif in_table(codepoint, emoji):
                return 2
            elif in_table(codepoint, narrow):
                return 2

            return 1

    fn string_width(self, content: StringSlice) -> Int:
        """Return width as you can see.

        Args:
            content: The string to calculate the width of.

        Returns:
            The printable width of the string.
        """
        var width = 0
        for codepoint in content.codepoints():
            width += self.char_width(codepoint)
        return width


fn in_tables(codepoint: Codepoint, *tables: InlineArray[Interval]) -> Bool:
    """Check if the codepoint is in any of the tables.

    Args:
        codepoint: The rune to check.
        tables: The tables to check.

    Returns:
        True if the codepoint is in any of the tables, False otherwise.
    """
    for t in tables:
        if in_table(codepoint, t[]):
            return True
    return False


fn in_table(codepoint: Codepoint, table: InlineArray[Interval]) -> Bool:
    """Check if the rune is in the table.

    Args:
        codepoint: The codepoint to check.
        table: The table to check.

    Returns:
        True if the codepoint is in the table, False otherwise.
    """
    var rune = codepoint.to_u32()
    if rune < table[0][0]:
        return False

    var bot = 0
    var top = len(table) - 1
    while top >= bot:
        var mid = (bot + top) >> 1
        if table[mid][1] < rune:
            bot = mid + 1
        elif table[mid][0] > rune:
            top = mid - 1
        else:
            return True

    return False


alias DEFAULT_CONDITION = Condition[east_asian_width=False, strict_emoji_neutral=True]()
"""The default configuration for calculating the width of runes and strings."""


fn string_width(content: StringSlice) -> Int:
    """Return width as you can see.

    Args:
        content: The string to calculate the width of.

    Returns:
        The printable width of the string.
    """
    return DEFAULT_CONDITION.string_width(content)


fn char_width(codepoint: Codepoint) -> Int:
    """Return width as you can see.

    Args:
        codepoint: The codepoint to calculate the width of.

    Returns:
        The printable width of the codepoint.
    """
    return DEFAULT_CONDITION.char_width(codepoint)
