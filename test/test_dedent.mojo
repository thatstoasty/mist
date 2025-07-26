import testing

from mist import dedent


def test_dedent():
    # Dedent single line.
    testing.assert_equal(dedent("    Hello, World!"), "Hello, World!")

    # Remove leading spaces from each line.
    testing.assert_equal(dedent("    Line 1!\n  Line 2!"), "  Line 1!\nLine 2!")


def test_noop():
    # Second line has no leading space, no dendenting applied.
    testing.assert_equal(dedent("  Line 1!\nLine 2!"), "  Line 1!\nLine 2!")

    # Only newlines, no dedenting applied.
    testing.assert_equal(dedent("\n\n\n"), "\n\n\n")

    # Empty string, no dedenting applied.
    testing.assert_equal(dedent(""), "")


def test_unicode():
    testing.assert_equal(dedent("    Line 1🔥!\n  Line 2🔥!"), "  Line 1🔥!\nLine 2🔥!")
