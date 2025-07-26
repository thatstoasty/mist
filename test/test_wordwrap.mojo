import testing

from mist import word_wrap


def test_wordwrap():
    # Basic wrap:
    testing.assert_equal(word_wrap("Hello Sekai!", 6), "Hello\nSekai!")

    # Space buffer needs to be emptied before breakpoints:
    testing.assert_equal(word_wrap("foo --bar", 9), "foo --bar")

    # Wrap words that are short enough and preserve long words.
    testing.assert_equal(word_wrap("foo bars foobars", 4), "foo\nbars\nfoobars")

    # A word that would run beyond the limit is wrapped:
    testing.assert_equal(word_wrap("foo bar", 5), "foo\nbar")


def test_whitespace():
    # Whitespace that trails a line and fits the width passes through, as does whitespace prefixing an explicit line break. A tab counts as one character:
    testing.assert_equal(word_wrap("foo\nb\t a\n bar", 4), "foo\nb\t a\n bar")

    # Trailing whitespace is removed if it doesn't fit the width. Runs of whitespace on which a line is broken are removed:
    testing.assert_equal(word_wrap("foo    \nb   ar   ", 4), "foo\nb\nar")


def test_keep_newlines():
    # An explicit line break at the end of the input is preserved:
    testing.assert_equal(word_wrap("foo bar foo\n", 4), "foo\nbar\nfoo\n")

    # Explicit break are always preserved:
    testing.assert_equal(word_wrap("\nfoo bar\n\n\nfoo\n", 4), "\nfoo\nbar\n\n\nfoo\n")

    # Unless we ask them to be ignored:
    testing.assert_equal(word_wrap[keep_newlines=False]("\nfoo bar\n\n\nfoo\n", 4), "foo\nbar\nfoo")

    # Complete example:
    testing.assert_equal(
        word_wrap(" This is a list: \n\n\t* foo\n\t* bar\n\n\n\t* foo  \nbar    ", 6),
        " This\nis a\nlist: \n\n\t* foo\n\t* bar\n\n\n\t* foo\nbar",
    )


def test_hyphen_breakpoint():
    # Hyphen breakpoint
    testing.assert_equal(word_wrap("foo-foobar", 4), "foo-\nfoobar")


def test_unicode():
    testing.assert_equal(word_wrap("Hello Sekai! 🔥", 6), "Hello\nSekai!\n🔥")


def test_noop():
    # No-op, should pass through, including trailing whitespace:
    testing.assert_equal(word_wrap("foobar\n ", 0), "foobar\n ")

    # Nothing to wrap here, should pass through:
    testing.assert_equal(word_wrap("foo", 4), "foo")

    # A single word that is too long passes through.
    # We do not break long words:
    testing.assert_equal(word_wrap("foobarfoo", 4), "foobarfoo")


def test_ansi_sequence():
    # ANSI sequence codes don't affect length calculation:
    testing.assert_equal(
        word_wrap("\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", 7),
        "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
    )

    # ANSI control codes don't get wrapped:
    testing.assert_equal(
        word_wrap(
            "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m", 3
        ),
        "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust\nanother\ntest\x1B[38;2;249;38;114m)\x1B[0m",
    )


# TODO: Weirdness with the strings not being equal but length and content is identical.
# def test_ansi_sequence():
#     testing.assert_equal(word_wrap("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 8), "I really \n\x1B[38;2;249;38;114mlove\x1B[0m \nMojo!")
