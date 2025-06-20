import sys
from mist.color import AnyColor
from mist.termios import Termios, tcgetattr, tcsetattr, set_raw, set_cbreak, WhenOption, is_a_tty
from mist.termios.c import LocalFlag
from mist.terminal.cursor import (
    move_cursor,
    clear_screen,
    hide_cursor,
    show_cursor,
    save_cursor_position,
    restore_cursor_position,
    cursor_up,
    cursor_down,
    cursor_forward,
    cursor_back,
    clear_lines,
    set_cursor_color,
)
from mist.terminal.screen import (
    reset_terminal,
    set_foreground_color,
    set_background_color,
    restore_screen,
    save_screen,
    alt_screen,
    exit_alt_screen,
    change_scrolling_region,
    set_window_title,
)


# TTY State modes
@fieldwise_init
struct Mode(Movable, Copyable, EqualityComparable, Stringable):
    """TTY state modes for terminal operations."""

    var value: String
    """TTY state mode for terminal operations."""
    alias RAW = Self("RAW")
    """Raw mode for terminal input."""
    alias CBREAK = Self("CBREAK")
    """Cbreak mode for terminal input."""

    fn __eq__(self, other: Self) -> Bool:
        """Check if two modes are equal.

        Args:
            other: The other mode to compare with.

        Returns:
            True if the modes are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Check if two modes are not equal.

        Args:
            other: The other mode to compare with.

        Returns:
            True if the modes are not equal, False otherwise.
        """
        return self.value != other.value

    fn __str__(self) -> String:
        """Return a string representation of the mode.

        Returns:
            The string representation of the mode.
        """
        return self.value


@value
@register_passable("trivial")
struct Direction:
    """Direction values for cursor movement."""

    var value: UInt8
    """The numeric value representing the direction."""
    alias UP = Self(0)
    alias DOWN = Self(1)
    alias LEFT = Self(2)
    alias RIGHT = Self(3)
    alias UP_LEFT = Self(4)
    alias UP_RIGHT = Self(5)
    alias DOWN_LEFT = Self(6)
    alias DOWN_RIGHT = Self(7)

    fn __eq__(self, other: Self) -> Bool:
        """Check if two directions are equal.

        Args:
            other: The other direction to compare with.

        Returns:
            True if the directions are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Check if two directions are not equal.

        Args:
            other: The other direction to compare with.

        Returns:
            Bool: True if the directions are not equal, False otherwise.
        """
        return self.value != other.value

    fn __str__(self) -> String:
        """Return a string representation of the direction.

        Returns:
            String: The string representation of the direction.
        """
        return String(self.value)


@value
@register_passable("trivial")
struct TTY[mode: Mode = Mode.RAW]():
    """A context manager for terminal state.

    Parameters:
        mode: The mode to set for the terminal, e.g., RAW or CBREAK.
    """

    var fd: FileDescriptor
    """File descriptor for the terminal."""
    var original_state: Termios
    """Original state of the terminal."""
    var state: Termios
    """Current state of the terminal."""

    var cursor_hidden: Bool
    """Flag indicating if the cursor is hidden."""

    fn __init__(out self) raises:
        """Initialize the TTY context manager.

        Raises:
            Error: If STDIN is not a terminal.
        """
        if not is_a_tty(sys.stdin):
            raise Error("STDIN is not a terminal.")
        self.fd = sys.stdin
        self.original_state = tcgetattr(self.fd)
        self.state = self.original_state
        self.cursor_hidden = False

        @parameter
        if mode == Mode.RAW:
            self.state = set_raw(self.fd)
        elif mode == Mode.CBREAK:
            self.state = set_cbreak(self.fd)

    fn restore_original_state(mut self, when: WhenOption = WhenOption.TCSADRAIN) raises:
        """Restore the original terminal state.

        Args:
            when: When to apply the changes, e.g., TCSADRAIN.
        """
        tcsetattr(self.fd, when, self.original_state)

    fn __enter__(self) -> Self:
        """Enter the context manager and set the terminal to the desired mode.

        Returns:
            Self: The TTY instance.
        """
        return self

    fn __exit__(mut self) raises:
        """Restore the original terminal state."""
        self.restore_original_state()

    fn set_attribute(mut self, optional_actions: WhenOption) raises -> None:
        """Set the terminal attributes.

        Args:
            optional_actions: When to apply the changes, e.g., TCSADRAIN.
        """
        tcsetattr(self.fd, optional_actions, self.state)

    fn disable_echo(mut self) raises -> None:
        """Disable echoing of characters in the terminal."""
        self.state.c_lflag &= ~LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_echo(mut self) raises -> None:
        """Enable echoing of characters in the terminal."""
        self.state.c_lflag |= LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_canonical_mode(mut self) raises -> None:
        """Enable canonical mode in the terminal."""
        self.state.c_lflag |= LocalFlag.ICANON.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn disable_canonical_mode(mut self) raises -> None:
        """Disable canonical mode in the terminal."""
        self.state.c_lflag &= ~LocalFlag.ICANON.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn move_cursor(self, x: UInt16, y: UInt16) -> None:
        """Move the cursor to the specified position.

        Args:
            x: The x-coordinate (column) to move the cursor to.
            y: The y-coordinate (row) to move the cursor to.
        """
        move_cursor(x, y)

    fn clear(self) -> None:
        """Clear the terminal."""
        clear_screen()

    fn hide_cursor(mut self) -> None:
        """Hide the cursor."""
        hide_cursor()
        self.cursor_hidden = True

    fn show_cursor(mut self) -> None:
        """Show the cursor."""
        show_cursor()
        self.cursor_hidden = False

    fn move_cursor[direction: Direction](self, n: UInt16) -> None:
        """Move the cursor in the specified direction.

        Parameters:
            direction: The direction to move the cursor in.

        Args:
            n: The number of lines/columns to move in that direction.
        """

        @parameter
        if direction == Direction.UP:
            cursor_up(n)
        elif direction == Direction.DOWN:
            cursor_down(n)
        elif direction == Direction.LEFT:
            cursor_forward(n)
        elif direction == Direction.RIGHT:
            cursor_back(n)
        elif direction == Direction.UP_LEFT:
            cursor_up(n)
            cursor_back(n)
        elif direction == Direction.UP_RIGHT:
            cursor_up(n)
            cursor_forward(n)
        elif direction == Direction.DOWN_LEFT:
            cursor_down(n)
            cursor_back(n)
        elif direction == Direction.DOWN_RIGHT:
            cursor_down(n)
            cursor_forward(n)

    fn set_cursor_color(self, color: AnyColor) -> None:
        """Set the cursor color.

        Args:
            color: The color to set for the cursor.
        """
        set_cursor_color(color)

    fn save_cursor_position(self) -> None:
        """Save the current cursor position."""
        save_cursor_position()

    fn restore_cursor_position(self) -> None:
        """Restore the saved cursor position."""
        restore_cursor_position()

    fn clear_lines(self, n: UInt16) -> None:
        """Clear the specified number of lines.

        Args:
            n: The number of lines to clear.
        """
        clear_lines(n)

    fn set_foreground_color(self, color: AnyColor) -> None:
        """Set the foreground color.

        Args:
            color: The color to set.
        """
        set_foreground_color(color)

    fn set_background_color(self, color: AnyColor) -> None:
        """Set the background color.

        Args:
            color: The color to set.
        """
        set_background_color(color)

    fn restore_screen(self) -> None:
        """Restore the screen to its previous state."""
        restore_screen()

    fn save_screen(self) -> None:
        """Save the current screen state."""
        save_screen()

    fn alt_screen(self) -> None:
        """Switch to the alternate screen buffer."""
        alt_screen()

    fn exit_alt_screen(self) -> None:
        """Exit the alternate screen buffer."""
        exit_alt_screen()

    fn change_scrolling_region(self, top: UInt16, bottom: UInt16) -> None:
        """Change the scrolling region of the terminal.

        Args:
            top: The top line of the scrolling region.
            bottom: The bottom line of the scrolling region.
        """
        change_scrolling_region(top, bottom)

    fn set_window_title(self, title: StringSlice) -> None:
        """Set the terminal window title.

        Args:
            title: The title to set for the terminal window.
        """
        set_window_title(title)
