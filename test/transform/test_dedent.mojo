import testing
from testing import TestSuite

from mist import dedent


fn test_dedent() raises:
    # Dedent single line.
    testing.assert_equal(dedent("    Hello, World!"), "Hello, World!")

    # Remove leading spaces from each line.
    testing.assert_equal(dedent("    Line 1!\n  Line 2!"), "  Line 1!\nLine 2!")


fn test_noop() raises:
    # Second line has no leading space, no dendenting applied.
    testing.assert_equal(dedent("  Line 1!\nLine 2!"), "  Line 1!\nLine 2!")

    # Only newlines, no dedenting applied.
    testing.assert_equal(dedent("\n\n\n"), "\n\n\n")

    # Empty string, no dedenting applied.
    testing.assert_equal(dedent(""), "")


fn test_unicode() raises:
    testing.assert_equal(dedent("    Line 1🔥!\n  Line 2🔥!"), "  Line 1🔥!\nLine 2🔥!")


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
