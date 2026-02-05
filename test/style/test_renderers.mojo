import testing
from testing import TestSuite

from mist import (
    Profile,
    blue,
    blue_background,
    bold,
    green,
    green_background,
    italic,
    red,
    red_background,
    strikethrough,
)


fn test_renderers() raises:
    testing.assert_equal(red("Hello, world!", Profile.TRUE_COLOR), "\x1B[38;2;232;131;136mHello, world!\x1B[0m")
    testing.assert_equal(green("Hello, world!", Profile.TRUE_COLOR), "\x1B[38;2;168;204;140mHello, world!\x1B[0m")
    testing.assert_equal(blue("Hello, world!", Profile.TRUE_COLOR), "\x1B[38;2;113;190;242mHello, world!\x1B[0m")
    testing.assert_equal(
        red_background("Hello, world!", Profile.TRUE_COLOR), "\x1B[48;2;232;131;136mHello, world!\x1B[0m"
    )
    testing.assert_equal(
        green_background("Hello, world!", Profile.TRUE_COLOR), "\x1B[48;2;168;204;140mHello, world!\x1B[0m"
    )
    testing.assert_equal(
        blue_background("Hello, world!", Profile.TRUE_COLOR), "\x1B[48;2;113;190;242mHello, world!\x1B[0m"
    )
    testing.assert_equal(bold("Hello, world!", Profile.TRUE_COLOR), "\x1B[1mHello, world!\x1B[0m")
    testing.assert_equal(italic("Hello, world!", Profile.TRUE_COLOR), "\x1B[3mHello, world!\x1B[0m")
    testing.assert_equal(strikethrough("Hello, world!", Profile.TRUE_COLOR), "\x1B[9mHello, world!\x1B[0m")


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
