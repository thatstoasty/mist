from mist.style.color import AnyColor
from mist.terminal.query import get_cursor_color
from mist.terminal.sgr import BEL, CSI, OSC


# Cursor positioning.
comptime ERASE_DISPLAY = CSI + "2J"
"""Clears the visible portion of the terminal `CSI + J + 2 = \\x1b[2J`."""
comptime SAVE_CURSOR_POSITION = CSI + "s"
"""Saves the cursor position `CSI + s = \\x1b[s`."""
comptime RESTORE_CURSOR_POSITION = CSI + "u"
"""Restores the cursor position `CSI + u = \\x1b[u`."""

# Session
comptime HIDE_CURSOR = CSI + "?25l"
"""Hide the cursor `CSI + ?25 + l = \\x1b[?25l`."""
comptime SHOW_CURSOR = CSI + "?25h"
"""Show the cursor `CSI + ?25 + h = \\x1b[?25h`."""

# NOTE: Why UInt16? It's a best guess at how many lines a terminal can feasibly have.
# Are you going to have 65535 lines or columns in your terminal? Probably not.
# But if it proves to be an issue in the future, I can change it.


fn move_cursor_sequence(row: UInt16, column: UInt16) -> String:
    """Returns ANSI sequence, which if written to stdout, will move the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.

    Returns:
        An ANSI sequence that moves the cursor to the specified position.
    """
    return String(CSI, row, ";", column, "H")


fn move_cursor(row: UInt16, column: UInt16) -> None:
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    print(CSI, row, ";", column, "H", sep="", end="")


fn clear_screen() -> None:
    """Clears the visible portion of the terminal."""
    print(ERASE_DISPLAY, sep="", end="")
    move_cursor(1, 1)


# TODO: Show and Hide cursor don't seem to work ATM.
fn hide_cursor() -> None:
    """Hides the cursor."""
    print(HIDE_CURSOR, sep="", end="")


fn show_cursor() -> None:
    """Shows the cursor."""
    print(SHOW_CURSOR, sep="", end="")


fn save_cursor_position() -> None:
    """Saves the cursor position."""
    print(SAVE_CURSOR_POSITION, sep="", end="")


fn restore_cursor_position() -> None:
    """Restores a saved cursor position."""
    print(RESTORE_CURSOR_POSITION, sep="", end="")


fn cursor_up_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor up `n` number of lines.

    Args:
        n: The number of lines to move up.

    Returns:
        An ANSI sequence that moves the cursor up the specified number of lines.
    """
    return String(CSI, n, "A")


fn cursor_up(n: UInt16) -> None:
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    print(CSI, n, "A", sep="", end="")


fn cursor_down_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor down `n` number of lines.

    Args:
        n: The number of lines to move down.

    Returns:
        An ANSI sequence that moves the cursor down the specified number of lines.
    """
    return String(CSI, n, "B")


fn cursor_down(n: UInt16) -> None:
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    print(CSI, n, "B", sep="", end="")


fn cursor_forward_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor forward `n` number of cells.

    Args:
        n: The number of cells to move forward.

    Returns:
        An ANSI sequence that moves the cursor forward the specified number of cells.
    """
    return String(CSI, n, "C")


fn cursor_forward(n: UInt16) -> None:
    """Moves the cursor forward a given number of cells.

    Args:
        n: The number of cells to move forward.
    """
    print(CSI, n, "C", sep="", end="")


fn cursor_back_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.

    Returns:
        An ANSI sequence that moves the cursor back the specified number of cells.
    """
    return String(CSI, n, "D")


fn cursor_back(n: UInt16) -> None:
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    print(CSI, n, "D", sep="", end="")


fn cursor_next_line_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor down a given number
    of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.

    Returns:
        An ANSI sequence that moves the cursor down the specified number of lines and places it at the beginning of the line.
    """
    return String(CSI, n, "E")


fn cursor_next_line(n: UInt16) -> None:
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    print(CSI, n, "E", sep="", end="")


fn cursor_prev_line_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor up a given number of lines
    and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.

    Returns:
        An ANSI sequence that moves the cursor up the specified number of lines and places it at the beginning of the line.
    """
    return String(CSI, n, "F")


fn cursor_prev_line(n: UInt16) -> None:
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    print(CSI, n, "F", sep="", end="")


struct Cursor:
    @staticmethod
    fn up(n: UInt16) -> None:
        """Moves the cursor up a given number of lines.

        Args:
            n: The number of lines to move up.
        """
        cursor_up(n)

    @staticmethod
    fn down(n: UInt16) -> None:
        """Moves the cursor down a given number of lines.

        Args:
            n: The number of lines to move down.
        """
        cursor_down(n)

    @staticmethod
    fn forward(n: UInt16) -> None:
        """Moves the cursor forward a given number of cells.

        Args:
            n: The number of cells to move forward.
        """
        cursor_forward(n)

    @staticmethod
    fn back(n: UInt16) -> None:
        """Moves the cursor backwards a given number of cells.

        Args:
            n: The number of cells to move back.
        """
        cursor_back(n)

    @staticmethod
    fn next_line(n: UInt16) -> None:
        """Moves the cursor down a given number of lines and places it at the beginning of the line.

        Args:
            n: The number of lines to move down.
        """
        cursor_next_line(n)

    @staticmethod
    fn previous_line(n: UInt16) -> None:
        """Moves the cursor up a given number of lines and places it at the beginning of the line.

        Args:
            n: The number of lines to move back.
        """
        cursor_prev_line(n)

    @staticmethod
    fn move_to(row: UInt16, column: UInt16) -> None:
        """Moves the cursor to a given position.

        Args:
            row: The row to move to.
            column: The column to move to.
        """
        move_cursor(row, column)

    @staticmethod
    fn set_color(color: AnyColor, *, initial_color: AnyColor = NoColor()) raises -> CursorColor:
        """Sets the cursor color and returns a `CursorColor` instance, which will reset the cursor color to its original value on destruction.

        Terminal must be in raw mode to query the initial color.

        Args:
            color: The color to set.
            initial_color: The initial color of the cursor. If not provided, it will be queried from the terminal. Providing this can be useful if you want to avoid the overhead of querying the terminal for the cursor color, which can be slow.
        """
        var original_color = get_cursor_color() if initial_color.isa[NoColor]() else initial_color.copy()
        set_cursor_color(color)
        return CursorColor(original_color^)


fn set_cursor_color(color: AnyColor) -> None:
    """Sets the cursor color.

    Args:
        color: The color to set.
    """
    print(OSC, "12;#", color.as_hex_string(), BEL, sep="", end="")


@fieldwise_init
@explicit_destroy("Calling `reset()` is required to reset the cursor color to its original value.")
struct CursorColor:
    var original_color: AnyColor
    """The original color of the cursor before it was changed."""

    fn reset(deinit self) -> None:
        """Resets the cursor color to its original value."""
        set_cursor_color(self.original_color)
