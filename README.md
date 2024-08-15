# mist

![Mojo 24.4](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.4-purple)

`mist` lets you safely use advanced styling options on the terminal. It offers you convenient methods to colorize and style your output, without you having to deal with all kinds of weird ANSI escape sequences and color conversions. This is a port/conversion of <https://github.com/muesli/termenv/tree/master>.

![Example](https://github.com/thatstoasty/mist/blob/main/examples/hello_world/hello_world.png)

![HW](https://github.com/thatstoasty/mist/blob/main/demos/tapes/hello_world.gif)

> NOTE: This is not a 1:1 port or stable due to missing features in Mojo and that I haven't ported everything over yet.

I've only tested this on MacOS VSCode terminal so far, so your mileage may vary!

## Installation

You should be able to build the package by running `bash scripts/build.sh package` from the root of the project. This will create a `mist.mojopkg` file that you can import into your project. You also need the following dependencies that it creates:

- `gojo.mojopkg`
- `hue.mojopkg`

You can drop the mojo packages in the root of your project, or in a directory of your choosing. If you put them in a directory, you'll need to add `-I path/to/directory` to your `mojo run` or `mojo build` command that you use to run your code. This will tell Mojo what directory to import from to import the `mist` package and it's dependencies.

> NOTE: It seems like `.mojopkg` files don't like being part of another package, eg. sticking all of your external deps in an `external` or `vendor` package. The only way I've gotten mojopkg files to work is to be in the same directory as the file being executed, or in the root directory like you can see in this project.

## Colors

It also supports multiple color profiles: Ascii (black & white only), ANSI (16 colors), ANSI Extended (256 colors), and TRUE_COLOR (24-bit RGB). If profile is not explicitly provided, it will be automatically set based on the terminal's capabilities. And if a profile is set manually, it will also automatically degrade colors to the best matching color in the desired profile. For example, you provide a hex code but your profile is in ANSI. The library will automatically degrade the color to the best matching ANSI color.

Once we have type checking in Mojo, Colors will automatically be degraded to the best matching available color in the desired profile:
`TRUE_COLOR` => `ANSI 256 Color`s => `ANSI 16 Colors` => `Ascii`

```mojo
import mist
from mist import Style, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var a: String = "Hello World!"
    var profile = Profile()

    # ) will automatically convert the color to the best matching color in the profile.
    # ANSI Color Support (0-15)
    var style = mist.Style().foreground(12)
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = mist.Style().foreground(55)
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = mist.Style().foreground(0xc9a0dc)
    print(style.render(a))

    # The color profile will also degrade colors automatically depending on the color's supported by the terminal.
    # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
    # Black and White only
    style = mist.Style(mist.ASCII_PROFILE).foreground(0xc9a0dc)
    print(style.render(a))

    # ANSI Color Support (0-15)
    style = mist.Style(mist.ANSI_PROFILE).foreground(0xc9a0dc)
    print(style.render(a))

    # ANSI256 Color Support (16-255)
    style = mist.Style(mist.ANSI256_PROFILE).foreground(0xc9a0dc)
    print(style.render(a))

    # RGBColor Support (Hex Codes)
    style = mist.Style(mist.TRUE_COLOR_PROFILE).foreground(0xc9a0dc)
    print(style.render(a))

    # It also supports using the Profile of the Style to instead of passing Profile().color().
    style = mist.Style(Profile(TRUE_COLOR)).foreground(0xc9a0dc)
    print(style.render(a))

```

![Profiles](https://github.com/thatstoasty/mist/blob/main/demos/tapes/profiles.gif)

## Styles

You can apply text formatting effects to your text by setting the rules on the `Style` object then using that object to render your text.

```mojo
from mist import Style

fn main() raises:
    var a: String = "Hello World!"
    var style = mist.Style()

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
    style = style.blink()

    print(style.render(a))
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

## Positioning

```mojo
from mist.screen import move_cursor, save_cursor_position, restore_cursor_position, cursor_up, cursor_down, cursor_forward, cursor_back, cursor_next_line, cursor_prev_line

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

## Screen

```mojo
from mist.screen import reset, restore_screen, save_screen, alt_screen, exit_alt_screen, clear_screen, clear_line, clear_lines, change_scrolling_region, insert_lines, delete_lines

fn main() raises:
    # Reset the terminal to its default style, removing any active styles
    reset()

    # RestoreScreen restores a previously saved screen state
    restore_screen()

    # SaveScreen saves the screen state
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
from mist.screen import cursor_back, clear_line_right


fn main():
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
```

Output

![Cursor](https://github.com/thatstoasty/mist/blob/main/demos/tapes/cursor.gif)

## Session

```mojo
from mist.screen import set_window_title, set_foreground_color, set_background_color, set_cursor_color

fn main() raises:
    # set_window_title sets the terminal window title
    set_window_title(title)

    # set_foreground_color sets the default foreground color
    set_foreground_color(color)

    # set_background_color sets the default background color
    set_background_color(color)

    # set_cursor_color sets the cursor color
    set_cursor_color(color)
```

## Mouse

```mojo
from mist.screen import enable_mouse_press, disable_mouse_press, enable_mouse, disable_mouse, enable_mouse_hilite, disable_mouse_hilite, enable_mouse_cell_motion, disable_mouse_cell_motion, enable_mouse_all_motion, disable_mouse_all_motion

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

## Bracketed Paste

```mojo
from mist.screen import enable_bracketed_paste, disable_bracketed_paste

fn main() raises:
    # Enables bracketed paste mode
    enable_bracketed_paste()

    # Disables bracketed paste mode
    disable_bracketed_paste()
```

## Color Chart

Color chart lifted from <https://github.com/muesli/termenv>, give their projects a star if you like this!
![ANSI color chart](https://github.com/thatstoasty/mist/blob/main/color-chart.png)

## TODO

- Enable terminal querying for platforms other than UNIX based.
- Switch to stdout writer
