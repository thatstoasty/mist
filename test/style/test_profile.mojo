import os

import testing
from mist.style.color import ANSI256Color, ANSIColor, NoColor, RGBColor
from mist.style.profile import Profile, get_color_profile
from testing import TestSuite

import mist


comptime TRUE_COLOR_STYLE = mist.Style(Profile.TRUE_COLOR)
comptime ANSI_STYLE = mist.Style(Profile.ANSI)
comptime ANSI256_STYLE = mist.Style(Profile.ANSI256)
comptime ASCII_STYLE = mist.Style(Profile.ASCII)


fn test_ascii_profile_color_conversions() raises:
    comptime profile = Profile.ASCII
    # Degrade Hex, ANSI256, and ANSI to ASCII
    testing.assert_equal(profile.convert(ANSIColor(5))[NoColor].sequence[False](), NoColor().sequence[False]())
    testing.assert_equal(profile.convert(ANSI256Color(100))[NoColor].sequence[False](), NoColor().sequence[False]())
    testing.assert_equal(profile.convert(RGBColor(0xC9A0DC))[NoColor].sequence[False](), NoColor().sequence[False]())


fn test_ansi_profile_color_conversions() raises:
    comptime profile = Profile.ANSI

    fn validate_ansi256_degradation(ansi256_color: UInt8, ansi_color: UInt8) raises -> None:
        testing.assert_equal(
            String(profile.convert(ANSI256Color(ansi256_color))[ANSIColor].value), String(ANSIColor(ansi_color).value)
        )

    # Degrade ANSI256 to ANSI
    validate_ansi256_degradation(ansi256_color=0, ansi_color=0)  # Black
    validate_ansi256_degradation(ansi256_color=50, ansi_color=14)  # Cyan
    validate_ansi256_degradation(ansi256_color=100, ansi_color=3)  # Yellow
    validate_ansi256_degradation(ansi256_color=150, ansi_color=10)  # Green
    validate_ansi256_degradation(ansi256_color=200, ansi_color=13)  # Magenta
    validate_ansi256_degradation(ansi256_color=255, ansi_color=15)  # White

    fn validate_rgb_degradation(rgb_color: UInt32, ansi_color: UInt8) raises -> None:
        testing.assert_equal(
            String(profile.convert(RGBColor(rgb_color))[ANSIColor].value), String(ANSIColor(ansi_color).value)
        )

    # Degrade Hex to ANSI
    validate_rgb_degradation(rgb_color=0x000000, ansi_color=0)
    validate_rgb_degradation(rgb_color=0x808000, ansi_color=3)
    validate_rgb_degradation(rgb_color=0xC9A0DC, ansi_color=13)
    validate_rgb_degradation(rgb_color=0x808080, ansi_color=8)
    validate_rgb_degradation(rgb_color=0x00FF00, ansi_color=10)
    validate_rgb_degradation(rgb_color=0x0000FF, ansi_color=12)
    validate_rgb_degradation(rgb_color=0xFFFFFF, ansi_color=15)


fn test_ansi256_profile_color_conversions() raises:
    comptime profile = Profile.ANSI256

    # Degrade Hex to ANSI256
    fn validate_rgb_degradation(rgb_color: UInt32, ansi256_color: UInt8) raises -> None:
        testing.assert_equal(
            String(profile.convert(RGBColor(rgb_color))[ANSI256Color].value), String(ANSI256Color(ansi256_color).value)
        )

    validate_rgb_degradation(rgb_color=0x000000, ansi256_color=16)
    validate_rgb_degradation(rgb_color=0x808000, ansi256_color=100)
    validate_rgb_degradation(rgb_color=0xC9A0DC, ansi256_color=182)
    validate_rgb_degradation(rgb_color=0x808080, ansi256_color=102)
    validate_rgb_degradation(rgb_color=0x00FF00, ansi256_color=46)
    validate_rgb_degradation(rgb_color=0x0000FF, ansi256_color=21)
    validate_rgb_degradation(rgb_color=0xFFFFFF, ansi256_color=231)


fn test_profile_color() raises:
    # ASCII profile returns NoColor for all colors.
    testing.assert_equal(Profile.ASCII.color(0xC9A0DC)[NoColor].sequence[False](), NoColor().sequence[False]())

    # ANSI256 profile will degrade the RGB color to the closest ANSI256 color.
    testing.assert_equal(String(Profile.ANSI256.color(0xC9A0DC)[ANSI256Color].value), String(ANSI256Color(182).value))

    # ANSI profile will degrade the ANSI256 color to the closest ANSI color.
    testing.assert_equal(String(Profile.ANSI.convert(ANSI256Color(100))[ANSIColor].value), String(ANSIColor(3).value))


fn test_render_profiles() raises:
    comptime a = "Hello World!"

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    testing.assert_equal(TRUE_COLOR_STYLE.foreground(12).render(a), "\x1B[94mHello World!\x1B[0m")

    # ANSI256 Color Support (16-255)
    testing.assert_equal(TRUE_COLOR_STYLE.foreground(55).render(a), "\x1B[38;5;55mHello World!\x1B[0m")

    # RGBColor Support (Hex Codes)
    testing.assert_equal(TRUE_COLOR_STYLE.foreground(0xC9A0DC).render(a), "\x1B[38;2;201;160;220mHello World!\x1B[0m")

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    testing.assert_equal(ASCII_STYLE.foreground(color=Profile.ASCII.color(0xC9A0DC)).render(a), "Hello World!")

    # ANSI Color Support (0-15)
    testing.assert_equal(
        ANSI_STYLE.foreground(color=Profile.ANSI.color(0xC9A0DC)).render(a),
        "\x1B[95mHello World!\x1B[0m",
    )

    # ANSI256 Color Support (16-255)
    testing.assert_equal(
        ANSI256_STYLE.foreground(color=Profile.ANSI256.color(0xC9A0DC)).render(a),
        "\x1B[38;5;182mHello World!\x1B[0m",
    )

    # RGBColor Support (Hex Codes)
    testing.assert_equal(
        TRUE_COLOR_STYLE.foreground(color=Profile.TRUE_COLOR.color(0xC9A0DC)).render(a),
        "\x1B[38;2;201;160;220mHello World!\x1B[0m",
    )

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    testing.assert_equal(TRUE_COLOR_STYLE.foreground(0xC9A0DC).render(a), "\x1B[38;2;201;160;220mHello World!\x1B[0m")


fn test_unicode_handling() raises:
    comptime a = "Hello──World!"
    testing.assert_equal(
        TRUE_COLOR_STYLE.underline().foreground(12).render(a),
        "\x1B[4;94mHello\xe2\x94\x80\xe2\x94\x80World!\x1b[0m",
    )


@fieldwise_init
struct EnvVar(Copyable, ImplicitlyCopyable, Movable):
    var name: String

    fn __init__(out self, name: String, value: String):
        self.name = name
        _ = os.setenv(name, value)

    fn __enter__(self) -> Self:
        return self

    fn __exit__(self) -> None:
        _ = os.unsetenv(self.name)


# fn test_get_color_profile() raises:
#     with EnvVar("GOOGLE_CLOUD_SHELL", "true"):
#         testing.assert_equal(get_color_profile(), Profile.TRUE_COLOR)

#     with EnvVar("COLOR_TERM", "24bit"):
#         testing.assert_equal(get_color_profile(), Profile.ANSI256)

#         with EnvVar("TERM", "xterm-kitty"):
#             testing.assert_equal(get_color_profile(), Profile.TRUE_COLOR)
#         with EnvVar("TERM", "wezterm"):
#             testing.assert_equal(get_color_profile(), Profile.TRUE_COLOR)
#         with EnvVar("TERM", "xterm-ghostty"):
#             testing.assert_equal(get_color_profile(), Profile.TRUE_COLOR)
#         with EnvVar("TERM", "linux"):
#             testing.assert_equal(get_color_profile(), Profile.ANSI)

#     with EnvVar("COLOR_TERM", "true"):
#         testing.assert_equal(get_color_profile(), Profile.ANSI256)


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
