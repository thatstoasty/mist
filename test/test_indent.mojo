import testing

from mist import indent


def test_indent():
    # Basic single line indentation
    testing.assert_equal(indent("Hello, World!", 4), "    Hello, World!")

    # Multi-line indentation
    testing.assert_equal(indent("Hello\nWorld\n  TEST!", 5), "     Hello\n     World\n       TEST!")


# def test_ansi_sequence():
#     testing.assert_equal(
#         indent("\x1B[38;2;249;38;114mLove\x1B[0m Mojo!", 4),
#         "\x1B[38;2;249;38;114m    Love\x1B[0m Mojo!",
#     )


def test_noop():
    # No indentation applied.
    testing.assert_equal(indent("Hello, World!", 0), "Hello, World!")


def test_unicode():
    testing.assert_equal(
        indent("Hello🔥\nWorld\n  TEST!🔥", 5),
        "     Hello🔥\n     World\n       TEST!🔥",
    )
