from mist import red, green, blue, bold, italic, crossout, red_background, green_background, blue_background
from tests.util import MojoTest


fn test_renderers():
    var test = MojoTest("Testing Profile.color")
    print(red("Hello, world!"))
    print(green("Hello, world!"))
    print(blue("Hello, world!"))
    print(red_background("Hello, world!"))
    print(green_background("Hello, world!"))
    print(blue_background("Hello, world!"))
    print(bold("Hello, world!"))
    print(italic("Hello, world!"))
    print(crossout("Hello, world!"))


fn main():
    test_renderers()
