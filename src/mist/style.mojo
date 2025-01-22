from .color import (
    Color,
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_rgb,
    hex_to_ansi256,
    ansi256_to_ansi,
)
from .profile import get_color_profile, ASCII

# Text formatting sequences
alias RESET = "0"
alias BOLD = "1"
alias FAINT = "2"
alias ITALIC = "3"
alias UNDERLINE = "4"
alias BLINK = "5"
alias REVERSE = "7"
alias CROSSOUT = "9"
alias OVERLINE = "53"

# ANSI Operations
alias ESCAPE = chr(27)
"""Escape character."""
alias BEL = "\a"
"""Bell character."""
alias CSI = ESCAPE + "["
"""Control Sequence Introducer."""
alias OSC = ESCAPE + "]"
"""Operating System Command."""
alias ST = ESCAPE + chr(92)
"""String Terminator."""

alias CLEAR = ESCAPE + "[2J" + ESCAPE + "[H"
"""Clear terminal and return cursor to top left."""


trait SizedWritable(Sized, Writable):
    """Trait for types that are both `Sized` and `Writable`."""

    ...


@value
struct Style(Movable, Copyable, ExplicitlyCopyable, Stringable, Representable, Writable):
    """Style stores a list of styles to format text with.
    These styles are ANSI sequences which modify text (and control the terminal).
    In reality, these styles are turning visual terminal features on and off around the text it's styling.

    This struct should be considered immutable and each style added returns a new instance of itself
    rather than modifying the struct in place.

    Examples:
    ```mojo
    import mist

    var style = mist.Style().foreground(0xE88388)
    print(style.render("Hello World"))
    ```
    """

    var styles: List[String]
    """The list of ANSI styles to apply to the text."""
    var profile: Profile
    """The color profile to use for color conversion."""

    fn __init__(out self, profile: Profile):
        """Constructs a Style.

        Args:
            profile: The color profile to use for color conversion.
        """
        self.styles = List[String]()
        self.profile = profile

    fn __init__(out self):
        """Constructs a Style. This constructor is not compile time friendly, because
        the default constructor for a Profile checks the terminal color profile.
        """
        self.styles = List[String]()
        self.profile = Profile()

    fn __init__(out self, other: Style):
        """Constructs a Style from another Style.

        Args:
            other: The Style to copy.
        """
        self.styles = other.styles
        self.profile = other.profile

    fn copy(self) -> Self:
        """Creates a copy of the Style.

        Returns:
            A new Style with the same styles and profile.
        """
        return Self(self)

    fn __str__(self) -> String:
        """Returns a string representation of the Style.

        Returns:
            A string representation of the Style.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Returns a string representation of the Style.

        Returns:
            A string representation of the Style.
        """
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the Style to a Writer.

        Parameters:
            W: The type of the Writer to write to.

        Args:
            writer: The Writer to write the Style to.
        """
        writer.write("Style(", "styles=", self.styles.__repr__(), ", profile=", self.profile, ")")

    fn _add_style(self, style: String) -> Self:
        """Creates a deepcopy of Self, adds a style to it's list of styles, and returns that.

        Args:
            style: The ANSI style to add to the list of styles.
        """
        var new = self
        new.styles.append(style)
        return new

    fn _add_style[style: String](self) -> Self:
        """Creates a deepcopy of Self, adds a style to it's list of styles, and returns that.

        Parameters:
            style: The ANSI style to add to the list of styles.
        """
        var new = self
        new.styles.append(style)
        return new

    fn bold(self) -> Self:
        """Makes the text bold when rendered.

        Returns:
            A new Style with the bold style added.
        """
        return self._add_style[BOLD]()

    fn faint(self) -> Self:
        """Makes the text faint when rendered.

        Returns:
            A new Style with the faint style added.
        """
        return self._add_style[FAINT]()

    fn italic(self) -> Self:
        """Makes the text italic when rendered.

        Returns:
            A new Style with the italic style added.
        """
        return self._add_style[ITALIC]()

    fn underline(self) -> Self:
        """Makes the text underlined when rendered.

        Returns:
            A new Style with the underline style added.
        """
        return self._add_style[UNDERLINE]()

    fn blink(self) -> Self:
        """Makes the text blink when rendered.

        Returns:
            A new Style with the blink style added.
        """
        return self._add_style[BLINK]()

    fn reverse(self) -> Self:
        """Makes the text have reversed background and foreground colors when rendered.

        Returns:
            A new Style with the reverse style added.
        """
        return self._add_style[REVERSE]()

    fn crossout(self) -> Self:
        """Makes the text crossed out when rendered.

        Returns:
            A new Style with the crossout style added.
        """
        return self._add_style[CROSSOUT]()

    fn overline(self) -> Self:
        """Makes the text overlined when rendered.

        Returns:
            A new Style with the overline style added.
        """
        return self._add_style[OVERLINE]()

    fn background(self, *, color: AnyColor) -> Self:
        """Set the background color of the text when it's rendered.

        Args:
            color: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the background color set.
        """
        if color.isa[NoColor]():
            return self

        return self._add_style(color.sequence[True]())

    fn background(self, color: UInt32) -> Self:
        """Shorthand for using the style profile to set the background color of the text.

        Args:
            color: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the background color set.
        """
        return self.background(color=self.profile.color(color))

    fn foreground(self, *, color: AnyColor) -> Self:
        """Set the foreground color of the text.

        Args:
            color: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the foreground color set.
        """
        if color.isa[NoColor]():
            return self

        return self._add_style(color.sequence[False]())

    fn foreground(self, color: UInt32) -> Self:
        """Shorthand for using the style profile to set the foreground color of the text.

        Args:
            color: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the foreground color set.
        """
        return self.foreground(color=self.profile.color(color))

    fn render[T: SizedWritable, //](self, text: T) -> String:
        """Renders text with the styles applied to it.

        Parameters:
            T: The type of the text object.

        Args:
            text: The text to render with the styles applied.

        Returns:
            The text with the styles applied.
        """
        if self.profile == Profile.ASCII or len(self.styles) == 0:
            var result = String(capacity=len(text) + 1)
            result.write(text)
            return result

        var result = String(capacity=int(len(text) * 1.25 + len(self.styles) * 3))
        result.write(CSI)
        for i in range(len(self.styles)):
            result.write(";", self.styles[i])
        result.write("m", text, CSI, RESET, "m")

        return result
