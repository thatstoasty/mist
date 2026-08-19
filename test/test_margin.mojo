from std import testing
from std.testing import TestSuite

from mist import margin


def test_margin() raises:
    # Basic margin
    testing.assert_equal(margin("Hello, World!", 17, 2), "  Hello, World!  ")

    # Multi line margin
    testing.assert_equal(
        margin("Hello\nWorld\n  TEST!", 5, 2),
        "  Hello\n  World\n    TEST!",
    )

    # Asymmetric margin
    testing.assert_equal(margin("foo", 6, 2), "  foo ")

    # Don't pad empty trailing lines
    testing.assert_equal(margin("foo\nbar\n", 5, 1), " foo \n bar \n")


def test_noop() raises:
    testing.assert_equal(margin("Hello, World!", 0, 0), "Hello, World!")


def test_ansi_sequence() raises:
    # Margin is indent composed with padding: the indent is emitted unstyled,
    # the style is replayed for the content, and the pad trails it.
    testing.assert_equal(
        margin("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 12, 2),
        "\x1B[38;2;249;38;114m\x1B[0m  \x1B[38;2;249;38;114mLove\x1B[0m Mojo!",
    )


def test_ansi_pad_beyond_content() raises:
    # "  Love Mojo!" is exactly 12 cells, so a pad of 12 adds nothing. Widening
    # the pad to 15 appends the difference after the closing reset.
    testing.assert_equal(
        margin("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 15, 2),
        "\x1B[38;2;249;38;114m\x1B[0m  \x1B[38;2;249;38;114mLove\x1B[0m Mojo!   ",
    )


def test_ansi_zero_margin() raises:
    # A zero-width margin is a true no-op: styled input passes through without
    # the indent writer closing and replaying the active style.
    testing.assert_equal(margin("\x1B[31mfoo\x1B[0m", 0, 0), "\x1B[31mfoo\x1B[0m")


def test_unicode() raises:
    testing.assert_equal(
        margin("Hello🔥\nWorld\n  TEST!🔥", 5, 2),
        "  Hello🔥\n  World\n    TEST!🔥",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
