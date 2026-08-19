from std import testing
from std.testing import TestSuite

from mist import word_wrap


def test_wordwrap() raises:
    # Basic wrap:
    testing.assert_equal(word_wrap("Hello Sekai!", 6), "Hello\nSekai!")

    # Space buffer needs to be emptied before breakpoints:
    testing.assert_equal(word_wrap("foo --bar", 9), "foo --bar")

    # Wrap words that are short enough and preserve long words.
    testing.assert_equal(word_wrap("foo bars foobars", 4), "foo\nbars\nfoobars")

    # A word that would run beyond the limit is wrapped:
    testing.assert_equal(word_wrap("foo bar", 5), "foo\nbar")


def test_whitespace() raises:
    # Whitespace that trails a line and fits the width passes through, as does whitespace prefixing an explicit line break. A tab counts as one character:
    testing.assert_equal(word_wrap("foo\nb\t a\n bar", 4), "foo\nb\t a\n bar")

    # Trailing whitespace is removed if it doesn't fit the width. Runs of whitespace on which a line is broken are removed:
    testing.assert_equal(word_wrap("foo    \nb   ar   ", 4), "foo\nb\nar")


def test_keep_newlines() raises:
    # An explicit line break at the end of the input is preserved:
    testing.assert_equal(word_wrap("foo bar foo\n", 4), "foo\nbar\nfoo\n")

    # Explicit break are always preserved:
    testing.assert_equal(word_wrap("\nfoo bar\n\n\nfoo\n", 4), "\nfoo\nbar\n\n\nfoo\n")

    # Unless we ask them to be ignored:
    testing.assert_equal(word_wrap[keep_newlines=False]("\nfoo bar\n\n\nfoo\n", 4), "foo\nbar\nfoo")

    # Complete example:
    testing.assert_equal(
        word_wrap(" This is a list: \n\n\t* foo\n\t* bar\n\n\n\t* foo  \nbar    ", 6),
        " This\nis a\nlist: \n\n\t* foo\n\t* bar\n\n\n\t* foo\nbar",
    )


def test_hyphen_breakpoint() raises:
    # Hyphen breakpoint
    testing.assert_equal(word_wrap("foo-foobar", 4), "foo-\nfoobar")


def test_unicode() raises:
    testing.assert_equal(word_wrap("Hello Sekai! 🔥", 6), "Hello\nSekai!\n🔥")


def test_noop() raises:
    # No-op, should pass through, including trailing whitespace:
    testing.assert_equal(word_wrap("foobar\n ", 0), "foobar\n ")

    # Nothing to wrap here, should pass through:
    testing.assert_equal(word_wrap("foo", 4), "foo")

    # A single word that is too long passes through.
    # We do not break long words:
    testing.assert_equal(word_wrap("foobarfoo", 4), "foobarfoo")


def test_ansi_sequence() raises:
    # ANSI sequence codes don't affect length calculation:
    testing.assert_equal(
        word_wrap("\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", 7),
        "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
    )

    # ANSI control codes don't get wrapped:
    testing.assert_equal(
        word_wrap(
            "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m", 3
        ),
        "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust\nanother\ntest\x1B[38;2;249;38;114m)\x1B[0m",
    )


def test_ansi_trailing_space_removed() raises:
    # The space after "really" would push the line past the limit, so it is
    # dropped -- the styled word moves to the next line with its style intact.
    testing.assert_equal(
        word_wrap("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 8),
        "I really\n\x1B[38;2;249;38;114mlove\x1B[0m\nMojo!",
    )


def test_ansi_hyphen_breakpoint() raises:
    # Breaking on a hyphen inside a styled run leaves the style open.
    testing.assert_equal(word_wrap("\x1B[31mfoo-foobar\x1B[0m", 4), "\x1B[31mfoo-\nfoobar\x1B[0m")


def test_ansi_reset_mid_content() raises:
    # A reset partway through the input applies from that point on; wrapping
    # does not move it relative to the surrounding words.
    testing.assert_equal(word_wrap("\x1B[31mfoo bar\x1B[0m baz", 3), "\x1B[31mfoo\nbar\x1B[0m\nbaz")


def test_ansi_noop() raises:
    # A zero limit passes styled content straight through.
    testing.assert_equal(word_wrap("\x1B[31mfoo bar\x1B[0m", 0), "\x1B[31mfoo bar\x1B[0m")


def test_crlf_line_break() raises:
    # CRLF is a single grapheme cluster, so it needs its own comparison to
    # register as a line break -- and it is written through unchanged, so the
    # input's line endings survive.
    testing.assert_equal(word_wrap("foo\r\nbar", 10), "foo\r\nbar")
    testing.assert_equal(word_wrap("foo\r\nbar", 2), "foo\r\nbar")


def test_input_line_breaks_are_preserved() raises:
    # A break already present in the input is written through verbatim, even
    # when a different `newline` is configured for inserted breaks.
    testing.assert_equal(word_wrap("foo\nbar", 10, newline="|"), "foo\nbar")
    testing.assert_equal(word_wrap("foo\r\nbar", 10, newline="|"), "foo\r\nbar")


def test_newline_argument_applies_to_inserted_breaks() raises:
    # `newline` is what the writer emits when *it* breaks a line.
    testing.assert_equal(word_wrap("foo bar", 3, newline="|"), "foo|bar")
    testing.assert_equal(word_wrap("foo bar", 3, newline="\r\n"), "foo\r\nbar")


def test_keep_newlines_false_drops_crlf() raises:
    # With newlines discarded, a CRLF must be removed as a unit rather than
    # leaving a stray carriage return behind.
    testing.assert_equal(word_wrap[keep_newlines=False]("foo\r\nbar", 10), "foo bar")


def test_grapheme_cluster_width() raises:
    # A ZWJ-joined emoji is 2 cells wide, so it fits a limit of 3 alongside
    # nothing else; summing its codepoints measured it as 8.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    testing.assert_equal(word_wrap(FAMILY + " ab", 3), FAMILY + "\nab")

    # Two skin-toned emoji are 4 cells, which still exceeds a limit of 3, so
    # the following word wraps.
    comptime WAVE = "\U0001F44B\U0001F3FB"
    testing.assert_equal(word_wrap(WAVE + WAVE + " ab", 3), WAVE + WAVE + "\nab")


def test_long_word_width_accumulates_correctly() raises:
    # Word width is accumulated incrementally rather than re-measured. Verify
    # a long word still wraps at exactly the same point as a short one would.
    testing.assert_equal(word_wrap("aaaa bbbb", 4), "aaaa\nbbbb")
    testing.assert_equal(word_wrap("aaaaaaaa bb", 4), "aaaaaaaa\nbb")

    # A styled long word: the sequences must not count toward the width.
    testing.assert_equal(word_wrap("\x1B[31maaaa\x1B[0m bbbb", 4), "\x1B[31maaaa\x1B[0m\nbbbb")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
