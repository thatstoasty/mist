from mist import TerminalStyle, Profile, ASCII, ANSI, ANSI256, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var a: String = "Hello World!"

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    var style = TerminalStyle.new().foreground("12")
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = TerminalStyle.new().foreground("55")
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = TerminalStyle.new().foreground("#c9a0dc")
    print(style.render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    style = TerminalStyle.new(Profile(ASCII)).foreground("#c9a0dc")
    print(style.render(a))

    # ANSI Color Support (0-15)
    style = TerminalStyle.new(Profile(ANSI)).foreground("#c9a0dc")
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = TerminalStyle.new(Profile(ANSI256)).foreground("#c9a0dc")
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = TerminalStyle.new(Profile(TRUE_COLOR)).foreground("#c9a0dc")
    print(style.render(a))

    # With a second color
    style = TerminalStyle.new().foreground("10")
    print(style.render(a))
    style = TerminalStyle.new().foreground("46")
    print(style.render(a))
    style = TerminalStyle.new().foreground("#15d673")
    print(style.render(a))
    style = TerminalStyle.new(Profile(ASCII)).foreground("#15d673")
    print(style.render(a))
    style = TerminalStyle.new(Profile(ANSI)).foreground("#15d673")
    print(style.render(a))
    style = TerminalStyle.new(Profile(ANSI256)).foreground("#15d673")
    print(style.render(a))
    style = TerminalStyle.new(Profile(TRUE_COLOR)).foreground("#15d673")
    print(style.render(a))
