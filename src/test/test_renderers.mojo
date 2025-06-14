from mist import (
    red,
    green,
    blue,
    bold,
    italic,
    strikethrough,
    red_background,
    green_background,
    blue_background,
    TRUE_COLOR,
)
import testing


def test_renderers():
    testing.assert_equal(red("Hello, world!", TRUE_COLOR), "\x1B[38;2;232;131;136mHello, world!\x1B[0m")
    testing.assert_equal(green("Hello, world!", TRUE_COLOR), "\x1B[38;2;168;204;140mHello, world!\x1B[0m")
    testing.assert_equal(blue("Hello, world!", TRUE_COLOR), "\x1B[38;2;113;190;242mHello, world!\x1B[0m")
    testing.assert_equal(red_background("Hello, world!", TRUE_COLOR), "\x1B[48;2;232;131;136mHello, world!\x1B[0m")
    testing.assert_equal(green_background("Hello, world!", TRUE_COLOR), "\x1B[48;2;168;204;140mHello, world!\x1B[0m")
    testing.assert_equal(blue_background("Hello, world!", TRUE_COLOR), "\x1B[48;2;113;190;242mHello, world!\x1B[0m")
    testing.assert_equal(bold("Hello, world!", TRUE_COLOR), "\x1B[1mHello, world!\x1B[0m")
    testing.assert_equal(italic("Hello, world!", TRUE_COLOR), "\x1B[3mHello, world!\x1B[0m")
    testing.assert_equal(strikethrough("Hello, world!", TRUE_COLOR), "\x1B[9mHello, world!\x1B[0m")
