from mist.ansi_colors import AnsiHex
from mist.stdlib.builtins import dict, HashableStr
from mist.math import max_float64
from mist.hue import DistanceHSLuv


struct GroundCodes:
    var foreground: String
    var background: String

    fn __init__(inout self):
        self.foreground = "38"
        self.background = "48"


trait Color:
    fn sequence(self, is_background: Bool) raises -> String:
        """Sequence returns the ANSI Sequence for the color."""
        ...


@value
struct NoColor(Color):
    fn sequence(self, is_background: Bool) raises -> String:
        return ""

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ""


@value
struct ANSIColor(Color):
    """ANSIColor is a color (0-15) as defined by the ANSI Standard."""

    var value: Int

    fn sequence(self, is_background: Bool) raises -> String:
        """String returns the ANSI Sequence for the color and the text."""
        var modifier: Int = 0
        if is_background:
            modifier += 10

        if self.value < 8:
            return String(modifier + self.value + 30)
        else:
            return String(modifier + self.value - 8 + 90)

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return AnsiHex().values[self.value]

    fn convert_to_rgb(self) raises -> RGB:
        """Converts an ANSI color to RGB by looking up the hex value and converting it.
        """
        var hex: String = AnsiHex().values[self.value]

        return hex_to_rgb(hex)


@value
struct ANSIColor256(Color):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: Int

    fn sequence(self, is_background: Bool) raises -> String:
        var prefix = GroundCodes().foreground
        if is_background:
            prefix = GroundCodes().background

        return prefix + ";5;" + String(self.value)

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return AnsiHex().values[self.value]

    fn convert_to_rgb(self) raises -> RGB:
        """Converts an ANSI color to RGB by looking up the hex value and converting it.
        """
        var hex: String = AnsiHex().values[self.value]

        return hex_to_rgb(hex)


@value
struct RGB:
    var R: Float64
    var G: Float64
    var B: Float64

    fn __str__(self) -> String:
        return (
            "RGB("
            + String(self.R)
            + ", "
            + String(self.G)
            + ", "
            + String(self.B)
            + ")"
        )


# fn convert_base10_to_base16(value: Int) raises -> String:
#     """Converts a base 10 number to base 16."""
#     var sum: Int = value
#     while value > 1:
#         let remainder = sum % 16
#         sum = sum / 16
#         print(remainder, sum)

#         print(remainder * 16)


fn convert_base16_to_base10(value: String) raises -> Int:
    """Converts a base 16 number to base 10.
    https://www.catalyst2.com/knowledgebase/dictionary/hexadecimal-base-16-numbers/#:~:text=To%20convert%20the%20hex%20number,16%20%2B%200%20%3D%2016).
    """
    var mapping = dict[HashableStr, Int]()
    mapping["0"] = 0
    mapping["1"] = 1
    mapping["2"] = 2
    mapping["3"] = 3
    mapping["4"] = 4
    mapping["5"] = 5
    mapping["6"] = 6
    mapping["7"] = 7
    mapping["8"] = 8
    mapping["9"] = 9
    mapping["a"] = 10
    mapping["b"] = 11
    mapping["c"] = 12
    mapping["d"] = 13
    mapping["e"] = 14
    mapping["f"] = 15

    let length = len(value)
    var sum: Int = 0
    for i in range(length - 1, -1, -1):
        let exponent = length - 1 - i
        sum += mapping[value[i]] * (16**exponent)

    return sum


fn hex_to_rgb(value: String) raises -> RGB:
    """Converts a hex color to RGB.

    Args:
        value: Hex color value.

    Returns:
        RGB color.
    """
    let hex = value[1:]
    var indices: DynamicVector[Int] = DynamicVector[Int]()
    indices.append(0)
    indices.append(2)
    indices.append(4)

    var results: DynamicVector[Int] = DynamicVector[Int]()
    for i in range(len(indices)):
        let base_10 = convert_base16_to_base10(hex[indices[i] : indices[i] + 2])
        results.append(atol(base_10))

    return RGB(results[0], results[1], results[2])


@value
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. '#abcdef'."""

    var value: String

    fn sequence(self, is_background: Bool) raises -> String:
        let rgb = hex_to_rgb(self.value)

        var prefix = GroundCodes().foreground
        if is_background:
            prefix = GroundCodes().background

        return prefix + ";5;" + String(self.value)
        return (
            prefix
            + String(";2;")
            + UInt8(int(rgb.R))
            + ";"
            + UInt8(int(rgb.G))
            + ";"
            + UInt8(int(rgb.B))
        )

    fn convert_to_rgb(self) raises -> RGB:
        """Converts the Hex code value to RGB."""
        return hex_to_rgb(self.value)


fn ansi256_to_ansi(value: Int) raises -> ANSIColor:
    """TODO: Converts an ANSI256 color to an ANSI color."""
    var r: Int = 0
    var md = max_float64()

    let h = hex_to_rgb(AnsiHex().values[value])

    var i: Int = 0
    while i <= 15:
        let hb = hex_to_rgb(AnsiHex().values[i])
        let d = DistanceHSLuv(h, hb)
        print(h.__str__(), hb.__str__(), d)

        if d < md:
            md = d
            r = i

        i += 1

    return ANSIColor(r)


fn hex_to_ansi256(value: Int):
    """TODO: Converts an ANSI256 color to an ANSI color."""
    pass


fn sgr_format(n: String) -> String:
    """SGR formatting: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters.
    """
    return chr(27) + "[" + n + "m"


@value
struct Properties:
    # Text colors
    var escape: String
    var BLUE: String
    var CYAN: String
    var GREEN: String
    var YELLOW: String
    var RED: String

    # Text formatting
    var BOLD: String
    var FAINT: String
    var UNDERLINE: String
    var BLINK: String
    var REVERSE: String
    var CROSSOUT: String
    var OVERLINE: String
    var ITALIC: String
    var INVERT: String

    # Background colors
    var BACKGROUND_BLACK: String
    var BACKGROUND_RED: String
    var BACKGROUND_GREEN: String
    var BACKGROUND_YELLOW: String
    var BACKGROUND_BLUE: String
    var BACKGROUND_PURPLE: String
    var BACKGROUND_CYAN: String
    var BACKGROUND_WHITE: String

    # Foreground colors
    var FOREGROUND_BLACK: String
    var FOREGROUND_RED: String
    var FOREGROUND_GREEN: String
    var FOREGROUND_YELLOW: String
    var FOREGROUND_BLUE: String
    var FOREGROUND_PURPLE: String
    var FOREGROUND_CYAN: String
    var FOREGROUND_WHITE: String

    # Other
    var RESET: String
    var CLEAR: String

    fn __init__(inout self):
        self.escape = chr(27)

        # Text colors
        self.BLUE = "94"
        self.CYAN = "96"
        self.GREEN = "92"
        self.YELLOW = "93"
        self.RED = "91"

        # Text formatting
        self.BOLD = "1"
        self.FAINT = "2"
        self.ITALIC = "3"
        self.UNDERLINE = "4"
        self.BLINK = "5"
        self.REVERSE = "7"
        self.CROSSOUT = "9"
        self.OVERLINE = "53"
        self.INVERT = "27"

        # Background colors
        self.BACKGROUND_BLACK = "40"
        self.BACKGROUND_RED = "41"
        self.BACKGROUND_GREEN = "42"
        self.BACKGROUND_YELLOW = "43"
        self.BACKGROUND_BLUE = "44"
        self.BACKGROUND_PURPLE = "45"
        self.BACKGROUND_CYAN = "46"
        self.BACKGROUND_WHITE = "47"

        # Foreground colors
        self.FOREGROUND_BLACK = self.escape + "[0;30m"
        self.FOREGROUND_RED = self.escape + "[0;31m"
        self.FOREGROUND_GREEN = self.escape + "[0;32m"
        self.FOREGROUND_YELLOW = self.escape + "[0;33m"
        self.FOREGROUND_BLUE = self.escape + "[0;34m"
        self.FOREGROUND_PURPLE = self.escape + "[0;35m"
        self.FOREGROUND_CYAN = self.escape + "[0;36m"
        self.FOREGROUND_WHITE = self.escape + "[0;37m"

        # Other
        # Reset terminal settings
        self.RESET = "0"

        # Clear terminal and return cursor to top left
        self.CLEAR = self.escape + "[2J" + self.escape + "[H"

    fn get_color(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "blue":
            code = self.BLUE
        elif type == "cyan":
            code = self.CYAN
        elif type == "green":
            code = self.GREEN
        elif type == "yellow":
            code = self.YELLOW
        elif type == "red":
            code = self.RED
        else:
            code = self.RESET

        return sgr_format(code)

    fn get_formatting(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "bold":
            code = self.BOLD
        elif type == "italic":
            code = self.ITALIC
        elif type == "underline":
            code = self.UNDERLINE
        elif type == "blink":
            code = self.BLINK
        elif type == "reverse":
            code = self.REVERSE
        elif type == "crossout":
            code = self.CROSSOUT
        elif type == "overline":
            code = self.OVERLINE
        elif type == "invert":
            code = self.INVERT
        else:
            code = self.RESET

        return sgr_format(code)

    fn get_background_color(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "black":
            code = self.BACKGROUND_BLACK
        elif type == "red":
            code = self.BACKGROUND_RED
        elif type == "green":
            code = self.BACKGROUND_GREEN
        elif type == "yellow":
            code = self.BACKGROUND_YELLOW
        elif type == "blue":
            code = self.BACKGROUND_BLUE
        elif type == "purple":
            code = self.BACKGROUND_PURPLE
        elif type == "cyan":
            code = self.BACKGROUND_CYAN
        elif type == "white":
            code = self.BACKGROUND_WHITE
        else:
            code = self.RESET

        return code

    fn get_foreground_color(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "black":
            code = self.FOREGROUND_BLACK
        elif type == "red":
            code = self.FOREGROUND_RED
        elif type == "green":
            code = self.FOREGROUND_GREEN
        elif type == "yellow":
            code = self.FOREGROUND_YELLOW
        elif type == "blue":
            code = self.FOREGROUND_BLUE
        elif type == "purple":
            code = self.FOREGROUND_PURPLE
        elif type == "cyan":
            code = self.FOREGROUND_CYAN
        elif type == "white":
            code = self.FOREGROUND_WHITE
        else:
            code = self.RESET

        return code

    fn get_other(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "reset":
            code = self.RESET
        elif type == "clear":
            code = self.CLEAR
        else:
            code = self.RESET

        return code
