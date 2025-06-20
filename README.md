# mist

`mist` is an ANSI aware toolkit that enables you to style and transform text on the terminal.

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-25.4-orange)
![Build Status](https://github.com/thatstoasty/mist/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/mist/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![Example](https://github.com/thatstoasty/mist/blob/main/doc/images/hello_world.png)

## Attributions

This project was heavily inspired by:

- <https://github.com/muesli/termenv/tree/master>
- <https://github.com/muesli/reflow/tree/master>

## Installation

1. First, you'll need to configure your `pixi.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `mist` to your project's dependencies by running `pixi add mist`.
3. Finally, run `pixi install` to install in `mist` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

## Colors

It also supports multiple color profiles: ASCII (black & white only), ANSI (16 colors), ANSI Extended (256 colors), and TRUE_COLOR (24-bit RGB). If profile is not explicitly provided, it will be automatically set based on the terminal's capabilities. And if a profile is set manually, it will also automatically degrade colors to the best matching color in the desired profile. For example, you provide a hex code but your profile is in ANSI. The library will automatically degrade the color to the best matching ANSI color.

Once we have type checking in Mojo, Colors will automatically be degraded to the best matching available color in the desired profile:
`TRUE_COLOR` => `ANSI (256 Colors)` => `ANSI (16 Colors)` => `ASCII`

```mojo
import mist

fn main() raises:
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
    style = mist.Style(mist.ASCII_PROFILE).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # ANSI Color Support (0-15)
    style = mist.Style(mist.ANSI_PROFILE).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # ANSI256 Color Support (16-255)
    style = mist.Style(mist.ANSI256_PROFILE).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # RGBColor Support (Hex Codes)
    style = mist.Style(mist.TRUE_COLOR_PROFILE).foreground(0xc9a0dc)
    print(style.render("Hello World!"))

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    style = mist.Style(Profile(TRUE_COLOR)).foreground(0xc9a0dc)
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

fn main() raises:
    var style = mist.Style()

    # Text styles
    _ = style.bold()
    _ = style.faint()
    _ = style.italic()
    _ = style.crossout()
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

alias style = mist.Style(mist.TRUE_COLOR_PROFILE)

fn main():
    print(style.render("Hello, world!"))
```

## Quick Styling

You can also use quick styling methods to apply formatting and colors to your text.

```mojo
from mist import red, green, blue, bold, italic, crossout, red_background, green_background, blue_background, render_as_color, render_with_background_color

fn main():
    print(red("Hello, world!"))
    print(green("Hello, world!"))
    print(blue("Hello, world!"))
    print(red_background("Hello, world!"))
    print(green_background("Hello, world!"))
    print(blue_background("Hello, world!"))
    print(bold("Hello, world!"))
    print(italic("Hello, world!"))
    print(crossout("Hello, world!"))
    print(render_as_color("Hello, world!", 0xc9a0dc))
    print(render_with_background_color("Hello, world!", 0xc9a0dc))
```

## Terminal Control

### Termios

`mist` offers a `termios` module that allows you to control terminal settings such as echo, canonical mode, and more. This is useful for creating interactive command-line applications.

TODO: Example of using `termios` to change terminal settings.

### TTY Context Manager

In the `mist.terminal` package, you can use the `TTY` context manager as a high-level interface to manage terminal settings rather than using the `termios` module directly. This context manager allows you to temporarily change terminal settings and automatically restores them when exiting the context.

```mojo
from mist.terminal.query import get_terminal_size
from mist.terminal.tty import TTY

fn main() raises -> None:
    var rows: UInt
    var columns: UInt
    with TTY():
        rows, columns = get_terminal_size()
    print("Terminal dimensions:", rows, "x", columns)
```

### Cursor Positioning

```mojo
from mist.terminal.cursor import move_cursor, save_cursor_position, restore_cursor_position, cursor_up, cursor_down, cursor_forward, cursor_back, cursor_next_line, cursor_prev_line

fn main() raises:
    # Move the cursor to a given position
    move_cursor(row, column)

    # Save the cursor position
    save_cursor_position()

    # Restore a saved cursor position
    restore_cursor_position()

    # Move the cursor up a given number of lines
    cursor_up(n)

    # Move the cursor down a given number of lines
    cursor_down(n)

    # Move the cursor up a given number of lines
    cursor_forward(n)

    # Move the cursor backwards a given number of cells
    cursor_back(n)

    # Move the cursor down a given number of lines and place it at the beginning
    # of the line
    cursor_next_line(n)

    # Move the cursor up a given number of lines and place it at the beginning of
    # the line
    cursor_prev_line(n)
```

### Screen

```mojo
from mist.terminal.screen import reset, restore_screen, save_screen, alt_screen, exit_alt_screen, clear_screen, clear_line, clear_lines, change_scrolling_region, insert_lines, delete_lines

fn main() raises:
    # Reset the terminal to its default style, removing any active styles
    reset()

    # Restores a previously saved screen state
    restore_screen()

    # Saves the screen state
    save_screen()

    # Switch to the altscreen. The former view can be restored with ExitAltScreen()
    alt_screen()

    # Exit the altscreen and return to the former terminal view
    exit_alt_screen()

    # Clear the visible portion of the terminal
    clear_screen()

    # Clear the current line
    clear_line()

    # Clear a given number of lines
    clear_lines(n)

    # Set the scrolling region of the terminal
    change_scrolling_region(top, bottom)

    # Insert the given number of lines at the top of the scrollable region, pushing
    # lines below down
    insert_lines(n)

    # Delete the given number of lines, pulling any lines in the scrollable region
    # below up
    delete_lines(n)
```

## Example using cursor and screen operations

```mojo
from mist.terminal.screen import cursor_back, clear_line_right

fn main():
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
```

Output

![Cursor](https://github.com/thatstoasty/mist/blob/main/doc/tapes/cursor.gif)

### Session

```mojo
from mist.terminal.screen import set_window_title, set_foreground_color, set_background_color, set_cursor_color

fn main() raises:
    # Sets the terminal window title
    set_window_title(title)

    # Sets the default foreground color
    set_foreground_color(color)

    # Sets the default background color
    set_background_color(color)

    # Sets the cursor color
    set_cursor_color(color)
```

### Mouse

```mojo
from mist.terminal.screen import enable_mouse_press, disable_mouse_press, enable_mouse, disable_mouse, enable_mouse_hilite, disable_mouse_hilite, enable_mouse_cell_motion, disable_mouse_cell_motion, enable_mouse_all_motion, disable_mouse_all_motion

fn main() raises:
    # Enable X10 mouse mode, only button press events are sent
    enable_mouse_press()

    # Disable X10 mouse mode
    disable_mouse_press()

    # Enable Mouse Tracking mode
    enable_mouse()

    # Disable Mouse Tracking mode
    disable_mouse()

    # Enable Hilite Mouse Tracking mode
    enable_mouse_hilite()

    # Disable Hilite Mouse Tracking mode
    disable_mouse_hilite()

    # Enable Cell Motion Mouse Tracking mode
    enable_mouse_cell_motion()

    # Disable Cell Motion Mouse Tracking mode
    disable_mouse_cell_motion()

    # Enable All Motion Mouse mode
    enable_mouse_all_motion()

    # Disable All Motion Mouse mode
    disable_mouse_all_motion()
```

### Bracketed Paste

```mojo
from mist.terminal.screen import enable_bracketed_paste, disable_bracketed_paste

fn main() raises:
    # Enables bracketed paste mode
    enable_bracketed_paste()

    # Disables bracketed paste mode
    disable_bracketed_paste()
```

### Terminal Querying

The `mist.terminal.query` module provides functions to query terminal properties such as size, color support, and more.

```mojo
from mist.terminal.query import get_terminal_size, query_osc
from mist.terminal.tty import TTY
from mist.color import RGBColor

fn main() raises -> None:
    var rows: UInt
    var columns: UInt
    with TTY():
        var xterm_background_color = query_osc("11;?")
        rows, columns = get_terminal_size()
    print("Terminal dimensions:", rows, "x", columns)
```

## Text Transformation

### Wrap (Unconditional Wrapping)

The `wrap` module lets you unconditionally wrap strings or entire blocks of text.

```mojo
from mist.transform import wrap

fn main():
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

fn main():
    print(word_wrap("Hello Sekai!", 6))
```

Output

```txt
Hello
Sekai!
```

#### ANSI Example

```mojo
print(word_wrap("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!", 10))
```

![ANSI Example Output](https://github.com/thatstoasty/mist/blob/main/doc/images/weave.png)

### Indent

The `indent` module lets you indent strings or entire blocks of text.

```mojo
from mist.transform import indent

fn main():
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

fn main():
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

fn main():
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

fn main():
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

fn main():
    print(padding(wrap("Hello Sekai!", 5), 5))
```

Output

```txt
Hello
Sekai
!
```

## Color Chart

Color chart lifted from <https://github.com/muesli/termenv>, give their projects a star if you like this!
![ANSI color chart](https://github.com/thatstoasty/mist/blob/main/doc/images/color-chart.png)

## TODO

- Enable terminal querying for platforms other than UNIX based.
- Support querying terminal background color and if it's light or dark.
