from .style import BEL, CSI, SGR, OSC
from .color import AnyColor, NoColor, ANSIColor, ANSI256Color, RGBColor

# Sequence definitions.
## Cursor positioning.
alias ERASE_DISPLAY = CSI + "2J"
"""Clears the visible portion of the terminal `CSI + J + 2 = \\x1b[2J`."""
alias SAVE_CURSOR_POSITION = CSI + "s"
"""Saves the cursor position `CSI + s = \\x1b[s`."""
alias RESTORE_CURSOR_POSITION = CSI + "u"
"""Restores the cursor position `CSI + u = \\x1b[u`."""

## Explicit values for EraseLineSeq.
alias CLEAR_LINE_RIGHT = CSI + "0K"
"""Clears the line to the right of the cursor `CSI + 0 + K = \\x1b[0K`."""
alias CLEAR_LINE_LEFT = CSI + "1K"
"""Clears the line to the left of the cursor `CSI + 1 + K = \\x1b[1K`."""
alias CLEAR_LINE = CSI + "2K"
"""Clears the entire line `CSI + 2 + K = \\x1b[2K`."""

## Mouse
alias ENABLE_MOUSE_PRESS = CSI + "?9h"
"""Enable press only (X10) `CSI + ?9 + h = \\x1b[?9h`."""
alias DISABLE_MOUSE_PRESS = CSI + "?9l"
"""Disable press only (X10) `CSI + ?9 + l = \\x1b[?9l`."""
alias ENABLE_MOUSE = CSI + "?1000h"
"""Enable press, release, wheel `CSI + ?1000 + h = \\x1b[?1000h`."""
alias DISABLE_MOUSE = CSI + "?1000l"
"""Disable press, release, wheel `CSI + ?1000 + l = \\x1b[?1000l`."""
alias ENABLE_MOUSE_HILITE = CSI + "?1001h"
"""Enable highlight `CSI + ?1001 + h = \\x1b[?1001h`."""
alias DISABLE_MOUSE_HILITE = CSI + "?1001l"
"""Disable highlight `CSI + ?1001 + l = \\x1b[?1001l`."""
alias ENABLE_MOUSE_ALL_MOTION = CSI + "?1003h"
"""Enable press, release, move on pressed, wheel `CSI + ?1003 + h = \\x1b[?1003h`."""
alias DISABLE_MOUSE_ALL_MOTION = CSI + "?1003l"
"""Disable press, release, move on pressed, wheel `CSI + ?1003 + l = \\x1b[?1003l`."""
alias ENABLE_MOUSE_CELL_MOTION = CSI + "?1002h"
"""Enable press, release, move on pressed, wheel `CSI + ?1002 + h = \\x1b[?1002h`."""
alias DISABLE_MOUSE_CELL_MOTION = CSI + "?1002l"
"""Enable press, release, move on pressed, wheel `CSI + ?1002 + l = \\x1b[?1002l`."""
alias ENABLE_MOUSE_EXTENDED_MODE = CSI + "?1006h"
"""Enable press, release, move, wheel, extended coordinates `CSI + ?1006 + h = \\x1b[?1006h`."""
alias DISABLE_MOUSE_EXTENDED_MODE = CSI + "?1006l"
"""Disable press, release, move, wheel, extended coordinates `CSI + ?1006 + l = \\x1b[?1006l`."""
alias ENABLE_MOUSE_PIXELS_MODE = CSI + "?1016h"
"""Enable press, release, move, wheel, extended pixel coordinates `CSI + ?1016 + h = \\x1b[?1016h`."""
alias DISABLE_MOUSE_PIXELS_MODE = CSI + "?1016l"
"""Disable press, release, move, wheel, extended pixel coordinates `CSI + ?1016 + l = \\x1b[?1016l`."""

## Screen
alias RESTORE_SCREEN = CSI + "?47l"
"""Restores the screen state `CSI + ?47 + l = \\x1b[?47l`."""
alias SAVE_SCREEN = CSI + "?47h"
"""Saves the screen state `CSI + ?47 + h = \\x1b[?47h`."""
alias ALT_SCREEN = CSI + "?1049h"
"""Switches to the alternate screen buffer `CSI + ?1049 + h = \\x1b[?1049h`."""
alias EXIT_ALT_SCREEN = CSI + "?1049l"
"""Exits the alternate screen buffer `CSI + ?1049 + l = \\x1b[?1049l`."""

## Bracketed paste.
## https://en.wikipedia.org/wiki/Bracketed-paste
alias ENABLE_BRACKETED_PASTE = CSI + "?2004h"
"""Enable bracketed paste `CSI + ?2004 + h = \\x1b[?2004h`."""
alias DISABLE_BRACKETED_PASTE = CSI + "?2004l"
"""Disable bracketed paste `CSI + ?2004 + l = \\x1b[?2004l`."""
alias START_BRACKETED_PASTE_SEQ = "200~"
alias END_BRACKETED_PASTE_SEQ = "201~"

## Session
alias HIDE_CURSOR = CSI + "?25l"
"""Hide the cursor `CSI + ?25 + l = \\x1b[?25l`."""
alias SHOW_CURSOR = CSI + "?25h"
"""Show the cursor `CSI + ?25 + h = \\x1b[?25h`."""


alias RESET_TERMINAL = CSI + SGR.RESET + "m"


fn reset_terminal():
    """Reset the terminal to its default style, removing any active styles."""
    print(RESET_TERMINAL, end="")


fn set_foreground_color(color: AnyColor) raises:
    """Sets the default foreground color.

    Args:
        color: The color to set.
    """
    print(String(OSC, "10;", color.sequence[False](), BEL), end="")


fn set_background_color(color: AnyColor):
    """Sets the default background color.

    Args:
        color: The color to set.
    """
    print(String(OSC, "11;", color.sequence[True](), BEL), end="")


fn set_cursor_color(color: AnyColor):
    """Sets the cursor color.

    Args:
        color: The color to set.
    """
    print(String(OSC, "12;", color.sequence[True](), BEL), end="")


fn restore_screen():
    """Restores a previously saved screen state."""
    print(RESTORE_SCREEN, end="")


fn save_screen():
    """Saves the screen state."""
    print(SAVE_SCREEN, end="")


fn alt_screen():
    """Switches to the alternate screen buffer. The former view can be restored with ExitAltScreen()."""
    print(ALT_SCREEN, end="")


fn exit_alt_screen():
    """Exits the alternate screen buffer and returns to the former terminal view."""
    print(EXIT_ALT_SCREEN, end="")


fn _move_cursor(row: UInt16, column: Int) -> String:
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    return String(CSI, row, ";", column, "H")


fn move_cursor(row: UInt16, column: Int):
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    print(_move_cursor(row, column), end="")


fn clear_screen():
    """Clears the visible portion of the terminal."""
    print(ERASE_DISPLAY, end="")
    move_cursor(1, 1)


fn hide_cursor():
    """TODO: Show and Hide cursor don't seem to work ATM. HideCursor hides the cursor."""
    print(HIDE_CURSOR, end="")


fn show_cursor():
    """Shows the cursor."""
    print(SHOW_CURSOR, end="")


fn save_cursor_position():
    """Saves the cursor position."""
    print(SAVE_CURSOR_POSITION, end="")


fn restore_cursor_position():
    """Restores a saved cursor position."""
    print(RESTORE_CURSOR_POSITION, end="")


fn _cursor_up(n: Int) -> String:
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    return String(CSI, n, "A")


fn cursor_up(n: Int):
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    print(_cursor_up(n), end="")


fn _cursor_down(n: Int) -> String:
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    return String(CSI, n, "B")


fn cursor_down(n: Int):
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    print(_cursor_down(n), end="")


fn _cursor_forward(n: Int) -> String:
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move forward.
    """
    return String(CSI, n, "C")


fn cursor_forward(n: Int):
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move forward.
    """
    print(_cursor_forward(n), end="")


fn _cursor_back(n: Int) -> String:
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    return String(CSI, n, "D")


fn cursor_back(n: Int):
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    print(_cursor_back(n), end="")


fn _cursor_next_line(n: Int) -> String:
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    return String(CSI, n, "E")


fn cursor_next_line(n: Int):
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    print(_cursor_next_line(n), end="")


fn _cursor_prev_line(n: Int) -> String:
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    return String(CSI, n, "F")


fn cursor_prev_line(n: Int):
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    print(_cursor_prev_line(n), end="")


fn clear_line():
    """Clears the current line."""
    print(CLEAR_LINE, end="")


fn clear_line_left():
    """Clears the line to the left of the cursor."""
    print(CLEAR_LINE_LEFT, end="")


fn clear_line_right():
    """Clears the line to the right of the cursor."""
    print(CLEAR_LINE_RIGHT, end="")


fn clear_lines(n: Int):
    """Clears a given number of lines.

    Args:
        n: The number of lines to CLEAR.
    """
    var movement = (_cursor_up(1) + CLEAR_LINE) * n
    print(CLEAR_LINE + movement, end="")


fn _change_scrolling_region(top: UInt16, bottom: UInt16) -> String:
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.
    """
    return String(CSI, top, ";", bottom, "r")


fn change_scrolling_region(top: UInt16, bottom: UInt16):
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.
    """
    print(_change_scrolling_region(top, bottom), end="")


fn _insert_lines(n: Int) -> String:
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.
    """
    return String(CSI, n, "L")


fn insert_lines(n: Int):
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.
    """
    print(_insert_lines(n), end="")


fn _delete_lines(n: Int) -> String:
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.
    """
    return String(CSI, n, "M")


fn delete_lines(n: Int):
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.
    """
    print(_delete_lines(n), end="")


fn enable_mouse_press():
    """Enables X10 mouse mode. Button press events are sent only."""
    print(ENABLE_MOUSE_PRESS, end="")


fn disable_mouse_press():
    """Disables X10 mouse mode."""
    print(DISABLE_MOUSE_PRESS, end="")


fn enable_mouse():
    """Enables Mouse Tracking mode."""
    print(ENABLE_MOUSE, end="")


fn disable_mouse():
    """Disables Mouse Tracking mode."""
    print(DISABLE_MOUSE, end="")


fn enable_mouse_hilite():
    """Enables Hilite Mouse Tracking mode."""
    print(ENABLE_MOUSE_HILITE, end="")


fn disable_mouse_hilite():
    """Disables Hilite Mouse Tracking mode."""
    print(DISABLE_MOUSE_HILITE, end="")


fn enable_mouse_cell_motion():
    """Enables Cell Motion Mouse Tracking mode."""
    print(ENABLE_MOUSE_CELL_MOTION, end="")


fn disable_mouse_cell_motion():
    """Disables Cell Motion Mouse Tracking mode."""
    print(DISABLE_MOUSE_CELL_MOTION, end="")


fn enable_mouse_all_motion():
    """Enables All Motion Mouse mode."""
    print(ENABLE_MOUSE_ALL_MOTION, end="")


fn disable_mouse_all_motion():
    """Disables All Motion Mouse mode."""
    print(DISABLE_MOUSE_ALL_MOTION, end="")


fn enable_mouse_extended_mode():
    """Enables Extended Mouse mode (SGR). This should be
    enabled in conjunction with EnableMouseCellMotion, and EnableMouseAllMotion."""
    print(ENABLE_MOUSE_EXTENDED_MODE, end="")


fn disable_mouse_extended_mode():
    """Disables Extended Mouse mode (SGR)."""
    print(DISABLE_MOUSE_EXTENDED_MODE, end="")


fn enable_mouse_pixels_mode():
    """Enables Pixel Motion Mouse mode (SGR-Pixels). This
    should be enabled in conjunction with EnableMouseCellMotion, and
    EnableMouseAllMotion."""
    print(ENABLE_MOUSE_PIXELS_MODE, end="")


fn disable_mouse_pixels_mode():
    """Disables Pixel Motion Mouse mode (SGR-Pixels)."""
    print(DISABLE_MOUSE_PIXELS_MODE, end="")


fn set_window_title(title: String):
    """Sets the terminal window title.

    Args:
        title: The title to set.
    """
    print(String(OSC, "2;", title, BEL), end="")


fn enable_bracketed_paste():
    """Enables bracketed paste."""
    print(ENABLE_BRACKETED_PASTE, end="")


fn disable_bracketed_paste():
    """Disables bracketed paste."""
    print(DISABLE_BRACKETED_PASTE, end="")
