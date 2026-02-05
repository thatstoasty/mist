from mist.style.color import AnyColor
from mist.terminal.sgr import BEL, CSI, OSC


comptime ENABLE_ALTERNATE_SCREEN = CSI + "?1049h"
"""Switches to the alternate screen buffer `CSI + ?1049 + h = \\x1b[?1049h`."""
comptime EXIT_ALTERNATE_SCREEN = CSI + "?1049l"
"""Exits the alternate screen buffer `CSI + ?1049 + l = \\x1b[?1049l`."""


fn enable_alternate_screen() -> None:
    """Switches to the alternate screen buffer. The former view can be restored with `disable_alternate_screen`."""
    print(ENABLE_ALTERNATE_SCREEN, sep="", end="")


fn disable_alternate_screen() -> None:
    """Exits the alternate screen buffer and returns to the former terminal view."""
    print(EXIT_ALTERNATE_SCREEN, sep="", end="")


@fieldwise_init
@explicit_destroy("Calling `disable()` is required to exit the alternate screen and restore normal terminal behavior.")
struct AlternateScreen(Movable):
    """Linear struct to enable the alternate screen on creation and guarantee exit on destruction."""

    @staticmethod
    fn enable() -> Self:
        """Enables the alternate screen and returns an `AlternateScreen` instance, which will disable the alternate screen on destruction.
        """
        enable_alternate_screen()
        return Self()

    fn disable(deinit self) -> None:
        """Disables the alternate screen and returns to the former terminal view."""
        disable_alternate_screen()


comptime RESTORE_SCREEN = CSI + "?47l"
"""Restores the screen state `CSI + ?47 + l = \\x1b[?47l`."""
comptime SAVE_SCREEN = CSI + "?47h"
"""Saves the screen state `CSI + ?47 + h = \\x1b[?47h`."""


fn restore_screen() -> None:
    """Restores a previously saved screen state."""
    print(RESTORE_SCREEN, sep="", end="")


fn save_screen() -> None:
    """Saves the screen state."""
    print(SAVE_SCREEN, sep="", end="")


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
    print(CSI, top, ";", bottom, "r", sep="", end="")


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
    print(CSI, n, "L", sep="", end="")


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
    print(CSI, n, "M", sep="", end="")


fn set_window_title(title: StringSlice) -> None:
    """Sets the terminal window title.

    Args:
        title: The title to set.
    """
    print(OSC, "2;", title, BEL, sep="", end="")


fn resize_terminal(width: UInt, height: UInt) -> None:
    """Resize the terminal to the specified width and height.

    Args:
        width: The new width of the terminal in columns.
        height: The new height of the terminal in rows.
    """
    print(CSI, 8, height, ";", width, "t", sep="", end="")


comptime RESET_STYLE = CSI + "0m"
"""Resets the terminal style `CSI + 0 + m = \\x1b[0m`."""


fn reset_terminal() -> None:
    """Reset the terminal to its default style, removing any active style."""
    print(RESET_STYLE, sep="", end="")


fn set_foreground_color(color: AnyColor) -> None:
    """Sets the default foreground color.

    Args:
        color: The color to set.
    """
    print(OSC, "10;", color.sequence[False](), BEL, sep="", end="")


fn set_background_color(color: AnyColor) -> None:
    """Sets the default background color.

    Args:
        color: The color to set.
    """
    print(OSC, "11;", color.sequence[True](), BEL, sep="", end="")
