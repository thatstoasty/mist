from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor
from mist.screen import move_cursor, save_cursor_position, restore_cursor_position, cursor_up, cursor_down, cursor_forward, cursor_back, cursor_next_line, cursor_prev_line, clear_line, clear_line_right
from mist.notification import notify
from mist.hyperlink import hyperlink

fn main() raises:
    let profile = Profile("TrueColor")
    # degrading colors doesn't exactly work rn, I need to figure that out
    # let text_color = profile.color("#c9a0dc")
    var style = TerminalStyle(profile)
    # style.background(ANSI256Color(33))
    style.foreground(profile.color("#c9a0dc"))
    style.underline()
    let styled = style.render("Hello World!")
    print(styled)


# fn main() raises:
#     # let a: String = "Hello World!"
#     # var profile = Profile("TrueColor")
#     # var style = TerminalStyle(profile)

#     # # profile.color() will automatically convert the color to the best matching color in the profile.
#     # # ANSI Color Support (0-15)
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("12"))
#     # print(style.render(a))

#     # # ANSI256 Color Support (16-255)
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("55"))
#     # print(style.render(a))

#     # # RGBColor Support (Hex Codes)
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("#c9a0dc"))
#     # print(style.render(a))

#     # # profile.color() will also degrade colors automatically depending on the color's supported by the terminal.
#     # # For now the profile setting is manually set, but eventually it will be automatically set based on the terminal.
#     # # Black and White only
#     # profile = Profile("ASCII")
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("#c9a0dc"))
#     # print(style.render(a))

#     # # ANSI Color Support (0-15)
#     # profile = Profile("ANSI")
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("#c9a0dc"))
#     # print(style.render(a))

#     # # ANSI256 Color Support (16-255)
#     # profile = Profile("ANSI256")
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("#c9a0dc"))
#     # print(style.render(a))

#     # # RGBColor Support (Hex Codes)
#     # profile = Profile("TrueColor")
#     # style = TerminalStyle(profile)
#     # style.foreground(profile.color("#c9a0dc"))
#     # print(style.render(a))

#     # # Positioning
#     # # Move the cursor to a given position
#     # let row = 1
#     # let column = 1
#     # let n = 1
#     # move_cursor(row, column)

#     # # Save the cursor position
#     # save_cursor_position()

#     # # Restore a saved cursor position
#     # restore_cursor_position()

#     # # Move the cursor up a given number of lines
#     # cursor_up(n)

#     # # Move the cursor down a given number of lines
#     # cursor_down(n)

#     # # Move the cursor up a given number of lines
#     # cursor_forward(n)

#     # # Move the cursor backwards a given number of cells
#     # cursor_back(n)

#     # # Move the cursor down a given number of lines and place it at the beginning
#     # # of the line
#     # cursor_next_line(n)

#     # # Move the cursor up a given number of lines and place it at the beginning of
#     # # the line
#     # cursor_prev_line(n)

#     print_no_newline("hello")
#     cursor_back(2)
#     clear_line_right()