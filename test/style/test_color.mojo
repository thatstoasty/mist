import mist.style._hue as hue
import testing
from mist.style.color import (
    ANSI256Color,
    ANSIColor,
    AnyColor,
    NoColor,
    RGBColor,
    ansi256_to_ansi,
    hex_to_ansi256,
    hex_to_rgb,
    rgb_to_hex,
)
from testing import TestSuite


fn test_color_sequence() raises:
    testing.assert_equal(ANSIColor(1).sequence[False](), "31")
    testing.assert_equal(ANSIColor(1).sequence[True](), "41")

    testing.assert_equal(ANSI256Color(100).sequence[False](), "38;5;100")
    testing.assert_equal(ANSI256Color(100).sequence[True](), "48;5;100")

    testing.assert_equal(RGBColor(0xFFFFFF).sequence[False](), "38;2;255;255;255")
    testing.assert_equal(RGBColor(0xFFFFFF).sequence[True](), "48;2;255;255;255")


fn test_no_color_equality() raises:
    testing.assert_true(NoColor() == NoColor())
    testing.assert_false(NoColor() != NoColor())


fn test_no_color_sequence() raises:
    var color = NoColor()
    testing.assert_equal(color.sequence[True](), "")
    testing.assert_equal(color.sequence[False](), "")


fn test_ansi_color_init() raises:
    var color = ANSIColor(0)
    testing.assert_equal(color.value, 0)

    var color2 = ANSIColor(color)
    testing.assert_equal(color2.value, 0)

    var color3 = ANSIColor(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 0)


fn test_ansi_color_equality() raises:
    testing.assert_equal(ANSIColor(0), ANSIColor(0))
    testing.assert_not_equal(ANSIColor(0), ANSIColor(1))


fn test_ansi_color_sequence() raises:
    var color = ANSIColor(0)
    testing.assert_equal(color.sequence[False](), "30")
    testing.assert_equal(color.sequence[True](), "40")


fn test_stringify_ansi_color() raises:
    var color = ANSIColor(0)
    testing.assert_equal(String(color), "ANSIColor(0)")


fn test_represent_ansi_color() raises:
    var color = ANSIColor(0)
    testing.assert_equal(repr(color), "ANSIColor(0)")


fn test_ansi_color_to_rgb() raises:
    var color = ANSIColor(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


fn test_ansi256_color_init() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(color.value, 0)

    var color2 = color.copy()
    testing.assert_equal(color2.value, 0)

    var color3 = ANSI256Color(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 16)


fn test_ansi256_color_equality() raises:
    testing.assert_equal(ANSI256Color(0), ANSI256Color(0))
    testing.assert_not_equal(ANSI256Color(0), ANSI256Color(1))


fn test_ansi256_color_sequence() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(color.sequence[False](), "38;5;0")
    testing.assert_equal(color.sequence[True](), "48;5;0")


fn test_stringify_ansi256_color() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(String(color), "ANSI256Color(0)")


fn test_represent_ansi256_color() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(repr(color), "ANSI256Color(0)")


fn test_ansi256_color_to_rgb() raises:
    var color = ANSI256Color(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


fn test_rgb_color_init() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.value, 16777215)

    var color2 = color.copy()
    testing.assert_equal(color2.value, 16777215)

    var color3 = RGBColor(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 0)


fn test_rgb_color_equality() raises:
    testing.assert_equal(RGBColor(0xFFFFFF), RGBColor(0xFFFFFF))
    testing.assert_not_equal(RGBColor(0xFFFFFF), RGBColor(0x000000))


fn test_rgb_color_sequence() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.sequence[False](), "38;2;255;255;255")
    testing.assert_equal(color.sequence[True](), "48;2;255;255;255")


fn test_stringify_rgb_color() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(String(color), "RGBColor(16777215)")


fn test_represent_rgb_color() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(repr(color), "RGBColor(16777215)")


fn test_rgb_color_to_rgb() raises:
    var color = RGBColor(0xFFFFFF).to_rgb()
    testing.assert_equal(color[0], 255)
    testing.assert_equal(color[1], 255)
    testing.assert_equal(color[2], 255)


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
