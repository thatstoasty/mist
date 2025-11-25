import testing
from testing import TestSuite

from mist import margin


fn test_margin() raises:
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


fn test_noop() raises:
    testing.assert_equal(margin("Hello, World!", 0, 0), "Hello, World!")


# fn test_ansi_sequence() raises:
#     testing.assert_equal(
#         margin("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 12, 2),
#         "\x1B[38;2;249;38;114m  Love\x1B[0m Mojo!  ",
#     )


fn test_unicode() raises:
    testing.assert_equal(
        margin("Hello🔥\nWorld\n  TEST!🔥", 5, 2),
        "  Hello🔥\n  World\n    TEST!🔥",
    )


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
