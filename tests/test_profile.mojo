import mist
from mist import Profile, ASCII, ANSI, ANSI256, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor, NoColor
from tests.util import MojoTest


fn test_profile_convert():
    var test = MojoTest("Testing Profile.convert")

    # Degrade Hex, ANSI256, and ANSI to ASCII
    test.assert_equal(mist.ASCII_PROFILE.convert(ANSIColor(5))[NoColor].sequence(False), NoColor().sequence(False))
    test.assert_equal(mist.ASCII_PROFILE.convert(ANSI256Color(100))[NoColor].sequence(False), NoColor().sequence(False))
    test.assert_equal(
        mist.ASCII_PROFILE.convert(RGBColor(0xC9A0DC))[NoColor].sequence(False), NoColor().sequence(False)
    )

    # Degrade Hex, and ANSI256 to ANSI
    test.assert_equal(str(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor].value), str(ANSIColor(3).value))
    test.assert_equal(str(mist.ANSI_PROFILE.convert(RGBColor(0xC9A0DC))[ANSIColor].value), str(ANSIColor(5).value))

    # Degrade Hex to ANSI256
    test.assert_equal(
        str(mist.ANSI256_PROFILE.convert(RGBColor(0xC9A0DC))[ANSI256Color].value), str(ANSI256Color(182).value)
    )


fn test_profile_color():
    var test = MojoTest("Testing Profile.color")

    # ASCII profile returns NoColor for all colors.
    test.assert_equal(mist.ASCII_PROFILE.color(0xC9A0DC)[NoColor].sequence(False), NoColor().sequence(False))

    # ANSI256 profile will degrade the RGB color to the closest ANSI256 color.
    test.assert_equal(str(mist.ANSI256_PROFILE.color(0xC9A0DC)[ANSI256Color].value), str(ANSI256Color(182).value))

    # ANSI profile will degrade the ANSI256 color to the closest ANSI color.
    test.assert_equal(str(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor].value), str(ANSIColor(3).value))


fn test_render_profiles():
    var test = MojoTest("Testing a few different renders")
    var a: String = "Hello World!"

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    test.assert_equal(mist.Style().foreground(12).render(a), "\x1B[;94mHello World!\x1B[0m")

    # ANSI256 Color Support (16-255)
    test.assert_equal(mist.Style().foreground(55).render(a), "\x1B[;38;5;55mHello World!\x1B[0m")

    # RGBColor Support (Hex Codes)
    test.assert_equal(mist.Style().foreground(0xC9A0DC).render(a), "\x1B[;38;2;201;160;220mHello World!\x1B[0m")

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    test.assert_equal(
        mist.Style(mist.ASCII).foreground(color=mist.ASCII_PROFILE.color(0xC9A0DC)).render(a), "Hello World!"
    )

    # ANSI Color Support (0-15)
    test.assert_equal(
        mist.Style(mist.ANSI).foreground(color=mist.ANSI_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;35mHello World!\x1B[0m",
    )

    # ANSI256 Color Support (16-255)
    test.assert_equal(
        mist.Style(mist.ANSI256).foreground(color=mist.ANSI256_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;38;5;182mHello World!\x1B[0m",
    )

    # RGBColor Support (Hex Codes)
    test.assert_equal(
        mist.Style(mist.TRUE_COLOR).foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;38;2;201;160;220mHello World!\x1B[0m",
    )

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    test.assert_equal(
        mist.Style(mist.TRUE_COLOR).foreground(0xC9A0DC).render(a), "\x1B[;38;2;201;160;220mHello World!\x1B[0m"
    )


fn test_unicode_handling() raises:
    var test = MojoTest("Testing unicode handling")
    alias a: String = "Hello──World!"
    print(mist.Style().underline().foreground(12).render(a).split("\n").__str__())

    test.assert_equal(mist.Style().underline().foreground(12).render(a), '\x1b[;4;94mHello\xe2\x94\x80\xe2\x94\x80World!\x1b[0m')



fn main() raises:
    test_profile_convert()
    test_profile_color()
    test_render_profiles()
    test_unicode_handling()
