"""CIE XYZ color space."""
from std import math
from mist.color.spaces.rgb import RGB
from mist.color.spaces.xyy import xyY
from mist.color.spaces.lab import Lab
from mist.color.spaces.luv import Luv
from mist.color.math import D65, in_range, lab_f, xyz_to_uv


struct xyz(Equatable, ImplicitlyCopyable, Writable):
    """A color in the CIE XYZ color space."""

    var x: Float64
    """X tristimulus value. Up to about 0.95 for sRGB colors."""
    var y: Float64
    """Y tristimulus value, the relative luminance, in the range [0.0, 1.0]."""
    var z: Float64
    """Z tristimulus value. Up to about 1.09 for sRGB colors."""

    def __init__(out self, x: Float64, y: Float64, z: Float64):
        """Initializes the XYZ color from its components.

        Args:
            x: X tristimulus value. Up to about 0.95 for sRGB colors.
            y: Y tristimulus value, the relative luminance, in the range [0.0, 1.0].
            z: Z tristimulus value. Up to about 1.09 for sRGB colors.
        """
        # Only invariants that hold for every color are checked. Converting back from the
        # perceptual spaces passes through out-of-gamut coordinates, which `Color.from_rgb` clamps.
        debug_assert(
            in_range(y, 0.0, 1.0),
            t"The xyz luminance y must be in the range [0.0, 1.0]. Received ({x}, {y}, {z}).",
        )
        self.x = x
        self.y = y
        self.z = z

    def __init__(out self, xyz: Tuple[Float64, Float64, Float64]):
        """Initializes the XYZ color from a tuple of components.

        Args:
            xyz: The (x, y, z) components.
        """
        var x = xyz[0]
        var y = xyz[1]
        var z = xyz[2]
        # Only invariants that hold for every color are checked. Converting back from the
        # perceptual spaces passes through out-of-gamut coordinates, which `Color.from_rgb` clamps.
        debug_assert(
            in_range(y, 0.0, 1.0),
            t"The xyz luminance y must be in the range [0.0, 1.0]. Received ({x}, {y}, {z}).",
        )

        self.x = x
        self.y = y
        self.z = z

    def to_xyY(self, white_ref: Array[Float64, 3] = D65) -> xyY:
        """Converts the given XYZ color to CIE xyY space, taking into account
        a given reference white. (i.e. the monitor's white).

        Args:
            white_ref: The reference white.

        Returns:
            The xyY values.
        """
        var Yout = self.y
        var N = self.x + self.y + self.z
        var xout: Float64
        var yout: Float64
        if abs(N) < 1e-14:
            xout = white_ref[0] / (white_ref[0] + white_ref[1] + white_ref[2])
            yout = white_ref[1] / (white_ref[0] + white_ref[1] + white_ref[2])
        else:
            xout = self.x / N
            yout = self.y / N

        return xyY(xout, yout, Yout)

    def to_Lab(self, white_ref: Array[Float64, 3] = D65) -> Lab:
        """Use a given reference white point to convert the given XYZ color to L*a*b* space.

        Args:
            white_ref: The reference white.

        Returns:
            The L*, a*, and b* values.

        #### Notes:
        * http://www.fredmiranda.com/forum/tomath.pic/1035332
        * http://en.wikipedia.org/wiki/Standard_illuminant.
        """
        var fy = lab_f(self.y / white_ref[1])
        var L = 1.16 * fy - 0.16
        var a = 5.0 * (lab_f(self.x / white_ref[0]) - fy)
        var b = 2.0 * (fy - lab_f(self.z / white_ref[2]))
        return Lab(L, a, b)

    def to_Luv(self, white_ref: Array[Float64, 3] = D65) -> Luv:
        """Converts the given XYZ color to CIE L*u*v* space, taking into account.

        Args:
            white_ref: The reference white.

        Returns:
            The L*, u*, and v* values.
        """
        var l: Float64
        if self.y / white_ref[1] <= 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
            l = self.y / white_ref[1] * (29.0 / 3.0 * 29.0 / 3.0 * 29.0 / 3.0) / 100.0
        else:
            l = 1.16 * math.cbrt(self.y / white_ref[1]) - 0.16

        var ubis, vbis = xyz_to_uv(self.x, self.y, self.z)
        var un, vn = xyz_to_uv(white_ref[0], white_ref[1], white_ref[2])
        var u = 13.0 * l * (ubis - un)
        var v = 13.0 * l * (vbis - vn)

        return Luv(l, u, v)

    def to_linear_rgb(self) -> RGB[linear=True]:
        """Converts from CIE XYZ-space to Linear Color space.

        Returns:
            The linearized red, green, and blue values.
        """
        var r = (3.2409699419045214 * self.x) - (1.5373831775700935 * self.y) - (0.49861076029300328 * self.z)
        var g = (-0.96924363628087983 * self.x) + (1.8759675015077207 * self.y) + (0.041555057407175613 * self.z)
        var b = (0.055630079696993609 * self.x) - (0.20397695888897657 * self.y) + (1.0569715142428786 * self.z)

        return RGB[linear=True](r, g, b)
