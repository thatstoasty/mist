import testing
from mist.style import SGR

import mist
from mist import Profile


def test_bold():
    testing.assert_equal(
        mist.Style(Profile.ANSI).bold().render("Hello─World"), "\x1B[" + SGR.BOLD + "mHello─World\x1B[0m"
    )


def test_faint():
    testing.assert_equal(
        mist.Style(Profile.ANSI).faint().render("Hello─World"), "\x1B[" + SGR.FAINT + "mHello─World\x1B[0m"
    )


def test_italic():
    testing.assert_equal(
        mist.Style(Profile.ANSI).italic().render("Hello─World"), "\x1B[" + SGR.ITALIC + "mHello─World\x1B[0m"
    )


def test_underline():
    testing.assert_equal(mist.Style(Profile.ANSI).underline().render("Hello─World"), "\x1B[4mHello─World\x1B[0m")


def test_blink():
    testing.assert_equal(mist.Style(Profile.ANSI).blink().render("Hello─World"), "\x1B[5mHello─World\x1B[0m")


def test_reverse():
    testing.assert_equal(mist.Style(Profile.ANSI).reverse().render("Hello─World"), "\x1B[7mHello─World\x1B[0m")


def test_crossout():
    testing.assert_equal(mist.Style(Profile.ANSI).strikethrough().render("Hello─World"), "\x1B[9mHello─World\x1B[0m")


def test_bold_faint():
    testing.assert_equal(mist.Style(Profile.ANSI).bold().faint().render("Hello─World"), "\x1B[1;2mHello─World\x1B[0m")
