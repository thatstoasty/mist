"""Constants and math helpers shared by the color space conversions."""
from std import math
from std.os import abort
from std.utils.numerics import max_finite

from mist._utils import lut


comptime WhiteReference = Array[Float64, 3]
"""Array of white reference values."""

comptime MAX_FLOAT64: Float64 = max_finite[DType.float64]()
"""The maximum value of a 64-bit floating-point number."""

# This is the tolerance used when comparing colors using AlmostEqualColor.
comptime DELTA = 1.0 / 255.0
"""The tolerance used when comparing colors using `AlmostEqualColor`."""

# This is the default reference white point.
comptime D65: Array[Float64, 3] = [0.95047, 1.00000, 1.08883]
"""The default reference white point, D65."""

comptime XYZ_TO_RGB_MATRIX: Array[Array[Float64, 3], 3] = [
    [3.2409699419045214, -1.5373831775700935, -0.49861076029300328],
    [-0.96924363628087983, 1.8759675015077207, 0.041555057407175613],
    [0.055630079696993609, -0.20397695888897657, 1.0569715142428786],
]
"""The matrix used to convert from XYZ to RGB."""
comptime hSLuvD65: Array[Float64, 3] = [0.95045592705167, 1.0, 1.089057750759878]
"""The reference white point for HSLuv, D65."""

comptime KAPPA = 903.2962962962963
"""The value of Kappa used in the CIE Luv color space."""
comptime EPSILON = 0.0088564516790356308
"""The value of Epsilon used in the CIE Luv color space."""


comptime RANGE_TOLERANCE = 1e-9
"""Slack allowed by `in_range` so floating-point rounding at a range's edge is not treated as out of range."""


@always_inline
def in_range(v: Float64, lower: Float64, upper: Float64) -> Bool:
    """Returns whether the value lies in [lower, upper], allowing `RANGE_TOLERANCE` of slack at either end.

    Args:
        v: The value to check.
        lower: The lower bound of the range.
        upper: The upper bound of the range.

    Returns:
        True if the value is within the range, otherwise False.
    """
    return lower - RANGE_TOLERANCE <= v <= upper + RANGE_TOLERANCE


@always_inline
def sq(v: Float64) -> Float64:
    """Returns the square of the given value.

    Args:
        v: The value to square.

    Returns:
        The square of the given value.
    """
    return v * v


@always_inline
def clamp01(v: Float64) -> Float64:
    """Clamps from 0 to 1.

    Args:
        v: The value to clamp.

    Returns:
        The clamped value.
    """
    return math.clamp(v, 0.0, 1.0)


def length_of_ray_until_intersect(theta: Float64, x: Float64, y: Float64) -> Float64:
    """Returns the length of the ray until it intersects with the line at the given angle.

    Args:
        theta: The angle of the ray.
        x: The x-coordinate of the line.
        y: The y-coordinate of the line.

    Returns:
        The length of the ray until it intersects with the line.
    """
    return y / (math.sin(theta) - x * math.cos(theta))


def get_bounds(l: Float64) -> Array[Array[Float64, 2], 6]:
    """Returns the bounds for the given luminance value.

    Args:
        l: The luminance value.

    Returns:
        The bounds for the given luminance value.
    """
    var ret: Array[Array[Float64, 2], 6] = [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
    ]

    var sub_1 = (l + 16.0**3.0) / 1560896.0
    var sub_2 = sub_1 if sub_1 > EPSILON else l / KAPPA

    comptime for i in range(len(XYZ_TO_RGB_MATRIX)):
        var k = 0
        while k < 2:
            var top1 = (284517.0 * lut[XYZ_TO_RGB_MATRIX](i)[0] - 94839.0 * lut[XYZ_TO_RGB_MATRIX](i)[2]) * sub_2
            var top2 = (
                838422.0 * lut[XYZ_TO_RGB_MATRIX](i)[2]
                + 769860.0 * lut[XYZ_TO_RGB_MATRIX](i)[1]
                + 731718.0 * lut[XYZ_TO_RGB_MATRIX](i)[0]
            ) * l * sub_2 - 769860.0 * Float64(k) * l
            var bottom = (
                632260.0 * lut[XYZ_TO_RGB_MATRIX](i)[2] - 126452.0 * lut[XYZ_TO_RGB_MATRIX](i)[1]
            ) * sub_2 + 126452.0 * Float64(k)
            ret[i * 2 + k][0] = top1 / bottom
            ret[i * 2 + k][1] = top2 / bottom
            k += 1

    return ret^


@always_inline
def intersection_of_two_lines(x1: Float64, y1: Float64, x2: Float64, y2: Float64) -> Float64:
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
def distance_from_pole(x: Float64, y: Float64) -> Float64:
    """Returns the distance from the pole.

    Args:
        x: The x-coordinate.
        y: The y-coordinate.

    Returns:
        The distance from the pole.
    """
    return math.sqrt(x**2 + y**2)


def max_chroma_for_lh(l: Float64, h: Float64) -> Float64:
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


def max_safe_chroma_for_l(l: Float64) -> Float64:
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


def interp_angle(a0: Float64, a1: Float64, t: Float64) -> Float64:
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


## Linear ##
#######
def linearize_fast(v: Float64) -> Float64:
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


def delinearize_fast(v: Float64) -> Float64:
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


# / L*a*b* #/
#######
# http://en.wikipedia.org/wiki/Lab_color_space#CIELAB-CIEXYZ_conversions
# For L*a*b*, we need to L*a*b*<->XYZ->RGB and the first one is device dependent.
def lab_f(t: Float64) -> Float64:
    """Helper function for the L*a*b* color space.

    Args:
        t: The value to calculate the function for.

    Returns:
        The calculated value.
    """
    if t > 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        return math.cbrt(t)
    return t / 3.0 * 29.0 / 6.0 * 29.0 / 6.0 + 4.0 / 29.0


def lab_finv(t: Float64) -> Float64:
    """Helper function for the L*a*b* color space.

    Args:
        t: The value to calculate the function for.

    Returns:
        The calculated value.
    """
    if t > 6.0 / 29.0:
        return t * t * t
    return 3.0 * 6.0 / 29.0 * 6.0 / 29.0 * (t - 4.0 / 29.0)


# / L*u*v* #/
#######
# http://en.wikipedia.org/wiki/CIELUV#XYZ_.E2.86.92_CIELUV_and_CIELUV_.E2.86.92_XYZ_conversions
# For L*u*v*, we need to L*u*v*<->XYZ<->RGB and the first one is device dependent.

## HCL ##
#########
# HCL is nothing else than L*a*b* in cylindrical coordinates!
# (this was wrong on English wikipedia, I fixed it, let's hope the fix stays.)
# But it is widely popular since it is a "correct HSV"
# http://www.hunterlab.com/appnotes/an09_96a.pdf


def linearize(v: Float64) -> Float64:
    """Linearizes the given value using the sRGB gamma function.

    Args:
        v: The value to linearize.

    Returns:
        The linearized value.
    """
    if v <= 0.04045:
        return v / 12.92
    return ((v + 0.055) / 1.055) ** 2.4


def xyz_to_uv(x: Float64, y: Float64, z: Float64) -> Tuple[Float64, Float64]:
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


def delinearize(v: Float64) -> Float64:
    """Delinearizes the given value using the sRGB gamma function.

    Args:
        v: The value to delinearize.

    Returns:
        The delinearized value.
    """
    if v <= 0.0031308:
        return 12.92 * v

    return 1.055 * (v ** (1.0 / 2.4)) - 0.055
