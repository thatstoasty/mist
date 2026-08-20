from std import testing
from std.testing import TestSuite

from mist import padding
from mist.transform.padder import PaddingWriter


def test_padding() raises:
    # Basic padding
    testing.assert_equal(padding("Hello, World!", 20), "Hello, World!       ")

    # Multi line padding
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text!", 20),
        "Hello               \nWorld               \nThis is my text!    ",
    )

    # Don't pad empty trailing lines
    testing.assert_equal(padding("foo\nbar\n", 6), "foo   \nbar   \n")


def test_noop() raises:
    testing.assert_equal(padding("Hello, World!", 0), "Hello, World!")


def test_ansi_sequence() raises:
    # ANSI sequence codes don't count toward the line width.
    testing.assert_equal(
        padding("\x1B[38;2;249;38;114mfoo", 6),
        "\x1B[38;2;249;38;114mfoo   ",
    )


def test_ansi_sequence_multiline() raises:
    # The open style is closed at the end of each line, so the padding of the
    # following line never picks up a stale background.
    testing.assert_equal(
        padding("\x1B[31mfoo\nbar\x1B[0m", 6),
        "\x1B[31mfoo   \x1B[0m\nbar\x1B[0m   ",
    )


def test_ansi_double_width() raises:
    # Wide characters are measured in cells, not codepoints.
    testing.assert_equal(padding("\x1B[31m\u4f60\u597d\x1B[0m", 6), "\x1B[31m\u4f60\u597d\x1B[0m  ")


def test_ansi_noop() raises:
    # A zero width leaves styled content completely untouched.
    testing.assert_equal(padding("\x1B[31mfoo\x1B[0m", 0), "\x1B[31mfoo\x1B[0m")


def test_unicode() raises:
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text! 🔥", 20),
        "Hello               \nWorld               \nThis is my text! 🔥 ",
    )


def test_grapheme_cluster_width() raises:
    # A ZWJ-joined emoji renders as one 2-cell glyph, so padding it to 6 adds
    # 4 spaces. Summing codepoint widths measured it as 8 and added none.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    testing.assert_equal(padding(FAMILY, 6), FAMILY + "    ")

    # Same for a skin tone modifier, which recolors rather than adding a glyph.
    comptime WAVE = "\U0001F44B\U0001F3FB"
    testing.assert_equal(padding(WAVE, 4), WAVE + "  ")


def test_as_string_slice_exposes_written_lines() raises:
    # Regression: the slice pointed at a cache that stayed empty until `finish`,
    # so it read as "" no matter how much had been written.
    var writer = PaddingWriter(6)
    writer.write("hi\n")

    # Read the slice and consume the writer before asserting: an assertion that
    # raises would otherwise abandon a writer that must be explicitly destroyed.
    var before_finish = String(writer.as_string_slice())
    var result = writer^.finish()

    testing.assert_equal(before_finish, "hi    \n")
    testing.assert_equal(result, "hi    \n")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
