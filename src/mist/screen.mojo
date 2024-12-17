from .style import BEL, CSI, RESET, OSC
from .color import AnyColor, NoColor, ANSIColor, ANSI256Color, RGBColor


# Sequence definitions.
## Cursor positioning.
alias CURSOR_UP_SEQ = "{}A"
alias CURSOR_DOWN_SEQ = "{}B"
alias CURSOR_FORWARD_SEQ = "{}C"
alias CURSOR_BACK_SEQ = "{}D"
alias CURSOR_NEXT_LINE_SEQ = "{}E"
alias CURSOR_PREVIOUS_LINE_SEQ = "{}F"
alias CURSOR_HORIZONTAL_SEQ = "{}G"
alias CURSOR_POSITION_SEQ = "{};{}H"
alias ERASE_DISPLAY_SEQ = "{}J"
alias ERASE_LINE_SEQ = "{}K"
alias SCROLL_UP_SEQ = "{}S"
alias SCROLL_DOWN_SEQ = "{}T"
alias SAVE_CURSOR_POSITION_SEQ = "s"
alias RESTORE_CURSOR_POSITION_SEQ = "u"
alias CHANGE_SCROLLING_REGION_SEQ = "{};{}r"
alias INSERT_LINE_SEQ = "{}L"
alias DELETE_LINE_SEQ = "{}M"

## Explicit values for EraseLineSeq.
alias ERASE_LINE_RIGHT_SEQ = "0K"
alias ERASE_LINE_LEFT_SEQ = "1K"
alias ERASE_ENTIRE_LINE_SEQ = "2K"

## Mouse
alias ENABLE_MOUSE_PRESS_SEQ = "?9h"  # press only (X10)
alias DISABLE_MOUSE_PRESS_SEQ = "?9l"
alias ENABLE_MOUSE_SEQ = "?1000h"  # press, release, wheel
alias DISABLE_MOUSE_SEQ = "?1000l"
alias ENABLE_MOUSE_HILITE_SEQ = "?1001h"  # highlight
alias DISABLE_MOUSE_HILITE_SEQ = "?1001l"
alias ENABLE_MOUSE_CELL_MOTION_SEQ = "?1002h"  # press, release, move on pressed, wheel
alias DISABLE_MOUSE_CELL_MOTION_SEQ = "?1002l"
alias ENABLE_MOUSE_ALL_MOTION_SEQ = "?1003h"  # press, release, move, wheel
alias DISABLE_MOUSE_ALL_MOTION_SEQ = "?1003l"
alias ENABLE_MOUSE_EXTENDED_MODE_SEQ = "?1006h"  # press, release, move, wheel, extended coordinates
alias DISABLE_MOUSE_EXTENDED_MODE_SEQ = "?1006l"
alias ENABLE_MOUSE_PIXELS_MODE_SEQ = "?1016h"  # press, release, move, wheel, extended pixel coordinates
alias DISABLE_MOUSE_PIXELS_MODE_SEQ = "?1016l"

## Screen
alias RESTORE_SCREEN_SEQ = "?47l"
alias SAVE_SCREEN_SEQ = "?47h"
alias ALT_SCREEN_SEQ = "?1049h"
alias EXIT_ALT_SCREEN_SEQ = "?1049l"

## Bracketed paste.
## https:#en.wikipedia.org/wiki/Bracketed-paste
alias ENABLE_BRACKETED_PASTE_SEQ = "?2004h"
alias DISABLE_BRACKETED_PASTE_SEQ = "?2004l"
alias START_BRACKETED_PASTE_SEQ = "200~"
alias END_BRACKETED_PASTE_SEQ = "201~"

## Session
alias SET_WINDOW_TITLE_SEQ = "2;{}" + BEL
alias SET_FOREGROUND_COLOR_SEQ = "10;{}" + BEL
alias SET_BACKGROUND_COLOR_SEQ = "11;{}" + BEL
alias SET_CURSOR_COLOR_SEQ = "12;{}" + BEL
alias SHOW_CURSOR_SEQ = "?25h"
alias HIDE_CURSOR_SEQ = "?25l"


fn reset_terminal():
    """Reset the terminal to its default style, removing any active styles."""
    print(CSI + RESET + "m", end="")


fn set_foreground_color(color: AnyColor) raises:
    """Sets the default foreground color.

    Args:
        color: The color to set.
    """
    var c: String = ""
    if color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(False)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(False)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(False)

    print(OSC + SET_FOREGROUND_COLOR_SEQ.format(c), end="")


fn set_background_color(color: AnyColor) raises:
    """Sets the default background color.

    Args:
        color: The color to set.
    """
    var c: String = ""
    if color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(True)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(True)

    print(OSC + SET_BACKGROUND_COLOR_SEQ.format(c), end="")


fn set_cursor_color(color: AnyColor) raises:
    """Sets the cursor color.

    Args:
        color: The color to set.
    """
    var c: String = ""
    if color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(True)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(True)

    print(OSC + SET_CURSOR_COLOR_SEQ.format(c), end="")


fn restore_screen():
    """Restores a previously saved screen state."""
    print(CSI + RESTORE_SCREEN_SEQ, end="")


fn save_screen():
    """Saves the screen state."""
    print(CSI + SAVE_SCREEN_SEQ, end="")


fn alt_screen():
    """Switches to the alternate screen buffer. The former view can be restored with ExitAltScreen()."""
    print(CSI + ALT_SCREEN_SEQ, end="")


fn exit_alt_screen():
    """Exits the alternate screen buffer and returns to the former terminal view."""
    print(CSI + EXIT_ALT_SCREEN_SEQ, end="")


fn clear_screen() raises:
    """Clears the visible portion of the terminal."""
    print(CSI + ERASE_DISPLAY_SEQ.format(2), end="")
    move_cursor(1, 1)


fn move_cursor(row: UInt16, column: Int) raises:
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    print(CSI + CURSOR_POSITION_SEQ.format(row, column), end="")


fn hide_cursor():
    """TODO: Show and Hide cursor don't seem to work ATM. HideCursor hides the cursor."""
    print(CSI + HIDE_CURSOR_SEQ, end="")


fn show_cursor():
    """Shows the cursor."""
    print(CSI + SHOW_CURSOR_SEQ, end="")


fn save_cursor_position():
    """Saves the cursor position."""
    print(CSI + SAVE_CURSOR_POSITION_SEQ, end="")


fn restore_cursor_position():
    """Restores a saved cursor position."""
    print(CSI + RESTORE_CURSOR_POSITION_SEQ, end="")


fn cursor_up(n: Int) raises:
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    print(CSI + CURSOR_UP_SEQ.format(n), end="")


fn cursor_down(n: Int) raises:
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    print(CSI + CURSOR_DOWN_SEQ.format(n), end="")


fn cursor_forward(n: Int) raises:
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move forward.
    """
    print(CSI + CURSOR_FORWARD_SEQ.format(n), end="")


fn cursor_back(n: Int) raises:
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    print(CSI + CURSOR_BACK_SEQ.format(n), end="")


fn cursor_next_line(n: Int) raises:
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    print(CSI + CURSOR_NEXT_LINE_SEQ.format(n), end="")


fn cursor_prev_line(n: Int) raises:
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    print(CSI + CURSOR_PREVIOUS_LINE_SEQ.format(n), end="")


fn clear_line():
    """Clears the current line."""
    print(CSI + ERASE_ENTIRE_LINE_SEQ, end="")


fn clear_line_left():
    """Clears the line to the left of the cursor."""
    print(CSI + ERASE_LINE_LEFT_SEQ, end="")


fn clear_line_right():
    """Clears the line to the right of the cursor."""
    print(CSI + ERASE_LINE_RIGHT_SEQ, end="")


fn clear_lines(n: Int) raises:
    """Clears a given number of lines.

    Args:
        n: The number of lines to CLEAR.
    """
    var clear_line = CSI + ERASE_LINE_SEQ.format(2)
    var cursor_up = CSI + CURSOR_UP_SEQ.format(1)
    var movement = (cursor_up + clear_line) * n
    print(clear_line + movement, end="")


fn change_scrolling_region(top: UInt16, bottom: UInt16) raises:
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.
    """
    print(CSI + CHANGE_SCROLLING_REGION_SEQ.format(top, bottom), end="")


fn insert_lines(n: Int) raises:
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.
    """
    print(CSI + INSERT_LINE_SEQ.format(n), end="")


fn delete_lines(n: Int) raises:
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.
    """
    print(CSI + DELETE_LINE_SEQ.format(n), end="")


fn enable_mouse_press():
    """Enables X10 mouse mode. Button press events are sent only."""
    print(CSI + ENABLE_MOUSE_PRESS_SEQ, end="")


fn disable_mouse_press():
    """Disables X10 mouse mode."""
    print(CSI + DISABLE_MOUSE_PRESS_SEQ, end="")


fn enable_mouse():
    """Enables Mouse Tracking mode."""
    print(CSI + ENABLE_MOUSE_SEQ, end="")


fn disable_mouse():
    """Disables Mouse Tracking mode."""
    print(CSI + DISABLE_MOUSE_SEQ, end="")


fn enable_mouse_hilite():
    """Enables Hilite Mouse Tracking mode."""
    print(CSI + ENABLE_MOUSE_HILITE_SEQ, end="")


fn disable_mouse_hilite():
    """Disables Hilite Mouse Tracking mode."""
    print(CSI + DISABLE_MOUSE_HILITE_SEQ, end="")


fn enable_mouse_cell_motion():
    """Enables Cell Motion Mouse Tracking mode."""
    print(CSI + ENABLE_MOUSE_CELL_MOTION_SEQ, end="")


fn disable_mouse_cell_motion():
    """Disables Cell Motion Mouse Tracking mode."""
    print(CSI + DISABLE_MOUSE_CELL_MOTION_SEQ, end="")


fn enable_mouse_all_motion():
    """Enables All Motion Mouse mode."""
    print(CSI + ENABLE_MOUSE_ALL_MOTION_SEQ, end="")


fn disable_mouse_all_motion():
    """Disables All Motion Mouse mode."""
    print(CSI + DISABLE_MOUSE_ALL_MOTION_SEQ, end="")


fn enable_mouse_extended_mode():
    """Enables Extended Mouse mode (SGR). This should be
    enabled in conjunction with EnableMouseCellMotion, and EnableMouseAllMotion."""
    print(CSI + ENABLE_MOUSE_EXTENDED_MODE_SEQ, end="")


fn disable_mouse_extended_mode():
    """Disables Extended Mouse mode (SGR)."""
    print(CSI + DISABLE_MOUSE_EXTENDED_MODE_SEQ, end="")


fn enable_mouse_pixels_mode():
    """Enables Pixel Motion Mouse mode (SGR-Pixels). This
    should be enabled in conjunction with EnableMouseCellMotion, and
    EnableMouseAllMotion."""
    print(CSI + ENABLE_MOUSE_PIXELS_MODE_SEQ, end="")


fn disable_mouse_pixels_mode():
    """Disables Pixel Motion Mouse mode (SGR-Pixels)."""
    print(CSI + DISABLE_MOUSE_PIXELS_MODE_SEQ, end="")


fn set_window_title(title: String):
    """Sets the terminal window title.

    Args:
        title: The title to set.
    """
    print(OSC + SET_WINDOW_TITLE_SEQ, title, end="")


fn enable_bracketed_paste():
    """Enables bracketed paste."""
    print(CSI + ENABLE_BRACKETED_PASTE_SEQ, end="")


fn disable_bracketed_paste():
    """Disables bracketed paste."""
    print(CSI + DISABLE_BRACKETED_PASTE_SEQ, end="")
