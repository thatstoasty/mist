from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var a: String = "Hello World!"
    var style = TerminalStyle()

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    style = TerminalStyle()
    style.foreground("12")
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = TerminalStyle()
    style.foreground("55")
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = TerminalStyle()
    style.foreground("#c9a0dc")
    print(style.render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    var profile = Profile("ASCII")
    style = TerminalStyle(profile)
    style.foreground("#c9a0dc")
    print(style.render(a))

    # ANSI Color Support (0-15)
    profile = Profile("ANSI")
    style = TerminalStyle(profile)
    style.foreground("#c9a0dc")
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    profile = Profile("ANSI256")
    style = TerminalStyle(profile)
    style.foreground("#c9a0dc")
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    profile = Profile("TrueColor")
    style = TerminalStyle(profile)
    style.foreground("#c9a0dc")
    print(style.render(a))
