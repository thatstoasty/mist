from utils import Variant
from collections import InlineArray
import .hue
from .ansi_colors import ANSI_HEX_CODES, COLOR_STRINGS

alias FOREGROUND = "38"
alias BACKGROUND = "48"


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

    fn copy(self) -> Self:
        """Copies the `NoColor`.

        Returns:
            A copy of the `NoColor`.
        """
        return self

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
        return String(self)

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

    var value: UInt8
    """The ANSI color value."""

    fn __init__(out self, value: UInt8):
        """Initializes the ANSIColor with a value.

        Args:
            value: The ANSI color value.
        """
        if value > 15:
            self.value = ansi256_to_ansi(value)
        else:
            self.value = value

    fn __init__(out self, color: hue.Color):
        """Initializes the ANSIColor with a `hue.Color`.

        Args:
            color: The `hue.Color` to convert to an ANSIColor.
        """
        self.value = ansi256_to_ansi(hex_to_ansi256(color))

    fn __init__(out self, other: Self):
        """Initializes the ANSIColor with another ANSIColor.

        Args:
            other: The ANSIColor to copy.
        """
        self.value = other.value

    fn copy(self) -> Self:
        """Copies the `ANSIColor`.

        Returns:
            A copy of the `ANSIColor`.
        """
        return self

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("ANSIColor(", String(self.value), ")")

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
        return String(self)

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

    fn to_rgb(self) -> (UInt8, UInt8, UInt8):
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
        # TODO: Literally faster to do this than use an alias of Strings bc StringLiteral no longer works.
        var cs = InlineArray[StringLiteral, 256](
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31",
            "32",
            "33",
            "34",
            "35",
            "36",
            "37",
            "38",
            "39",
            "40",
            "41",
            "42",
            "43",
            "44",
            "45",
            "46",
            "47",
            "48",
            "49",
            "50",
            "51",
            "52",
            "53",
            "54",
            "55",
            "56",
            "57",
            "58",
            "59",
            "60",
            "61",
            "62",
            "63",
            "64",
            "65",
            "66",
            "67",
            "68",
            "69",
            "70",
            "71",
            "72",
            "73",
            "74",
            "75",
            "76",
            "77",
            "78",
            "79",
            "80",
            "81",
            "82",
            "83",
            "84",
            "85",
            "86",
            "87",
            "88",
            "89",
            "90",
            "91",
            "92",
            "93",
            "94",
            "95",
            "96",
            "97",
            "98",
            "99",
            "100",
            "101",
            "102",
            "103",
            "104",
            "105",
            "106",
            "107",
            "108",
            "109",
            "110",
            "111",
            "112",
            "113",
            "114",
            "115",
            "116",
            "117",
            "118",
            "119",
            "120",
            "121",
            "122",
            "123",
            "124",
            "125",
            "126",
            "127",
            "128",
            "129",
            "130",
            "131",
            "132",
            "133",
            "134",
            "135",
            "136",
            "137",
            "138",
            "139",
            "140",
            "141",
            "142",
            "143",
            "144",
            "145",
            "146",
            "147",
            "148",
            "149",
            "150",
            "151",
            "152",
            "153",
            "154",
            "155",
            "156",
            "157",
            "158",
            "159",
            "160",
            "161",
            "162",
            "163",
            "164",
            "165",
            "166",
            "167",
            "168",
            "169",
            "170",
            "171",
            "172",
            "173",
            "174",
            "175",
            "176",
            "177",
            "178",
            "179",
            "180",
            "181",
            "182",
            "183",
            "184",
            "185",
            "186",
            "187",
            "188",
            "189",
            "190",
            "191",
            "192",
            "193",
            "194",
            "195",
            "196",
            "197",
            "198",
            "199",
            "200",
            "201",
            "202",
            "203",
            "204",
            "205",
            "206",
            "207",
            "208",
            "209",
            "210",
            "211",
            "212",
            "213",
            "214",
            "215",
            "216",
            "217",
            "218",
            "219",
            "220",
            "221",
            "222",
            "223",
            "224",
            "225",
            "226",
            "227",
            "228",
            "229",
            "230",
            "231",
            "232",
            "233",
            "234",
            "235",
            "236",
            "237",
            "238",
            "239",
            "240",
            "241",
            "242",
            "243",
            "244",
            "245",
            "246",
            "247",
            "248",
            "249",
            "250",
            "251",
            "252",
            "253",
            "254",
            "255",
        )
        var modifier: Int

        @parameter
        if is_background:
            modifier = 10
        else:
            modifier = 0

        if self.value < 8:
            return cs[modifier + self.value + 30]
        return cs[modifier + self.value - 8 + 90]


@register_passable("trivial")
struct ANSI256Color(Color):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: UInt8
    """The ANSI256 color value."""

    fn __init__(out self, value: UInt8):
        """Initializes the ANSI256Color with a value.

        Args:
            value: The ANSI256 color value.
        """
        self.value = value

    fn __init__(out self, color: hue.Color):
        """Initializes the ANSI256Color with a `hue.Color`.

        Args:
            color: The `hue.Color` to convert to an ANSI256Color.
        """
        self.value = hex_to_ansi256(color)

    fn __init__(out self, other: Self):
        """Initializes the ANSI256Color with another ANSI256Color.

        Args:
            other: The ANSI256Color to copy.
        """
        self.value = other.value

    fn copy(self) -> Self:
        """Copies the `ANSI256Color`.

        Returns:
            A copy of the `ANSI256Color`.
        """
        return self

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("ANSI256Color(", String(self.value), ")")

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
        return String(self)

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

    fn to_rgb(self) -> (UInt8, UInt8, UInt8):
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
        var cs = InlineArray[StringLiteral, 256](
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31",
            "32",
            "33",
            "34",
            "35",
            "36",
            "37",
            "38",
            "39",
            "40",
            "41",
            "42",
            "43",
            "44",
            "45",
            "46",
            "47",
            "48",
            "49",
            "50",
            "51",
            "52",
            "53",
            "54",
            "55",
            "56",
            "57",
            "58",
            "59",
            "60",
            "61",
            "62",
            "63",
            "64",
            "65",
            "66",
            "67",
            "68",
            "69",
            "70",
            "71",
            "72",
            "73",
            "74",
            "75",
            "76",
            "77",
            "78",
            "79",
            "80",
            "81",
            "82",
            "83",
            "84",
            "85",
            "86",
            "87",
            "88",
            "89",
            "90",
            "91",
            "92",
            "93",
            "94",
            "95",
            "96",
            "97",
            "98",
            "99",
            "100",
            "101",
            "102",
            "103",
            "104",
            "105",
            "106",
            "107",
            "108",
            "109",
            "110",
            "111",
            "112",
            "113",
            "114",
            "115",
            "116",
            "117",
            "118",
            "119",
            "120",
            "121",
            "122",
            "123",
            "124",
            "125",
            "126",
            "127",
            "128",
            "129",
            "130",
            "131",
            "132",
            "133",
            "134",
            "135",
            "136",
            "137",
            "138",
            "139",
            "140",
            "141",
            "142",
            "143",
            "144",
            "145",
            "146",
            "147",
            "148",
            "149",
            "150",
            "151",
            "152",
            "153",
            "154",
            "155",
            "156",
            "157",
            "158",
            "159",
            "160",
            "161",
            "162",
            "163",
            "164",
            "165",
            "166",
            "167",
            "168",
            "169",
            "170",
            "171",
            "172",
            "173",
            "174",
            "175",
            "176",
            "177",
            "178",
            "179",
            "180",
            "181",
            "182",
            "183",
            "184",
            "185",
            "186",
            "187",
            "188",
            "189",
            "190",
            "191",
            "192",
            "193",
            "194",
            "195",
            "196",
            "197",
            "198",
            "199",
            "200",
            "201",
            "202",
            "203",
            "204",
            "205",
            "206",
            "207",
            "208",
            "209",
            "210",
            "211",
            "212",
            "213",
            "214",
            "215",
            "216",
            "217",
            "218",
            "219",
            "220",
            "221",
            "222",
            "223",
            "224",
            "225",
            "226",
            "227",
            "228",
            "229",
            "230",
            "231",
            "232",
            "233",
            "234",
            "235",
            "236",
            "237",
            "238",
            "239",
            "240",
            "241",
            "242",
            "243",
            "244",
            "245",
            "246",
            "247",
            "248",
            "249",
            "250",
            "251",
            "252",
            "253",
            "254",
            "255",
        )
        var output = String(capacity=8)

        @parameter
        if is_background:
            output.write(BACKGROUND)
        else:
            output.write(FOREGROUND)
        output.write(";5;", cs[self.value])

        return output


fn ansi_to_rgb(ansi: UInt8) -> (UInt8, UInt8, UInt8):
    """Converts an ANSI color to a 24-bit RGB color.

    Args:
        ansi: The ANSI color value.

    Returns:
        The RGB color tuple.
    """
    # For out-of-range values return black.
    if ansi > 255:
        return UInt8(0), UInt8(0), UInt8(0)

    # Low ANSI.
    if ansi < 16:
        return hex_to_rgb(ANSI_HEX_CODES[Int(ansi)])

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

    @parameter
    for _ in range(3):
        if v > 0:
            v = v * 40 + 55

    return r, g, b


fn hex_to_rgb(hex: UInt32) -> (UInt8, UInt8, UInt8):
    """Converts a number in hexadecimal format to red, green, and blue values.
    `r, g, b = hex_to_rgb(0x0000FF) # (0, 0, 255)`.

    Args:
        hex: The hex value.

    Returns:
        The red, green, and blue values.
    """
    # Downcast to UInt8 to ensure the values are in the correct range, 0-255.
    # Better to truncate down to 255 rather than try to handle unexpectedly large values.
    var r = (hex >> 16).cast[DType.uint8]()
    var g = (hex >> 8 & 0xFF).cast[DType.uint8]()
    var b = (hex & 0xFF).cast[DType.uint8]()
    return r, g, b


fn rgb_to_hex(r: UInt8, g: UInt8, b: UInt8) -> UInt32:
    """Converts red, green, and blue values to a number in hexadecimal format.
    `hex = rgb_to_hex(0, 0, 255) # 0x0000FF`.

    Args:
        r: The red value.
        g: The green value.
        b: The blue value.

    Returns:
        The hex value.
    """
    return (r.cast[DType.uint32]() << 16) | (g.cast[DType.uint32]() << 8) | b.cast[DType.uint32]()


@register_passable("trivial")
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. `0xabcdef`."""

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

    fn copy(self) -> Self:
        """Copies the `RGBColor`.

        Returns:
            A copy of the `RGBColor`.
        """
        return self

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the representation to the writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the data to.
        """
        writer.write("RGBColor(", String(self.value), ")")

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

    fn to_rgb(self) -> (UInt8, UInt8, UInt8):
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
        var cs = InlineArray[StringLiteral, 256](
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31",
            "32",
            "33",
            "34",
            "35",
            "36",
            "37",
            "38",
            "39",
            "40",
            "41",
            "42",
            "43",
            "44",
            "45",
            "46",
            "47",
            "48",
            "49",
            "50",
            "51",
            "52",
            "53",
            "54",
            "55",
            "56",
            "57",
            "58",
            "59",
            "60",
            "61",
            "62",
            "63",
            "64",
            "65",
            "66",
            "67",
            "68",
            "69",
            "70",
            "71",
            "72",
            "73",
            "74",
            "75",
            "76",
            "77",
            "78",
            "79",
            "80",
            "81",
            "82",
            "83",
            "84",
            "85",
            "86",
            "87",
            "88",
            "89",
            "90",
            "91",
            "92",
            "93",
            "94",
            "95",
            "96",
            "97",
            "98",
            "99",
            "100",
            "101",
            "102",
            "103",
            "104",
            "105",
            "106",
            "107",
            "108",
            "109",
            "110",
            "111",
            "112",
            "113",
            "114",
            "115",
            "116",
            "117",
            "118",
            "119",
            "120",
            "121",
            "122",
            "123",
            "124",
            "125",
            "126",
            "127",
            "128",
            "129",
            "130",
            "131",
            "132",
            "133",
            "134",
            "135",
            "136",
            "137",
            "138",
            "139",
            "140",
            "141",
            "142",
            "143",
            "144",
            "145",
            "146",
            "147",
            "148",
            "149",
            "150",
            "151",
            "152",
            "153",
            "154",
            "155",
            "156",
            "157",
            "158",
            "159",
            "160",
            "161",
            "162",
            "163",
            "164",
            "165",
            "166",
            "167",
            "168",
            "169",
            "170",
            "171",
            "172",
            "173",
            "174",
            "175",
            "176",
            "177",
            "178",
            "179",
            "180",
            "181",
            "182",
            "183",
            "184",
            "185",
            "186",
            "187",
            "188",
            "189",
            "190",
            "191",
            "192",
            "193",
            "194",
            "195",
            "196",
            "197",
            "198",
            "199",
            "200",
            "201",
            "202",
            "203",
            "204",
            "205",
            "206",
            "207",
            "208",
            "209",
            "210",
            "211",
            "212",
            "213",
            "214",
            "215",
            "216",
            "217",
            "218",
            "219",
            "220",
            "221",
            "222",
            "223",
            "224",
            "225",
            "226",
            "227",
            "228",
            "229",
            "230",
            "231",
            "232",
            "233",
            "234",
            "235",
            "236",
            "237",
            "238",
            "239",
            "240",
            "241",
            "242",
            "243",
            "244",
            "245",
            "246",
            "247",
            "248",
            "249",
            "250",
            "251",
            "252",
            "253",
            "254",
            "255",
        )

        var rgb = hex_to_rgb(self.value)
        var output = String(capacity=8)

        @parameter
        if is_background:
            output.write(BACKGROUND)
        else:
            output.write(FOREGROUND)
        output.write(";2;", cs[rgb[0]], ";", cs[rgb[1]], ";", cs[rgb[2]])

        return output


fn ansi256_to_ansi(value: UInt8) -> UInt8:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.

    Returns:
        The ANSI color value.
    """
    alias MAX_ANSI = 16
    var r: UInt8 = 0
    var md = hue.MAX_FLOAT64
    var h = hex_to_rgb(ANSI_HEX_CODES[Int(value)])
    var h_color = hue.Color(R=h[0], G=h[1], B=h[2])

    for i in range(MAX_ANSI):
        var hb = hex_to_rgb(ANSI_HEX_CODES[Int(i)])
        var d = h_color.distance_HSLuv(hue.Color(R=hb[0], G=hb[1], B=hb[2]))

        if d < md:
            md = d
            r = i

    return r


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
    return Int((value - 35) / 40)


fn hex_to_ansi256(color: hue.Color) -> UInt8:
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
    alias i2cv = InlineArray[UInt8, 6](0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF)
    var cr = i2cv[r]  # r/g/b, 0..255 each
    var cg = i2cv[g]
    var cb = i2cv[b]

    # Calculate the nearest 0-based gray index at 232..255
    var gray_index: UInt8
    var average = (r + g + b) / 3
    if average > 238:
        gray_index = 23
    else:
        gray_index = Int((average - 3) / 10)  # 0..23
    var gv = 8 + 10 * gray_index  # same value for r/g/b, 0..255

    # Return the one which is nearer to the original input rgb value
    # Originall had / 255.0 for r, g, and b in each of these
    var color_dist = color.distance_HSLuv(hue.Color(R=cr, G=cg, B=cb))
    var gray_dist = color.distance_HSLuv(hue.Color(R=gv, G=gv, B=gv))

    if color_dist <= gray_dist:
        var ci: UInt8 = (36 * r) + (6 * g) + b  # 0..215
        return 16 + ci
    return 232 + gray_index


@value
struct AnyColor:
    """`AnyColor` is a `Variant` which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`."""

    alias _type = Variant[NoColor, ANSIColor, ANSI256Color, RGBColor]
    """The internal type of the `AnyColor`."""
    var value: Self._type
    """The color value."""

    @implicit
    fn __init__(out self, value: NoColor):
        """Initializes the AnyColor with a value.

        Args:
            value: The color value.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: ANSIColor):
        """Initializes the AnyColor with a value.

        Args:
            value: The color value.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: ANSI256Color):
        """Initializes the AnyColor with a value.

        Args:
            value: The color value.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: RGBColor):
        """Initializes the AnyColor with a value.

        Args:
            value: The color value.
        """
        self.value = value

    fn __init__(out self, other: Self):
        """Initializes the AnyColor with another AnyColor.

        Args:
            other: The AnyColor to copy.
        """
        self.value = other.value

    fn sequence[is_background: Bool](self) -> String:
        """Sequence returns the ANSI Sequence for the color.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color.
        """
        # Internal type is a variant, so these branches exhaustively match all types.
        if self.value.isa[ANSIColor]():
            return self.value[ANSIColor].sequence[is_background]()
        elif self.value.isa[ANSI256Color]():
            return self.value[ANSI256Color].sequence[is_background]()
        elif self.value.isa[RGBColor]():
            return self.value[RGBColor].sequence[is_background]()

        return self.value[NoColor].sequence[is_background]()

    fn isa[T: CollectionElement](self) -> Bool:
        """Checks if the value is of the given type.

        Parameters:
            T: The type to check against.

        Returns:
            True if the value is of the given type, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem__[T: CollectionElement](ref self) -> ref [self.value] T:
        """Gets the value as the given type.

        Parameters:
            T: The type to get the value as.

        Returns:
            The value as the given type.
        """
        return self.value[T]
