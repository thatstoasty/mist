import math
from collections import InlineArray
from os import abort
from sys import is_compile_time

from utils.numerics import max_finite


@always_inline
fn sq(v: Float64) -> Float64:
    """Returns the square of the given value.

    Args:
        v: The value to square.

    Returns:
        The square of the given value.
    """
    return v * v


@always_inline
fn clamp01(v: Float64) -> Float64:
    """Clamps from 0 to 1.

    Args:
        v: The value to clamp.

    Returns:
        The clamped value.
    """
    return math.clamp(v, 0.0, 1.0)


alias MAX_FLOAT64: Float64 = max_finite[DType.float64]()
"""The maximum value of a 64-bit floating-point number."""

# This is the tolerance used when comparing colors using AlmostEqualColor.
alias DELTA = 1.0 / 255.0
"""The tolerance used when comparing colors using `AlmostEqualColor`."""

# This is the default reference white point.
alias D65: InlineArray[Float64, 3] = [0.95047, 1.00000, 1.08883]
"""The default reference white point, D65."""

alias XYZ_TO_RGB_MATRIX: InlineArray[InlineArray[Float64, 3], 3] = [
    [3.2409699419045214, -1.5373831775700935, -0.49861076029300328],
    [-0.96924363628087983, 1.8759675015077207, 0.041555057407175613],
    [0.055630079696993609, -0.20397695888897657, 1.0569715142428786],
]
"""The matrix used to convert from XYZ to RGB."""
alias hSLuvD65: InlineArray[Float64, 3] = [0.95045592705167, 1.0, 1.089057750759878]
"""The reference white point for HSLuv, D65."""

alias KAPPA = 903.2962962962963
"""The value of Kappa used in the CIE Luv color space."""
alias EPSILON = 0.0088564516790356308
"""The value of Epsilon used in the CIE Luv color space."""


fn length_of_ray_until_intersect(theta: Float64, x: Float64, y: Float64) -> Float64:
    """Returns the length of the ray until it intersects with the line at the given angle.

    Args:
        theta: The angle of the ray.
        x: The x-coordinate of the line.
        y: The y-coordinate of the line.

    Returns:
        The length of the ray until it intersects with the line.
    """
    return y / (math.sin(theta) - x * math.cos(theta))


fn get_bounds(l: Float64) -> InlineArray[InlineArray[Float64, 2], 6]:
    """Returns the bounds for the given luminance value.

    Args:
        l: The luminance value.

    Returns:
        The bounds for the given luminance value.
    """
    var ret: InlineArray[InlineArray[Float64, 2], 6] = [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
    ]

    var sub_1 = (l + 16.0**3.0) / 1560896.0
    var sub_2 = sub_1 if sub_1 > EPSILON else l / KAPPA

    @parameter
    for i in range(len(XYZ_TO_RGB_MATRIX)):
        var k = 0
        while k < 2:
            var top1 = (284517.0 * XYZ_TO_RGB_MATRIX[i][0] - 94839.0 * XYZ_TO_RGB_MATRIX[i][2]) * sub_2
            var top2 = (
                838422.0 * XYZ_TO_RGB_MATRIX[i][2]
                + 769860.0 * XYZ_TO_RGB_MATRIX[i][1]
                + 731718.0 * XYZ_TO_RGB_MATRIX[i][0]
            ) * l * sub_2 - 769860.0 * Float64(k) * l
            var bottom = (
                632260.0 * XYZ_TO_RGB_MATRIX[i][2] - 126452.0 * XYZ_TO_RGB_MATRIX[i][1]
            ) * sub_2 + 126452.0 * Float64(k)
            ret[i * 2 + k][0] = top1 / bottom
            ret[i * 2 + k][1] = top2 / bottom
            k += 1

    return ret^


@always_inline
fn intersection_of_two_lines(x1: Float64, y1: Float64, x2: Float64, y2: Float64) -> Float64:
    """Returns the intersection of two lines.

    Args:
        x1: The x-coordinate of the first line.
        y1: The y-coordinate of the first line.
        x2: The x-coordinate of the second line.
        y2: The y-coordinate of the second line.

    Returns:
        The intersection of the two lines.
    """
    return (y1 - y2) / (x2 - x1)


@always_inline
fn distance_from_pole(x: Float64, y: Float64) -> Float64:
    """Returns the distance from the pole.

    Args:
        x: The x-coordinate.
        y: The y-coordinate.

    Returns:
        The distance from the pole.
    """
    return math.sqrt(x**2 + y**2)


fn max_chroma_for_lh(l: Float64, h: Float64) -> Float64:
    """Returns the maximum chroma for the given luminance and hue.

    Args:
        l: The luminance value.
        h: The hue value.

    Returns:
        The maximum chroma for the given luminance and hue.
    """
    var h_rad = h / 360.0 * math.pi * 2.0
    var min_length = MAX_FLOAT64
    var bounds = get_bounds(l)

    for i in range(len(bounds)):
        var length = length_of_ray_until_intersect(h_rad, bounds[i][0], bounds[i][1])
        if length > 0.0 and length < min_length:
            min_length = length

    return min_length


fn max_safe_chroma_for_l(l: Float64) -> Float64:
    """Returns the maximum safe chroma for the given luminance.

    Args:
        l: The luminance value.

    Returns:
        The maximum safe chroma for the given luminance.
    """
    var minimum_length = MAX_FLOAT64
    var bounds = get_bounds(l)
    for i in range(len(bounds)):
        var m1 = bounds[i][0]
        var b1 = bounds[i][1]
        var x = intersection_of_two_lines(m1, b1, -1.0 / m1, 0.0)
        var dist = distance_from_pole(x, b1 + x * m1)
        if dist < minimum_length:
            minimum_length = dist
    return minimum_length


fn LuvLCh_to_HPLuv(var l: Float64, var c: Float64, h: Float64) -> (Float64, Float64, Float64):
    """Converts the given LuvLCh color to HPLuv.
    [-1..1] but the code expects it to be [-100..100].

    Args:
        l: The luminance value.
        c: The chroma value.
        h: The hue value.

    Returns:
        The hue, saturation, and luminance values.
    """
    c *= 100.0
    l *= 100.0

    var s = 0.0 if (l > 99.9999999 or l < 0.00000001) else (c / max_safe_chroma_for_l(l) * 100.0)
    return h, s / 100.0, l / 100.0


fn LuvLch_to_HSLuv(var l: Float64, var c: Float64, h: Float64) -> (Float64, Float64, Float64):
    """Converts the given LuvLCh color to HSLuv.
    [-1..1] but the code expects it to be [-100..100].

    Args:
        l: The luminance value.
        c: The chroma value.
        h: The hue value.

    Returns:
        The hue, saturation, and luminance values.
    """
    # [-1..1] but the code expects it to be [-100..100]
    l *= 100.0
    c *= 100.0

    var s = 0.0
    if l < 99.9999999 and l > 0.00000001:
        s = c / max_chroma_for_lh(l, h) * 100.0

    return h, clamp01(s / 100.0), clamp01(l / 100.0)


@fieldwise_init
@register_passable("trivial")
struct Color(Copyable, Movable, Representable, Stringable):
    """A color represented by red, green, and blue values.
    RGB values are stored internally using sRGB (standard RGB) values in the range 0-1.
    """

    var R: Float64
    """The red value, between 0 to 1."""
    var G: Float64
    """The green value, between 0 to 1."""
    var B: Float64
    """The blue value, between 0 to 1."""

    fn __init__(out self, other: Self):
        """Initializes a new `Color` by copying the values from another `Color`.

        Args:
            other: The other `Color` to copy the values from.
        """
        self.R = other.R
        self.G = other.G
        self.B = other.B

    fn __init__(out self, R: UInt8, G: UInt8, B: UInt8):
        """Initializes a new `Color` with the given red, green, and blue values.

        Args:
            R: The red value, between 0 and 255.
            G: The green value, between 0 and 255.
            B: The blue value, between 0 and 255.
        """
        self.R = R.cast[DType.float64]() / 255.0
        self.G = G.cast[DType.float64]() / 255.0
        self.B = B.cast[DType.float64]() / 255.0

    fn __init__(out self, rgb: Tuple[UInt8, UInt8, UInt8]):
        """Initializes a new `Color` with the given red, green, and blue values.

        Args:
            rgb: The red, green, and blue values.
        """
        self.R = rgb[0].cast[DType.float64]() / 255.0
        self.G = rgb[1].cast[DType.float64]() / 255.0
        self.B = rgb[2].cast[DType.float64]() / 255.0

    fn __init__(out self, hex: UInt32):
        """Initializes a new `Color` with the given hex value.

        Args:
            hex: The hex value.
        """
        # Downcast to UInt8 to ensure the values are in the correct range, 0-255.
        # Better to truncate down to 255 rather than try to handle unexpectedly large values.
        self.R = (hex >> 16).cast[DType.uint8]().cast[DType.float64]() / 255.0
        self.G = (hex >> 8 & 0xFF).cast[DType.uint8]().cast[DType.float64]() / 255.0
        self.B = (hex & 0xFF).cast[DType.uint8]().cast[DType.float64]() / 255.0

    fn __str__(self) -> String:
        """Returns the string representation of the color.

        Returns:
            The string representation of the color.
        """
        return String("Color(", self.R, ", ", self.G, ", ", self.B, ")")

    fn __repr__(self) -> String:
        """Returns the string representation of the color.

        Returns:
            The string representation of the color.
        """
        return String("Color(", self.R, ", ", self.G, ", ", self.B, ")")

    fn hex(self) -> UInt32:
        """Converts red, green, and blue values to a number in hexadecimal format.

        Returns:
            The hexadecimal representation of the color.
        """
        return (Int(self.R * 255.0) << 16) | (Int(self.G * 255.0) << 8) | Int(self.B * 255.0)

    fn linear_rgb(self) -> (Float64, Float64, Float64):
        """Converts the color into the linear color space (see http://www.sjbrown.co.uk/2004/05/14/gamma-correct-rendering/).

        Returns:
            The linear RGB values.
        """
        return linearize(self.R), linearize(self.G), linearize(self.B)

    fn xyz(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE XYZ space using D65 as reference white.

        Returns:
            The XYZ values.
        """
        var rgb = self.linear_rgb()
        return linear_rgb_to_xyz(rgb[0], rgb[1], rgb[2])

    fn Luv_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*u*v* space, taking into account
        a given reference white. (i.e. the monitor's white)
        L* is in [0..1] and both u* and v* are in about [-1..1].

        Args:
            wref: The reference white.

        Returns:
            The Luminance, u, and v values.
        """
        var xyz = self.xyz()
        return xyz_to_Luv_white_ref(xyz[0], xyz[1], xyz[2], wref)

    fn LuvLCh_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE LuvLCh space, taking into account
        a given reference white. (i.e. the monitor's white).

        Args:
            wref: The reference white.

        Returns:
            The LuvLCh values.
        """
        var luv = self.Luv_white_ref(wref)
        return Luv_To_LuvLCh(luv[0], luv[1], luv[2])

    fn HSLuv(self) -> (Float64, Float64, Float64):
        """Order: sColor -> Linear Color -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv.
        HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (luminance) in [0..1].

        Returns:
            The Hue, Saturation, and Luminance values.
        """
        var lch = self.LuvLCh_white_ref(hSLuvD65)
        return LuvLch_to_HSLuv(lch[0], lch[1], lch[2])

    fn distance_HSLuv(self, c2: Self) -> Float64:
        """Computes the distance between two colors in HSLuv space.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in HSLuv space.
        """
        var hsl = self.HSLuv()
        var hsl2 = c2.HSLuv()
        return math.sqrt(((hsl[0] - hsl2[0]) / 100.0) ** 2 + (hsl[1] - hsl2[1]) ** 2 + (hsl[2] - hsl2[2]) ** 2)

    fn is_valid(self) -> Bool:
        """Checks whether the color exists in RGB space, i.e. all values are in [0..1].

        Returns:
            Whether the color is valid.
        """
        return 0.0 <= self.R and self.R <= 1.0 and 0.0 <= self.G and self.G <= 1.0 and 0.0 <= self.B and self.B <= 1.0

    fn clamped(self) -> Self:
        """Clamps the color to the [0..1] range. If the color is valid already, this is a no-op.

        Returns:
            The clamped color.
        """
        return Color(clamp01(self.R), clamp01(self.G), clamp01(self.B))

    fn distance_rgb(self, c2: Self) -> Float64:
        """Computes the distance between two colors in RGB space.
        This is not a good measure! Rather do it in Lab space.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in RGB space.
        """
        return math.sqrt(sq(self.R - c2.R) + sq(self.G - c2.G) + sq(self.B - c2.B))

    fn distance_linear_rgb(self, c2: Self) -> Float64:
        """Computes the distance between two colors in linear RGB space.
        This is not useful for measuring how humans perceive color, but
        might be useful for other things, like dithering.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in linear RGB space.
        """
        # NOTE: If we start to see unusual results, switch to `linear_rgb` instead of `fast_linear_rgb`.
        var rgb = self.linear_rgb()
        var rgb2 = c2.linear_rgb()
        return math.sqrt(sq(rgb[0] - rgb2[0]) + sq(rgb[1] - rgb2[1]) + sq(rgb[2] - rgb2[2]))

    fn distance_riemersma(self, c2: Self) -> Float64:
        """Color distance algorithm developed by Thiadmer Riemersma.
        It uses RGB coordinates, but he claims it has similar results to CIELUV.
        This makes it both fast and accurate.

        Sources: https://www.compuphase.com/cmetric.htm

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors.
        """
        var rAvg = (self.R + c2.R) / 2.0
        # Deltas
        var dR = self.R - c2.R
        var dG = self.G - c2.G
        var dB = self.B - c2.B
        return math.sqrt(((2 + rAvg) * dR * dR) + (4 * dG * dG) + (2 + (1 - rAvg)) * dB * dB)

    fn almost_equal_rgb(self, c2: Self) -> Bool:
        """Check for equality between colors within the tolerance Delta (1/255).

        Args:
            c2: The other color to compare to.

        Returns:
            Whether the two colors are almost equal.
        """
        return abs(self.R - c2.R) + abs(self.G - c2.G) + abs(self.B - c2.B) < 3.0 * DELTA

    fn hsv(self) -> (Float64, Float64, Float64):
        """Hsv returns the Hue [0..360], Saturation and Value [0..1] of the color.

        Returns:
            The Hue, Saturation, and Value values.
        """
        var min = min(min(self.R, self.G), self.B)
        var v = max(max(self.R, self.G), self.B)
        var C = v - min

        var s = 0.0
        if v != 0.0:
            s = C / v

        var h = 0.0  # We use 0 instead of undefined as in wp.
        if min != v:
            if v == self.R:
                h = (self.G - self.B) / C % 6.0
            if v == self.G:
                h = (self.B - self.R) / C + 2.0
            if v == self.B:
                h = (self.R - self.G) / C + 4.0
            h *= 60.0
            if h < 0.0:
                h += 360.0
        return h, s, v

    fn hsl(self) -> (Float64, Float64, Float64):
        """Hsl returns the Hue [0..360], Saturation [0..1], and Luminance (luminance) [0..1] of the color.

        Returns:
            The Hue, Saturation, and Luminance values.
        """
        var min = min(min(self.R, self.G), self.B)
        var max = max(max(self.R, self.G), self.B)

        var l = (max + min) / 2.0

        if min == max:
            return 0.0, 0.0, l

        var s: Float64
        if l < 0.5:
            s = (max - min) / (max + min)
        else:
            s = (max - min) / (2.0 - max - min)

        var h: Float64
        if max == self.R:
            h = (self.G - self.B) / (max - min)
        elif max == self.G:
            h = 2.0 + (self.B - self.R) / (max - min)
        else:
            h = 4.0 + (self.R - self.G) / (max - min)

        h *= 60.0

        if h < 0.0:
            h += 360.0

        return h, s, l

    fn fast_linear_rgb(self) -> (Float64, Float64, Float64):
        """Is much faster than and almost as accurate as `linear_rgb`.
        BUT it is important to NOTE that they only produce good results for valid colors r,g,b in [0,1].

        Returns:
            The linear RGB values.
        """
        return linearize_fast(self.R), linearize_fast(self.G), linearize_fast(self.B)

    fn blend_linear_rgb(self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the Linear RGB color-space.
        Unlike `blend_rgb`, this will not produce dark color around the center.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var rgb = self.linear_rgb()
        var rgb2 = c2.linear_rgb()
        return fast_linear_rgb(
            rgb[0] + t * (rgb2[0] - rgb[0]),
            rgb[1] + t * (rgb2[1] - rgb[1]),
            rgb[2] + t * (rgb2[2] - rgb[2]),
        )

    fn xyy(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE xyY space using `D65` as reference white.
        (Note that the reference white is only used for black input.)
        x, y and Y are in [0..1].

        Returns:
            The xyY values.
        """
        var XYZ = self.xyz()
        return xyz_to_xyY(XYZ[0], XYZ[1], XYZ[2])

    fn xyy_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE xyY space, taking into account
        a given reference white. (i.e. the monitor's white)
        (Note that the reference white is only used for black input.)
        x, y and Y are in [0..1].

        Args:
            wref: The reference white.

        Returns:
            The xyY values.
        """
        var XY2Z = self.xyz()
        return xyz_to_xyY_white_ref(XY2Z[0], XY2Z[1], XY2Z[2], wref)

    fn lab(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*a*b* space using D65 as reference white.

        Returns:
            The L*a*b* values.
        """
        var xyz = self.xyz()
        return xyz_to_lab(xyz[0], xyz[1], xyz[2])

    fn lab_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*a*b* space, taking into account
        a given reference white. (i.e. the monitor's white).

        Args:
            wref: The reference white.

        Returns:
            The L*a*b* values.
        """
        var xyz = self.xyz()
        return xyz_to_lab_white_ref(xyz[0], xyz[1], xyz[2], wref)

    fn distance_lab(self, other: Self) -> Float64:
        """`distance_Lab` is a good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        var lab = self.lab()
        var lab2 = other.lab()
        return math.sqrt(sq(lab[0] - lab2[0]) + sq(lab[1] - lab2[1]) + sq(lab[2] - lab2[2]))

    fn distance_cie76(self, other: Self) -> Float64:
        """Same as `distance_Lab`.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        return self.distance_lab(other)

    fn distance_cie94(self, other: Self) -> Float64:
        """Uses the CIE94 formula to calculate color distance. More accurate than
        `distance_Lab`, but also more work.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        l1, a1, b1 = self.lab()
        l2, a2, b2 = other.lab()

        # NOTE: Since all those formulas expect L,a,b values 100x larger than we
        #       have them in this library, we either need to adjust all constants
        #       in the formula, or convert the ranges of L,a,b before, and then
        #       scale the distances down again. The latter is less error-prone.
        l1 *= 100.0
        a1 *= 100.0
        b1 *= 100.0
        l2 *= 100.0
        a2 *= 100.0
        b2 *= 100.0

        alias kl = 1.0  # 2.0 for textiles
        alias kc = 1.0
        alias kh = 1.0
        alias k1 = 0.045  # 0.048 for textiles
        alias k2 = 0.015  # 0.014 for textiles.

        var delta_L = l1 - l2
        var c1 = math.sqrt(sq(a1) + sq(b1))
        var c2 = math.sqrt(sq(a2) + sq(b2))
        var delta_Cab = c1 - c2

        # Not taking Sqrt here for stability, and it's unnecessary.
        var deltaHab2 = sq(a1 - a2) + sq(b1 - b2) - sq(delta_Cab)
        alias sl = 1.0
        var sc = 1.0 + k1 * c1
        var sh = 1.0 + k2 * c1

        var vL2 = sq(delta_L / (kl * sl))
        var vC2 = sq(delta_Cab / (kc * sc))
        var vH2 = deltaHab2 / sq(kh * sh)

        return math.sqrt(vL2 + vC2 + vH2) * 0.01  # See above.

    fn distance_ciede2000(self, other: Self) -> Float64:
        """Uses the Delta E 2000 formula to calculate color
        distance. It is more expensive but more accurate than both `distance_Lab`
        and `distance_CIE94`.

        Args:
            other: The other color to compare to.

        Returns:
            The distance between the two colors in Lab space.
        """
        return self.distance_ciede2000klch(other, 1.0, 1.0, 1.0)

    fn distance_ciede2000klch(self, other: Self, kl: Float64, kc: Float64, kh: Float64) -> Float64:
        """Uses the Delta E 2000 formula with custom values
        for the weighting factors kL, kC, and kH.

        Args:
            other: The other color to compare to.
            kl: The weighting factor for luminance.
            kc: The weighting factor for chroma.
            kh: The weighting factor for hue.

        Returns:
            The distance between the two colors in Lab space.
        """
        var lab = self.lab()
        var lab2 = other.lab()

        # As with CIE94, we scale up the ranges of L,a,b beforehand and scale
        # them down again afterwards.
        var l1 = lab[0] * 100.0
        var a1 = lab[1] * 100.0
        var b1 = lab[2] * 100.0
        var l2 = lab2[0] * 100.0
        var a2 = lab2[1] * 100.0
        var b2 = lab2[2] * 100.0

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

    fn blend_lab(self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the L*a*b* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var LAB = self.lab()
        var LAB2 = c2.lab()

        return lab(LAB[0] + t * (LAB2[0] - LAB[0]), LAB[1] + t * (LAB2[1] - LAB[1]), LAB[2] + t * (LAB2[2] - LAB[2]))

    fn luv(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*u*v* space using `D65` as reference white.
        L* is in [0..1] and both u* and v* are in about [-1..1].

        Returns:
            The Luminance, u, and v values.
        """
        var xyz = self.xyz()
        return xyz_to_Luv(xyz[0], xyz[1], xyz[2])

    fn distance_luv(self, c2: Self) -> Float64:
        """Good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot.

        Args:
            c2: The other color to compare to.

        Returns:
            The distance between the two colors in Luv space.
        """
        var luv = self.luv()
        var luv2 = c2.luv()
        return math.sqrt(sq(luv[0] - luv2[0]) + sq(luv[1] - luv2[1]) + sq(luv[2] - luv2[2]))

    fn blend_luv(self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the CIE-L*u*v* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            c2: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var luv = self.luv()
        var luv2 = c2.luv()

        return Luv(luv[0] + t * (luv2[0] - luv[0]), luv[1] + t * (luv2[1] - luv[1]), luv[2] + t * (luv2[2] - luv[2]))

    fn hcl(self) -> (Float64, Float64, Float64):
        """Converts the given color to HCL space using `D65` as reference white.
        H values are in [0..360], C and L values are in [0..1] although C can overshoot 1.0.

        Returns:
            The Hue, Chroma, and Luminance values.
        """
        return self.hcl_white_ref(D65)

    fn hcl_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to HCL space, taking into account
        a given reference white. (i.e. the monitor's white)
        H values are in [0..360], C and L values are in [0..1].

        Args:
            wref: The reference white.

        Returns:
            The Hue, Chroma, and Luminance values.
        """
        L, a, b = self.lab_white_ref(wref)
        return lab_to_hcl(L, a, b)

    fn blend_hcl(self, other: Self, t: Float64) -> Self:
        """BlendHcl blends two colors in the CIE-L*C*h° color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            other: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        h1, c1, l1 = self.hcl()
        h2, c2, l2 = other.hcl()

        if c1 <= 0.00015 and c2 >= 0.00015:
            h1 = h2
        elif c2 <= 0.00015 and c1 >= 0.00015:
            h2 = h1

        # We know that h are both in [0..360]
        return hcl(interp_angle(h1, h2, t), c1 + t * (c2 - c1), l1 + t * (l2 - l1)).clamped()

    fn LuvLCh(self) -> (Float64, Float64, Float64):
        """Converts the given color to LuvLCh space using `D65` as reference white.
        h values are in [0..360], C and L values are in [0..1] although C can overshoot 1.0.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        return self.Luv_LCh_white_ref(D65)

    fn Luv_LCh_white_ref(self, wref: InlineArray[Float64, 3]) -> (Float64, Float64, Float64):
        """Converts the given color to LuvLCh space, taking into account
        a given reference white. (i.e. the monitor's white)
        h values are in [0..360], c and l values are in [0..1].

        Args:
            wref: The reference white.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        var luv = self.Luv_white_ref(wref)
        return Luv_To_LuvLCh(luv[0], luv[1], luv[2])

    fn blend_Luv_LCh(self, other: Self, t: Float64) -> Self:
        """Blends two colors in the cylindrical CIELUV color space.
        t == 0 results in c1, t == 1 results in c2.

        Args:
            other: The other color to blend with.
            t: The blending factor.

        Returns:
            The blended color.
        """
        var lch = self.LuvLCh()
        var lch2 = other.LuvLCh()

        # We know that h are both in [0..360]
        return LuvLCh(
            lch[0] + t * (lch2[0] - lch[0]), lch[1] + t * (lch2[1] - lch[1]), interp_angle(lch2[2], lch[2], t)
        )

    fn HPLuv(self) -> (Float64, Float64, Float64):
        """HPLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (luminance) in [0..1].

        Note that HPLuv can only represent pastel colors, and so the Saturation
        value could be much larger than 1 for colors it can't represent.

        Returns:
            The Hue, Saturation, and Luminance values.
        """
        var lch = self.LuvLCh_white_ref(hSLuvD65)
        return LuvLCh_to_HPLuv(lch[0], lch[1], lch[2])


fn interp_angle(a0: Float64, a1: Float64, t: Float64) -> Float64:
    """Utility used by Hxx color-spaces for interpolating between two angles in [0,360].

    Args:
        a0: The first angle.
        a1: The second angle.
        t: The blending factor.

    Returns:
        The interpolated angle.
    """
    # Based on the answer here: http://stackoverflow.com/a/14498790/2366315
    # With potential proof that it works here: http://math.stackexchange.com/a/2144499
    var delta = ((((a1 - a0) % 360.0) + 540.0)) % 360.0 - 180.0
    return (a0 + t * delta + 360.0) % 360.0


### HSV ###
###########
# From http://en.wikipedia.org/wiki/HSL_and_HSV
# Note that h is in [0..360] and s,v in [0..1]
fn hsv(h: Float64, s: Float64, v: Float64) -> Color:
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

    return Color(m + r, m + g, m + b)


## HSL ##
#########
fn hsl(var h: Float64, s: Float64, l: Float64) -> Color:
    """Creates a new Color given a Hue in [0..360], a Saturation [0..1], and a Luminance (luminance) in [0..1].

    Args:
        h: The Hue in [0..360].
        s: The Saturation in [0..1].
        l: The Luminance in [0..1].

    Returns:
        The new Color.
    """
    if s == 0:
        return Color(l, l, l)

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

    return Color(r, g, b)


## Linear ##
#######
fn linearize_fast(v: Float64) -> Float64:
    """A much faster and still quite precise linearization using a 6th-order Taylor approximation.
    Much faster than and almost as accurate as `linearize`.

    Args:
        v: The value to linearize.

    Returns:
        The linearized value.
    """
    var v1 = v - 0.5
    var v2 = v1 * v1
    var v3 = v2 * v1
    var v4 = v2 * v2
    return (
        -0.248750514614486
        + 0.925583310193438 * v
        + 1.16740237321695 * v2
        + 0.280457026598666 * v3
        - 0.0757991963780179 * v4
    )


fn delinearize_fast(v: Float64) -> Float64:
    """A much faster and still quite precise delinearization using a 6th-order Taylor approximation.
    Much faster than and almost as accurate as `delinearize`.

    Args:
        v: The value to delinearize.

    Returns:
        The delinearized value.
    """
    if v > 0.2:
        var v1 = v - 0.6
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.442430344268235
            + 0.592178981271708 * v
            - 0.287864782562636 * v2
            + 0.253214392068985 * v3
            - 0.272557158129811 * v4
            + 0.325554383321718 * v5
        )
    elif v > 0.03:
        var v1 = v - 0.115
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.194915592891669
            + 1.55227076330229 * v
            - 3.93691860257828 * v2
            + 18.0679839248761 * v3
            - 101.468750302746 * v4
            + 632.341487393927 * v5
        )
    else:
        var v1 = v - 0.015
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.0519565234928877
            + 5.09316778537561 * v
            - 99.0338180489702 * v2
            + 3484.52322764895 * v3
            - 150028.083412663 * v4
            + 7168008.42971613 * v5
        )


fn fast_linear_rgb(r: Float64, g: Float64, b: Float64) -> Color:
    """Creates a new Color given linear RGB values.
    Much faster than and almost as accurate as `linear_rgb`.
    BUT it is important to NOTE that they only produce good results for valid inputs r,g,b in [0,1].

    Args:
        r: The red value in [0..1].
        g: The green value in [0..1].
        b: The blue value in [0..1].

    Returns:
        The new Color.
    """
    return Color(delinearize_fast(r), delinearize_fast(g), delinearize_fast(b))


fn xyz_to_xyY(X: Float64, Y: Float64, Z: Float64) -> (Float64, Float64, Float64):
    """Converts the given XYZ color to CIE xyY space.

    Args:
        X: The X value.
        Y: The Y value.
        Z: The Z value.

    Returns:
        The xyY values.
    """
    return xyz_to_xyY_white_ref(X, Y, Z, D65)


fn xyz_to_xyY_white_ref(
    X: Float64, Y: Float64, Z: Float64, wref: InlineArray[Float64, 3]
) -> (Float64, Float64, Float64):
    """Converts the given XYZ color to CIE xyY space, taking into account
    a given reference white. (i.e. the monitor's white).

    Args:
        X: The X value.
        Y: The Y value.
        Z: The Z value.
        wref: The reference white.

    Returns:
        The xyY values.
    """
    var Yout = Y
    var N = X + Y + Z
    var x = X
    var y = Y
    if abs(N) < 1e-14:
        x = wref[0] / (wref[0] + wref[1] + wref[2])
        y = wref[1] / (wref[0] + wref[1] + wref[2])
    else:
        x = x / N
        y = y / N

    return x, y, Yout


fn xyy_to_xyz(x: Float64, y: Float64, Y: Float64) -> (Float64, Float64, Float64):
    """Converts the given CIE xyY color to XYZ space.

    Args:
        x: The x value.
        y: The y value.
        Y: The Y value.

    Returns:
        The XYZ values.
    """
    if -1e-14 < y and y < 1e-14:
        return 0.0, Y, 0.0

    var X = Y / y * x
    var Z = Y / y * (1.0 - x - y)
    return X, Y, Z


fn xyy(x: Float64, y: Float64, Y: Float64) -> Color:
    """Generates a color by using data given in CIE xyY space.

    Args:
        x: The x value.
        y: The y value.
        Y: The Y value.

    Returns:
        The new Color.
    """
    X, new_Y, Z = xyy_to_xyz(x, y, Y)
    return xyz(X, new_Y, Z)


# / L*a*b* #/
#######
# http://en.wikipedia.org/wiki/Lab_color_space#CIELAB-CIEXYZ_conversions
# For L*a*b*, we need to L*a*b*<->XYZ->RGB and the first one is device dependent.
fn lab_f(t: Float64) -> Float64:
    """Helper function for the L*a*b* color space.

    Args:
        t: The value to calculate the function for.

    Returns:
        The calculated value.
    """
    if t > 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        # if is_compile_time():
        #     abort("Cannot call `math.cbrt` at compile time. Please execute it at runtime.")
        return math.cbrt(t)
    return t / 3.0 * 29.0 / 6.0 * 29.0 / 6.0 + 4.0 / 29.0


fn xyz_to_lab(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Use `D65` white as reference point by default.
    http://www.fredmiranda.com/forum/tomath.pic/1035332
    http://en.wikipedia.org/wiki/Standard_illuminant.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.

    Returns:
        The L*, a*, and b* values.
    """
    return xyz_to_lab_white_ref(x, y, z, D65)


fn xyz_to_lab_white_ref(
    x: Float64, y: Float64, z: Float64, wref: InlineArray[Float64, 3]
) -> (Float64, Float64, Float64):
    """Use a given reference white point to convert the given XYZ color to L*a*b* space.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.
        wref: The reference white.

    Returns:
        The L*, a*, and b* values.
    """
    var fy = lab_f(y / wref[1])
    var l = 1.16 * fy - 0.16
    var a = 5.0 * (lab_f(x / wref[0]) - fy)
    var b = 2.0 * (fy - lab_f(z / wref[2]))
    return l, a, b


fn lab_finv(t: Float64) -> Float64:
    """Helper function for the L*a*b* color space.

    Args:
        t: The value to calculate the function for.

    Returns:
        The calculated value.
    """
    if t > 6.0 / 29.0:
        return t * t * t
    return 3.0 * 6.0 / 29.0 * 6.0 / 29.0 * (t - 4.0 / 29.0)


fn lab_to_xyz(l: Float64, a: Float64, b: Float64) -> (Float64, Float64, Float64):
    """`D65` white (see above).

    Args:
        l: The L* value.
        a: The a* value.
        b: The b* value.

    Returns:
        The X, Y, and Z values.
    """
    return lab_to_xyz_white_ref(l, a, b, D65)


fn lab_to_xyz_white_ref(
    l: Float64, a: Float64, b: Float64, wref: InlineArray[Float64, 3]
) -> (Float64, Float64, Float64):
    """Use a given reference white point to convert the given L*a*b* color to XYZ space.

    Args:
        l: The L* value.
        a: The a* value.
        b: The b* value.
        wref: The reference white.

    Returns:
        The X, Y, and Z values.
    """
    var l2 = (l + 0.16) / 1.16
    var x = wref[0] * lab_finv(l2 + a / 5.0)
    var y = wref[1] * lab_finv(l2)
    var z = wref[2] * lab_finv(l2 - b / 2.0)
    return x, y, z


fn lab(l: Float64, a: Float64, b: Float64) -> Color:
    """Generates a color by using data given in CIE L*a*b* space using `D65` as reference white.
    WARNING: many combinations of `l`, `a`, and `b` values do not have corresponding
    valid RGB values.

    Args:
        l: The L* value.
        a: The a* value.
        b: The b* value.

    Returns:
        The new Color.
    """
    var XYZ = lab_to_xyz(l, a, b)
    return xyz(XYZ[0], XYZ[1], XYZ[2])


fn lab_white_ref(l: Float64, a: Float64, b: Float64, wref: InlineArray[Float64, 3]) -> Color:
    """Generates a color by using data given in CIE L*a*b* space, taking
    into account a given reference white. (i.e. the monitor's white).

    Args:
        l: The L* value.
        a: The a* value.
        b: The b* value.
        wref: The reference white.

    Returns:
        The new Color.
    """
    var XYZ = lab_to_xyz_white_ref(l, a, b, wref)
    return xyz(XYZ[0], XYZ[1], XYZ[2])


# / L*u*v* #/
#######
# http://en.wikipedia.org/wiki/CIELUV#XYZ_.E2.86.92_CIELUV_and_CIELUV_.E2.86.92_XYZ_conversions
# For L*u*v*, we need to L*u*v*<->XYZ<->RGB and the first one is device dependent.
fn xyz_to_Luv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Converts the given XYZ color to CIE L*u*v* space using `D65` as reference white.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.

    Returns:
        The L*, u*, and v* values.
    """
    return xyz_to_Luv_white_ref(x, y, z, D65)


fn luv_to_xyz(l: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    """Converts the given CIE L*u*v* color to XYZ space using `D65` as reference white.
    Use D65 white as reference point by default.

    Args:
        l: The L* value.
        u: The u* value.
        v: The v* value.

    Returns:
        The X, Y, and Z values.
    """
    return luv_to_xyz_white_ref(l, u, v, D65)


fn Luv(l: Float64, u: Float64, v: Float64) -> Color:
    """Generates a color by using data given in CIE L*u*v* space using D65 as reference white.
    L* is in [0..1] and both u* and v* are in about [-1..1]
    WARNING: many combinations of `l`, `u`, and `v` values do not have corresponding
    valid RGB values.

    Args:
        l: The L* value.
        u: The u* value.
        v: The v* value.

    Returns:
        The new Color.
    """
    var XYZ = luv_to_xyz(l, u, v)
    return xyz(XYZ[0], XYZ[1], XYZ[2])


fn Luv_white_ref(l: Float64, u: Float64, v: Float64, wref: InlineArray[Float64, 3]) -> Color:
    """Generates a color by using data given in CIE L*u*v* space, taking
    into account a given reference white. (i.e. the monitor's white)
    L* is in [0..1] and both u* and v* are in about [-1..1].

    Args:
        l: The L* value.
        u: The u* value.
        v: The v* value.
        wref: The reference white.

    Returns:
        The new Color.
    """
    var XYZ = luv_to_xyz_white_ref(l, u, v, wref)
    return xyz(XYZ[0], XYZ[1], XYZ[2])


## HCL ##
#########
# HCL is nothing else than L*a*b* in cylindrical coordinates!
# (this was wrong on English wikipedia, I fixed it, let's hope the fix stays.)
# But it is widely popular since it is a "correct HSV"
# http://www.hunterlab.com/appnotes/an09_96a.pdf


fn lab_to_hcl(L: Float64, a: Float64, b: Float64) -> (Float64, Float64, Float64):
    """Converts the given L*a*b* color to HCL space.

    Args:
        L: The L* value.
        a: The a* value.
        b: The b* value.

    Returns:
        The Hue, Chroma, and Luminance values.
    """
    var h = 0.0
    if abs(b - a) > 1e-4 and abs(a) > 1e-4:
        h = (57.29577951308232087721 * math.atan2(b, a) + 360.0) % 360.0  # Rad2Deg

    var c = math.sqrt(sq(a) + sq(b))
    var l = L
    return h, c, l


fn hcl(h: Float64, c: Float64, l: Float64) -> Color:
    """Generates a color by using data given in HCL space using `D65` as reference white.
    H values are in [0..360], C and L values are in [0..1]
    WARNING: many combinations of `h`, `c`, and `l` values do not have corresponding
    valid RGB values.

    Args:
        h: The Hue in [0..360].
        c: The Chroma in [0..1].
        l: The Luminance in [0..1].

    Returns:
        The new Color.
    """
    return hcl_white_ref(h, c, l, D65)


fn hcl_to_Lab(h: Float64, c: Float64, l: Float64) -> (Float64, Float64, Float64):
    """Converts the given HCL color to L*a*b* space.

    Args:
        h: The Hue in [0..360].
        c: The Chroma in [0..1].
        l: The Luminance in [0..1].

    Returns:
        The L*, a*, and b* values.
    """
    var H = 0.01745329251994329576 * h  # Deg2Rad
    var a = c * math.cos(H)
    var b = c * math.sin(H)
    return l, a, b


fn hcl_white_ref(h: Float64, c: Float64, l: Float64, wref: InlineArray[Float64, 3]) -> Color:
    """Generates a color by using data given in HCL space, taking
    into account a given reference white. (i.e. the monitor's white)
    H values are in [0..360], C and L values are in [0..1].

    Args:
        h: The Hue in [0..360].
        c: The Chroma in [0..1].
        l: The Luminance in [0..1].
        wref: The reference white.

    Returns:
        The new Color.
    """
    var Lab = hcl_to_Lab(h, c, l)
    return lab_white_ref(Lab[0], Lab[1], Lab[2], wref)


fn LuvLCh(l: Float64, c: Float64, h: Float64) -> Color:
    """Generates a color by using data given in LuvLCh space using D65 as reference white.
    h values are in [0..360], C and L values are in [0..1]
    WARNING: many combinations of `l`, `c`, and `h` values do not have corresponding
    valid RGB values.

    Args:
        l: The Luminance in [0..1].
        c: The Chroma in [0..1].
        h: The Hue in [0..360].

    Returns:
        The new Color.
    """
    return LuvLCh_white_ref(l, c, h, D65)


fn LuvLChToLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    """Converts the given LuvLCh color to Luv space.

    Args:
        l: The Luminance in [0..1].
        c: The Chroma in [0..1].
        h: The Hue in [0..360].

    Returns:
        The Luminance, u*, and v* values.
    """
    var H = 0.01745329251994329576 * h  # Deg2Rad
    return l, c * math.cos(H), c * math.sin(H)


fn LuvLCh_white_ref(l: Float64, c: Float64, h: Float64, wref: InlineArray[Float64, 3]) -> Color:
    """Generates a color by using data given in LuvLCh space, taking
    into account a given reference white. (i.e. the monitor's white)
    h values are in [0..360], C and L values are in [0..1].

    Args:
        l: The Luminance in [0..1].
        c: The Chroma in [0..1].
        h: The Hue in [0..360].
        wref: The reference white.

    Returns:
        The new Color.
    """
    var Luv = LuvLChToLuv(l, c, h)
    return Luv_white_ref(Luv[0], Luv[1], Luv[2], wref)


fn clamped(color: Color) -> Color:
    """Clamps the given color to the [0..1] range.

    Args:
        color: The color to clamp.

    Returns:
        The clamped color.
    """
    return Color(clamp01(color.R), clamp01(color.G), clamp01(color.B))


fn linearize(v: Float64) -> Float64:
    """Linearizes the given value using the sRGB gamma function.

    Args:
        v: The value to linearize.

    Returns:
        The linearized value.
    """
    if v <= 0.04045:
        return v / 12.92
    return ((v + 0.055) / 1.055) ** 2.4


fn linear_rgb_to_xyz(r: Float64, g: Float64, b: Float64) -> (Float64, Float64, Float64):
    """Converts from Linear Color space to CIE XYZ-space.

    Args:
        r: The red value.
        g: The green value.
        b: The blue value.

    Returns:
        The X, Y, and Z values.
    """
    return (
        0.41239079926595948 * r + 0.35758433938387796 * g + 0.18048078840183429 * b,
        0.21263900587151036 * r + 0.71516867876775593 * g + 0.072192315360733715 * b,
        0.019330818715591851 * r + 0.11919477979462599 * g + 0.95053215224966058 * b,
    )


fn luv_to_xyz_white_ref(
    l: Float64, u: Float64, v: Float64, wref: InlineArray[Float64, 3]
) -> (Float64, Float64, Float64):
    """Converts the given CIE L*u*v* color to XYZ space, taking into account
    a given reference white. (i.e. the monitor's white).

    Args:
        l: The L* value.
        u: The u* value.
        v: The v* value.
        wref: The reference white.

    Returns:
        The X, Y, and Z values.
    """
    var y: Float64
    if l <= 0.08:
        y = wref[1] * l * 100.0 * 3.0 / 29.0 * 3.0 / 29.0 * 3.0 / 29.0
    else:
        y = wref[1] * ((l + 0.16) / 1.16) ** 3

    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var x = 0.0
    var z = 0.0
    if l != 0.0:
        var ubis = (u / (13.0 * l)) + un
        var vbis = (v / (13.0 * l)) + vn
        x = y * 9.0 * ubis / (4.0 * vbis)
        z = y * (12.0 - (3.0 * ubis) - (20.0 * vbis)) / (4.0 * vbis)
    else:
        y = 0.0

    return x, y, z


fn xyz_to_uv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64):
    """For this part, we do as R's graphics.hcl does, not as wikipedia does.
    Or is it the same.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.

    Returns:
        The u* and v* values.
    """
    var denom = x + (15.0 * y) + (3.0 * z)
    var u: Float64
    var v: Float64

    if denom == 0.0:
        u = 0.0
        v = 0.0

        return u, v

    u = 4.0 * x / denom
    v = 9.0 * y / denom

    return u, v


fn xyz_to_Luv_white_ref(
    x: Float64, y: Float64, z: Float64, wref: InlineArray[Float64, 3]
) -> (Float64, Float64, Float64):
    """Converts the given XYZ color to CIE L*u*v* space, taking into account.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.
        wref: The reference white.

    Returns:
        The L*, u*, and v* values.
    """
    var l: Float64
    if y / wref[1] <= 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        l = y / wref[1] * (29.0 / 3.0 * 29.0 / 3.0 * 29.0 / 3.0) / 100.0
    else:
        # if is_compile_time():
        #     abort("Cannot call `math.cbrt` at compile time. Please execute it at runtime.")
        l = 1.16 * math.cbrt(y / wref[1]) - 0.16

    ubis, vbis = xyz_to_uv(x, y, z)
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])
    var u = 13.0 * l * (ubis - un)
    var v = 13.0 * l * (vbis - vn)

    return l, u, v


fn Luv_To_LuvLCh(L: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    """Converts the given Luv color to LuvLCh space.

    Args:
        L: The Luminance in [0..1].
        u: The u* value.
        v: The v* value.

    Returns:
        The Luminance, Chroma, and Hue values.
    """
    # Oops, floating point workaround necessary if u ~= v and both are very small (i.e. almost zero).
    var h: Float64
    if abs(v - u) > 1e-4 and abs(u) > 1e-4:
        h = (57.29577951308232087721 * math.atan2(v, u) + 360.0) % 360.0  # Rad2Deg
    else:
        h = 0.0

    var l = L
    var c = math.sqrt(sq(u) + sq(v))

    return l, c, h


fn xyz_to_linear_rgb(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Converts from CIE XYZ-space to Linear Color space.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.

    Returns:
        The red, green, and blue values.
    """
    var r = (3.2409699419045214 * x) - (1.5373831775700935 * y) - (0.49861076029300328 * z)
    var g = (-0.96924363628087983 * x) + (1.8759675015077207 * y) + (0.041555057407175613 * z)
    var b = (0.055630079696993609 * x) - (0.20397695888897657 * y) + (1.0569715142428786 * z)

    return r, g, b


fn delinearize(v: Float64) -> Float64:
    """Delinearizes the given value using the sRGB gamma function.

    Args:
        v: The value to delinearize.

    Returns:
        The delinearized value.
    """
    if v <= 0.0031308:
        return 12.92 * v

    return 1.055 * (v ** (1.0 / 2.4)) - 0.055


fn linear_rgb(r: Float64, g: Float64, b: Float64) -> Color:
    """Creates a new Color given linear RGB values.

    Args:
        r: The red value.
        g: The green value.
        b: The blue value.

    Returns:
        The new Color.
    """
    return Color(delinearize(r), delinearize(g), delinearize(b))


fn xyz(x: Float64, y: Float64, z: Float64) -> Color:
    """Generates a color by using data given in CIE XYZ space.

    Args:
        x: The x value.
        y: The y value.
        z: The z value.

    Returns:
        The new Color.
    """
    var rgb = xyz_to_linear_rgb(x, y, z)
    return linear_rgb(rgb[0], rgb[1], rgb[2])
