from mist.style.color import AnyColor
from mist.terminal.cursor import cursor_up_sequence
from mist.terminal.sgr import BEL, CSI, OSC

# Explicit values for EraseLineSeq.
comptime CLEAR_LINE_RIGHT = CSI + "0K"
"""Clears the line to the right of the cursor `CSI + 0 + K = \\x1b[0K`."""
comptime CLEAR_LINE_LEFT = CSI + "1K"
"""Clears the line to the left of the cursor `CSI + 1 + K = \\x1b[1K`."""
comptime CLEAR_LINE = CSI + "2K"
"""Clears the entire line `CSI + 2 + K = \\x1b[2K`."""


fn clear_line() -> None:
    """Clears the current line."""
    print(CLEAR_LINE, sep="", end="")


fn clear_line_left() -> None:
    """Clears the line to the left of the cursor."""
    print(CLEAR_LINE_LEFT, sep="", end="")


fn clear_line_right() -> None:
    """Clears the line to the right of the cursor."""
    print(CLEAR_LINE_RIGHT, sep="", end="")


fn clear_lines(n: UInt16) -> None:
    """Clears a given number of lines.

    Args:
        n: The number of lines to CLEAR.
    """
    var movement = (cursor_up_sequence(1) + CLEAR_LINE) * Int(n)
    print(CLEAR_LINE + movement, sep="", end="")



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
    """Sets the terminal foreground color.

    Args:
        color: The color to set.
    """
    print(OSC, "10;", color.sequence[False](), BEL, sep="", end="")


fn set_background_color(color: AnyColor) -> None:
    """Sets the terminal background color.

    Args:
        color: The color to set.
    """
    print(OSC, "11;", color.sequence[True](), BEL, sep="", end="")


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

    fn disable(deinit self) -> None:
        """Disables the alternate screen and returns to the former terminal view."""
        disable_alternate_screen()


struct Screen(ImplicitlyCopyable):
    """A namespace for screen-related functions."""

    @staticmethod
    fn enable_alternate_screen() -> AlternateScreen:
        """Enables the alternate screen and returns an `AlternateScreen` instance, which will disable the alternate screen on destruction.
        """
        enable_alternate_screen()
        return AlternateScreen()

    @staticmethod
    fn save() -> None:
        """Saves the screen state."""
        save_screen()

    @staticmethod
    fn restore() -> None:
        """Restores the screen state."""
        restore_screen()

    @staticmethod
    fn change_scrolling_region(top: UInt16, bottom: UInt16) -> None:
        """Sets the scrolling region of the terminal.

        Args:
            top: The top of the scrolling region.
            bottom: The bottom of the scrolling region.
        """
        change_scrolling_region(top, bottom)

    @staticmethod
    fn insert_lines(n: UInt16) -> None:
        """Inserts the given number of lines at the top of the scrollable
        region, pushing lines below down.

        Args:
            n: The number of lines to insert.
        """
        insert_lines(n)

    @staticmethod
    fn delete_lines(n: UInt16) -> None:
        """Deletes the given number of lines, pulling any lines in
        the scrollable region below up.

        Args:
            n: The number of lines to delete.
        """
        delete_lines(n)

    @staticmethod
    fn set_foreground_color(color: AnyColor) -> None:
        """Sets the terminal foreground color.

        Args:
            color: The color to set.
        """
        set_foreground_color(color)

    @staticmethod
    fn set_background_color(color: AnyColor) -> None:
        """Sets the terminal background color.

        Args:
            color: The color to set.
        """
        set_background_color(color)

    @staticmethod
    fn reset() -> None:
        """Resets the terminal style to default, removing any active style."""
        reset_terminal()

    @staticmethod
    fn clear_line() -> None:
        """Clears the current line."""
        clear_line()

    @staticmethod
    fn clear_lines(n: UInt16) -> None:
        """Clears a given number of lines.

        Args:
            n: The number of lines to CLEAR.
        """
        clear_lines(n)
