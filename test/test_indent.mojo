import testing
from testing import TestSuite

from mist import indent


fn test_indent() raises:
    # Basic single line indentation
    testing.assert_equal(indent("Hello, World!", 4), "    Hello, World!")

    # Multi-line indentation
    testing.assert_equal(indent("Hello\nWorld\n  TEST!", 5), "     Hello\n     World\n       TEST!")


# fn test_ansi_sequence() raises:
#     testing.assert_equal(
#         indent("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 4),
#         "\x1B[38;2;249;38;114m    Love\x1B[0m Mojo!",
#     )


fn test_noop() raises:
    # No indentation applied.
    testing.assert_equal(indent("Hello, World!", 0), "Hello, World!")


fn test_unicode() raises:
    testing.assert_equal(
        indent("Hello🔥\nWorld\n  TEST!🔥", 5),
        "     Hello🔥\n     World\n       TEST!🔥",
    )


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
