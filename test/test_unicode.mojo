from std import testing
from std.testing import TestSuite

from mist.transform.unicode import char_width, grapheme_width, string_width


def test_char_width() raises:
    for codepoint in "a".codepoints():
        testing.assert_equal(char_width(codepoint), 1)

    # Wide East Asian characters occupy two cells.
    for codepoint in "你".codepoints():
        testing.assert_equal(char_width(codepoint), 2)

    # Control characters occupy none.
    for codepoint in "\t".codepoints():
        testing.assert_equal(char_width(codepoint), 0)


def test_string_width_basic() raises:
    testing.assert_equal(string_width(""), 0)
    testing.assert_equal(string_width("abc"), 3)
    testing.assert_equal(string_width("你好"), 4)
    testing.assert_equal(string_width("こんにちは, 世界!"), 17)
    testing.assert_equal(string_width("🔥"), 2)


def test_grapheme_width_combining_marks() raises:
    # A base character plus a combining mark renders in the base's cells.
    testing.assert_equal(grapheme_width("á"), 1)
    testing.assert_equal(string_width("ábc"), 3)


def test_grapheme_width_zwj_sequence() raises:
    # A ZWJ-joined family emoji is a single glyph. Summing the widths of its
    # codepoints would give 8 (four emoji at two cells each); it renders as 2.
    comptime FAMILY = "\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466"
    testing.assert_equal(grapheme_width(FAMILY), 2)
    testing.assert_equal(string_width(FAMILY), 2)

    # Two separate (unjoined) emoji are two clusters, so they do total 4.
    testing.assert_equal(string_width("\U0001F468\U0001F469"), 4)


def test_grapheme_width_skin_tone_modifier() raises:
    # A skin tone modifier recolors the base emoji rather than adding a glyph.
    comptime WAVE = "\U0001F44B\U0001F3FB"
    testing.assert_equal(grapheme_width(WAVE), 2)
    testing.assert_equal(string_width(WAVE + "hi"), 4)


def test_grapheme_width_regional_indicators() raises:
    # A pair of regional indicators forms one flag glyph, which renders wide
    # even though a lone regional indicator is narrow.
    testing.assert_equal(grapheme_width("\U0001F1FA\U0001F1F8"), 2)
    testing.assert_equal(string_width("\U0001F1FA\U0001F1F8"), 2)


def test_grapheme_width_variation_selectors() raises:
    # VS16 forces emoji presentation, which is double-width.
    testing.assert_equal(grapheme_width("❤️"), 2)

    # VS15 forces text presentation, which is single-width. Summing codepoint
    # widths gave 2 here, because the selector itself counted as a cell.
    testing.assert_equal(grapheme_width("❤︎"), 1)


def test_string_width_mixed() raises:
    # 3 ("hi ") + 2 (emoji) + 1 (space) + 5 ("there")
    testing.assert_equal(string_width("hi \U0001F525 there"), 11)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
