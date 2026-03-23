import mist.style._hue as hue
from mist.style.color import RGBColor, hex_to_string


fn parse_xterm_color(sequence: StringSlice) raises -> Tuple[UInt8, UInt8, UInt8]:
    """Parses an xterm color sequence.

    Args:
        sequence: The color sequence to parse.

    Raises:
        Error: If the sequence is not a valid xterm color sequence, it will fail to convert the hex values to UInt8.

    Returns:
        A tuple containing the red, green, and blue components of the color.
    """
    # String should look something like this: 'rgb:1717/9393/d0d0\x1b\\'
    # It should be safe to just take the first 2 characters of each RGB value.
    var color = sequence.split("rgb:")[1]
    var parts = color.split("/")
    if len(parts) != 3:
        return 0, 0, 0

    fn convert_part_to_color(part: StringSlice) raises -> UInt8:
        """Converts a hex color part to an UInt8.

        Args:
            part: The hex color part to convert.

        Returns:
            An UInt8 representing the color component.
        """
        return UInt8(atol(part[byte=0:2], base=16))

    return convert_part_to_color(parts[0]), convert_part_to_color(parts[1]), convert_part_to_color(parts[2])


@fieldwise_init
struct XTermColor(Writable):
    var r: UInt8
    """Red component of the color."""
    var g: UInt8
    """Green component of the color."""
    var b: UInt8
    """Blue component of the color."""

    fn __init__(out self, color: StringSlice) raises:
        var rgb = parse_xterm_color(color)
        self.r = rgb[0]
        self.g = rgb[1]
        self.b = rgb[2]

    fn write_to(self, mut writer: Some[Writer]):
        """Writes the XTermColor to the given writer in the format 'rgb:rr/gg/bb'.

        Args:
            writer: The writer to write the XTermColor to.
        """
        # String should look something like this: 'rgb:1717/9393/d0d0'
        var r_hex = hex_to_string(UInt32(self.r))
        var g_hex = hex_to_string(UInt32(self.g))
        var b_hex = hex_to_string(UInt32(self.b))
        writer.write("rgb:")
        writer.write(
            r_hex,
            r_hex,
            "/",
            g_hex,
            g_hex,
            "/",
            b_hex,
            b_hex,
        )

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the XTermColor to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write(t"XTermColor(r={Int(self.r)}, g={Int(self.g)}, b={Int(self.b)})")

    fn to_rgb_color(self) -> RGBColor:
        """Converts the XTermColor to an RGBColor.

        Returns:
            An RGBColor representing the same color as the XTermColor.
        """
        return RGBColor(self.r, self.g, self.b)
