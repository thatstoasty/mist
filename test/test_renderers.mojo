from mist import red, green, blue, bold, italic, crossout, red_background, green_background, blue_background
import testing


def test_renderers():
    testing.assert_equal(red("Hello, world!"), "\x1B[;38;2;232;131;136mHello, world!\x1B[0m")
    testing.assert_equal(green("Hello, world!"), "\x1B[;38;2;168;204;140mHello, world!\x1B[0m")
    testing.assert_equal(blue("Hello, world!"), "\x1B[;38;2;113;190;242mHello, world!\x1B[0m")
    testing.assert_equal(red_background("Hello, world!"), "\x1B[;48;2;232;131;136mHello, world!\x1B[0m")
    testing.assert_equal(green_background("Hello, world!"), "\x1B[;48;2;168;204;140mHello, world!\x1B[0m")
    testing.assert_equal(blue_background("Hello, world!"), "\x1B[;48;2;113;190;242mHello, world!\x1B[0m")
    testing.assert_equal(bold("Hello, world!"), "\x1B[;1mHello, world!\x1B[0m")
    testing.assert_equal(italic("Hello, world!"), "\x1B[;3mHello, world!\x1B[0m")
    testing.assert_equal(crossout("Hello, world!"), "\x1B[;9mHello, world!\x1B[0m")