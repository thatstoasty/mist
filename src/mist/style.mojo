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
struct SGR:
    alias RESET = "0"
    alias BOLD = "1"
    alias FAINT = "2"
    alias ITALIC = "3"
    alias UNDERLINE = "4"
    alias SLOW_BLINK = "5"
    alias RAPID_BLINK = "6"
    alias REVERSE = "7"
    alias CONCEAL = "8"
    alias STRIKETHROUGH = "9"
    alias NO_BOLD = "21"
    alias NORMAL_INTENSITY = "22"
    alias NO_ITALIC = "23"
    alias NO_UNDERLINE = "24"
    alias NO_BLINK = "25"
    alias NO_REVERSE = "27"
    alias NO_CONCEAL = "28"
    alias NO_STRIKETHROUGH = "29"
    alias BLACK_FOREGROUND_COLOR = "30"
    alias RED_FOREGROUND_COLOR = "31"
    alias GREEN_FOREGROUND_COLOR = "32"
    alias YELLOW_FOREGROUND_COLOR = "33"
    alias BLUE_FOREGROUND_COLOR = "34"
    alias MAGENTA_FOREGROUND_COLOR = "35"
    alias CYAN_FOREGROUND_COLOR = "36"
    alias WHITE_FOREGROUND_COLOR = "37"
    alias EXTENDED_FOREGROUND_COLOR = "38"
    alias DEFAULT_FOREGROUND_COLOR = "39"
    alias BLACK_BACKGROUND_COLOR = "40"
    alias RED_BACKGROUND_COLOR = "41"
    alias GREEN_BACKGROUND_COLOR = "42"
    alias YELLOW_BACKGROUND_COLOR = "43"
    alias BLUE_BACKGROUND_COLOR = "44"
    alias MAGENTA_BACKGROUND_COLOR = "45"
    alias CYAN_BACKGROUND_COLOR = "46"
    alias WHITE_BACKGROUND_COLOR = "47"
    alias EXTENDED_BACKGROUND_COLOR = "48"
    alias DEFAULT_BACKGROUND_COLOR = "49"
    alias OVERLINE = "53"
    alias EXTENDED_UNDERLINE_COLOR = "58"
    alias DEFAULT_UNDERLINE_COLOR = "59"
    alias BRIGHT_BLACK_FOREGROUND_COLOR = "90"
    alias BRIGHT_RED_FOREGROUND_COLOR = "91"
    alias BRIGHT_GREEN_FOREGROUND_COLOR = "92"
    alias BRIGHT_YELLOW_FOREGROUND_COLOR = "93"
    alias BRIGHT_BLUE_FOREGROUND_COLOR = "94"
    alias BRIGHT_MAGENTA_FOREGROUND_COLOR = "95"
    alias BRIGHT_CYAN_FOREGROUND_COLOR = "96"
    alias BRIGHT_WHITE_FOREGROUND_COLOR = "97"
    alias BRIGHT_BLACK_BACKGROUND_COLOR = "100"
    alias BRIGHT_RED_BACKGROUND_COLOR = "101"
    alias BRIGHT_GREEN_BACKGROUND_COLOR = "102"
    alias BRIGHT_YELLOW_BACKGROUND_COLOR = "103"
    alias BRIGHT_BLUE_BACKGROUND_COLOR = "104"
    alias BRIGHT_MAGENTA_BACKGROUND_COLOR = "105"
    alias BRIGHT_CYAN_BACKGROUND_COLOR = "106"
    alias BRIGHT_WHITE_BACKGROUND_COLOR = "107"


# ANSI Operations
alias ESCAPE = "\x1b"
"""Escape character."""
alias BEL = "\x07"
"""Bell character."""
alias CSI = ESCAPE + "["
"""Control Sequence Introducer."""
alias OSC = ESCAPE + "]"
"""Operating System Command."""
alias ST = ESCAPE + "\\"
"""String Terminator."""

alias CLEAR = "\x1b[2J\x1b[H"
"""Clear terminal and return cursor to top left."""


trait SizedWritable(Sized, Writable):
    """Trait for types that are both `Sized` and `Writable`."""

    ...


struct Style(Movable, ExplicitlyCopyable, Stringable, Representable, Writable):
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

    fn __moveinit__(out self, owned other: Style):
        """Constructs a Style from another Style.

        Args:
            other: The Style to move.
        """
        self.styles = other.styles^
        self.profile = other.profile

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

    fn add_style(self, style: String) -> Self:
        """Creates a deepcopy of Self, adds a style to it's list of styles, and returns that.

        Args:
            style: The ANSI style to add to the list of styles.

        #### Notes:
        - The style being added must be a valid ANSI SGR sequence.
        - You can use the `SGR` enum for some common styles to apply.
        """
        var new = self.copy()
        new.styles.append(style)
        return new^

    fn add_style[style: String](self) -> Self:
        """Creates a deepcopy of Self, adds a style to it's list of styles, and returns that.

        Parameters:
            style: The ANSI style to add to the list of styles.

        #### Notes:
        - The style being added must be a valid ANSI SGR sequence.
        - You can use the `SGR` enum for some common styles to apply.
        """
        var new = self.copy()
        new.styles.append(style)
        return new^

    @always_inline
    fn bold(self) -> Self:
        """Makes the text bold when rendered.

        Returns:
            A new Style with the bold style added.
        """
        return self.add_style[SGR.BOLD]()

    @always_inline
    fn disable_bold(self) -> Self:
        """Disables the bold style.

        Returns:
            A new Style with the bold style disabled.
        """
        return self.add_style[SGR.NO_BOLD]()

    @always_inline
    fn faint(self) -> Self:
        """Makes the text faint when rendered.

        Returns:
            A new Style with the faint style added.
        """
        return self.add_style[SGR.FAINT]()

    @always_inline
    fn disable_faint(self) -> Self:
        """Disables the faint style.

        Returns:
            A new Style with the faint style disabled.
        """
        return self.add_style[SGR.NORMAL_INTENSITY]()

    @always_inline
    fn italic(self) -> Self:
        """Makes the text italic when rendered.

        Returns:
            A new Style with the italic style added.
        """
        return self.add_style[SGR.ITALIC]()

    @always_inline
    fn disable_italic(self) -> Self:
        """Disables the italic style.

        Returns:
            A new Style with the italic style disabled.
        """
        return self.add_style[SGR.NO_ITALIC]()

    @always_inline
    fn underline(self) -> Self:
        """Makes the text underlined when rendered.

        Returns:
            A new Style with the underline style added.
        """
        return self.add_style[SGR.UNDERLINE]()

    @always_inline
    fn disable_underline(self) -> Self:
        """Disables the underline style.

        Returns:
            A new Style with the underline style disabled.
        """
        return self.add_style[SGR.NO_UNDERLINE]()

    @always_inline
    fn blink(self) -> Self:
        """Makes the text blink when rendered.

        Returns:
            A new Style with the blink style added.
        """
        return self.add_style[SGR.SLOW_BLINK]()

    @always_inline
    fn disable_blink(self) -> Self:
        """Disables the blink style.

        Returns:
            A new Style with the blink style disabled.
        """
        return self.add_style[SGR.NO_BLINK]()

    @always_inline
    fn rapid_blink(self) -> Self:
        """Makes the text rapidly blink when rendered.

        Returns:
            A new Style with the rapid blink style added.
        """
        return self.add_style[SGR.RAPID_BLINK]()

    @always_inline
    fn reverse(self) -> Self:
        """Makes the text have reversed background and foreground colors when rendered.

        Returns:
            A new Style with the reverse style added.
        """
        return self.add_style[SGR.REVERSE]()

    @always_inline
    fn disable_reverse(self) -> Self:
        """Disables the reverse style.

        Returns:
            A new Style with the reverse style disabled.
        """
        return self.add_style[SGR.NO_REVERSE]()

    @always_inline
    fn conceal(self) -> Self:
        """Makes the text concealed when rendered.

        Returns:
            A new Style with the conceal style added.
        """
        return self.add_style[SGR.CONCEAL]()

    @always_inline
    fn disable_conceal(self) -> Self:
        """Disables the conceal style.

        Returns:
            A new Style with the conceal style disabled.
        """
        return self.add_style[SGR.NO_CONCEAL]()

    @always_inline
    fn strikethrough(self) -> Self:
        """Makes the text crossed out when rendered.

        Returns:
            A new Style with the strikethrough style added.
        """
        return self.add_style[SGR.STRIKETHROUGH]()

    @always_inline
    fn disable_strikethrough(self) -> Self:
        """Disables the strikethrough style.

        Returns:
            A new Style with the strikethrough style disabled.
        """
        return self.add_style[SGR.NO_STRIKETHROUGH]()

    @always_inline
    fn overline(self) -> Self:
        """Makes the text overlined when rendered.

        Returns:
            A new Style with the overline style added.
        """
        return self.add_style[SGR.OVERLINE]()

    fn background(self, *, color: AnyColor) -> Self:
        """Set the background color of the text when it's rendered.

        Args:
            color: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the background color set.
        """
        if color.isa[NoColor]():
            return self.copy()

        return self.add_style(color.sequence[True]())

    @always_inline
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
            return self.copy()

        return self.add_style(color.sequence[False]())

    @always_inline
    fn foreground(self, color: UInt32) -> Self:
        """Shorthand for using the style profile to set the foreground color of the text.

        Args:
            color: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the foreground color set.
        """
        return self.foreground(color=self.profile.color(color))

    @always_inline
    fn black(self) -> Self:
        """Set the foreground color to ANSI standard black (ANSI 0).

        Returns:
            A new Style with the foreground color set to standard black.
        """
        return self.add_style[SGR.BLACK_FOREGROUND_COLOR]()

    @always_inline
    fn black_background(self) -> Self:
        """Set the background color to ANSI black (ANSI 0).

        Returns:
            A new Style with the background color set to black.
        """
        return self.add_style[SGR.BLACK_BACKGROUND_COLOR]()

    @always_inline
    fn dark_red(self) -> Self:
        """Set the foreground color to ANSI standard red (ANSI 1).

        Returns:
            A new Style with the foreground color set to standard red.
        """
        return self.add_style[SGR.RED_FOREGROUND_COLOR]()

    @always_inline
    fn dark_red_background(self) -> Self:
        """Set the background color to ANSI standard red (ANSI 1).

        Returns:
            A new Style with the background color set to standard red.
        """
        return self.add_style[SGR.RED_BACKGROUND_COLOR]()

    @always_inline
    fn dark_green(self) -> Self:
        """Set the foreground color to ANSI standard green (ANSI 2).

        Returns:
            A new Style with the foreground color set to standard green.
        """
        return self.add_style[SGR.GREEN_FOREGROUND_COLOR]()

    @always_inline
    fn dark_green_background(self) -> Self:
        """Set the background color to ANSI standard green (ANSI 2).

        Returns:
            A new Style with the background color set to standard green.
        """
        return self.add_style[SGR.GREEN_BACKGROUND_COLOR]()

    @always_inline
    fn dark_yellow(self) -> Self:
        """Set the foreground color to ANSI standard yellow (ANSI 3).

        Returns:
            A new Style with the foreground color set to standard yellow.
        """
        return self.add_style[SGR.YELLOW_FOREGROUND_COLOR]()

    @always_inline
    fn dark_yellow_background(self) -> Self:
        """Set the background color to ANSI standard yellow (ANSI 3).

        Returns:
            A new Style with the background color set to standard yellow.
        """
        return self.add_style[SGR.YELLOW_BACKGROUND_COLOR]()

    @always_inline
    fn navy(self) -> Self:
        """Set the foreground color to ANSI standard blue (ANSI 4).

        Returns:
            A new Style with the foreground color set to standard blue.
        """
        return self.add_style[SGR.BLUE_FOREGROUND_COLOR]()

    @always_inline
    fn navy_background(self) -> Self:
        """Set the background color to ANSI standard blue (ANSI 4).

        Returns:
            A new Style with the background color set to standard blue.
        """
        return self.add_style[SGR.BLUE_BACKGROUND_COLOR]()

    @always_inline
    fn purple(self) -> Self:
        """Set the foreground color to ANSI standard magenta (ANSI 5).

        Returns:
            A new Style with the foreground color set to standard magenta.
        """
        return self.add_style[SGR.MAGENTA_FOREGROUND_COLOR]()

    @always_inline
    fn purple_background(self) -> Self:
        """Set the background color to ANSI standard magenta (ANSI 5).

        Returns:
            A new Style with the background color set to standard magenta.
        """
        return self.add_style[SGR.MAGENTA_BACKGROUND_COLOR]()

    @always_inline
    fn teal(self) -> Self:
        """Set the foreground color to ANSI standard cyan (ANSI 6).

        Returns:
            A new Style with the foreground color set to standard cyan.
        """
        return self.add_style[SGR.CYAN_FOREGROUND_COLOR]()

    @always_inline
    fn teal_background(self) -> Self:
        """Set the background color to ANSI standard cyan (ANSI 6).

        Returns:
            A new Style with the background color set to standard cyan.
        """
        return self.add_style[SGR.CYAN_BACKGROUND_COLOR]()

    @always_inline
    fn light_gray(self) -> Self:
        """Set the foreground color to ANSI white (ANSI 7).

        Returns:
            A new Style with the foreground color set to white.
        """
        return self.add_style[SGR.WHITE_FOREGROUND_COLOR]()

    @always_inline
    fn light_gray_background(self) -> Self:
        """Set the background color to ANSI white (ANSI 7).

        Returns:
            A new Style with the background color set to white.
        """
        return self.add_style[SGR.WHITE_BACKGROUND_COLOR]()

    @always_inline
    fn dark_gray(self) -> Self:
        """Set the foreground color to ANSI dark gray (ANSI 8).

        Returns:
            A new Style with the foreground color set to dark gray.
        """
        return self.add_style[SGR.BRIGHT_BLACK_FOREGROUND_COLOR]()

    @always_inline
    fn dark_gray_background(self) -> Self:
        """Set the background color to ANSI dark gray (ANSI 8).

        Returns:
            A new Style with the background color set to dark gray.
        """
        return self.add_style[SGR.BRIGHT_BLACK_BACKGROUND_COLOR]()

    @always_inline
    fn red(self) -> Self:
        """Set the foreground color to ANSI high intensity red (ANSI 9).

        Returns:
            A new Style with the foreground color set to high intensity red.
        """
        return self.add_style[SGR.BRIGHT_RED_FOREGROUND_COLOR]()

    @always_inline
    fn red_background(self) -> Self:
        """Set the background color to ANSI high intensity red (ANSI 9).

        Returns:
            A new Style with the background color set to high intensity red.
        """
        return self.add_style[SGR.BRIGHT_RED_BACKGROUND_COLOR]()

    @always_inline
    fn green(self) -> Self:
        """Set the foreground color to ANSI high intensity green (ANSI 10).

        Returns:
            A new Style with the foreground color set to high intensity green.
        """
        return self.add_style[SGR.BRIGHT_GREEN_FOREGROUND_COLOR]()

    @always_inline
    fn green_background(self) -> Self:
        """Set the background color to ANSI high intensity green (ANSI 10).

        Returns:
            A new Style with the background color set to high intensity green.
        """
        return self.add_style[SGR.BRIGHT_GREEN_BACKGROUND_COLOR]()

    @always_inline
    fn yellow(self) -> Self:
        """Set the foreground color to ANSI high intensity yellow (ANSI 11).

        Returns:
            A new Style with the foreground color set to high intensity yellow.
        """
        return self.add_style[SGR.BRIGHT_YELLOW_FOREGROUND_COLOR]()

    @always_inline
    fn yellow_background(self) -> Self:
        """Set the background color to ANSI high intensity yellow (ANSI 11).

        Returns:
            A new Style with the background color set to high intensity yellow.
        """
        return self.add_style[SGR.BRIGHT_YELLOW_BACKGROUND_COLOR]()

    @always_inline
    fn blue(self) -> Self:
        """Set the foreground color to ANSI high intensity blue (ANSI 12).

        Returns:
            A new Style with the foreground color set to high intensity blue.
        """
        return self.add_style[SGR.BRIGHT_BLUE_FOREGROUND_COLOR]()

    @always_inline
    fn blue_background(self) -> Self:
        """Set the background color to ANSI high intensity blue (ANSI 12).

        Returns:
            A new Style with the background color set to high intensity blue.
        """
        return self.add_style[SGR.BRIGHT_BLUE_BACKGROUND_COLOR]()

    @always_inline
    fn magenta(self) -> Self:
        """Set the foreground color to ANSI high intensity magenta (ANSI 13).

        Returns:
            A new Style with the foreground color set to high intensity magenta.
        """
        return self.add_style[SGR.BRIGHT_MAGENTA_FOREGROUND_COLOR]()

    @always_inline
    fn magenta_background(self) -> Self:
        """Set the background color to ANSI high intensity magenta (ANSI 13).

        Returns:
            A new Style with the background color set to high intensity magenta.
        """
        return self.add_style[SGR.BRIGHT_MAGENTA_BACKGROUND_COLOR]()

    @always_inline
    fn cyan(self) -> Self:
        """Set the foreground color to ANSI high intensity cyan (ANSI 14).

        Returns:
            A new Style with the foreground color set to high intensity cyan.
        """
        return self.add_style[SGR.BRIGHT_CYAN_FOREGROUND_COLOR]()

    @always_inline
    fn cyan_background(self) -> Self:
        """Set the background color to ANSI high intensity cyan (ANSI 14).

        Returns:
            A new Style with the background color set to high intensity cyan.
        """
        return self.add_style[SGR.BRIGHT_CYAN_BACKGROUND_COLOR]()

    @always_inline
    fn white(self) -> Self:
        """Set the foreground color to ANSI high intensity white (ANSI 15).

        Returns:
            A new Style with the foreground color set to high intensity white.
        """
        return self.add_style[SGR.BRIGHT_WHITE_FOREGROUND_COLOR]()

    @always_inline
    fn white_background(self) -> Self:
        """Set the background color to ANSI high intensity white (ANSI 15).

        Returns:
            A new Style with the background color set to high intensity white.
        """
        return self.add_style[SGR.BRIGHT_WHITE_BACKGROUND_COLOR]()

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

        var result = String(capacity=Int(len(text) * 1.25 + len(self.styles) * 3))

        # 1. Write the SGR styles. The SGR function starts with CSI and ends with m. Styles are delimited by ;.
        # 2. Write the text.
        # 3. Write the reset SGR sequence to turn off any styles that have been applied.
        result.write(CSI)
        for i in range(len(self.styles)):
            result.write(";", self.styles[i])
        result.write("m", text, CSI, SGR.RESET, "m")

        return result^
