# mist

`mist` is an ANSI aware toolkit that enables you to:

* Style and transform text on the terminal.

> NOTE: Terminal control functionality has moved over to [Termctl](https://github.com/thatstoasty/termctl)!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-1.0.0-orange)
![Build Status](https://github.com/thatstoasty/mist/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/mist/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![Example](https://github.com/thatstoasty/mist/blob/main/doc/images/hello_world.png)

## Attributions

This project was heavily inspired by:

* [Termenv](https://github.com/muesli/termenv/tree/master)
* [Reflow](https://github.com/muesli/reflow/tree/master)
* [Crossterm](https://github.com/crossterm-rs/crossterm)

## Adding the `mist` package to your project

First, you'll need to enable the `pixi-build` preview by adding this to the `workspace` section of your `pixi.toml` file.

```bash
preview = ["pixi-build"]
```

### Building it from source

There's two ways to build `mist` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add mist --git "https://github.com/thatstoasty/mist.git" --tag "v0.3.0" && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/mist.git

# Add the package to your project from the local path
pixi add -s ./path/to/mist && pixi install
```

## Colors

It also supports multiple color profiles: ASCII (black & white only), ANSI (16 colors), ANSI Extended (256 colors), and TRUE_COLOR (24-bit RGB). If profile is not explicitly provided, it will be automatically set based on the terminal's capabilities. And if a profile is set manually, it will also automatically degrade colors to the best matching color in the desired profile. For example, you provide a hex code but your profile is in ANSI. The library will automatically degrade the color to the best matching ANSI color.

Once we have type checking in Mojo, Colors will automatically be degraded to the best matching available color in the desired profile:
`TRUE_COLOR` => `ANSI (256 Colors)` => `ANSI (16 Colors)` => `ASCII`

```mojo
import mist
from mist import Profile

def main() raises:
    var profile = mist.Profile()

    # will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    var style = mist.Style().foreground(12)
    print(style.render("Hello World!"))

    # ANSI256 Color Support (16-255)
    style = mist.Style().foreground(55)
    print(style.render("Hello World!"))

    # RGBColor Support (Hex Codes)
    style = mist.Style().foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    style = mist.Style(Profile.ASCII).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # ANSI Color Support (0-15)
    style = mist.Style(Profile.ANSI).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # ANSI256 Color Support (16-255)
    style = mist.Style(Profile.ANSI256).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # RGBColor Support (Hex Codes)
    style = mist.Style(Profile.TRUE_COLOR).foreground(0xc9a0dc)
    print(style.render("Hello World!"))
```

![Profiles](https://github.com/thatstoasty/mist/blob/main/doc/tapes/profiles.gif)

### Setting the color profile as a build parameter

If you want to set the color profile during the build process, you can do so by setting the `MIST_PROFILE` parameter environment variable. This will set the color profile for all styles that do not have a profile explicitly set.

```bash
mojo build my_file.mojo -D MIST_PROFILE=TRUE_COLOR
# or...
mojo my_file.mojo -D MIST_PROFILE=TRUE_COLOR
```

The valid values are: `TRUE_COLOR`, `ANSI256`, `ANSI`, `ASCII`. If it is not set, the profile will be automatically set based on the terminal's capabilities. However, if you're constructing a style at compile time, and you didn't set the profile explicitly nor did you set the `MIST_PROFILE` parameter environment variable, the compilation will fail as the terminal cannot be queried at that time.

## Styles

You can apply text formatting effects to your text by setting the rules on the `Style` object then using that object to render your text. Setting a new style **copies** the current style and applies the new rule to it. This means you can chain multiple styles together, without worrying about modifying the original.

```mojo
import mist

def main() raises:
    var style = mist.Style()

    # Text styles
    _ = style.bold()
    _ = style.faint()
    _ = style.italic()
    _ = style.strikethrough()
    _ = style.underline()
    _ = style.overline()

    # Swaps current foreground and background colors
    _ = style.reverse()

    # Blinking text
    style = style.blink()

    print(style.render("Hello World!"))
```

## Compile Time Styles

`mist` Styles can be built at compile time and used as constants in your code. This can be useful if you have a set of styles that you want to reuse throughout your code as Mojo currently does not support file-scope variables. This can be done by specifying the color profile of the style. Without specifying it, the style will attempt to query the terminal for its color capabilities, which cannot run at compile time.

```mojo
import mist
from mist import Profile

comptime style = mist.Style(Profile.TRUE_COLOR)

def main():
    print(style.render("Hello, world!"))
```

## Quick Styling

You can also use quick styling methods to apply formatting and colors to your text.

```mojo
from mist import red, green, blue, bold, italic, strikethrough, red_background, green_background, blue_background, render_as_color, render_with_background_color

def main():
    print(red("Hello, world!"))
    print(green("Hello, world!"))
    print(blue("Hello, world!"))
    print(red_background("Hello, world!"))
    print(green_background("Hello, world!"))
    print(blue_background("Hello, world!"))
    print(bold("Hello, world!"))
    print(italic("Hello, world!"))
    print(strikethrough("Hello, world!"))
    print(render_as_color("Hello, world!", 0xc9a0dc))
    print(render_with_background_color("Hello, world!", 0xc9a0dc))
```

## ANSI Aware Text Transformation

### Wrap (Unconditional Wrapping)

The `wrap` module lets you unconditionally wrap strings or entire blocks of text.

```mojo
from mist.transform import wrap

def main():
    print(wrap("Hello Sekai!", 5))
```

Output

```txt
Hello
Sekai
!
```

### Word wrap

The `word_wrap` package lets you word-wrap strings or entire blocks of text.

```mojo
from mist.transform import word_wrap

def main():
    print(word_wrap("Hello Sekai!", 6))
```

Output

```txt
Hello
Sekai!
```

#### ANSI Example

```mojo
from mist.transform import word_wrap

def main():
    print(word_wrap("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 10))
```

![ANSI Example Output](https://github.com/thatstoasty/mist/blob/main/doc/images/weave.png)

### Indent

The `indent` module lets you indent strings or entire blocks of text.

```mojo
from mist.transform import indent

def main():
    print(indent("Hello\nWorld\n  TEST!", 5))
```

Output

```txt
     Hello
     World
       TEST!
```

### Dedent

The `dedent` module lets you dedent strings or entire blocks of text.
It takes the minimum indentation of all lines and removes that amount of leading whitespace from each line.

```mojo
from mist.transform import dedent

def main():
    print(dedent("    Line 1!\n  Line 2!"))
```

Output

```txt
  Line 1!
Line 2!
```

### Padding

The `padding` module lets you right pad strings or entire blocks of text.

```mojo
from mist.transform import padding

def main():
    print(padding("Hello\nWorld\nThis is my text!", 15))
```

Output

```txt
Hello
World
This is my text!
```

### Truncate

```mojo
from mist.transform import truncate

def main():
    print(truncate("abcdefghikl\nasjdn", 5))
```

Output

```txt
abcde
```

### Chaining outputs

```mojo
from mist.transform import wrap
from mist.transform import padding

def main():
    print(padding(wrap("Hello Sekai!", 5), 5))
```

Output

```txt
Hello
Sekai
!
```

## Color Chart

Color chart lifted from [termenv](https://github.com/muesli/termenv), give their projects a star if you like this!
![ANSI color chart](https://github.com/thatstoasty/mist/blob/main/doc/images/color-chart.png)

## TODO
