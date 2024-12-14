from mist.color import (
    int_to_str,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    NoColor,
    AnyColor,
    ansi_to_rgb,
    hex_to_rgb,
    rgb_to_hex,
    ansi256_to_ansi,
    _v2ci,
    hex_to_ansi256,
)
import mist.hue
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


def test_no_color_init():
    var color = NoColor()
    _ = NoColor(color)


def test_no_color_equality():
    testing.assert_true(NoColor() == NoColor())
    testing.assert_false(NoColor() != NoColor())


def test_no_color_sequence():
    var color = NoColor()
    testing.assert_equal(color.sequence(True), "")
    testing.assert_equal(color.sequence(False), "")


def test_ansi_color_init():
    var color = ANSIColor(0)
    testing.assert_equal(color.value, 0)

    var color2 = ANSIColor(color)
    testing.assert_equal(color2.value, 0)

    var color3 = ANSIColor(hue.Color(UInt32(0), UInt32(0), UInt32(0)))
    testing.assert_equal(color3.value, 0)


def test_ansi_color_equality():
    testing.assert_equal(ANSIColor(0), ANSIColor(0))
    testing.assert_not_equal(ANSIColor(0), ANSIColor(1))


def test_ansi_color_sequence():
    var color = ANSIColor(0)
    testing.assert_equal(color.sequence(False), "30")
    testing.assert_equal(color.sequence(True), "40")


def test_stringify_ansi_color():
    var color = ANSIColor(0)
    testing.assert_equal(str(color), "ANSIColor(0)")


def test_represent_ansi_color():
    var color = ANSIColor(0)
    testing.assert_equal(repr(color), "ANSIColor(0)")


def test_ansi_color_to_rgb():
    var color = ANSIColor(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


def test_ansi256_color_init():
    var color = ANSI256Color(0)
    testing.assert_equal(color.value, 0)

    var color2 = ANSI256Color(color)
    testing.assert_equal(color2.value, 0)

    var color3 = ANSI256Color(hue.Color(UInt32(0), UInt32(0), UInt32(0)))
    testing.assert_equal(color3.value, 0)


def test_ansi256_color_equality():
    testing.assert_equal(ANSI256Color(0), ANSI256Color(0))
    testing.assert_not_equal(ANSI256Color(0), ANSI256Color(1))


def test_ansi256_color_sequence():
    var color = ANSI256Color(0)
    testing.assert_equal(color.sequence(False), "38;5;0")
    testing.assert_equal(color.sequence(True), "48;5;0")


def test_stringify_ansi256_color():
    var color = ANSI256Color(0)
    testing.assert_equal(str(color), "ANSI256Color(0)")


def test_represent_ansi256_color():
    var color = ANSI256Color(0)
    testing.assert_equal(repr(color), "ANSI256Color(0)")


def test_ansi256_color_to_rgb():
    var color = ANSI256Color(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


def test_rgb_color_init():
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.value, 16777215)

    var color2 = RGBColor(color)
    testing.assert_equal(color2.value, 16777215)

    var color3 = RGBColor(hue.Color(UInt32(0), UInt32(0), UInt32(0)))
    testing.assert_equal(color3.value, 0)


def test_rgb_color_equality():
    testing.assert_equal(RGBColor(0xFFFFFF), RGBColor(0xFFFFFF))
    testing.assert_not_equal(RGBColor(0xFFFFFF), RGBColor(0x000000))


def test_rgb_color_sequence():
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.sequence(False), "38;2;255;255;255")
    testing.assert_equal(color.sequence(True), "48;2;255;255;255")


def test_stringify_rgb_color():
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(str(color), "RGBColor(16777215)")


def test_represent_rgb_color():
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(repr(color), "RGBColor(16777215)")


def test_rgb_color_to_rgb():
    var color = RGBColor(0xFFFFFF).to_rgb()
    print(color[0], color[1], color[2])
    testing.assert_equal(color[0], 255)
    testing.assert_equal(color[1], 255)
    testing.assert_equal(color[2], 255)


# def test_ansi_to_rgb():
#     ansi_to_rgb()
