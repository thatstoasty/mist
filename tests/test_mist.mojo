from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor
from mist.screen import (
    move_cursor,
    save_cursor_position,
    restore_cursor_position,
    cursor_up,
    cursor_down,
    cursor_forward,
    cursor_back,
    cursor_next_line,
    cursor_prev_line,
    clear_line,
    clear_line_right,
)
from mist.notification import notify
from mist.hyperlink import hyperlink


# fn main() raises:
#     # var profile = Profile("TrueColor")
#     # degrading colors doesn't exactly work rn, I need to figure that out
#     # var text_color = "#c9a0dc")
#     var style = TerminalStyle()
#     # style.background(ANSI256Color(33))
#     style = style.foreground("#c9a0dc")
#     style.underline()
#     var styled = style.render("Hello World!")
#     print(styled)


fn main() raises:
    pass
    # # Positioning
    # # Move the cursor to a given position
    # var row = 1
    # var column = 1
    # var n = 1
    # move_cursor(row, column)

    # # Save the cursor position
    # save_cursor_position()

    # # Restore a saved cursor position
    # restore_cursor_position()

    # # Move the cursor up a given number of lines
    # cursor_up(n)

    # # Move the cursor down a given number of lines
    # cursor_down(n)

    # # Move the cursor up a given number of lines
    # cursor_forward(n)

    # # Move the cursor backwards a given number of cells
    # cursor_back(n)

    # # Move the cursor down a given number of lines and place it at the beginning
    # # of the line
    # cursor_next_line(n)

    # # Move the cursor up a given number of lines and place it at the beginning of
    # # the line
    # cursor_prev_line(n)

    # print_no_newline("hello")
    # cursor_back(2)
    # clear_line_right()
