"""Tests that exercise the transforms against real `Style` output and against
each other, where ANSI handling is most likely to break."""
from std import testing
from std.testing import TestSuite

import mist
from mist.profile import Profile
from mist.transform.ansi import printable_rune_width
from mist import truncate, indent, padding, margin, wrap, word_wrap, dedent


def _styled() -> String:
    """Returns styled text produced by `Style` rather than a hand-written literal.

    Returns:
        Bold red "Hello, World!" in the true color profile.
    """
    return mist.Style(Profile.TRUE_COLOR).bold().foreground(0xE88388).render("Hello, World!")


def test_style_output_width() raises:
    # A `Style` combines its attributes into a single sequence, which must be
    # invisible to the width calculation.
    testing.assert_equal(_styled(), "\x1B[1;38;2;232;131;136mHello, World!\x1B[0m")
    testing.assert_equal(printable_rune_width(_styled()), 13)


def test_style_output_through_transforms() raises:
    # Truncating a combined sequence must keep it whole and close it.
    testing.assert_equal(truncate(_styled(), 5), "\x1B[1;38;2;232;131;136mHello\x1B[0m")

    # Padding measures the styled text at its printable width.
    testing.assert_equal(padding(_styled(), 20), "\x1B[1;38;2;232;131;136mHello, World!\x1B[0m       ")

    # Word wrapping does not split the sequence, and does not break long words.
    testing.assert_equal(word_wrap(_styled(), 5), "\x1B[1;38;2;232;131;136mHello,\nWorld!\x1B[0m")


def test_ascii_profile_has_no_sequences() raises:
    # Under the ASCII profile the style degrades to plain text, so the
    # transforms have nothing to skip and behave like the unstyled case.
    var plain = mist.Style(Profile.ASCII).bold().foreground(0xE88388).render("Hello, World!")
    testing.assert_equal(plain, "Hello, World!")
    testing.assert_equal(truncate(plain, 5), "Hello")
    testing.assert_equal(padding(plain, 15), "Hello, World!  ")


def test_transform_composition() raises:
    # Truncate then pad: the truncation appends a reset, and the padding must
    # count the styled text at 5 cells and add 3 spaces.
    var composed = padding(truncate("\x1B[31mHello, World!\x1B[0m", 5), 8)
    testing.assert_equal(composed, "\x1B[31mHello\x1B[0m   ")
    testing.assert_equal(printable_rune_width(composed), 8)

    # Wrapping styled text and then indenting it indents every produced line.
    testing.assert_equal(
        indent(wrap("\x1B[31mabcdef\x1B[0m", 3, tab_width=0), 2),
        "\x1B[31m\x1B[0m  \x1B[31mabc\n\x1B[0m  \x1B[31mdef\x1B[0m",
    )


def test_padding_width_invariant() raises:
    # Every padded line must measure exactly the requested width, regardless of
    # how many sequences are interleaved.
    comptime WIDTH = 12
    var padded = padding("\x1B[31mfoo\x1B[0m\n\x1B[1m\x1B[32mbarbaz\x1B[0m\nqux", WIDTH)
    for line in padded.split("\n"):
        testing.assert_equal(printable_rune_width(line), WIDTH)


def test_truncate_never_exceeds_width() raises:
    # Truncation must respect the width for every prefix of a styled string.
    comptime TEXT = "\x1B[31mred\x1B[0m \x1B[1m\x1B[32mgreen\x1B[0m \x1B[34mblue\x1B[0m"
    for i in range(0, 16):
        var width = UInt(i)
        testing.assert_true(printable_rune_width(truncate(TEXT, width)) <= width)


def test_hyperlink_through_transforms() raises:
    # OSC 8 hyperlinks are terminated by BEL, not by a letter -- a naive scan
    # would misread the `h` in `http` as the end of the sequence and treat the
    # rest of the URL as printable text. Every transform must measure and
    # truncate at the link's actual visible width of 4 ("link").
    comptime LINK = "\x1B]8;;http://example.com\x07link\x1B]8;;\x07"
    testing.assert_equal(printable_rune_width(LINK), 4)
    testing.assert_equal(truncate("see " + LINK, 8), "see " + LINK)
    testing.assert_equal(truncate("see " + LINK, 6), "see \x1B]8;;http://example.com\x07li")
    testing.assert_equal(padding(LINK, 8), LINK + "    ")


def test_dedent_with_leading_ansi_sequence() raises:
    # A sequence ahead of a line's leading whitespace (styling an indented
    # block, say) must not defeat indentation detection.
    testing.assert_equal(
        dedent("\x1B[31m    foo\x1B[0m\n\x1B[31m    bar\x1B[0m"),
        "\x1B[31mfoo\x1B[0m\n\x1B[31mbar\x1B[0m",
    )


def test_styled_grapheme_clusters_survive_transforms() raises:
    # Clusters and escape sequences interleaved: the style must be preserved
    # and closed, and the cluster must never be split.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    comptime STYLED = "\x1B[31m" + FAMILY + "abc\x1B[0m"

    testing.assert_equal(printable_rune_width(STYLED), 5)
    testing.assert_equal(truncate(STYLED, 2), "\x1B[31m" + FAMILY + "\x1B[0m")

    var padded = padding(STYLED, 9)
    testing.assert_equal(printable_rune_width(padded), 9)


def test_truncate_output_is_whole_clusters() raises:
    # Across widths, truncation of styled cluster-heavy text must stay within
    # the requested width and never emit a partial cluster.
    comptime TEXT = "\x1B[31m\U0001F468\u200D\U0001F469\x1B[0m \U0001F1FA\U0001F1F8 \U0001F44B\U0001F3FB ok"
    for i in range(0, 14):
        var width = UInt(i)
        var truncated = truncate(TEXT, width)
        testing.assert_true(printable_rune_width(truncated) <= width)

        # Every cluster in the output must appear whole in the input.
        for grapheme in truncated.graphemes():
            testing.assert_true(StringSpan(TEXT).find(grapheme) != -1)


def test_crlf_preserved_by_every_transform() raises:
    # Line endings are content: no transform may silently rewrite the input's
    # CRLF into a bare LF. `wrap` is checked on both its fast path (content
    # already fits) and its wrapping path, which used to disagree.
    testing.assert_equal(wrap("ab\r\ncd", 4, tab_width=0), "ab\r\ncd")
    testing.assert_equal(wrap("abcd\r\nefgh", 3, tab_width=0), "abc\nd\r\nefg\nh")
    testing.assert_equal(word_wrap("foo\r\nbar", 10), "foo\r\nbar")
    testing.assert_equal(word_wrap("foo\r\nbar", 2), "foo\r\nbar")
    testing.assert_equal(padding("a\r\nb", 3), "a  \r\nb  ")
    testing.assert_equal(indent("a\r\nb", 2), "  a\r\n  b")
    testing.assert_equal(margin("a\r\nb", 4, 1), " a  \r\n b  ")
    testing.assert_equal(dedent("  a\r\n  b"), "a\r\nb")
    testing.assert_equal(truncate("ab\r\ncd", 10), "ab\r\ncd")


def test_wrap_and_word_wrap_agree_on_newline_semantics() raises:
    # Both writers treat `newline` the same way: it is the string emitted when
    # the writer itself breaks a line, and it never rewrites a break that was
    # already in the input.
    testing.assert_equal(wrap("abcdef", 3, newline="|", tab_width=0), "abc|def")
    testing.assert_equal(word_wrap("foo bar", 3, newline="|"), "foo|bar")

    testing.assert_equal(wrap("ab\ncd", 3, newline="|", tab_width=0), "ab\ncd")
    testing.assert_equal(word_wrap("foo\nbar", 10, newline="|"), "foo\nbar")

    # Both detect LF and CRLF as input breaks regardless of `newline`.
    testing.assert_equal(wrap("ab\r\ncd", 4, newline="|", tab_width=0), "ab\r\ncd")
    testing.assert_equal(word_wrap("foo\r\nbar", 10, newline="|"), "foo\r\nbar")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
