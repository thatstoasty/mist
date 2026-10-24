"""Color types and conversions for representing terminal colors."""
from std import math
from std.math import sqrt
from std.utils.numerics import max_finite

from mist.color.spaces import RGB, HSL, HSV, HSLuv, HPLuv, xyz, Luv, LuvLCh, Lab, xyY, hcl
from mist.color.math import (
    WhiteReference,
    delinearize,
    delinearize_fast,
    interp_angle,
    lab_finv,
    linearize,
    linearize_fast,
    hSLuvD65,
    clamp01,
    sq,
    DELTA,
    D65,
)
from mist._utils import lut
from mist._ansi_colors import ANSI256_LAB, ANSI256_TO_ANSI, ANSI_HEX_CODES, COLOR_STRINGS


comptime FOREGROUND = "38"
"""ANSI code for foreground colors."""
comptime BACKGROUND = "48"
"""ANSI code for background colors."""
comptime RGB_HEX_DIGITS = 6
"""Digits in a `RRGGBB` hex string, which keeps a color's leading zeros."""


@always_inline
def _to_channel(v: Float64) -> UInt8:
    """Quantizes a [0.0, 1.0] component to 0..255, clamping out-of-range values and rounding to nearest.

    Args:
        v: The component to quantize.

    Returns:
        The 8-bit channel value.
    """
    return UInt8(clamp01(v) * 255.0 + 0.5)


def _ansi_to_rgb(value: UInt8) -> Tuple[UInt8, UInt8, UInt8]:
    """Converts the ANSI256 Color to an RGB Tuple.

    Returns:
        The RGB Tuple.
    """
    return hex_to_rgb(lut[ANSI_HEX_CODES](Int(value)))


def _ansi_sequence[is_background: Bool](value: UInt8) -> String:
    """Converts the ANSI Color to an ANSI Sequence.

    Parameters:
        is_background: Whether the color is a background color.

    Returns:
        The ANSI Sequence for the color and the text.
    """
    var modifier: UInt8

    comptime if is_background:
        modifier = 10
    else:
        modifier = 0

    if value < 8:
        return String(lut[COLOR_STRINGS](modifier + value + 30))
    return String(lut[COLOR_STRINGS](modifier + value - 8 + 90))


def _ansi256_to_rgb(value: UInt8) -> Tuple[UInt8, UInt8, UInt8]:
    """Converts the ANSI256 Color to an RGB Tuple.

    Returns:
        The RGB Tuple.
    """
    return hex_to_rgb(lut[ANSI_HEX_CODES](Int(value)))


def _ansi256_sequence[is_background: Bool](value: UInt8) -> String:
    """Converts the ANSI256 Color to an ANSI Sequence.

    Parameters:
        is_background: Whether the color is a background color.

    Returns:
        The ANSI Sequence for the color and the text.
    """
    var output = String(capacity_bytes=8)

    comptime if is_background:
        output.write(BACKGROUND)
    else:
        output.write(FOREGROUND)
    output.write(";5;", lut[COLOR_STRINGS](value))

    return output^


def hex_to_rgb(hex: UInt32) -> Tuple[UInt8, UInt8, UInt8]:
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


def rgb_to_hex(r: UInt8, g: UInt8, b: UInt8) -> UInt32:
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


def hex_to_string(value: UInt32, *, min_width: Int = 0) -> String:
    """Convert a UInt32 value to a lowercase hexadecimal string.

    Args:
        value: The UInt32 value to convert.
        min_width: Pad with leading zeros to at least this many digits.

    Returns:
        A lowercase hexadecimal string (e.g., "1a2b3c4d").
    """
    comptime HEX_CHARS: Array[StaticString, 16] = [
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
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
    ]
    comptime NIBBLES = 8
    """The number of hexadecimal digits a `UInt32` can occupy."""

    var significant = 1
    var remaining = value >> 4
    while remaining > 0:
        significant += 1
        remaining >>= 4

    var digits = significant if significant > min_width else min_width

    # Emitted most significant digit first. Building the other way round meant
    # prepending each digit to the result, which reallocated and copied the
    # whole string once per digit.
    var result = String(capacity_bytes=digits)
    for index in reversed(range(digits)):
        # Anything past the value's own width is a padding zero.
        var nibble = Int((value >> UInt32(index * 4)) & 0xF) if index < NIBBLES else 0
        result.write(lut[HEX_CHARS](nibble))

    return result^


def _rgb_sequence[is_background: Bool](value: UInt32) -> String:
    """Converts the RGB Color to an ANSI Sequence.

    Parameters:
        is_background: Whether the color is a background color.

    Returns:
        The ANSI Sequence for the color and the text.
    """
    var output = String(capacity_bytes=8)

    comptime if is_background:
        output.write(BACKGROUND)
    else:
        output.write(FOREGROUND)
    var rgb = hex_to_rgb(value)
    output.write(";2;", lut[COLOR_STRINGS](rgb[0]), ";", lut[COLOR_STRINGS](rgb[1]), ";", lut[COLOR_STRINGS](rgb[2]))

    return output^


def ansi256_to_ansi(value: UInt8) -> UInt8:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.

    Returns:
        The ANSI color value.
    """
    # A nearest-neighbour search over 16 fixed candidates, for 256 possible
    # inputs, is a table: see `ANSI256_TO_ANSI` for how it was generated. The
    # search itself cost 16 HSLuv distances, which dominated every conversion
    # to this profile.
    return lut[ANSI256_TO_ANSI](Int(value))


@always_inline
def _hue_delta(a: Float64, b: Float64) -> Float64:
    """Returns the angle between two hues in degrees, going the short way round the circle.

    go-colorful and termenv subtract hues directly, which scores 2 and 359 degrees as
    357 degrees apart and sends reds that straddle 0 to the gray ramp.

    Args:
        a: The first hue, in [0.0, 360.0].
        b: The second hue, in [0.0, 360.0].

    Returns:
        The hue difference, in [0.0, 180.0].
    """
    var delta = abs(a - b) % 360.0
    return 360.0 - delta if delta > 180.0 else delta


def _hsluv_distance(a: HSLuv, b: HSLuv) -> Float64:
    """Returns the HSLuv-space distance between two already-converted colors.

    Backs `Color.distance_HSLuv`, and takes the converted coordinates rather than
    the colors so a color compared against several candidates is only converted
    once instead of once per comparison.

    Args:
        a: The first color's hue, saturation and luminance.
        b: The second color's hue, saturation and luminance.

    Returns:
        The distance between the two colors in HSLuv space.
    """
    return sqrt((_hue_delta(a.H, b.H) / 100.0) ** 2 + (a.S - b.S) ** 2 + (a.L - b.L) ** 2)


def _ciede2000(lab: Lab, lab2: Lab, kl: Float64 = 1.0, kc: Float64 = 1.0, kh: Float64 = 1.0) -> Float64:
    """Returns the CIEDE2000 color difference between two already-converted colors, on mist's [0, 1] Lab scale.

    Backs `Color.distance_ciede2000klch`, and takes the converted coordinates rather
    than the colors so a color compared against several candidates is only
    converted once.

    Args:
        lab: The first color in L*a*b*.
        lab2: The second color in L*a*b*.
        kl: The weighting factor for lightness.
        kc: The weighting factor for chroma.
        kh: The weighting factor for hue.

    Returns:
        The CIEDE2000 difference, scaled by 0.01 to match the library's Lab range.
    """
    # As with CIE94, we scale up the ranges of L,a,b beforehand and scale
    # them down again afterwards.
    var l1 = lab.L * 100.0
    var a1 = lab.a * 100.0
    var b1 = lab.b * 100.0
    var l2 = lab2.L * 100.0
    var a2 = lab2.a * 100.0
    var b2 = lab2.b * 100.0

    var cab1 = math.sqrt(sq(a1) + sq(b1))
    var cab2 = math.sqrt(sq(a2) + sq(b2))
    var cab_mean = (cab1 + cab2) / 2
    var p: Float64 = 25.0

    var g = 0.5 * (1 - math.sqrt((cab_mean**7) / ((cab_mean**7) + (p**7))))
    var ap1 = (1 + g) * a1
    var ap2 = (1 + g) * a2
    var cp1 = math.sqrt(sq(ap1) + sq(b1))
    var cp2 = math.sqrt(sq(ap2) + sq(b2))

    var hp1 = 0.0
    if b1 != ap1 or ap1 != 0:
        hp1 = math.atan2(b1, ap1)
        if hp1 < 0:
            hp1 += math.pi * 2
        hp1 *= 180 / math.pi
    var hp2 = 0.0
    if b2 != ap2 or ap2 != 0:
        hp2 = math.atan2(b2, ap2)
        if hp2 < 0:
            hp2 += math.pi * 2
        hp2 *= 180 / math.pi

    var delta_Lp = l2 - l1
    var delta_Cp = cp2 - cp1
    var dhp = 0.0
    var cpProduct = cp1 * cp2
    if cpProduct != 0:
        dhp = hp2 - hp1
        if dhp > 180:
            dhp -= 360
        elif dhp < -180:
            dhp += 360
    var delta_Hp = 2 * math.sqrt(cpProduct) * math.sin(dhp / 2 * math.pi / 180)

    var lp_mean = (l1 + l2) / 2
    var cp_mean = (cp1 + cp2) / 2
    var hp_mean = hp1 + hp2
    if cpProduct != 0:
        hp_mean /= 2
        if abs(hp1 - hp2) > 180:
            if hp1 + hp2 < 360:
                hp_mean += 180
            else:
                hp_mean -= 180

    var t = (
        1
        - 0.17 * math.cos((hp_mean - 30) * math.pi / 180)
        + 0.24 * math.cos(2 * hp_mean * math.pi / 180)
        + 0.32 * math.cos((3 * hp_mean + 6) * math.pi / 180)
        - 0.2 * math.cos((4 * hp_mean - 63) * math.pi / 180)
    )
    var delta_theta = 30 * math.exp(-sq((hp_mean - 275) / 25))
    var rc = 2 * math.sqrt((cp_mean**7) / ((cp_mean**7) + (p**7)))
    var sl = 1 + (0.015 * sq(lp_mean - 50)) / math.sqrt(20 + sq(lp_mean - 50))
    var sc = 1 + 0.045 * cp_mean
    var sh = 1 + 0.015 * cp_mean * t
    var rt = -math.sin(2 * delta_theta * math.pi / 180) * rc

    return (
        math.sqrt(
            sq(delta_Lp / (kl * sl))
            + sq(delta_Cp / (kc * sc))
            + sq(delta_Hp / (kh * sh))
            + rt * (delta_Cp / (kc * sc)) * (delta_Hp / (kh * sh))
        )
        * 0.01
    )


comptime _CUBE_LEVELS: Array[UInt8, 6] = [0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF]
"""The channel value of each of the six levels of the ANSI256 6x6x6 color cube (indices 16..231)."""


@always_inline
def _lower_cube_level(value: UInt8) -> Int:
    """Returns the index of the highest cube level at or below a channel value.

    Args:
        value: The channel value, 0..255.

    Returns:
        The cube level index, 0..5.
    """
    var level = 0
    while level < 5 and lut[_CUBE_LEVELS](level + 1) <= value:
        level += 1
    return level


@always_inline
def _ansi256_lab(index: Int) -> Lab:
    """Returns the precomputed L*a*b* coordinates of an ANSI256 color.

    Args:
        index: The ANSI256 color, 0..255.

    Returns:
        The color in L*a*b* space.
    """
    return Lab(lut[ANSI256_LAB](index * 3), lut[ANSI256_LAB](index * 3 + 1), lut[ANSI256_LAB](index * 3 + 2))


def hex_to_ansi256(color: Color) -> UInt8:
    """Converts a color to the nearest ANSI256 color by CIEDE2000.

    The candidates are the eight cube colors whose levels bracket the color's
    channels, and the three gray ramp entries nearest its lightness.

    Args:
        color: The color to convert.

    Returns:
        The ANSI256 color, 16..255.
    """
    # termenv quantizes each channel to its nearest cube level and compares that one
    # cube color against one gray, by HSLuv distance. Rounding the channels separately
    # can land on a color of the wrong hue -- #993322 quantized to #875f00, an olive,
    # and lost to a gray -- so the box around the color is searched instead, and
    # CIEDE2000 replaces HSLuv distance, which rates pale colors as highly saturated.
    var R, G, B = color.to_rgb_tuple()
    var r = _lower_cube_level(R)
    var g = _lower_cube_level(G)
    var b = _lower_cube_level(B)

    # Candidates are compared in Lab; the palette's coordinates are precomputed, so
    # only the input is converted.
    var lab = color.to_Lab()
    var best = 16 + 36 * r + 6 * g + b
    var best_distance = _ciede2000(lab, _ansi256_lab(best))
    for ri in range(r, min(r + 1, 5) + 1):
        for gi in range(g, min(g + 1, 5) + 1):
            for bi in range(b, min(b + 1, 5) + 1):
                var index = 16 + 36 * ri + 6 * gi + bi
                var distance = _ciede2000(lab, _ansi256_lab(index))
                if distance < best_distance:
                    best = index
                    best_distance = distance

    # The gray candidates are centred on the ramp entry with the input's lightness,
    # not its channel average: saturated colors look lighter or darker than their
    # average suggests (a dark green is lighter than it), and the nearest gray tracks L*.
    # Ties go to the cube color, as they did in termenv.
    var gray_value = delinearize(lab_finv((lab.L + 0.16) / 1.16)) * 255.0
    var center = Int(clamp01((gray_value - 8.0) / 230.0) * 23.0 + 0.5)
    for gray in range(max(center - 1, 0), min(center + 1, 23) + 1):
        var distance = _ciede2000(lab, _ansi256_lab(232 + gray))
        if distance < best_distance:
            best = 232 + gray
            best_distance = distance

    return UInt8(best)


__enum Color(ImplicitlyCopyable, Writable):
    """`Color` is may be a `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`."""

    case ASCII
    case ANSI(UInt8)
    case ANSI256(UInt8)
    case RGB(UInt32)

    def write_to[T: Writer, //](self, mut writer: T):
        """Writes the ANSI Sequence for the color to a writer.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.to_hex_str())

    def sequence[is_background: Bool](self) -> String:
        """Sequence returns the ANSI Sequence for the color.

        Parameters:
            is_background: Whether the color is a background color.

        Returns:
            The ANSI Sequence for the color.
        """
        # Internal type is a variant, so these branches exhaustively match all types.
        match self:
            case .ASCII:
                return ""
            case .ANSI(value):
                return _ansi_sequence[is_background](value)
            case .ANSI256(value):
                return _ansi256_sequence[is_background](value)
            case .RGB(value):
                return _rgb_sequence[is_background](value)

    ############
    # Hex      #
    ############

    def to_hex(self) -> UInt32:
        """Converts red, green, and blue values to a number in hexadecimal format.

        Returns:
            The hexadecimal representation of the color.
        """
        var r, g, b = self.to_rgb_tuple()
        return UInt32((Int(r) << 16) | (Int(g) << 8) | Int(b))

    def to_hex_str(self) -> String:
        """Returns the hex string for the color, if it exists.

        Returns:
            The hex string for the color, or an empty string if the color cannot be represented as a hex string.
        """
        match self:
            case .ASCII:
                return ""
            case .ANSI(value):
                return hex_to_string(lut[ANSI_HEX_CODES](Int(value)), min_width=RGB_HEX_DIGITS)
            case .ANSI256(value):
                return hex_to_string(lut[ANSI_HEX_CODES](Int(value)), min_width=RGB_HEX_DIGITS)
            case .RGB(value):
                return hex_to_string(value, min_width=RGB_HEX_DIGITS)

    ############
    # RGB      #
    ############

    def to_rgb_tuple(self) -> Tuple[UInt8, UInt8, UInt8]:
        """Returns the RGB tuple for the color.

        Returns:
            The RGB tuple for the color.
        """
        match self:
            case .ASCII:
                return (0, 0, 0)
            case .ANSI(value):
                return hex_to_rgb(lut[ANSI_HEX_CODES](Int(value)))
            case .ANSI256(value):
                return _ansi256_to_rgb(value)
            case .RGB(value):
                return hex_to_rgb(value)

    def to_rgb(self) -> RGB[linear=False]:
        """Returns the RGB tuple for the color, with each component as a float in the range [0.0, 1.0].

        Returns:
            The RGB tuple for the color.
        """
        match self:
            case .ASCII:
                return RGB(0.0, 0.0, 0.0)
            case .ANSI(value):
                return RGB(hex_to_rgb(lut[ANSI_HEX_CODES](Int(value))))
            case .ANSI256(value):
                return RGB(_ansi256_to_rgb(value))
            case .RGB(value):
                return RGB(hex_to_rgb(value))

    def to_linear_rgb[fast: Bool = False](self) -> RGB[linear=True]:
        """Converts the color into the linear color space (see http://www.sjbrown.co.uk/2004/05/14/gamma-correct-rendering/).

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Returns:
            The linear RGB values.
        """
        return self.to_rgb().linearize[fast]()

    @staticmethod
    def from_rgb(r: UInt8, g: UInt8, b: UInt8) -> Self:
        """Creates a `Color` from red, green, and blue values.

        Args:
            r: The red value.
            g: The green value.
            b: The blue value.

        Returns:
            A `Color` Variant which may be `NoColor`, `ANSIColor`, `ANSI256Color`, or `RGBColor`.
        """
        return Color.RGB(rgb_to_hex(r, g, b))

    @staticmethod
    def from_rgb(r: Float64, g: Float64, b: Float64) -> Self:
        """Creates a `Color` from red, green, and blue values.

        Components outside [0.0, 1.0] are clamped, so colors that conversions from
        the perceptual spaces push out of the sRGB gamut land on its nearest edge.

        Args:
            r: The red value from 0.0 to 1.0.
            g: The green value from 0.0 to 1.0.
            b: The blue value from 0.0 to 1.0.

        Returns:
            A `Color.RGB` holding the color.
        """
        return Color.RGB(rgb_to_hex(_to_channel(r), _to_channel(g), _to_channel(b)))

    @staticmethod
    def from_rgb[linear: Bool, //, fast: Bool = False](rgb: RGB[linear]) -> Self:
        """Creates a `Color` from an `RGB` value, delinearizing it first if it is linear.

        Parameters:
            linear: Whether `rgb` holds linear RGB values.
            fast: If True, uses a faster but less accurate delinearization method.

        Args:
            rgb: The RGB color to convert.

        Returns:
            A `Color.RGB` holding the color.
        """
        var r = rgb.R
        var g = rgb.G
        var b = rgb.B
        comptime if linear:
            comptime if fast:
                return Self.from_rgb(delinearize_fast(r), delinearize_fast(g), delinearize_fast(b))
            else:
                return Self.from_rgb(delinearize(r), delinearize(g), delinearize(b))
        else:
            return Self.from_rgb(r, g, b)

    def distance_rgb(self, c2: Self) -> Float64:
        """Computes the distance between two colors in RGB space.
        This is not a good measure! Rather do it in Lab space.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in RGB space.
        """
        var rgb = self.to_rgb()
        var rgb2 = c2.to_rgb()
        return math.sqrt(sq(rgb.R - rgb2.R) + sq(rgb.G - rgb2.G) + sq(rgb.B - rgb2.B))

    def distance_linear_rgb[fast: Bool = False](self, c2: Self) -> Float64:
        """Computes the distance between two colors in linear RGB space.
        This is not useful for measuring how humans perceive color, but
        might be useful for other things, like dithering.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in linear RGB space.
        """
        # NOTE: If we start to see unusual results, switch to `linear_rgb` instead of `fast_linear_rgb`.
        var rgb = self.to_linear_rgb[fast]()
        var rgb2 = c2.to_linear_rgb[fast]()
        return math.sqrt(sq(rgb.R - rgb2.R) + sq(rgb.G - rgb2.G) + sq(rgb.B - rgb2.B))

    def distance_riemersma(self, c2: Self) -> Float64:
        """Color distance algorithm developed by Thiadmer Riemersma.
        It uses RGB coordinates, but he claims it has similar results to CIELUV.
        This makes it both fast and accurate.

        Sources: https://www.compuphase.com/cmetric.htm

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors.
        """
        var rgb = self.to_rgb()
        var rgb2 = c2.to_rgb()
        var rAvg = (rgb.R + rgb2.R) / 2.0

        # Deltas
        var dR = rgb.R - rgb2.R
        var dG = rgb.G - rgb2.G
        var dB = rgb.B - rgb2.B
        return math.sqrt(((2 + rAvg) * dR * dR) + (4 * dG * dG) + (2 + (1 - rAvg)) * dB * dB)

    def almost_equal_rgb(self, c2: Self) -> Bool:
        """Check for equality between colors within the tolerance Delta (1/255).

        Args:
            c2: The other color to compare to.

        Returns:
            Whether the two colors are almost equal.
        """
        var rgb = self.to_rgb()
        var rgb2 = c2.to_rgb()
        return abs(rgb.R - rgb2.R) + abs(rgb.G - rgb2.G) + abs(rgb.B - rgb2.B) < 3.0 * DELTA

    def blend_linear_rgb[fast: Bool = False](self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the Linear RGB color-space.
        Unlike `blend_rgb`, this will not produce dark color around the center.
        t == 0 results in c1, t == 1 results in c2.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var rgb = self.to_linear_rgb[fast]()
        var rgb2 = c2.to_linear_rgb[fast]()
        return Self.from_rgb[fast=fast](
            RGB[linear=True](
                rgb.R + t * (rgb2.R - rgb.R),
                rgb.G + t * (rgb2.G - rgb.G),
                rgb.B + t * (rgb2.B - rgb.B),
            )
        )

    ############
    # xyz      #
    ############

    def to_xyz[fast: Bool = False](self) -> xyz:
        """Converts the given color to CIE xyz space using D65 as reference white.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Returns:
            The xyz values.
        """
        return self.to_linear_rgb[fast]().to_xyz()

    @staticmethod
    def from_xyz(x: Float64, y: Float64, z: Float64) -> Self:
        """Generates a color by using data given in CIE xyz space.

        Args:
            x: The x value.
            y: The y value.
            z: The z value.

        Returns:
            The new Color.
        """
        return Self.from_xyz(xyz(x, y, z))

    @staticmethod
    def from_xyz(value: xyz) -> Self:
        """Generates a color from CIE XYZ space.

        Args:
            value: The color in CIE XYZ space.

        Returns:
            The new Color.
        """
        return Self.from_rgb(value.to_linear_rgb())

    ############
    # Luv      #
    ############

    def to_Luv[fast: Bool = False](self, white_ref: WhiteReference = D65) -> Luv:
        """Converts the given color to CIE L*u*v* space, taking into account
        a given reference white. (i.e. the monitor's white)
        L* is in [0..1] and both u* and v* are in about [-1..1].

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The Luminance, u, and v values.
        """
        return self.to_xyz[fast]().to_Luv(white_ref)

    @staticmethod
    def from_Luv(l: Float64, u: Float64, v: Float64, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color by using data given in CIE L*u*v* space, taking
        into account a given reference white. (i.e. the monitor's white)
        L* is in [0..1] and both u* and v* are in about [-1..1].

        Args:
            l: The L* value.
            u: The u* value.
            v: The v* value.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_Luv(Luv(l, u, v), white_ref=white_ref)

    @staticmethod
    def from_Luv(value: Luv, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color from CIE L*u*v* space.
        The reference white is the one the coordinates were computed against (i.e. the monitor's white).

        Args:
            value: The color in CIE L*u*v* space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_xyz(value.to_xyz(white_ref))

    def distance_Luv(self, c2: Self) -> Float64:
        """Good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in Luv space.
        """
        var luv = self.to_Luv()
        var luv2 = c2.to_Luv()
        return math.sqrt(sq(luv.L - luv2.L) + sq(luv.u - luv2.u) + sq(luv.v - luv2.v))

    def blend_Luv[fast: Bool = False](self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the CIE-L*u*v* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var luv = self.to_Luv[fast]()
        var luv2 = c2.to_Luv[fast]()

        return Self.from_Luv(luv.L + t * (luv2.L - luv.L), luv.u + t * (luv2.u - luv.u), luv.v + t * (luv2.v - luv.v))

    ############
    # LuvLCh   #
    ############

    def to_LuvLCh[fast: Bool = False](self, white_ref: WhiteReference = D65) -> LuvLCh:
        """Converts the given color to CIE LuvLCh space, taking into account
        a given reference white. (i.e. the monitor's white).

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        return self.to_Luv[fast](white_ref=white_ref).to_LuvLCh()

    @staticmethod
    def from_LuvLCh(l: Float64, c: Float64, h: Float64, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color by using data given in LuvLCh space, taking
        into account a given reference white. (i.e. the monitor's white)
        h values are in [0..360], C and L values are in [0..1].

        Args:
            l: The Luminance in [0..1].
            c: The Chroma in [0..1].
            h: The Hue in [0..360].
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_LuvLCh(LuvLCh(l, c, h), white_ref=white_ref)

    @staticmethod
    def from_LuvLCh(value: LuvLCh, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color from CIE LCh(uv) space.

        Args:
            value: The color in CIE LCh(uv) space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_Luv(value.to_Luv(), white_ref=white_ref)

    def blend_Luv_LCh(self, other: Self, t: Float64) -> Self:
        """Blends two colors in the cylindrical CIELUV color space.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            other: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var lch = self.to_LuvLCh()
        var lch2 = other.to_LuvLCh()

        # We know that h are both in [0..360]
        return Self.from_LuvLCh(
            lch.L + t * (lch2.L - lch.L), lch.C + t * (lch2.C - lch.C), interp_angle(lch.h, lch2.h, t)
        )

    ############
    # HSLuv    #
    ############

    def to_HSLuv[fast: Bool = False](self, white_ref: WhiteReference = hSLuvD65) -> HSLuv:
        """Order: sColor -> Linear Color -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv.
        HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (luminance) in [0..1].

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The Hue, Saturation, and Luminance values.
        """
        return self.to_LuvLCh[fast](white_ref).to_HSLuv()

    @staticmethod
    def from_HSLuv(h: Float64, s: Float64, l: Float64, *, white_ref: WhiteReference = hSLuvD65) -> Self:
        """Generates a color from HSLuv values: Hue in [0..360], Saturation and Luminance in [0..1].

        Args:
            h: The Hue in [0..360].
            s: The Saturation in [0..1].
            l: The Luminance in [0..1].
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_HSLuv(HSLuv(h, s, l), white_ref=white_ref)

    @staticmethod
    def from_HSLuv(value: HSLuv, *, white_ref: WhiteReference = hSLuvD65) -> Self:
        """Generates a color from HSLuv space.

        Args:
            value: The color in HSLuv space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_LuvLCh(value.to_LuvLCh(), white_ref=white_ref)

    def to_hsl(self) -> HSL:
        """Converts the color to HSL: Hue [0..360], Saturation [0..1], and Lightness [0..1].

        This is the classic hexcone model computed from gamma-encoded sRGB, not the
        perceptual HSLuv space; see `to_HSLuv` for that.

        Returns:
            The Hue, Saturation, and Lightness values.
        """
        var r, g, b = self.to_rgb_tuple()
        var R = Float64(r) / 255.0
        var G = Float64(g) / 255.0
        var B = Float64(b) / 255.0

        var min = min(min(R, G), B)
        var max = max(max(R, G), B)

        var l = (max + min) / 2.0

        if min == max:
            return HSL(0.0, 0.0, l)

        var s: Float64
        if l < 0.5:
            s = (max - min) / (max + min)
        else:
            s = (max - min) / (2.0 - max - min)

        var h: Float64
        if max == R:
            h = (G - B) / (max - min)
        elif max == G:
            h = 2.0 + (B - R) / (max - min)
        else:
            h = 4.0 + (R - G) / (max - min)

        h *= 60.0

        if h < 0.0:
            h += 360.0

        return HSL(h, s, l)

    def distance_HSLuv(self, c2: Self) -> Float64:
        """Computes the distance between two colors in HSLuv space.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in HSLuv space.
        """
        return _hsluv_distance(self.to_HSLuv(), c2.to_HSLuv())

    ############
    # HPLuv    #
    ############

    def to_HPLuv[fast: Bool = False](self, white_ref: WhiteReference = hSLuvD65) -> HPLuv:
        """HPLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (luminance) in [0..1].

        Note that HPLuv can only represent pastel colors, and so the Saturation
        value could be much larger than 1 for colors it can't represent.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The Hue, Saturation, and Luminance values.
        """
        return self.to_LuvLCh[fast](white_ref).to_HPLuv()

    @staticmethod
    def from_HPLuv(h: Float64, p: Float64, l: Float64, *, white_ref: WhiteReference = hSLuvD65) -> Self:
        """Generates a color from HPLuv values: Hue in [0..360], Saturation and Luminance in [0..1].
        HPLuv only represents pastel colors, so `p` above 1 leaves the sRGB gamut and the
        result is clamped to its edge.

        Args:
            h: The Hue in [0..360].
            p: The Saturation in [0..1]; values above 1 are outside the sRGB gamut and clamp.
            l: The Luminance in [0..1].
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_HPLuv(HPLuv(h, p, l), white_ref=white_ref)

    @staticmethod
    def from_HPLuv(value: HPLuv, *, white_ref: WhiteReference = hSLuvD65) -> Self:
        """Generates a color from HPLuv space.

        Args:
            value: The color in HPLuv space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_LuvLCh(value.to_LuvLCh(), white_ref=white_ref)

    ############
    # HSV      #
    ############
    # From http://en.wikipedia.org/wiki/HSL_and_HSV
    # Note that h is in [0..360] and s,v in [0..1]

    def to_HSV(self) -> HSV:
        """HSV returns the Hue [0..360], Saturation and Value [0..1] of the color.

        Returns:
            The Hue, Saturation, and Value values.
        """
        var rgb = self.to_rgb()
        var R = rgb.R
        var G = rgb.G
        var B = rgb.B
        var min = min(min(R, G), B)
        var v = max(max(R, G), B)
        var C = v - min

        var s = 0.0
        if v != 0.0:
            s = C / v

        var h = 0.0  # We use 0 instead of undefined as in wp.
        if min != v:
            if v == R:
                h = (G - B) / C % 6.0
            if v == G:
                h = (B - R) / C + 2.0
            if v == B:
                h = (R - G) / C + 4.0
            h *= 60.0
            if h < 0.0:
                h += 360.0
        return HSV(h, s, v)

    @staticmethod
    def from_hsv(h: Float64, s: Float64, v: Float64) -> Self:
        """Creates a new Color given a Hue in [0..360], a Saturation and a Value in [0..1].

        Args:
            h: The Hue in [0..360].
            s: The Saturation in [0..1].
            v: The Value in [0..1].

        Returns:
            The new Color.
        """
        var hp = h / 60.0
        var C = v * s
        var X = C * (1.0 - abs((hp % 2.0) - 1.0))
        var m = v - C
        var r = 0.0
        var g = 0.0
        var b = 0.0

        if 0.0 <= hp and hp < 1.0:
            r = C
            g = X
        elif 1.0 <= hp and hp < 2.0:
            r = X
            g = C
        elif 2.0 <= hp and hp < 3.0:
            g = C
            b = X
        elif 3.0 <= hp and hp < 4.0:
            g = X
            b = C
        elif 4.0 <= hp and hp < 5.0:
            r = X
            b = C
        elif 5.0 <= hp and hp < 6.0:
            r = C
            b = X

        return Self.from_rgb(m + r, m + g, m + b)

    @staticmethod
    def from_hsv(value: HSV) -> Self:
        """Generates a color from HSV space.

        Args:
            value: The color in HSV space.

        Returns:
            The new Color.
        """
        return Self.from_hsv(value.H, value.S, value.V)

    ############
    # HSL      #
    ############

    @staticmethod
    def from_hsl(var h: Float64, s: Float64, l: Float64) -> Self:
        """Creates a new Color given a Hue in [0..360], a Saturation [0..1], and a Luminance (luminance) in [0..1].

        Args:
            h: The Hue in [0..360].
            s: The Saturation in [0..1].
            l: The Luminance in [0..1].

        Returns:
            The new Color.
        """
        if s == 0:
            return Self.from_rgb(l, l, l)

        var r: Float64
        var g: Float64
        var b: Float64
        var t1: Float64
        var t2: Float64
        var tr: Float64
        var tg: Float64
        var tb: Float64

        if l < 0.5:
            t1 = l * (1.0 + s)
        else:
            t1 = l + s - l * s

        t2 = 2 * l - t1
        h /= 360
        tr = h + 1.0 / 3.0
        tg = h
        tb = h - 1.0 / 3.0

        if tr < 0:
            tr += 1
        if tr > 1:
            tr -= 1
        if tg < 0:
            tg += 1
        if tg > 1:
            tg -= 1
        if tb < 0:
            tb += 1
        if tb > 1:
            tb -= 1

        # Red
        if 6 * tr < 1:
            r = t2 + (t1 - t2) * 6 * tr
        elif 2 * tr < 1:
            r = t1
        elif 3 * tr < 2:
            r = t2 + (t1 - t2) * (2.0 / 3.0 - tr) * 6
        else:
            r = t2

        # Green
        if 6 * tg < 1:
            g = t2 + (t1 - t2) * 6 * tg
        elif 2 * tg < 1:
            g = t1
        elif 3 * tg < 2:
            g = t2 + (t1 - t2) * (2.0 / 3.0 - tg) * 6
        else:
            g = t2

        # Blue
        if 6 * tb < 1:
            b = t2 + (t1 - t2) * 6 * tb
        elif 2 * tb < 1:
            b = t1
        elif 3 * tb < 2:
            b = t2 + (t1 - t2) * (2.0 / 3.0 - tb) * 6
        else:
            b = t2

        return Self.from_rgb(r, g, b)

    @staticmethod
    def from_hsl(value: HSL) -> Self:
        """Generates a color from HSL space.

        Args:
            value: The color in HSL space.

        Returns:
            The new Color.
        """
        return Self.from_hsl(value.H, value.S, value.L)

    ############
    # xyY      #
    ############

    def to_xyY[fast: Bool = False](self, white_ref: WhiteReference = D65) -> xyY:
        """Converts the given color to CIE xyY space using `D65` as reference white.
        (Note that the reference white is only used for black input.)
        x, y and Y are in [0..1].

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The xyY values.
        """
        return self.to_xyz[fast]().to_xyY(white_ref=white_ref)

    @staticmethod
    def from_xyY(x: Float64, y: Float64, Y: Float64) -> Self:
        """Generates a color by using data given in CIE xyY space.

        Args:
            x: The x value.
            y: The y value.
            Y: The Y value.

        Returns:
            The new Color.
        """
        return Self.from_xyY(xyY(x, y, Y))

    @staticmethod
    def from_xyY(value: xyY) -> Self:
        """Generates a color from CIE xyY space.

        Args:
            value: The color in CIE xyY space.

        Returns:
            The new Color.
        """
        return Self.from_xyz(value.to_xyz())

    ############
    # Lab      #
    ############

    def to_Lab[fast: Bool = False](self, white_ref: WhiteReference = D65) -> Lab:
        """Converts the given color to CIE L*a*b* space, taking into account
        a given reference white. (i.e. the monitor's white).

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            white_ref: The reference white.

        Returns:
            The L*a*b* values.
        """
        return self.to_xyz[fast]().to_Lab(white_ref=white_ref)

    @staticmethod
    def from_Lab(L: Float64, a: Float64, b: Float64, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color by using data given in CIE L*a*b* space, taking
        into account a given reference white. (i.e. the monitor's white).

        Args:
            L: The Luminance value.
            a: The a* value.
            b: The b* value.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_Lab(Lab(L, a, b), white_ref=white_ref)

    @staticmethod
    def from_Lab(value: Lab, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color from CIE L*a*b* space.

        Args:
            value: The color in CIE L*a*b* space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_xyz(value.to_xyz(white_ref))

    def distance_lab[fast: Bool = False](self, other: Self) -> Float64:
        """`distance_Lab` is a good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        var lab = self.to_Lab[fast]()
        var lab2 = other.to_Lab[fast]()
        return math.sqrt(sq(lab.L - lab2.L) + sq(lab.a - lab2.a) + sq(lab.b - lab2.b))

    def distance_cie76[fast: Bool = False](self, other: Self) -> Float64:
        """Same as `distance_Lab`.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        return self.distance_lab[fast](other)

    def distance_cie94[fast: Bool = False](self, other: Self) -> Float64:
        """Uses the CIE94 formula to calculate color distance. More accurate than
        `distance_Lab`, but also more work.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        var Lab = self.to_Lab[fast]()
        var Lab2 = other.to_Lab[fast]()

        # NOTE: Since all those formulas expect L,a,b values 100x larger than we
        #       have them in this library, we either need to adjust all constants
        #       in the formula, or convert the ranges of L,a,b before, and then
        #       scale the distances down again. The latter is less error-prone.
        var l1 = Lab.L * 100.0
        var a1 = Lab.a * 100.0
        var b1 = Lab.b * 100.0
        var l2 = Lab2.L * 100.0
        var a2 = Lab2.a * 100.0
        var b2 = Lab2.b * 100.0

        comptime kl = 1.0  # 2.0 for textiles
        comptime kc = 1.0
        comptime kh = 1.0
        comptime k1 = 0.045  # 0.048 for textiles
        comptime k2 = 0.015  # 0.014 for textiles.

        var delta_L = l1 - l2
        var c1 = math.sqrt(sq(a1) + sq(b1))
        var c2 = math.sqrt(sq(a2) + sq(b2))
        var delta_Cab = c1 - c2

        # Not taking Sqrt here for stability, and it's unnecessary.
        var deltaHab2 = sq(a1 - a2) + sq(b1 - b2) - sq(delta_Cab)
        comptime sl = 1.0
        var sc = 1.0 + k1 * c1
        var sh = 1.0 + k2 * c1

        var vL2 = sq(delta_L / (kl * sl))
        var vC2 = sq(delta_Cab / (kc * sc))
        var vH2 = deltaHab2 / sq(kh * sh)

        return math.sqrt(vL2 + vC2 + vH2) * 0.01  # See above.

    def distance_ciede2000[fast: Bool = False](self, other: Self) -> Float64:
        """Uses the Delta E 2000 formula to calculate color
        distance. It is more expensive but more accurate than both `distance_Lab`
        and `distance_CIE94`.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        return self.distance_ciede2000klch[fast](other, 1.0, 1.0, 1.0)

    def distance_ciede2000klch[fast: Bool = False](self, other: Self, kl: Float64, kc: Float64, kh: Float64) -> Float64:
        """Uses the Delta E 2000 formula with custom values
        for the weighting factors kL, kC, and kH.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Args:
            other: The other color to compare to.
            kl: The weighting factor for luminance.
            kc: The weighting factor for chroma.
            kh: The weighting factor for hue.

        Returns:
            The distance between the two colors in Lab space.
        """
        return _ciede2000(self.to_Lab[fast](), other.to_Lab[fast](), kl, kc, kh)

    def blend_lab(self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the L*a*b* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var Lab = self.to_Lab()
        var Lab2 = c2.to_Lab()

        return Self.from_Lab(Lab.L + t * (Lab2.L - Lab.L), Lab.a + t * (Lab2.a - Lab.a), Lab.b + t * (Lab2.b - Lab.b))

    ############
    # hcl      #
    ############

    def to_hcl(self, white_ref: WhiteReference = D65) -> hcl:
        """Converts the given color to HCL space using `D65` as reference white.
        H values are in [0..360], C and L values are in [0..1] although C can overshoot 1.0.

        Args:
            white_ref: The reference white.

        Returns:
            The Hue, Chroma, and Luminance values.
        """
        return self.to_Lab(white_ref).to_hcl()

    @staticmethod
    def from_hcl(h: Float64, c: Float64, l: Float64, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color by using data given in HCL space using `D65` as reference white.
        H values are in [0..360], C and L values are in [0..1]
        WARNING: many combinations of `h`, `c`, and `l` values do not have corresponding
        valid RGB values.

        Args:
            h: The Hue in [0..360].
            c: The Chroma in [0..1].
            l: The Luminance in [0..1].
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_hcl(hcl(h, c, l), white_ref=white_ref)

    @staticmethod
    def from_hcl(value: hcl, *, white_ref: WhiteReference = D65) -> Self:
        """Generates a color from HCL space.

        Args:
            value: The color in HCL space.
            white_ref: The reference white.

        Returns:
            The new Color.
        """
        return Self.from_Lab(value.to_Lab(), white_ref=white_ref)

    def blend_hcl(self, other: Self, t: Float64) -> Self:
        """BlendHcl blends two colors in the CIE-L*C*h° color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            other: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var hcl = self.to_hcl()
        var hcl2 = other.to_hcl()
        var h1 = hcl.h
        var h2 = hcl2.h

        if hcl.c <= 0.00015 and hcl2.c >= 0.00015:
            h1 = h2
        elif hcl2.c <= 0.00015 and hcl.c >= 0.00015:
            h2 = h1

        # We know that h are both in [0..360]
        return Self.from_hcl(interp_angle(h1, h2, t), hcl.c + t * (hcl2.c - hcl.c), hcl.l + t * (hcl2.l - hcl.l))
