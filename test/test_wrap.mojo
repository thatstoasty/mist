from std import testing
from std.testing import TestSuite

from mist import wrap


def test_wrap() raises:
    # Basic wrapping:
    testing.assert_equal(wrap("Hello Sekai!", 5), "Hello\nSekai\n!")

    # Long words are broken to obey the limit:
    testing.assert_equal(wrap("foobarfoo", 4, tab_width=0), "foob\narfo\no")


def test_keep_newlines() raises:
    # Newlines in the input are respected if desired
    testing.assert_equal(wrap("f\no\nobar", 3, tab_width=0), "f\no\noba\nr")

    # Newlines can be ignored if desired
    testing.assert_equal(wrap[keep_newlines=False]("f\no\nobar", 3, tab_width=0), "foo\nbar")


def test_preserve_space() raises:
    # Leading whitespaces after forceful line break can be preserved if desired
    testing.assert_equal(wrap("foo bar\n  baz", 3, preserve_space=True, tab_width=0), "foo\n ba\nr\n  b\naz")

    # Leading whitespaces after forceful line break can be removed if desired
    testing.assert_equal(wrap("foo bar\n  baz", 3, tab_width=0), "foo\nbar\n  b\naz")


def test_tab_width() raises:
    # Tabs are broken up according to the configured tab_width
    testing.assert_equal(wrap("foo\tbar", 4, preserve_space=True, tab_width=3), "foo \n  ba\nr")

    # The remaining width of a wrapped tab is ignored when space is not preserved
    testing.assert_equal(wrap("foo\tbar", 4, tab_width=3), "foo \nbar")


def test_noop() raises:
    # No-op, should pass through, including trailing whitespace:
    testing.assert_equal(wrap("foobar\n ", 0, tab_width=0), "foobar\n ")

    # Nothing to wrap here, should pass through:
    testing.assert_equal(wrap("foo", 4, tab_width=0), "foo")


def test_ansi_sequence() raises:
    # ANSI sequence codes don't affect length calculation:
    testing.assert_equal(
        wrap(
            "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
            7,
            tab_width=0,
        ),
        "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
    )

    # ANSI control codes don't get wrapped. Unlike `word_wrap`, `wrap` breaks
    # mid-word, but never inside an escape sequence:
    testing.assert_equal(
        wrap(
            "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m",
            3,
            tab_width=0,
        ),
        "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mju\nst \nano\nthe\nr t\nest\x1B[38;2;249;38;114m\n)\x1B[0m",
    )


def test_ansi_break_boundary() raises:
    # A hard break inside a styled run leaves the style open across the newline.
    testing.assert_equal(wrap("\x1B[31mabcdef\x1B[0m", 3, tab_width=0), "\x1B[31mabc\ndef\x1B[0m")

    # Adjacent sequences are treated as zero-width, so the break lands on the
    # same character as it would for unstyled input.
    testing.assert_equal(wrap("\x1B[1m\x1B[31mabcd\x1B[0m", 3, tab_width=0), "\x1B[1m\x1B[31mabc\nd\x1B[0m")


def test_ansi_noop_path() raises:
    # Content that already fits takes the fast path and must pass through with
    # its sequences intact.
    testing.assert_equal(wrap("\x1B[31mfoo\x1B[0m", 10, tab_width=0), "\x1B[31mfoo\x1B[0m")


def test_unicode() raises:
    testing.assert_equal(wrap("Hello Sekai! 🔥", 5), "Hello\nSekai\n! 🔥")


def test_does_not_split_grapheme_clusters() raises:
    # Hard wrapping breaks mid-word by design, but never mid-cluster: the
    # break goes before the cluster, so no line ends with a partial glyph.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    testing.assert_equal(wrap(FAMILY + "abc", 2, tab_width=0), FAMILY + "\nab\nc")
    testing.assert_equal(wrap(FAMILY + "abc", 3, tab_width=0), FAMILY + "a\nbc")

    # A skin tone modifier travels with its base emoji across the break.
    comptime WAVE = "\U0001F44B\U0001F3FB"
    testing.assert_equal(wrap("ab" + WAVE, 2, tab_width=0), "ab\n" + WAVE)


def test_crlf_line_break() raises:
    # CRLF is a single grapheme cluster, so it must still be recognized as a
    # line break rather than measured as content. Content that already fits
    # takes the fast path and is returned untouched.
    testing.assert_equal(wrap("ab\r\ncd", 4, tab_width=0), "ab\r\ncd")

    # The wrapping path must preserve it too: inserted breaks use `newline`,
    # while the input's own CRLF is written through unchanged.
    testing.assert_equal(wrap("abcd\r\nefgh", 3, tab_width=0), "abc\nd\r\nefg\nh")


def test_input_line_breaks_are_preserved() raises:
    # `newline` governs only the breaks wrapping inserts -- a break already in
    # the input is written through verbatim.
    testing.assert_equal(wrap("ab\ncd", 3, newline="|", tab_width=0), "ab\ncd")
    testing.assert_equal(wrap("abcdef", 3, newline="|", tab_width=0), "abc|def")
    testing.assert_equal(wrap("abcdef", 3, newline="\r\n", tab_width=0), "abc\r\ndef")


def test_keep_newlines_false_drops_crlf() raises:
    # With newlines discarded, a CRLF must be removed as a unit rather than
    # leaving a stray carriage return behind.
    testing.assert_equal(wrap[keep_newlines=False]("ab\r\ncd", 10, tab_width=0), "abcd")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
