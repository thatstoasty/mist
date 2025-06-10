from mist.color import AnyColor
from mist.terminal.sgr import CSI, BEL, OSC, _write_sequence_to_stdout

alias RESTORE_SCREEN = CSI + "?47l"
"""Restores the screen state `CSI + ?47 + l = \\x1b[?47l`."""
alias SAVE_SCREEN = CSI + "?47h"
"""Saves the screen state `CSI + ?47 + h = \\x1b[?47h`."""
alias ALT_SCREEN = CSI + "?1049h"
"""Switches to the alternate screen buffer `CSI + ?1049 + h = \\x1b[?1049h`."""
alias EXIT_ALT_SCREEN = CSI + "?1049l"
"""Exits the alternate screen buffer `CSI + ?1049 + l = \\x1b[?1049l`."""

alias RESET_STYLE = CSI + "0m"
"""Resets the terminal style `CSI + 0 + m = \\x1b[0m`."""


fn reset_terminal() -> None:
    """Reset the terminal to its default style, removing any active styles."""
    _write_sequence_to_stdout(RESET_STYLE)


fn set_foreground_color(color: AnyColor) -> None:
    """Sets the default foreground color.

    Args:
        color: The color to set.
    """
    _write_sequence_to_stdout(OSC, "10;", color.sequence[False](), BEL)


fn set_background_color(color: AnyColor) -> None:
    """Sets the default background color.

    Args:
        color: The color to set.
    """
    _write_sequence_to_stdout(OSC, "11;", color.sequence[True](), BEL)


fn restore_screen() -> None:
    """Restores a previously saved screen state."""
    _write_sequence_to_stdout(RESTORE_SCREEN)


fn save_screen() -> None:
    """Saves the screen state."""
    _write_sequence_to_stdout(SAVE_SCREEN)


fn alt_screen() -> None:
    """Switches to the alternate screen buffer. The former view can be restored with `exit_alt_screen`."""
    _write_sequence_to_stdout(ALT_SCREEN)


fn exit_alt_screen() -> None:
    """Exits the alternate screen buffer and returns to the former terminal view."""
    _write_sequence_to_stdout(EXIT_ALT_SCREEN)


fn change_scrolling_region_sequence(top: UInt16, bottom: UInt16) -> String:
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.

    Returns:
        A string representing the ANSI sequence to change the scrolling region.
    """
    return String(CSI, top, ";", bottom, "r")


fn change_scrolling_region(top: UInt16, bottom: UInt16) -> None:
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.
    """
    _write_sequence_to_stdout(CSI, top, ";", bottom, "r")


fn insert_lines_sequence(n: UInt16) -> String:
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.

    Returns:
        A string representing the ANSI sequence to insert lines.
    """
    return String(CSI, n, "L")


fn insert_lines(n: UInt16) -> None:
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.
    """
    _write_sequence_to_stdout(CSI, n, "L")


fn delete_lines_sequence(n: UInt16) -> String:
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.

    Returns:
        A string representing the ANSI sequence to delete lines.
    """
    return String(CSI, n, "M")


fn delete_lines(n: UInt16) -> None:
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.
    """
    _write_sequence_to_stdout(CSI, n, "M")


fn set_window_title(title: StringSlice) -> None:
    """Sets the terminal window title.

    Args:
        title: The title to set.
    """
    _write_sequence_to_stdout(OSC, "2;", title, BEL)
