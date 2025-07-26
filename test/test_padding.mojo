import testing

from mist import padding


def test_padding():
    # Basic padding
    testing.assert_equal(padding("Hello, World!", 20), "Hello, World!       ")

    # Multi line padding
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text!", 20),
        "Hello               \nWorld               \nThis is my text!    ",
    )

    # Don't pad empty trailing lines
    testing.assert_equal(padding("foo\nbar\n", 6), "foo   \nbar   \n")


def test_noop():
    testing.assert_equal(padding("Hello, World!", 0), "Hello, World!")


# def test_ansi_sequence():
#     # ANSI sequence codes:
#     testing.assert_equal(
#         padding("\x1B[38;2;249;38;114mfoo", 6),
#         "\x1B[38;2;249;38;114mfoo   ",
#     )


def test_unicode():
    testing.assert_equal(
        padding("Hello\nWorld\nThis is my text! 🔥", 20),
        "Hello               \nWorld               \nThis is my text! 🔥 ",
    )
