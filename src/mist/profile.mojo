from sys import external_call, os_is_linux, os_is_macos, os_is_windows
from sys.param_env import env_get_string
from sys.ffi import _Global
from collections import InlineArray
from collections.string import StringSlice
from memory import UnsafePointer
import .hue
from .color import (
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_ansi256,
    ansi256_to_ansi,
    hex_to_rgb,
)

alias TRUE_COLOR: Int = 0
alias ANSI256: Int = 1
alias ANSI: Int = 2
alias ASCII: Int = 3

alias TRUE_COLOR_PROFILE = Profile(TRUE_COLOR)
alias ANSI256_PROFILE = Profile(ANSI256)
alias ANSI_PROFILE = Profile(ANSI)
alias ASCII_PROFILE = Profile(ASCII)


# Faster getenv implementation that doesn't need to convert StringLiterals to strings.
fn getenv[name: StringLiteral, default: StringLiteral = ""]() -> String:
    """Returns the value of the given environment variable.

    Constraints:
      The function only works on macOS or Linux and returns an empty string
      otherwise.

    Parameters:
      name: The name of the environment variable.
      default: The default value to return if the environment variable
        doesn't exist.

    Returns:
      The value of the environment variable.
    """
    constrained[
        not os_is_windows(), "operating system must be Linux or macOS"
    ]()

    var ptr = external_call["getenv", UnsafePointer[UInt8]](
        name.unsafe_cstr_ptr()
    )
    if not ptr:
        return default
    return String(StringSlice[ptr.origin](unsafe_from_utf8_ptr=ptr))


fn get_color_profile() -> Profile:
    """Queries the terminal to determine the color profile it supports.
    `ASCII`, `ANSI`, `ANSI256`, or `TRUE_COLOR`.

    Returns:
        The color profile the terminal supports.
    """
    if getenv["GOOGLE_CLOUD_SHELL", "false"]() == "true":
        return Profile.TRUE_COLOR

    # TODO: Remove the conversion to lower case as it is consuming a fair bit of time in the critical path.
    var term = getenv["TERM"]().lower()
    var color_term = getenv["COLORTERM"]()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if getenv["TERM_PROGRAM"]() != "tmux":
                return Profile.ANSI256
        return Profile.TRUE_COLOR
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return Profile.ANSI256

    # TERM is used by most terminals to indicate color support.
    alias TRUE_COLOR_TERMINALS = InlineArray[String, 6](
        "alacritty", "contour", "rio", "wezterm", "xterm-ghostty", "xterm-kitty"
    )
    alias ANSI_TERMINALS = InlineArray[String, 2]("linux", "xterm")
    if term in TRUE_COLOR_TERMINALS:
        return Profile.TRUE_COLOR
    elif term in ANSI_TERMINALS:
        return Profile.ANSI

    if "256color" in term:
        return Profile.ANSI256
    elif "color" in term or "ansi" in term:
        return Profile.ANSI

    return Profile.ASCII


@register_passable("trivial")
struct Profile(ComparableCollectionElement, Writable, Stringable, Representable):
    """The color profile for the terminal."""

    var _value: Int

    alias TRUE_COLOR = Self(0)
    alias ANSI256 = Self(1)
    alias ANSI = Self(2)
    alias ASCII = Self(3)

    @implicit
    fn __init__(out self, value: Int):
        """Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: [`TRUE_COLOR`, `ANSI256`, `ANSI`, `ASCII`].

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        if value < 0 or value > 3:
            self._value = ASCII
            return

        self._value = value

    fn __init__(out self):
        """Initialize a new profile with the given profile type.

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        alias profile = env_get_string["MIST_PROFILE", ""]()

        @parameter
        if profile == "TRUE_COLOR":
            self._value = TRUE_COLOR
            return
        elif profile == "ANSI256":
            self._value = ANSI256
            return
        elif profile == "ANSI":
            self._value = ANSI
            return
        elif profile == "ASCII":
            self._value = ASCII
            return
        elif profile != "":
            # A profile was passed, but was invalid. If none passed, move on to `get_color_profile`
            constrained[
                False,
                "Invalid profile setting. Must be one of [TRUE_COLOR, ANSI256, ANSI, ASCII].",
            ]()

        self._value = get_color_profile()._value

    fn __init__(out self, other: Self):
        """Initialize a new profile using the value of an existing profile.

        Args:
            other: The profile to copy the value from.
        """
        self._value = other._value

    fn __eq__(self, other: Self) -> Bool:
        """Check if two profiles are equal.

        Args:
            other: The profile to compare against.

        Returns:
            True if the profiles are equal, False otherwise.
        """
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        """Check if two profiles are not equal.

        Args:
            other: The profile to compare against.

        Returns:
            True if the profiles are not equal, False otherwise.
        """
        return self._value != other._value

    fn __lt__(self, other: Self) -> Bool:
        """Check if the current profile is less than another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is less than the other profile, False otherwise.
        """
        return self._value < other._value

    fn __le__(self, other: Self) -> Bool:
        """Check if the current profile is less than or equal to another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is less than or equal to the other profile, False otherwise.
        """
        return self._value <= other._value

    fn __gt__(self, other: Self) -> Bool:
        """Check if the current profile is greater than another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is greater than the other profile, False otherwise.
        """
        return self._value > other._value

    fn __ge__(self, other: Self) -> Bool:
        """Check if the current profile is greater than or equal to another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is greater than or equal to the other profile, False otherwise.
        """
        return self._value >= other._value

    fn __str__(self) -> String:
        """Returns a string representation of the profile.

        Returns:
            A string representation of the profile.
        """
        if self._value == TRUE_COLOR:
            return "TRUE_COLOR"
        elif self._value == ANSI256:
            return "ANSI256"
        elif self._value == ANSI:
            return "ANSI"
        elif self._value == ASCII:
            return "ASCII"
        else:
            return "INVALID STATE"

    fn __repr__(self) -> String:
        """Returns a string representation of the profile.

        Returns:
            A string representation of the profile.
        """
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the profile to a Writer.

        Parameters:
            W: The type of the Writer to write to.

        Args:
            writer: The Writer to write the profile to.
        """
        writer.write("Profile(_value=", self._value, ")")

    fn convert_ansi256(self, color: ANSI256Color) -> AnyColor:
        """Degrades an ANSI color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self == Self.ASCII:
            return NoColor()

        if self == Self.ANSI:
            return ANSIColor(ansi256_to_ansi(color.value))

        return color

    fn convert_rgb(self, color: RGBColor) -> AnyColor:
        """Degrades an RGB color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self == Self.ASCII:
            return NoColor()

        if self != Self.TRUE_COLOR:
            var ansi256 = hex_to_ansi256(hue.Color(hex_to_rgb(color.value)))
            if self == Self.ANSI:
                return ANSIColor(ansi256_to_ansi(ansi256.value))

            return ANSI256Color(ansi256)

        return color

    fn convert(self, color: AnyColor) -> AnyColor:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self == Self.ASCII:
            return NoColor()

        if color.isa[NoColor]():
            return color.value[NoColor]
        elif color.isa[ANSIColor]():
            return color.value[ANSIColor]
        elif color.isa[ANSI256Color]():
            if self == Self.ANSI:
                return ANSIColor(ansi256_to_ansi(color.value[ANSI256Color].value))

            return color.value[ANSI256Color]
        elif color.isa[RGBColor]():
            if self != Self.TRUE_COLOR:
                var ansi256 = hex_to_ansi256(hue.Color(hex_to_rgb(color.value[RGBColor].value)))
                if self == Self.ANSI:
                    return ANSIColor(ansi256_to_ansi(ansi256.value))

                return ANSI256Color(ansi256)

            return color.value[RGBColor]

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color.value[NoColor]

    fn color(self, value: UInt32) -> AnyColor:
        """Creates a `Color` from a number. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255). If an invalid input is passed in,
        `NoColor` is returned which will not apply any coloring.

        Args:
            value: The string to convert to a color.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self == Self.ASCII:
            return NoColor()

        if value < 16:
            return ANSIColor(value.cast[DType.uint8]())
        elif value < 256:
            return self.convert_ansi256(ANSI256Color(value.cast[DType.uint8]()))

        return self.convert_rgb(RGBColor(value))
