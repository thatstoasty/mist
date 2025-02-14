import os
import mist
from mist import Profile, ASCII, ANSI, ANSI256, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor, NoColor
from mist.profile import get_color_profile
import testing


def test_profile_convert():
    # Degrade Hex, ANSI256, and ANSI to ASCII
    testing.assert_equal(
        mist.ASCII_PROFILE.convert(ANSIColor(5))[NoColor].sequence[False](), NoColor().sequence[False]()
    )
    testing.assert_equal(
        mist.ASCII_PROFILE.convert(ANSI256Color(100))[NoColor].sequence[False](), NoColor().sequence[False]()
    )
    testing.assert_equal(
        mist.ASCII_PROFILE.convert(RGBColor(0xC9A0DC))[NoColor].sequence[False](), NoColor().sequence[False]()
    )

    # Degrade Hex, and ANSI256 to ANSI
    testing.assert_equal(String(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor].value), String(ANSIColor(3).value))
    testing.assert_equal(String(mist.ANSI_PROFILE.convert(RGBColor(0xC9A0DC))[ANSIColor].value), String(ANSIColor(5).value))

    # Degrade Hex to ANSI256
    testing.assert_equal(
        String(mist.ANSI256_PROFILE.convert(RGBColor(0xC9A0DC))[ANSI256Color].value), String(ANSI256Color(182).value)
    )


def test_profile_color():
    # ASCII profile returns NoColor for all colors.
    testing.assert_equal(mist.ASCII_PROFILE.color(0xC9A0DC)[NoColor].sequence[False](), NoColor().sequence[False]())

    # ANSI256 profile will degrade the RGB color to the closest ANSI256 color.
    testing.assert_equal(String(mist.ANSI256_PROFILE.color(0xC9A0DC)[ANSI256Color].value), String(ANSI256Color(182).value))

    # ANSI profile will degrade the ANSI256 color to the closest ANSI color.
    testing.assert_equal(String(mist.ANSI_PROFILE.convert(ANSI256Color(100))[ANSIColor].value), String(ANSIColor(3).value))


def test_render_profiles():
    alias a = "Hello World!"

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    testing.assert_equal(mist.Style(mist.TRUE_COLOR).foreground(12).render(a), "\x1B[;94mHello World!\x1B[0m")

    # ANSI256 Color Support (16-255)
    testing.assert_equal(mist.Style(mist.TRUE_COLOR).foreground(55).render(a), "\x1B[;38;5;55mHello World!\x1B[0m")

    # RGBColor Support (Hex Codes)
    testing.assert_equal(
        mist.Style(mist.TRUE_COLOR).foreground(0xC9A0DC).render(a), "\x1B[;38;2;201;160;220mHello World!\x1B[0m"
    )

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    testing.assert_equal(
        mist.Style(mist.ASCII).foreground(color=mist.ASCII_PROFILE.color(0xC9A0DC)).render(a), "Hello World!"
    )

    # ANSI Color Support (0-15)
    testing.assert_equal(
        mist.Style(mist.ANSI).foreground(color=mist.ANSI_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;35mHello World!\x1B[0m",
    )

    # ANSI256 Color Support (16-255)
    testing.assert_equal(
        mist.Style(mist.ANSI256).foreground(color=mist.ANSI256_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;38;5;182mHello World!\x1B[0m",
    )

    # RGBColor Support (Hex Codes)
    testing.assert_equal(
        mist.Style(mist.TRUE_COLOR).foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a),
        "\x1B[;38;2;201;160;220mHello World!\x1B[0m",
    )

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    testing.assert_equal(
        mist.Style(mist.TRUE_COLOR).foreground(0xC9A0DC).render(a), "\x1B[;38;2;201;160;220mHello World!\x1B[0m"
    )


def test_unicode_handling():
    alias a = "Hello──World!"
    testing.assert_equal(
        mist.Style(mist.TRUE_COLOR).underline().foreground(12).render(a),
        "\x1b[;4;94mHello\xe2\x94\x80\xe2\x94\x80World!\x1b[0m",
    )


@value
struct EnvVar:
    var name: String

    fn __init__(out self, name: String, value: String):
        self.name = name
        _ = os.setenv(name, value)

    fn __enter__(self) -> Self:
        return self

    fn __exit__(self) -> None:
        _ = os.unsetenv(self.name)


# def test_get_color_profile():
#     with EnvVar("GOOGLE_CLOUD_SHELL", "true"):
#         testing.assert_equal(get_color_profile(), TRUE_COLOR)

#     with EnvVar("COLOR_TERM", "24bit"):
#         testing.assert_equal(get_color_profile(), ANSI256)

#         with EnvVar("TERM", "xterm-kitty"):
#             testing.assert_equal(get_color_profile(), TRUE_COLOR)
#         with EnvVar("TERM", "wezterm"):
#             testing.assert_equal(get_color_profile(), TRUE_COLOR)
#         with EnvVar("TERM", "xterm-ghostty"):
#             testing.assert_equal(get_color_profile(), TRUE_COLOR)
#         with EnvVar("TERM", "linux"):
#             testing.assert_equal(get_color_profile(), ANSI)

#     with EnvVar("COLOR_TERM", "true"):
#         testing.assert_equal(get_color_profile(), ANSI256)
