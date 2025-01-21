from utils import Variant
from collections import InlineArray
import .hue
from .ansi_colors import ANSI_HEX_CODES


# Workaround for str() not working at compile time due to using an external_call to c.
fn int_to_str(owned value: UInt32, base: Int = 10) -> String:
    """Converts an integer to a string.

    Args:
        value: The integer to convert to a string.
        base: The base to convert the integer to.

    Returns:
        The string representation of the integer.
    """
    # Catch edge case of 0
    if value == 0:
        return "0"

    alias valid = "0123456789abcdef"
    var temp = List[Byte](capacity=3)
    var i = 0
    while value > 0:
        byte = ord(valid[int(value) % base])
        temp.append(byte)
        i += 1
        value /= 10

    var buffer = List[Byte](capacity=3)
    for i in range(len(temp) - 1, -1, -1):
        buffer.append(temp[i])

    buffer.append(0)
    return String(buffer^)


alias FOREGROUND = "38"
alias BACKGROUND = "48"
alias AnyColor = Variant[NoColor, ANSIColor, ANSI256Color, RGBColor]


trait Color(EqualityComparable, RepresentableCollectionElement, ExplicitlyCopyable, Writable, Stringable):
    """Represents colors that can be displayed in the terminal."""

    fn sequence[is_background: Bool](self) -> String:
        """Sequence returns the ANSI Sequence for the color.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color.
        """
        ...


@register_passable("trivial")
struct NoColor(Color):
    """NoColor represents an ASCII color which is binary black or white."""

    fn __init__(out self):
        """Initializes a `NoColor` color."""
        pass

    fn __init__(out self, other: Self):
        """Initializes a `NoColor` color with another `NoColor` color.

        Args:
            other: The `NoColor` color to copy.
        """
        pass

    fn __eq__(self, other: NoColor) -> Bool:
        """Compares two colors for equality.

        Args:
            other: The `NoColor` color to compare to.

        Returns:
            True if the colors are equal, False otherwise.
        """
        return True

    fn __ne__(self, other: NoColor) -> Bool:
        """Compares two colors for unequality.

        Args:
            other: The `NoColor` color to compare to.

        Returns:
            True if the colors are not equal, False otherwise.
        """
        return False

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("NoColor()")

    fn __str__(self) -> String:
        """Returns the string representation of the NoColor.

        Returns:
            The string representation of the NoColor.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Returns the string representation of the NoColor.

        Returns:
            The string representation of the NoColor.
        """
        return str(self)

    fn sequence[is_background: Bool](self) -> String:
        """Returns an empty string. This function is used to implement the Color trait.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            An empty string.
        """
        return ""


@register_passable("trivial")
struct ANSIColor(Color):
    """ANSIColor is a color (0-15) as defined by the ANSI Standard."""

    var value: UInt32
    """The ANSI color value."""

    fn __init__(out self, value: UInt32):
        """Initializes the ANSIColor with a value.

        Args:
            value: The ANSI color value.
        """
        self.value = value

    fn __init__(out self, other: Self):
        """Initializes the ANSIColor with another ANSIColor.

        Args:
            other: The ANSIColor to copy.
        """
        self.value = other.value

    fn __init__(out self, color: hue.Color):
        """Initializes the ANSIColor with a `hue.Color`.

        Args:
            color: The `hue.Color` to convert to an ANSIColor.
        """
        self.value = color.hex()

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("ANSIColor(", str(self.value), ")")

    fn __str__(self) -> String:
        """Converts the ANSIColor to a string.

        Returns:
            The string representation of the ANSIColor.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Converts the ANSIColor to a string.

        Returns:
            The string representation of the ANSIColor.
        """
        return str(self)

    fn __eq__(self, other: ANSIColor) -> Bool:
        """Compares two colors for equality.

        Args:
            other: The ANSIColor to compare to.

        Returns:
            True if the colors are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: ANSIColor) -> Bool:
        """Compares two colors for unequality.

        Args:
            other: The ANSIColor to compare to.

        Returns:
            True if the colors are not equal, False otherwise.
        """
        return self.value != other.value

    fn to_rgb(self) -> (UInt32, UInt32, UInt32):
        """Converts the ANSI256 Color to an RGB Tuple.

        Returns:
            The RGB Tuple.
        """
        return ansi_to_rgb(self.value)

    fn sequence[is_background: Bool](self) -> String:
        """Converts the ANSI Color to an ANSI Sequence.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color and the text.
        """
        var modifier = 0

        @parameter
        if is_background:
            modifier += 10

        if self.value < 8:
            return int_to_str(modifier + self.value + 30)
        return int_to_str(modifier + self.value - 8 + 90)


@register_passable("trivial")
struct ANSI256Color(Color):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: UInt32
    """The ANSI256 color value."""

    fn __init__(out self, value: UInt32):
        """Initializes the ANSI256Color with a value.

        Args:
            value: The ANSI256 color value.
        """
        self.value = value

    fn __init__(out self, other: Self):
        """Initializes the ANSI256Color with another ANSI256Color.

        Args:
            other: The ANSI256Color to copy.
        """
        self.value = other.value

    fn __init__(out self, color: hue.Color):
        """Initializes the ANSI256Color with a `hue.Color`.

        Args:
            color: The `hue.Color` to convert to an ANSI256Color.
        """
        self.value = color.hex()

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("ANSI256Color(", str(self.value), ")")

    fn __str__(self) -> String:
        """Converts the color to a string.

        Returns:
            The string representation of the color value.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Converts the ANSI256Color to a string.

        Returns:
            The string representation of the ANSI256Color.
        """
        return str(self)

    fn __eq__(self, other: ANSI256Color) -> Bool:
        """Compares two colors for equality.

        Args:
            other: The ANSI256Color to compare to.

        Returns:
            True if the colors are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: ANSI256Color) -> Bool:
        """Compares two colors for unequality.

        Args:
            other: The ANSI256Color to compare to.

        Returns:
            True if the colors are not equal, False otherwise.
        """
        return self.value != other.value

    fn to_rgb(self) -> (UInt32, UInt32, UInt32):
        """Converts the ANSI256 Color to an RGB Tuple.

        Returns:
            The RGB Tuple.
        """
        return ansi_to_rgb(self.value)

    fn sequence[is_background: Bool](self) -> String:
        """Converts the ANSI256 Color to an ANSI Sequence.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color and the text.
        """
        var output = String(capacity=8)

        @parameter
        if is_background:
            output.write(BACKGROUND)
        else:
            output.write(FOREGROUND)
        output.write(";5;", int_to_str(self.value))

        return output


fn ansi_to_rgb(ansi: UInt32) -> (UInt32, UInt32, UInt32):
    """Converts an ANSI color to a 24-bit RGB color.

    Args:
        ansi: The ANSI color value.

    Returns:
        The RGB color tuple.
    """
    # For out-of-range values return black.
    if ansi > 255:
        return UInt32(0), UInt32(0), UInt32(0)

    # Low ANSI.
    if ansi < 16:
        return hex_to_rgb(ANSI_HEX_CODES[int(ansi)])

    # Grays.
    if ansi > 231:
        var s = (ansi - 232) * 10 + 8
        return s, s, s

    # ANSI256.
    var n = ansi - 16
    var b = n % 6
    var g = (n - b) / 6 % 6
    var r = (n - b - g * 6) / 36 % 6
    var v = r
    for _ in range(3):
        if v > 0:
            v = v * 40 + 55

    return r, g, b


fn hex_to_rgb(hex: UInt32) -> (UInt32, UInt32, UInt32):
    """Converts a number in hexadecimal format to red, green, and blue values.
    `r, g, b = hex_to_rgb(0x0000FF) # (0, 0, 255)`.

    Args:
        hex: The hex value.

    Returns:
        The red, green, and blue values.
    """
    return hex >> 16, hex >> 8 & 0xFF, hex & 0xFF


fn rgb_to_hex(r: UInt32, g: UInt32, b: UInt32) -> UInt32:
    """Converts red, green, and blue values to a number in hexadecimal format.
    `hex = rgb_to_hex(0, 0, 255) # 0x0000FF`.

    Args:
        r: The red value.
        g: The green value.
        b: The blue value.

    Returns:
        The hex value.
    """
    return (r << 16) | (g << 8) | b


@register_passable("trivial")
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. '0xabcdef'."""

    var value: UInt32
    """The hex-encoded color value."""

    fn __init__(out self, value: UInt32):
        """Initializes the RGBColor with a value.

        Args:
            value: The hex-encoded color value.
        """
        self.value = value

    fn __init__(out self, color: hue.Color):
        """Initializes the RGBColor with a `hue.Color`.

        Args:
            color: The `hue.Color` to convert to an RGBColor.
        """
        self.value = color.hex()

    fn __init__(out self, other: Self):
        """Initializes the RGBColor with another RGBColor.

        Args:
            other: The RGBColor to copy.
        """
        self.value = other.value

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("RGBColor(", str(self.value), ")")

    fn __str__(self) -> String:
        """Converts the RGBColor to a string.

        Returns:
            The string representation of the RGBColor.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Converts the RGBColor to a string.

        Returns:
            The string representation of the RGBColor.
        """
        return String.write(self)

    fn __eq__(self, other: RGBColor) -> Bool:
        """Compares two colors for equality.

        Args:
            other: The RGBColor to compare to.

        Returns:
            True if the colors are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: RGBColor) -> Bool:
        """Compares two colors for unequality.

        Args:
            other: The RGBColor to compare to.

        Returns:
            True if the colors are not equal, False otherwise.
        """
        return self.value != other.value

    fn to_rgb(self) -> (UInt32, UInt32, UInt32):
        """Converts the RGB Color to an RGB Tuple.

        Returns:
            The RGB Tuple.
        """
        return hex_to_rgb(self.value)

    fn sequence[is_background: Bool](self) -> String:
        """Converts the RGB Color to an ANSI Sequence.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color and the text.
        """
        var rgb = hex_to_rgb(self.value)
        var output = String(capacity=8)

        @parameter
        if is_background:
            output.write(BACKGROUND)
        else:
            output.write(FOREGROUND)
        output.write(";2;", int_to_str(rgb[0]), ";", int_to_str(rgb[1]), ";", int_to_str(rgb[2]))

        return output


fn ansi256_to_ansi(value: UInt32) -> ANSIColor:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.

    Returns:
        The ANSI color value.
    """
    var r = 0
    var md = hue.MAX_FLOAT64
    var h = hex_to_rgb(ANSI_HEX_CODES[int(value)])
    var h_color = hue.Color(R=h[0], G=h[1], B=h[2])

    for i in range(16):
        var hb = hex_to_rgb(ANSI_HEX_CODES[int(i)])
        var d = h_color.distance_HSLuv(hue.Color(R=hb[0], G=hb[1], B=hb[2]))

        if d < md:
            md = d
            r = i

    return ANSIColor(r)


fn _v2ci(value: Float64) -> Int:
    """Converts a value to a color index.

    Args:
        value: The value to convert to a color index.

    Returns:
        The color index.
    """
    if value < 48:
        return 0
    elif value < 115:
        return 1
    return int((value - 35) / 40)


fn hex_to_ansi256(color: hue.Color) -> ANSI256Color:
    """Converts a hex code to a ANSI256 color.

    Args:
        color: Hex code color from hue.Color.

    Returns:
        The ANSI256 color.
    """
    # Calculate the nearest 0-based color index at 16..231
    # Originally had * 255 in each of these
    var r = _v2ci(color.R)  # 0..5 each
    var g = _v2ci(color.G)
    var b = _v2ci(color.B)

    # Calculate the represented colors back from the index
    alias i2cv = InlineArray[UInt32, 6](0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF)
    var cr = i2cv[r]  # r/g/b, 0..255 each
    var cg = i2cv[g]
    var cb = i2cv[b]

    # Calculate the nearest 0-based gray index at 232..255
    var gray_index: UInt32
    var average = (r + g + b) / 3
    if average > 238:
        gray_index = 23
    else:
        gray_index = int((average - 3) / 10)  # 0..23
    var gv = 8 + 10 * gray_index  # same value for r/g/b, 0..255

    # Return the one which is nearer to the original input rgb value
    # Originall had / 255.0 for r, g, and b in each of these
    var color_dist = color.distance_HSLuv(hue.Color(R=cr, G=cg, B=cb))
    var gray_dist = color.distance_HSLuv(hue.Color(R=gv, G=gv, B=gv))

    if color_dist <= gray_dist:
        var ci = int((36 * r) + (6 * g) + b)  # 0..215
        return ANSI256Color(16 + ci)
    return ANSI256Color(232 + gray_index)
