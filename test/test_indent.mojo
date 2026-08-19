from std import testing
from std.testing import TestSuite

from mist import indent


def test_indent() raises:
    # Basic single line indentation
    testing.assert_equal(indent("Hello, World!", 4), "    Hello, World!")

    # Multi-line indentation
    testing.assert_equal(indent("Hello\nWorld\n  TEST!", 5), "     Hello\n     World\n       TEST!")


def test_ansi_sequence() raises:
    # The indent itself must not inherit the active style, so the writer closes
    # the open sequence, emits the spaces, then replays the style.
    testing.assert_equal(
        indent("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 4),
        "\x1B[38;2;249;38;114m\x1B[0m    \x1B[38;2;249;38;114mLove\x1B[0m Mojo!",
    )


def test_ansi_sequence_multiline() raises:
    # Every line gets the same reset/indent/restore treatment, and a style that
    # spans the newline is replayed on the following line.
    testing.assert_equal(
        indent("\x1B[31mfoo\nbar\x1B[0m", 2),
        "\x1B[31m\x1B[0m  \x1B[31mfoo\n\x1B[0m  \x1B[31mbar\x1B[0m",
    )


def test_ansi_non_sgr_sequence() raises:
    # A non-SGR sequence (e.g. an erase-line command) carries no styling, so
    # no reset/restore is emitted around the indent -- only real SGR sequences
    # mark the style as changed.
    testing.assert_equal(indent("\x1B[2Kfoo", 2), "\x1B[2K  foo")


def test_noop() raises:
    # No indentation applied.
    testing.assert_equal(indent("Hello, World!", 0), "Hello, World!")


def test_unicode() raises:
    testing.assert_equal(
        indent("Hello🔥\nWorld\n  TEST!🔥", 5),
        "     Hello🔥\n     World\n       TEST!🔥",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
