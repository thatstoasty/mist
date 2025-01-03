import os
from collections import InlineArray
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


# TODO: UNIX systems only for now. Need to add Windows, POSIX, and SOLARIS support.
fn get_color_profile() -> Int:
    """Queries the terminal to determine the color profile it supports.
    `ASCII`, `ANSI`, `ANSI256`, or `TRUE_COLOR`.

    Returns:
        The color profile the terminal supports.
    """
    if os.getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        return TRUE_COLOR

    var term = os.getenv("TERM").lower()
    var color_term = os.getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if os.getenv("TERM_PROGRAM") != "tmux":
                return ANSI256
        return TRUE_COLOR
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return ANSI256

    # TERM is used by most terminals to indicate color support.
    if term in ["alacritty", "contour", "rio", "wezterm", "xterm-ghostty", "xterm-kitty"]:
        return TRUE_COLOR
    elif term in ["linux", "xterm"]:
        return ANSI

    if "256color" in term:
        return ANSI256
    elif "color" in term or "ansi" in term:
        return ANSI

    return ASCII


@register_passable("trivial")
struct Profile:
    """The color profile for the terminal."""

    alias valid = InlineArray[Int, 4](TRUE_COLOR, ANSI256, ANSI, ASCII)
    """Valid color profiles."""
    var value: Int
    """The color profile to use. Valid values: [TRUE_COLOR, ANSI256, ANSI, ASCII]."""

    @implicit
    fn __init__(out self, value: Int):
        """Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: [TRUE_COLOR, ANSI256, ANSI, ASCII].

        Notes:
            If an invalid value is passed in, the profile will default to ASCII.
            This is to workaround the virtality of raising functions.
        """
        if value not in Self.valid:
            self.value = ASCII
            return

        self.value = value

    fn __init__(out self):
        """Initialize a new profile with the given profile type."""
        self.value = get_color_profile()

    fn __init__(out self, other: Self):
        """Initialize a new profile using the value of an existing profile.

        Args:
            other: The profile to copy the value from.
        """
        self.value = other.value

    fn convert(self, color: AnyColor) -> AnyColor:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self.value == ASCII:
            return NoColor()

        if color.isa[NoColor]():
            return color[NoColor]
        elif color.isa[ANSIColor]():
            return color[ANSIColor]
        elif color.isa[ANSI256Color]():
            if self.value == ANSI:
                return ansi256_to_ansi(color[ANSI256Color].value)

            return color[ANSI256Color]
        elif color.isa[RGBColor]():
            if self.value != TRUE_COLOR:
                var ansi256 = hex_to_ansi256(hue.Color(hex_to_rgb(color[RGBColor].value)))
                if self.value == ANSI:
                    return ansi256_to_ansi(ansi256.value)

                return ansi256

            return color[RGBColor]

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color[NoColor]

    fn color(self, value: UInt32) -> AnyColor:
        """Creates a `Color` from a number. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255). If an invalid input is passed in,
        `NoColor` is returned which will not apply any coloring.

        Args:
            value: The string to convert to a color.

        Returns:
            An `AnyColor` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        if self.value == ASCII:
            return NoColor()

        if value < 16:
            return self.convert(ANSIColor(value))
        elif value < 256:
            return self.convert(ANSI256Color(value))

        return self.convert(RGBColor(value))
