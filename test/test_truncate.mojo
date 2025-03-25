from mist import truncate
import testing


def test_truncate():
    testing.assert_equal(truncate("abcdefghikl\nasjdn", 5), "abcde")


def test_unicode():
    testing.assert_equal(truncate("abcdefghikl🔥a\nsjdn🔥", 13), "abcdefghikl🔥")


# TODO: Weirdness with the strings not being equal but length and content is identical.
# def test_ansi():
#     testing.assert_equal(truncate("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 13), "I really \x1B[38;2;249;38;114mlove\x1B[0m")


def test_noop():
    testing.assert_equal(truncate("foo", 10), "foo")

    # Same width
    testing.assert_equal(truncate("foo", 3), "foo")


def test_truncate_with_tail():
    testing.assert_equal(truncate("foobar", 4, "."), "foo.")

    # With tail longer than width
    testing.assert_equal(truncate("foobar", 3, "..."), "...")

    # Truncate spaces
    testing.assert_equal(truncate("    ", 2, "…"), " …")


def test_double_width():
    testing.assert_equal(truncate("你好", 2), "你")

    # Double-width character is dropped if it is too wide
    testing.assert_equal(truncate("你", 1), "")

    # ANSI sequence codes and double-width characters
    testing.assert_equal(truncate("\x1B[38;2;249;38;114m你好\x1B[0m", 3), "\x1B[38;2;249;38;114m你\x1B[0m")


def test_reset_sequence():
    # Reset styling sequence is added after truncate
    testing.assert_equal(truncate("\x1B[7m--", 1), "\x1B[7m-\x1B[0m")

    # Reset styling sequence not added if operation is a noop
    testing.assert_equal(truncate("\x1B[7m--", 2), "\x1B[7m--")

    # Tail is printed before reset sequence
    testing.assert_equal(truncate("\x1B[38;5;219mHiya!", 3, "…"), "\x1B[38;5;219mHi…\x1B[0m")
