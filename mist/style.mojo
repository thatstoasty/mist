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
from .profile import get_color_profile

# Text formatting sequences
alias reset = "0"
alias bold = "1"
alias faint = "2"
alias italic = "3"
alias underline = "4"
alias blink = "5"
alias reverse = "7"
alias crossout = "9"
alias overline = "53"

# ANSI Operations
alias escape = chr(27)  # Escape character
alias bel = "\a"  # Bell
alias csi = escape + "["  # Control Sequence Introducer
alias osc = escape + "]"  # Operating System Command
alias st = escape + chr(
    92
)  # String Terminator - Might not work, haven't tried. 92 should be a raw backslash

# clear terminal and return cursor to top left
alias clear = escape + "[2J" + escape + "[H"


@value
struct TerminalStyle:
    var styles: DynamicVector[String]
    var profile: Profile

    fn __init__(inout self, profile: Profile):
        self.styles = DynamicVector[String]()
        self.profile = profile

    fn __init__(inout self) raises:
        self.styles = DynamicVector[String]()
        self.profile = get_color_profile()

    fn bold(inout self) -> None:
        self.styles.push_back(bold)

    fn faint(inout self) -> None:
        self.styles.push_back(faint)

    fn italic(inout self) -> None:
        self.styles.push_back(italic)

    fn underline(inout self) -> None:
        self.styles.push_back(underline)

    fn blink(inout self) -> None:
        self.styles.push_back(blink)

    fn reverse(inout self) -> None:
        self.styles.push_back(reverse)

    fn crossout(inout self) -> None:
        self.styles.push_back(crossout)

    fn overline(inout self) -> None:
        self.styles.push_back(overline)

    fn background(inout self, color_value: String) raises -> None:
        """Set the background color of the text.

        Args:
            color_value: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.
        """
        var color = self.profile.color(color_value)
        if color.isa[NoColor]():
            return None

        if color.isa[ANSIColor]():
            var c = color.get[ANSIColor]()[]
            self.styles.push_back(c.sequence(True))
        elif color.isa[ANSI256Color]():
            var c = color.get[ANSI256Color]()[]
            self.styles.push_back(c.sequence(True))
        elif color.isa[RGBColor]():
            var c = color.get[RGBColor]()[]
            self.styles.push_back(c.sequence(True))

    fn foreground(inout self, color_value: String) raises -> None:
        """Set the foreground color of the text.

        Args:
            color_value: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.
        """
        var color = self.profile.color(color_value)
        if color.isa[NoColor]():
            return None

        if color.isa[ANSIColor]():
            var c = color.get[ANSIColor]()[]
            self.styles.push_back(c.sequence(False))
        elif color.isa[ANSI256Color]():
            var c = color.get[ANSI256Color]()[]
            self.styles.push_back(c.sequence(False))
        elif color.isa[RGBColor]():
            var c = color.get[RGBColor]()[]
            self.styles.push_back(c.sequence(False))

    fn render(self, text: String) -> String:
        if self.profile.value == "ASCII":
            return text

        if len(self.styles) == 0:
            return text

        var seq: String = ""
        for i in range(len(self.styles)):
            seq = seq + ";" + self.styles[i]

        return csi + seq + "m" + text + csi + reset + "m"
