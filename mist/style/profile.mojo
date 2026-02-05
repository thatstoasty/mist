from os import abort, getenv
from sys import is_compile_time
from sys.param_env import env_get_string
from sys.ffi import _get_global, external_call

import mist.style._hue as hue
from mist.style.color import ANSI256Color, ANSIColor, AnyColor, NoColor, RGBColor, ansi256_to_ansi, hex_to_ansi256


fn _init_global() -> UnsafePointer[NoneType, origin=MutExternalOrigin]:
    var ptr = alloc[UInt8](1)
    ptr[] = get_color_profile()._value
    return ptr.bitcast[NoneType]()


fn _destroy_global(lib: UnsafePointer[NoneType, origin=MutExternalOrigin]):
    var ptr = lib.bitcast[UInt8]()
    ptr.free()


@always_inline
fn get_profile() -> Profile:
    """Initializes or gets the global profile value.

    This is so we only query the terminal once per program execution.

    Returns:
        Terminal profile value.
    """
    return _get_global["profile", _init_global, _destroy_global]().bitcast[UInt8]()[]


fn get_color_profile() -> Profile:
    """Queries the terminal to determine the color profile it supports.
    `ASCII`, `ANSI`, `ANSI256`, or `TRUE_COLOR`.

    Returns:
        The color profile the terminal supports.
    """
    if getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        return Profile.TRUE_COLOR

    var term = getenv("TERM").lower()
    var color_term = getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if getenv("TERM_PROGRAM") != "tmux":
                return Profile.ANSI256
        return Profile.TRUE_COLOR
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return Profile.ANSI256

    # TERM is used by most terminals to indicate color support.
    var TRUE_COLOR_TERMINALS: InlineArray[String, 6] = [
        "alacritty",
        "contour",
        "rio",
        "wezterm",
        "xterm-ghostty",
        "xterm-kitty",
    ]
    var ANSI_TERMINALS: InlineArray[String, 2] = ["linux", "xterm"]
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
struct Profile(Comparable, ImplicitlyCopyable, Representable, Stringable, Writable):
    """The color profile for the terminal."""

    var _value: UInt8
    comptime TRUE_COLOR = Self(0)
    """The terminal supports true color (24-bit color)."""
    comptime ANSI256 = Self(1)
    """The terminal supports 256 colors (8-bit color)."""
    comptime ANSI = Self(2)
    """The terminal supports basic ANSI colors (16 colors)."""
    comptime ASCII = Self(3)
    """The terminal supports no colors (ASCII only)."""

    @implicit
    fn __init__(out self, value: UInt8):
        """Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: [`TRUE_COLOR`, `ANSI256`, `ANSI`, `ASCII`].

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        if value > 3:
            self._value = 0
            return

        self._value = value

    fn __init__(out self):
        """Initialize a new profile with the given profile type.

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        comptime profile = env_get_string["MIST_PROFILE", ""]()

        @parameter
        if profile == "TRUE_COLOR":
            self = Self.TRUE_COLOR
            return
        elif profile == "ANSI256":
            self = Self.ANSI256
            return
        elif profile == "ANSI":
            self = Self.ANSI
            return
        elif profile == "ASCII":
            self = Self.ASCII
            return
        elif profile != "":
            # A profile was passed, but was invalid. If none passed, move on to `get_color_profile`
            constrained[
                False,
                "Invalid profile setting. Must be one of [TRUE_COLOR, ANSI256, ANSI, ASCII].",
            ]()

        # if is_compile_time():
        #     abort(
        #         "No profile was set that could be evaluated at compilation time. Either set profile value explicitly,"
        #         " set the MIST_PROFILE build parameter, or move the Profile or Style creation into a runtime context."
        #     )

        self = get_profile()

    fn __init__(out self, other: Self):
        """Initialize a new profile using the value of an existing profile.

        Args:
            other: The profile to copy the value from.
        """
        self._value = other._value

    fn __eq__(self, other: Self) -> Bool:
        """Check if the current profile is equal to another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is equal to the other profile, False otherwise.
        """
        return self._value == other._value

    fn __lt__(self, other: Self) -> Bool:
        """Check if the current profile is less than another profile.

        Args:
            other: The profile to compare against.

        Returns:
            True if the current profile is less than the other profile, False otherwise.
        """
        return self._value < other._value

    fn __str__(self) -> String:
        """Returns a string representation of the profile.

        Returns:
            A string representation of the profile.
        """
        if self == self.TRUE_COLOR:
            return "TRUE_COLOR"
        elif self == self.ANSI256:
            return "ANSI256"
        elif self == self.ANSI:
            return "ANSI"
        elif self == self.ASCII:
            return "ASCII"
        else:
            return "INVALID STATE"

    fn __repr__(self) -> String:
        """Returns a string representation of the profile.

        Returns:
            A string representation of the profile.
        """
        return String.write(self)

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the profile to a Writer.

        Args:
            writer: The Writer to write the profile to.
        """
        writer.write("Profile(", self._value, ")")

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
            var ansi256 = hex_to_ansi256(hue.Color(color.value))
            if self == Self.ANSI:
                return ANSIColor(ansi256_to_ansi(ansi256))

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
            return self.convert_ansi256(color.value[ANSI256Color])
        elif color.isa[RGBColor]():
            return self.convert_rgb(color.value[RGBColor])

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
