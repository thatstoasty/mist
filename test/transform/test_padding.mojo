import testing
from testing import TestSuite

from mist import padding


fn test_padding() raises:
    # Basic padding
    testing.assert_equal(padding("Hello, World!", 20), "Hello, World!       ")

    # Multi line padding
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text!", 20),
        "Hello               \nWorld               \nThis is my text!    ",
    )

    # Don't pad empty trailing lines
    testing.assert_equal(padding("foo\nbar\n", 6), "foo   \nbar   \n")


fn test_noop() raises:
    testing.assert_equal(padding("Hello, World!", 0), "Hello, World!")


# fn test_ansi_sequence() raises:
#     # ANSI sequence codes:
#     testing.assert_equal(
#         padding("\x1B[38;2;249;38;114mfoo", 6),
#         "\x1B[38;2;249;38;114mfoo   ",
#     )


fn test_unicode() raises:
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text! 🔥", 20),
        "Hello               \nWorld               \nThis is my text! 🔥 ",
    )


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
