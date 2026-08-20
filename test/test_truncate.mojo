from std import testing
from std.testing import TestSuite

from mist import truncate
from mist.transform.truncater import TruncateWriter


def test_truncate() raises:
    testing.assert_equal(truncate("abcdefghikl\nasjdn", 5), "abcde")


def test_unicode() raises:
    testing.assert_equal(truncate("abcdefghikl🔥a\nsjdn🔥", 13), "abcdefghikl🔥")


def test_ansi() raises:
    testing.assert_equal(
        truncate("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 13),
        "I really \x1B[38;2;249;38;114mlove\x1B[0m",
    )


def test_ansi_multiple_sequences() raises:
    # Truncating mid-way through the second styled run keeps both styles and
    # closes the one still in effect.
    testing.assert_equal(
        truncate("\x1B[31mred\x1B[0m \x1B[32mgreen\x1B[0m", 5),
        "\x1B[31mred\x1B[0m \x1B[32mg\x1B[0m",
    )

    # Adjacent sequences before the content are both preserved.
    testing.assert_equal(truncate("\x1B[1m\x1B[31mabcdef\x1B[0m", 3), "\x1B[1m\x1B[31mabc\x1B[0m")


def test_ansi_only_input() raises:
    # A string with no printable cells passes through untouched.
    testing.assert_equal(truncate("\x1B[31m\x1B[0m", 5), "\x1B[31m\x1B[0m")

    # A zero width drops all content but still closes the open style.
    testing.assert_equal(truncate("\x1B[31mabc\x1B[0m", 0), "\x1B[31m\x1B[0m")


def test_ansi_sequence_at_cut_point() raises:
    # A sequence that opens exactly where truncation lands is still emitted,
    # then immediately closed, so the result carries no dangling style.
    testing.assert_equal(truncate("ab\x1B[31mcd\x1B[0m", 2), "ab\x1B[31m\x1B[0m")


def test_non_sgr_sequence() raises:
    # Non-SGR CSI sequences do not count toward the width and are not styling,
    # so no reset is appended.
    testing.assert_equal(truncate("\x1B[2Kabcdef", 3), "\x1B[2Kabc")


def test_tail_wider_than_width() raises:
    # When the tail alone fills the width, only the tail is emitted -- no
    # styling was written, so no reset is needed either.
    testing.assert_equal(truncate("\x1B[31mfoobar\x1B[0m", 2, "..."), "...")


def test_ansi_with_double_width() raises:
    # A wide character that would overflow is dropped, style still closed.
    testing.assert_equal(truncate("\x1B[31m\u4f60\u597d\u4e16\u754c\x1B[0m", 5), "\x1B[31m\u4f60\u597d\x1B[0m")


def test_idempotent() raises:
    # Truncating an already-truncated string must be a fixed point. This
    # regressed when the ANSI writer accumulated sequences across the input.
    var text = String("\x1B[90mMilky\x1B[0m")
    for _ in range(3):
        var truncated = truncate(text, 10)
        testing.assert_equal(truncated, "\x1B[90mMilky\x1B[0m")
        text = truncated^

    # Same for a result that actually needed truncating.
    var cut = truncate("\x1B[38;5;219mHiya!", 3, "\u2026")
    testing.assert_equal(cut, "\x1B[38;5;219mHi\u2026\x1B[0m")
    testing.assert_equal(truncate(cut, 3, "\u2026"), cut)


def test_noop() raises:
    testing.assert_equal(truncate("foo", 10), "foo")

    # Same width
    testing.assert_equal(truncate("foo", 3), "foo")


def test_truncate_with_tail() raises:
    testing.assert_equal(truncate("foobar", 4, "."), "foo.")

    # With tail longer than width
    testing.assert_equal(truncate("foobar", 3, "..."), "...")

    # Truncate spaces
    testing.assert_equal(truncate("    ", 2, "…"), " …")


def test_double_width() raises:
    testing.assert_equal(truncate("你好", 2), "你")

    # Double-width character is dropped if it is too wide
    testing.assert_equal(truncate("你", 1), "")

    # ANSI sequence codes and double-width characters
    testing.assert_equal(truncate("\x1B[38;2;249;38;114m你好\x1B[0m", 3), "\x1B[38;2;249;38;114m你\x1B[0m")


def test_reset_sequence() raises:
    # Reset styling sequence is added after truncate
    testing.assert_equal(truncate("\x1B[7m--", 1), "\x1B[7m-\x1B[0m")

    # Reset styling sequence not added if operation is a noop
    testing.assert_equal(truncate("\x1B[7m--", 2), "\x1B[7m--")

    # Tail is printed before reset sequence
    testing.assert_equal(truncate("\x1B[38;5;219mHiya!", 3, "…"), "\x1B[38;5;219mHi…\x1B[0m")


def test_does_not_split_grapheme_clusters() raises:
    # A ZWJ-joined emoji is one glyph. Truncating inside it used to emit a
    # partial cluster ending in a dangling ZWJ, which is malformed and can
    # join with whatever text follows.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    testing.assert_equal(truncate(FAMILY + "abc", 1), "")
    testing.assert_equal(truncate(FAMILY + "abc", 2), FAMILY)
    testing.assert_equal(truncate(FAMILY + "abc", 3), FAMILY + "a")

    # A skin tone modifier must not be stripped from its base emoji -- doing
    # so silently changes how the character renders.
    comptime WAVE = "\U0001F44B\U0001F3FB"
    testing.assert_equal(truncate(WAVE + "hi", 2), WAVE)
    testing.assert_equal(truncate(WAVE + "hi", 3), WAVE + "h")

    # A combining mark stays attached to its base character.
    testing.assert_equal(truncate("a\u0301bc", 1), "a\u0301")


def test_cluster_count_never_splits() raises:
    # For every width, the output must be a whole-cluster prefix of the input:
    # no cluster may be broken apart. Compare cluster-by-cluster rather than
    # by byte length, since a partial cluster can still be a byte prefix.
    comptime TEXT = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466a\u0301\U0001F1FA\U0001F1F8xy"
    for i in range(0, 12):
        var truncated = truncate(TEXT, UInt(i))

        var source = List[String]()
        for grapheme in TEXT.graphemes():
            source.append(String(grapheme))

        var index = 0
        for grapheme in truncated.graphemes():
            testing.assert_true(index < len(source), "produced more clusters than the input has")
            testing.assert_equal(String(grapheme), source[index])
            index += 1


def test_repeated_writes_share_one_budget() raises:
    # Regression: the tail width was subtracted from the budget on every call
    # and the running width restarted each time, so content split across writes
    # escaped truncation entirely.
    var split = TruncateWriter(10, tail=".")
    split.write("abcde")
    split.write("fghij")

    var whole = TruncateWriter(10, tail=".")
    whole.write("abcdefghij")

    testing.assert_equal(String(split), String(whole))
    testing.assert_equal(String(split), "abcdefghi.")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
