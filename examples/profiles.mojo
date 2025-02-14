import mist


fn render_profiles():
    var a: String = "Hello World!"

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    print(mist.Style().foreground(12).render(a))

    # ANSI256 Color Support (16-255)
    print(mist.Style().foreground(55).render(a))

    # RGBColor Support (Hex Codes)
    print(mist.Style().foreground(0xC9A0DC).render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    print(mist.Style(mist.ASCII).foreground(color=mist.ASCII_PROFILE.color(0xC9A0DC)).render(a))

    # ANSI Color Support (0-15)
    print(mist.Style(mist.ANSI).foreground(color=mist.ANSI_PROFILE.color(0xC9A0DC)).render(a))

    # ANSI256 Color Support (16-255)
    print(mist.Style(mist.ANSI256).foreground(color=mist.ANSI256_PROFILE.color(0xC9A0DC)).render(a))

    # RGBColor Support (Hex Codes)
    print(mist.Style(mist.TRUE_COLOR).foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a))

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    print(mist.Style(mist.TRUE_COLOR).foreground(0xC9A0DC).render(a))


fn renderers():
    print(mist.red("Hello, world!"))
    print(mist.green("Hello, world!"))
    print(mist.blue("Hello, world!"))
    print(mist.red_background("Hello, world!"))
    print(mist.green_background("Hello, world!"))
    print(mist.blue_background("Hello, world!"))
    print(mist.bold("Hello, world!"))
    print(mist.italic("Hello, world!"))
    print(mist.strikethrough("Hello, world!"))


fn main():
    render_profiles()
    renderers()
