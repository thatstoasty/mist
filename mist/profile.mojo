"""Detects and represents the terminal's supported color profile."""
from std.os import abort, getenv
from std.sys.defines import get_defined_string
from std.ffi import _get_global, external_call
from std.memory.alloc import unsafe_alloc

from mist.color import Color, ansi256_to_ansi, hex_to_ansi256


def _init_global() -> Optional[Pointer[NoneType, MutUntrackedOrigin]]:
    var ptr = unsafe_alloc[Profile](1)
    ptr[] = get_color_profile()
    return ptr.unsafe_bitcast[NoneType]()


def _destroy_global(lib: Optional[Pointer[NoneType, MutUntrackedOrigin]]):
    if not lib:
        return

    var ptr = lib.value().unsafe_bitcast[Profile]()
    ptr.unsafe_deinit_pointee()
    ptr.unsafe_free()


@always_inline
def get_profile() -> Profile:
    """Initializes or gets the global profile value.

    This is so we only query the terminal once per program execution.

    Returns:
        Terminal profile value.
    """
    return _get_global["profile", _init_global, _destroy_global]().value().unsafe_bitcast[Profile]()[]


def get_color_profile() -> Profile:
    """Queries the terminal to determine the color profile it supports.
    `ASCII`, `ANSI`, `ANSI256`, or `TRUE_COLOR`.

    Returns:
        The color profile the terminal supports.
    """
    if getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        return Profile.true_color

    var term = getenv("TERM").lower()
    var color_term = getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if getenv("TERM_PROGRAM") != "tmux":
                return Profile.ansi256
        return Profile.true_color
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return Profile.ansi256

    # TERM is used by most terminals to indicate color support.
    var TRUE_COLOR_TERMINALS = [
        "alacritty",
        "contour",
        "rio",
        "wezterm",
        "xterm-ghostty",
        "xterm-kitty",
    ]
    var ANSI_TERMINALS = ["linux", "xterm"]
    if term in TRUE_COLOR_TERMINALS:
        return Profile.true_color
    elif term in ANSI_TERMINALS:
        return Profile.ansi

    if "256color" in term:
        return Profile.ansi256
    elif "color" in term or "ansi" in term:
        return Profile.ansi

    return Profile.ascii


__enum Profile(Defaultable, ImplicitlyCopyable, Writable):
    """The color profile for the terminal."""

    case true_color
    """The terminal supports true color (24-bit color)."""
    case ansi256
    """The terminal supports 256 colors (8-bit color)."""
    case ansi
    """The terminal supports basic ANSI colors (16 colors)."""
    case ascii
    """The terminal supports no colors (ASCII only)."""

    def __init__(out self):
        """Initialize a new profile with the given profile type.

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        comptime profile = get_defined_string["MIST_PROFILE", ""]()
        comptime if profile == "TRUE_COLOR":
            self = Self.true_color
            return
        elif profile == "ANSI256":
            self = Self.ansi256
            return
        elif profile == "ANSI":
            self = Self.ansi
            return
        elif profile == "ASCII":
            self = Self.ascii
            return
        elif profile != "":
            # A profile was passed, but was invalid. If none passed, move on to `get_color_profile`
            comptime assert False, "Invalid profile setting. Must be one of [TRUE_COLOR, ANSI256, ANSI, ASCII]."

        self = get_profile()

    def write_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the profile to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        match self:
            case .true_color:
                writer.write("TRUE_COLOR")
            case .ansi256:
                writer.write("ANSI256")
            case .ansi:
                writer.write("ANSI")
            case .ascii:
                writer.write("ASCII")

    def convert_ansi256(self, color: UInt8) -> Color:
        """Degrades an ANSI color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `Color` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        match self:
            case .ascii:
                return Color.ascii
            case .ansi:
                return Color.ansi(ansi256_to_ansi(color))
            case _:
                return Color.ansi256(color)

    def convert_rgb(self, color: Color) -> Color:
        """Degrades an RGB color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `Color` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        match self:
            case .ascii:
                return Color.ascii
            case .ansi:
                var ansi256 = hex_to_ansi256(color)
                return Color.ansi(ansi256_to_ansi(ansi256))
            case .ansi256:
                var ansi256 = hex_to_ansi256(color)
                return Color.ansi256(ansi256)
            case .true_color:
                return color

    def convert(self, color: Color) -> Color:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `Color` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        match self:
            case Self.ascii:
                return Color.ascii
            case _:
                pass

        match color:
            case .ascii:
                return color
            case .ansi:
                return color
            case .ansi256(value):
                return self.convert_ansi256(value)
            case .rgb:
                return self.convert_rgb(color)

    def color(self, value: UInt32) -> Color:
        """Creates a `Color` from a number. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255). If an invalid input is passed in,
        `NoColor` is returned which will not apply any coloring.

        Args:
            value: The string to convert to a color.

        Returns:
            A `Color` which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        match self:
            case Self.ascii:
                return Color.ascii
            case _:
                pass

        if value < 16:
            return Color.ansi(value.cast[DType.uint8]())
        elif value < 256:
            return self.convert_ansi256(value.cast[DType.uint8]())

        return self.convert_rgb(Color.rgb(value))
