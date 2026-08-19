from std import testing
from std.testing import TestSuite

from mist import dedent


def test_dedent() raises:
    # Dedent single line.
    testing.assert_equal(dedent("    Hello, World!"), "Hello, World!")

    # Remove leading spaces from each line.
    testing.assert_equal(dedent("    Line 1!\n  Line 2!"), "  Line 1!\nLine 2!")


def test_noop() raises:
    # Second line has no leading space, no dendenting applied.
    testing.assert_equal(dedent("  Line 1!\nLine 2!"), "  Line 1!\nLine 2!")

    # Only newlines, no dedenting applied.
    testing.assert_equal(dedent("\n\n\n"), "\n\n\n")

    # Empty string, no dedenting applied.
    testing.assert_equal(dedent(""), "")


def test_unicode() raises:
    testing.assert_equal(dedent("    Line 1🔥!\n  Line 2🔥!"), "  Line 1🔥!\nLine 2🔥!")


def test_ansi_sequence() raises:
    # Indentation is measured from literal leading whitespace; sequences that
    # follow it are carried along untouched.
    testing.assert_equal(
        dedent("    \x1B[31mfoo\x1B[0m\n  \x1B[32mbar\x1B[0m"),
        "  \x1B[31mfoo\x1B[0m\n\x1B[32mbar\x1B[0m",
    )


def test_ansi_sequence_before_indentation() raises:
    # A sequence ahead of the leading whitespace (e.g. a color applied to an
    # indented line) is transparent to indentation detection: it's carried
    # through untouched and doesn't count against the columns stripped.
    testing.assert_equal(
        dedent("\x1B[31m    foo\x1B[0m\n\x1B[31m  bar\x1B[0m"),
        "\x1B[31m  foo\x1B[0m\n\x1B[31mbar\x1B[0m",
    )


def test_ansi_sequence_interleaved_with_indentation() raises:
    # A sequence in the middle of the leading whitespace is also transparent:
    # it doesn't reset the whitespace run, and it isn't itself stripped. Both
    # lines share 4 columns of real whitespace, so all of it is removed.
    testing.assert_equal(
        dedent("  \x1B[31m  foo\x1B[0m\n    bar"),
        "\x1B[31mfoo\x1B[0m\nbar",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
