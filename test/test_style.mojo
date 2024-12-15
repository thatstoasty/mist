import mist
import testing


def test_bold():
    testing.assert_equal(mist.Style().bold().render("Hello─World"), "\x1B[;1mHello─World\x1B[0m")


def test_faint():
    testing.assert_equal(mist.Style().faint().render("Hello─World"), "\x1B[;2mHello─World\x1B[0m")


def test_italic():
    testing.assert_equal(mist.Style().italic().render("Hello─World"), "\x1B[;3mHello─World\x1B[0m")


def test_underline():
    testing.assert_equal(mist.Style().underline().render("Hello─World"), "\x1B[;4mHello─World\x1B[0m")


def test_blink():
    testing.assert_equal(mist.Style().blink().render("Hello─World"), "\x1B[;5mHello─World\x1B[0m")


def test_reverse():
    testing.assert_equal(mist.Style().reverse().render("Hello─World"), "\x1B[;7mHello─World\x1B[0m")


def test_crossout():
    testing.assert_equal(mist.Style().crossout().render("Hello─World"), "\x1B[;9mHello─World\x1B[0m")


def test_bold_faint():
    testing.assert_equal(mist.Style().bold().faint().render("Hello─World"), "\x1B[;1;2mHello─World\x1B[0m")
