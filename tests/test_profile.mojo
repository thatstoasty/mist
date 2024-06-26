from mist import Profile, ASCII, ANSI, ANSI256, TRUE_COLOR, new_style
from mist.color import ANSIColor, ANSI256Color, RGBColor, NoColor
from tests.util import MojoTest


fn test_profile_convert():
    var test = MojoTest("Testing Profile.convert")

    # Degrade Hex, ANSI256, and ANSI to ASCII
    test.assert_equal(mist.ASCII_PROFILE.convert(ANSIColor(5))[NoColor], NoColor())
    test.assert_equal(mist.ASCII_PROFILE.convert(ANSI256Color(100))[NoColor], NoColor())
    test.assert_equal(mist.ASCII_PROFILE.convert(RGBColor("#c9a0dc"))[NoColor], NoColor())

    # Degrade Hex, and ANSI256 to ANSI
    test.assert_equal(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor], ANSIColor(5))
    test.assert_equal(mist.ANSI_PROFILE.convert(RGBColor("#c9a0dc"))[ANSIColor], ANSIColor(2))

    # Degrade Hex to ANSI256
    test.assert_equal(mist.ANSI256_PROFILE.convert(RGBColor("#c9a0dc"))[ANSI256Color], ANSI256Color(182))


fn test_profile_color():
    var test = MojoTest("Testing Profile.color")

    # Empty string and non hex string will return NoColor, as will and ASCII profile.
    test.assert_equal(str(mist.ASCII_PROFILE.color("")[NoColor]), str(NoColor()))
    test.assert_equal(str(mist.ASCII_PROFILE.color("1234567")[NoColor]), str(NoColor()))
    test.assert_equal(str(mist.ASCII_PROFILE.color("#c9a0dc")[NoColor]), str(NoColor()))

    # ANSI256 profile will degrade the RGB color to the closest ANSI256 color.
    test.assert_equal(mist.ANSI256_PROFILE.color("#c9a0dc")[ANSI256Color], ANSI256Color(182))

    # ANSI profile will degrade the ANSI256 color to the closest ANSI color.
    test.assert_equal(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor], ANSIColor(5))


fn test_render_profiles():
    var test = MojoTest("Testing a few different renders")
    var a: String = "Hello World!"
    var profile = Profile()

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    print(new_style(profile).foreground(profile.color(12)).render(a))

    # ANSI256 Color Support (16-255)
    print(new_style(profile).foreground(profile.color(55)).render(a))

    # RGBColor Support (Hex Codes)
    print(new_style(profile).foreground(profile.color("#c9a0dc")).render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    print(new_style(mist.ASCII_PROFILE).foreground(mist.ASCII_PROFILE.color("#c9a0dc")).render(a))

    # ANSI Color Support (0-15)
    print(new_style(mist.ANSI_PROFILE).foreground(mist.ANSI_PROFILE.color("#c9a0dc")).render(a))

    # ANSI256 Color Support (16-255)
    print(new_style(mist.ANSI256_PROFILE).foreground(mist.ANSI256_PROFILE.color("#c9a0dc")).render(a))

    # RGBColor Support (Hex Codes)
    print(new_style(mist.TRUE_COLOR_PROFILE).foreground(mist.TRUE_COLOR_PROFILE.color("#c9a0dc")).render(a))

    # It also supports using the Profile of the TerminalStyle to instead of passing Profile().color().
    print(new_style(mist.TRUE_COLOR_PROFILE).foreground("#c9a0dc").render(a))

    # With a second color
    print(new_style().foreground(profile.color(10)).render(a))
    print(new_style().foreground(profile.color(46)).render(a))
    print(new_style().foreground(profile.color("#15d673")).render(a))
    print(new_style(mist.ASCII_PROFILE).foreground(mist.ASCII_PROFILE.color("#15d673")).render(a))
    print(new_style(mist.ANSI_PROFILE).foreground(mist.ANSI_PROFILE.color("#15d673")).render(a))
    print(new_style(mist.ANSI256_PROFILE).foreground(mist.ANSI256_PROFILE.color("#15d673")).render(a))
    print(new_style(mist.TRUE_COLOR_PROFILE).foreground(mist.TRUE_COLOR_PROFILE.color("#15d673")).render(a))


fn main():
    test_profile_convert()
    test_profile_color()
    test_render_profiles()
