from mist import TerminalStyle, Profile, ASCII, ANSI, ANSI256, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var a: String = "Hello World!"
    var profile = Profile()

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    var style = TerminalStyle.new().foreground(profile.color("12"))
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = TerminalStyle.new().foreground(profile.color("55"))
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = TerminalStyle.new().foreground(profile.color("#c9a0dc"))
    print(style.render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    style = TerminalStyle.new(Profile(ASCII)).foreground(profile.color("#c9a0dc"))
    print(style.render(a))

    # ANSI Color Support (0-15)
    style = TerminalStyle.new(Profile(ANSI)).foreground(profile.color("#c9a0dc"))
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = TerminalStyle.new(Profile(ANSI256)).foreground(profile.color("#c9a0dc"))
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = TerminalStyle.new(Profile(TRUE_COLOR)).foreground(profile.color("#c9a0dc"))
    print(style.render(a))

    # It also supports using the Profile of the TerminalStyle to instead of passing Profile().color().
    style = TerminalStyle.new(Profile(TRUE_COLOR)).foreground("#c9a0dc")
    print(style.render(a))

    # With a second color
    style = TerminalStyle.new().foreground(profile.color("10"))
    print(style.render(a))
    style = TerminalStyle.new().foreground(profile.color("46"))
    print(style.render(a))
    style = TerminalStyle.new().foreground(profile.color("#15d673"))
    print(style.render(a))
    style = TerminalStyle.new(Profile(ASCII)).foreground(profile.color("#15d673"))
    print(style.render(a))
    style = TerminalStyle.new(Profile(ANSI)).foreground(profile.color("#15d673"))
    print(style.render(a))
    style = TerminalStyle.new(Profile(ANSI256)).foreground(profile.color("#15d673"))
    print(style.render(a))
    style = TerminalStyle.new(Profile(TRUE_COLOR)).foreground(profile.color("#15d673"))
    print(style.render(a))
