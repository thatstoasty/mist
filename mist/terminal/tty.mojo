import sys

from mist.color import AnyColor
from mist.terminal.bracketed_paste import disable_bracketed_paste, enable_bracketed_paste
from mist.terminal.cursor import (
    clear_lines,
    clear_screen,
    cursor_back,
    cursor_down,
    cursor_forward,
    cursor_up,
    hide_cursor,
    move_cursor,
    restore_cursor_position,
    save_cursor_position,
    set_cursor_color,
    show_cursor,
)
from mist.terminal.mouse import (
    disable_mouse,
    disable_mouse_hilite,
    disable_mouse_press,
    enable_mouse,
    enable_mouse_hilite,
    enable_mouse_press,
)
from mist.terminal.query import get_background_color, get_terminal_size
from mist.terminal.screen import (
    alt_screen,
    change_scrolling_region,
    exit_alt_screen,
    reset_terminal,
    restore_screen,
    save_screen,
    set_background_color,
    set_foreground_color,
    set_window_title,
)
from mist.termios.c import LocalFlag

from mist.termios import Termios, WhenOption, is_a_tty, set_cbreak, set_raw, tcgetattr, tcsetattr


# TTY State modes
@fieldwise_init
struct Mode(Copyable, EqualityComparable, Movable, Stringable):
    """TTY state modes for terminal operations."""

    var value: String
    """TTY state mode for terminal operations."""
    alias RAW = Self("RAW")
    """Raw mode for terminal input."""
    alias CBREAK = Self("CBREAK")
    """Cbreak mode for terminal input."""
    alias NONE = Self("NONE")
    """No special mode for terminal input. Does not change the terminal state."""

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


@fieldwise_init
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


@fieldwise_init
@register_passable("trivial")
struct Area(Copyable, Movable, Writable):
    """An area in the terminal defined by its row and column length."""

    var rows: UInt16
    """Number of rows."""
    var columns: UInt16
    """Number of columns."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Write the area to a writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write to.
        """
        writer.write("Area(", self.rows, ", ", self.columns, ")")


@fieldwise_init
@register_passable("trivial")
struct TTY[mode: Mode = Mode.NONE]():
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
    var bracketed_paste: Bool
    """Flag indicating if bracketed paste mode is enabled."""
    var tracking_mouse_press: Bool
    """Flag indicating if mouse press tracking is enabled."""
    var tracking_mouse: Bool
    """Flag indicating if mouse tracking is enabled."""
    var tracking_mouse_hilite: Bool
    """Flag indicating if mouse hilite tracking is enabled."""
    var alternate_screen: Bool
    """Flag indicating if the alternate screen buffer is enabled."""
    var scrolling_region: Area
    """The current scrolling region of the terminal."""

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
        self.bracketed_paste = False
        self.tracking_mouse_press = False
        self.tracking_mouse = False
        self.tracking_mouse_hilite = False
        self.alternate_screen = False
        self.scrolling_region = Area(0, 0)

        @parameter
        if mode == Mode.RAW:
            self.state = set_raw(self.fd)
        elif mode == Mode.CBREAK:
            self.state = set_cbreak(self.fd)

    fn restore_original_state(mut self, when: WhenOption = WhenOption.TCSADRAIN) raises:
        """Restore the original terminal state.

        Args:
            when: When to apply the changes, e.g., TCSADRAIN.

        Raises:
            Error: If setting the terminal attributes fails.
        """
        tcsetattr(self.fd, when, self.original_state)

    fn __enter__(self) -> Self:
        """Enter the context manager and set the terminal to the desired mode.

        Returns:
            Self: The TTY instance.
        """
        return self

    fn __exit__(mut self) raises:
        """Restore the original terminal state.

        Raises:
            Error: If setting the terminal attributes fails.
        """
        self.restore_original_state()

    fn set_attribute(mut self, optional_actions: WhenOption) raises -> None:
        """Set the terminal attributes.

        Args:
            optional_actions: When to apply the changes, e.g., TCSADRAIN.

        Raises:
            Error: If setting the terminal attribute fails.
        """
        tcsetattr(self.fd, optional_actions, self.state)

    fn disable_echo(mut self) raises -> None:
        """Disable echoing of characters in the terminal.

        Raises:
            Error: If setting the terminal attribute fails.
        """
        self.state.c_lflag &= ~LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_echo(mut self) raises -> None:
        """Enable echoing of characters in the terminal.

        Raises:
            Error: If setting the terminal attribute fails.
        """
        self.state.c_lflag |= LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_canonical_mode(mut self) raises -> None:
        """Enable canonical mode in the terminal.

        Raises:
            Error: If setting the terminal attribute fails.
        """
        self.state.c_lflag |= LocalFlag.ICANON.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn disable_canonical_mode(mut self) raises -> None:
        """Disable canonical mode in the terminal.

        Raises:
            Error: If setting the terminal attribute fails.
        """
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
        if not self.cursor_hidden:
            hide_cursor()
            self.cursor_hidden = True

    fn show_cursor(mut self) -> None:
        """Show the cursor."""
        if self.cursor_hidden:
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

    fn background_color(self) raises -> RGBColor:
        """Query the terminal for the current background color of the terminal.

        Raises:
            Error: If querying the terminal for the background color fails.

        Returns:
            The RGBColor representing the current background color.
        """
        return get_background_color()

    fn restore_screen(self) -> None:
        """Restore the screen to its previous state."""
        restore_screen()

    fn save_screen(self) -> None:
        """Save the current screen state."""
        save_screen()

    fn alt_screen(mut self) -> None:
        """Switch to the alternate screen buffer."""
        if not self.alternate_screen:
            alt_screen()
            self.alternate_screen = True

    fn exit_alt_screen(mut self) -> None:
        """Exit the alternate screen buffer."""
        if self.alternate_screen:
            exit_alt_screen()
            self.alternate_screen = False

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

    fn enable_bracketed_paste(mut self) -> None:
        """Enable bracketed paste mode."""
        if not self.bracketed_paste:
            enable_bracketed_paste()
            self.bracketed_paste = True

    fn disable_bracketed_paste(mut self) -> None:
        """Disable bracketed paste mode."""
        if self.bracketed_paste:
            disable_bracketed_paste()
            self.bracketed_paste = False

    fn enable_mouse_press(mut self) -> None:
        """Enable mouse press tracking."""
        if not self.tracking_mouse_press:
            enable_mouse_press()
            self.tracking_mouse_press = True

    fn disable_mouse_press(mut self) -> None:
        """Disable mouse press tracking."""
        if self.tracking_mouse_press:
            disable_mouse_press()
            self.tracking_mouse_press = False

    fn enable_mouse(mut self) -> None:
        """Enable mouse tracking."""
        if not self.tracking_mouse:
            enable_mouse()
            self.tracking_mouse = True

    fn disable_mouse(mut self) -> None:
        """Disable mouse tracking."""
        if self.tracking_mouse:
            disable_mouse()
            self.tracking_mouse = False

    fn enable_mouse_hilite(mut self) -> None:
        """Enable mouse hilite tracking."""
        if not self.tracking_mouse_hilite:
            enable_mouse_hilite()
            self.tracking_mouse_hilite = True

    fn disable_mouse_hilite(mut self) -> None:
        """Disable mouse hilite tracking."""
        if self.tracking_mouse_hilite:
            disable_mouse_hilite()
            self.tracking_mouse_hilite = False

    fn terminal_size(self) raises -> Area:
        """Get the current terminal size.

        Raises:
            Error: If querying the terminal for terminal size fails.

        Returns:
            An Area representing the current terminal size.
        """
        var dimensions = get_terminal_size()
        return Area(dimensions[0], dimensions[1])

    fn write_bytes(mut self, bytes: Span[Byte]) -> None:
        """Write bytes to the terminal.

        Args:
            bytes: The bytes to write to the terminal.
        """
        self.fd.write_bytes(bytes)

    fn write[*Ts: Writable](mut self, *args: *Ts) -> None:
        """Write to the terminal.

        Parameters:
            Ts: The types of the arguments to write.

        Args:
            args: The arguments to write to the terminal.
        """
        alias length = args.__len__()

        @parameter
        for i in range(length):
            args[i].write_to(self.fd)
