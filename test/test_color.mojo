from mist.color import int_to_str, ANSIColor, ANSI256Color, RGBColor, NoColor, AnyColor
import testing


def test_int_to_str():
    testing.assert_equal(int_to_str(0), "0")
    testing.assert_equal(int_to_str(5), "5")
    testing.assert_equal(int_to_str(10), "10")
    testing.assert_equal(int_to_str(100), "100")
    testing.assert_equal(int_to_str(987), "987")


def test_color_sequence():
    testing.assert_equal(ANSIColor(1).sequence(False), "31")
    testing.assert_equal(ANSIColor(1).sequence(True), "41")

    testing.assert_equal(ANSI256Color(100).sequence(False), "38;5;100")
    testing.assert_equal(ANSI256Color(100).sequence(True), "48;5;100")

    testing.assert_equal(RGBColor(0xFFFFFF).sequence(False), "38;2;255;255;255")
    testing.assert_equal(RGBColor(0xFFFFFF).sequence(True), "48;2;255;255;255")
