# mist
`mist` lets you safely use advanced styling options on the terminal. It offers you convenient methods to colorize and style your output, without you having to deal with all kinds of weird ANSI escape sequences and color conversions. This is a port/conversion of https://github.com/muesli/termenv/tree/master.

![Example](https://github.com/thatstoasty/mist/blob/main/examples/hello_world/hello_world.png)

> NOTE: This is not a 1:1 port or stable due to missing features in Mojo and that I haven't ported everything over yet.

I've only tested this on MacOS VSCode terminal so far, so your mileage may vary!

# Colors
It also supports multiple color profiles: Ascii (black & white only), ANSI (16 colors), ANSI Extended (256 colors), and TrueColor (24-bit RGB). At the moment, the Profile is not used, so you'll need to set the foreground or background colors directly with the Color objects. Eventually, calling p.Color and providing a hex code or ansi color will automatically convert it to the best matching color in the profile.

Once we have type checking in Mojo, Colors will automatically be degraded to the best matching available color in the desired profile:
`TrueColor` => `ANSI 256 Color`s => `ANSI 16 Colors` => `Ascii`

```python
from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    let a: String = "Hello World!"
    let profile = Profile("TrueColor")
    var style = TerminalStyle(profile)

    # ANSI Color Support (0-15)
    style.foreground(ANSIColor(12))

    # ANSI256 Color Support (16-255)
    style.foreground(ANSI256Color(33))

    # RGBColor Support (Hex Codes)
    style.foreground(RGBColor("#c9a0dc"))

    print(style.render(a))
```

# Styles
You can apply text formatting effects to your text by setting the rules on the `TerminalStyle` object then using that object to render your text.
Chaining is not supported yet, but will be in the future!

```python
from mist import TerminalStyle, Profile

fn main() raises:
    let a: String = "Hello World!"
    let profile = Profile("TrueColor")
    var style = TerminalStyle(profile)

    # Text styles
    style.bold()
    style.faint()
    style.italic()
    style.crossout()
    style.underline()
    style.overline()

    # Swaps current foreground and background colors
    style.reverse()

    # Blinking text
    style.blink()

    print(style.render(a))
```

## Color Chart
Color chart lifted from https://github.com/muesli/termenv, give their projects a star if you like this!
![ANSI color chart](https://github.com/thatstoasty/mist/blob/main/color-chart.png)


# TODO
- Enable terminal querying
- Switch to stdout writer