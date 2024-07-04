from mist.color import int_to_str, ANSIColor, ANSI256Color, RGBColor, NoColor, AnyColor
from tests.util import MojoTest


fn test_int_to_str():
    var test = MojoTest("Testing int_to_str")
    test.assert_equal(int_to_str(0), "0")
    test.assert_equal(int_to_str(5), "5")
    test.assert_equal(int_to_str(10), "10")
    test.assert_equal(int_to_str(100), "100")
    test.assert_equal(int_to_str(987), "987")


fn test_color_sequence():
    var test = MojoTest("Testing ANSIColor.sequence")
    test.assert_equal(ANSIColor(1).sequence(False), "31")
    test.assert_equal(ANSIColor(1).sequence(True), "41")

    test = MojoTest("Testing ANSI256Color.sequence")
    test.assert_equal(ANSI256Color(100).sequence(False), "38;5;100")
    test.assert_equal(ANSI256Color(100).sequence(True), "48;5;100")

    test = MojoTest("Testing RGBColor.sequence")
    test.assert_equal(RGBColor(0xFFFFFF).sequence(False), "38;2;255;255;255")
    test.assert_equal(RGBColor(0xFFFFFF).sequence(True), "48;2;255;255;255")


fn main():
    test_int_to_str()
    test_color_sequence()
