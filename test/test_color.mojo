import mist._hue as hue
from std import testing
from mist.color import (
    ANSI256Color,
    ANSIColor,
    AnyColor,
    NoColor,
    RGBColor,
    ansi256_to_ansi,
    hex_to_ansi256,
    hex_to_rgb,
    hex_to_string,
    rgb_to_hex,
)
from std.testing import TestSuite


def test_color_sequence() raises:
    testing.assert_equal(ANSIColor(1).sequence[False](), "31")
    testing.assert_equal(ANSIColor(1).sequence[True](), "41")

    testing.assert_equal(ANSI256Color(100).sequence[False](), "38;5;100")
    testing.assert_equal(ANSI256Color(100).sequence[True](), "48;5;100")

    testing.assert_equal(RGBColor(0xFFFFFF).sequence[False](), "38;2;255;255;255")
    testing.assert_equal(RGBColor(0xFFFFFF).sequence[True](), "48;2;255;255;255")


def test_no_color_equality() raises:
    testing.assert_true(NoColor() == NoColor())
    testing.assert_false(NoColor() != NoColor())


def test_no_color_sequence() raises:
    var color = NoColor()
    testing.assert_equal(color.sequence[True](), "")
    testing.assert_equal(color.sequence[False](), "")


def test_ansi_color_init() raises:
    var color = ANSIColor(0)
    testing.assert_equal(color.value, 0)

    var color2 = ANSIColor(color)
    testing.assert_equal(color2.value, 0)

    var color3 = ANSIColor(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 0)


def test_ansi_color_equality() raises:
    testing.assert_equal(ANSIColor(0), ANSIColor(0))
    testing.assert_not_equal(ANSIColor(0), ANSIColor(1))


def test_ansi_color_sequence() raises:
    var color = ANSIColor(0)
    testing.assert_equal(color.sequence[False](), "30")
    testing.assert_equal(color.sequence[True](), "40")


def test_stringify_ansi_color() raises:
    var color = ANSIColor(0)
    testing.assert_equal(String(color), "ANSIColor(value=0)")


def test_represent_ansi_color() raises:
    var color = ANSIColor(0)
    testing.assert_equal(repr(color), "ANSIColor(value=UInt8(0))")


def test_ansi_color_to_rgb() raises:
    var color = ANSIColor(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


def test_ansi256_color_init() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(color.value, 0)

    var color2 = color.copy()
    testing.assert_equal(color2.value, 0)

    var color3 = ANSI256Color(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 16)


def test_ansi256_color_equality() raises:
    testing.assert_equal(ANSI256Color(0), ANSI256Color(0))
    testing.assert_not_equal(ANSI256Color(0), ANSI256Color(1))


def test_ansi256_color_sequence() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(color.sequence[False](), "38;5;0")
    testing.assert_equal(color.sequence[True](), "48;5;0")


def test_stringify_ansi256_color() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(String(color), "ANSI256Color(value=0)")


def test_represent_ansi256_color() raises:
    var color = ANSI256Color(0)
    testing.assert_equal(repr(color), "ANSI256Color(value=UInt8(0))")


def test_ansi256_color_to_rgb() raises:
    var color = ANSI256Color(1).to_rgb()
    testing.assert_equal(color[0], 128)
    testing.assert_equal(color[1], 0)
    testing.assert_equal(color[2], 0)


def test_rgb_color_init() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.value, 16777215)

    var color2 = color.copy()
    testing.assert_equal(color2.value, 16777215)

    var color3 = RGBColor(hue.Color(UInt8(0), UInt8(0), UInt8(0)))
    testing.assert_equal(color3.value, 0)


def test_rgb_color_equality() raises:
    testing.assert_equal(RGBColor(0xFFFFFF), RGBColor(0xFFFFFF))
    testing.assert_not_equal(RGBColor(0xFFFFFF), RGBColor(0x000000))


def test_rgb_color_sequence() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(color.sequence[False](), "38;2;255;255;255")
    testing.assert_equal(color.sequence[True](), "48;2;255;255;255")


def test_stringify_rgb_color() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(String(color), "RGBColor(value=16777215)")


def test_represent_rgb_color() raises:
    var color = RGBColor(0xFFFFFF)
    testing.assert_equal(repr(color), "RGBColor(value=UInt32(16777215))")


def test_rgb_color_to_rgb() raises:
    var color = RGBColor(0xFFFFFF).to_rgb()
    testing.assert_equal(color[0], 255)
    testing.assert_equal(color[1], 255)
    testing.assert_equal(color[2], 255)


def test_ansi256_to_ansi_is_identity_below_16() raises:
    # The ANSI colors are their own nearest neighbours, so the lookup table that
    # replaced the nearest-neighbour search has to agree on that range -- a
    # table shifted by one row would still look plausible everywhere else.
    for value in range(16):
        testing.assert_equal(ansi256_to_ansi(UInt8(value)), UInt8(value))


def test_ansi256_to_ansi_is_in_range() raises:
    # Every entry must name one of the 16 ANSI colors.
    for value in range(256):
        testing.assert_true(ansi256_to_ansi(UInt8(value)) < 16)


def test_ansi256_to_ansi_known_values() raises:
    # Spot checks past the identity range, so a regenerated table cannot drift
    # silently: 16 is black, 21 is pure blue, 231 is white, and the gray ramp
    # runs from black up to white.
    testing.assert_equal(ansi256_to_ansi(16), 0)
    testing.assert_equal(ansi256_to_ansi(21), 12)
    testing.assert_equal(ansi256_to_ansi(196), 9)
    testing.assert_equal(ansi256_to_ansi(231), 15)
    testing.assert_equal(ansi256_to_ansi(232), 0)
    testing.assert_equal(ansi256_to_ansi(255), 15)


def test_hex_to_string() raises:
    # The bare converter emits as few digits as the value needs.
    testing.assert_equal(hex_to_string(0), "0")
    testing.assert_equal(hex_to_string(0xFF), "ff")
    testing.assert_equal(hex_to_string(0x0000FF), "ff")
    testing.assert_equal(hex_to_string(0xABCDEF), "abcdef")
    testing.assert_equal(hex_to_string(0x1A2B3C4D), "1a2b3c4d")

    # Padding adds leading zeros without truncating a wider value.
    testing.assert_equal(hex_to_string(0, min_width=6), "000000")
    testing.assert_equal(hex_to_string(0x0000FF, min_width=6), "0000ff")
    testing.assert_equal(hex_to_string(0xABCDEF, min_width=6), "abcdef")
    testing.assert_equal(hex_to_string(0x1A2B3C4D, min_width=6), "1a2b3c4d")


def test_as_hex_string_keeps_leading_zeros() raises:
    # Regression: a color renders as `RRGGBB`, so dropping leading zeros made
    # blue read as the two-digit "ff" rather than "0000ff".
    testing.assert_equal(RGBColor(0x0000FF).as_hex_string(), "0000ff")
    testing.assert_equal(RGBColor(0x00FF00).as_hex_string(), "00ff00")
    testing.assert_equal(RGBColor(0x000000).as_hex_string(), "000000")
    testing.assert_equal(RGBColor(0xE88388).as_hex_string(), "e88388")
    testing.assert_equal(ANSIColor(0).as_hex_string(), "000000")
    testing.assert_equal(ANSI256Color(21).as_hex_string(), "0000ff")

    # Every color's hex string is a full six digits.
    for value in range(256):
        testing.assert_equal(ANSI256Color(UInt8(value)).as_hex_string().byte_length(), 6)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
