import testing

from mist import wrap


def test_wrap():
    # Basic wrapping:
    testing.assert_equal(wrap("Hello Sekai!", 5), "Hello\nSekai\n!")

    # Long words are broken to obey the limit:
    testing.assert_equal(wrap("foobarfoo", 4, tab_width=0), "foob\narfo\no")


def test_keep_newlines():
    # Newlines in the input are respected if desired
    testing.assert_equal(wrap("f\no\nobar", 3, tab_width=0), "f\no\noba\nr")

    # Newlines can be ignored if desired
    testing.assert_equal(wrap[keep_newlines=False]("f\no\nobar", 3, tab_width=0), "foo\nbar")


def test_preserve_space():
    # Leading whitespaces after forceful line break can be preserved if desired
    testing.assert_equal(wrap("foo bar\n  baz", 3, preserve_space=True, tab_width=0), "foo\n ba\nr\n  b\naz")

    # Leading whitespaces after forceful line break can be removed if desired
    testing.assert_equal(wrap("foo bar\n  baz", 3, tab_width=0), "foo\nbar\n  b\naz")


def test_tab_width():
    # Tabs are broken up according to the configured tab_width
    testing.assert_equal(wrap("foo\tbar", 4, preserve_space=True, tab_width=3), "foo \n  ba\nr")

    # The remaining width of a wrapped tab is ignored when space is not preserved
    testing.assert_equal(wrap("foo\tbar", 4, tab_width=3), "foo \nbar")


def test_noop():
    # No-op, should pass through, including trailing whitespace:
    testing.assert_equal(wrap("foobar\n ", 0, tab_width=0), "foobar\n ")

    # Nothing to wrap here, should pass through:
    testing.assert_equal(wrap("foo", 4, tab_width=0), "foo")


# TODO: Weirdness with the strings not being equal but length and content is identical.
# def test_ansi_sequence():
#     # ANSI sequence codes don't affect length calculation:
#     testing.assert_equal(
#         wrap(
#             "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
#             7,
#             tab_width=0,
#         ),
#         "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
#     )

#     # ANSI control codes don't get wrapped:
#     testing.assert_equal(
#         wrap(
#             "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m",
#             3,
#             tab_width=0,
#         ),
#         "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust\nanother\ntest\x1B[38;2;249;38;114m)\x1B[0m",
#     )


def test_unicode():
    testing.assert_equal(wrap("Hello Sekai! 🔥", 5), "Hello\nSekai\n! 🔥")
