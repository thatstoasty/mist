"""CIE L*a*b* color space."""
from std import math
from mist.color.math import D65, in_range, lab_finv, sq
from mist.color.spaces.xyz import xyz
from mist.color.spaces.hcl import hcl


struct Lab(Equatable, ImplicitlyCopyable, Writable):
    """A color in the CIE L*a*b* color space."""

    var L: Float64
    """Luminance, perceived brightness. In the range [0.0, 1.0]."""
    var a: Float64
    """Green-red axis. Within about [-0.87, 0.99] for sRGB colors."""
    var b: Float64
    """Blue-yellow axis. Within about [-1.08, 0.95] for sRGB colors."""

    def __init__(out self, L: Float64, a: Float64, b: Float64):
        """Initializes the L*a*b* color from its components.

        Args:
            L: Luminance, perceived brightness. In the range [0.0, 1.0].
            a: Green-red axis. Within about [-0.87, 0.99] for sRGB colors.
            b: Blue-yellow axis. Within about [-1.08, 0.95] for sRGB colors.
        """
        # Only invariants that hold for every color are checked. Converting back from the
        # perceptual spaces passes through out-of-gamut coordinates, which `Color.from_rgb` clamps.
        debug_assert(
            in_range(L, 0.0, 1.0),
            t"The Lab lightness L must be in the range [0.0, 1.0]. Received ({L}, {a}, {b}).",
        )
        self.L = L
        self.a = a
        self.b = b

    def __init__(out self, Lab: Tuple[Float64, Float64, Float64]):
        """Initializes the L*a*b* color from a tuple of components.

        Args:
            Lab: The (L, a, b) components.
        """
        var L = Lab[0]
        var a = Lab[1]
        var b = Lab[2]
        # Only invariants that hold for every color are checked. Converting back from the
        # perceptual spaces passes through out-of-gamut coordinates, which `Color.from_rgb` clamps.
        debug_assert(
            in_range(L, 0.0, 1.0),
            t"The Lab lightness L must be in the range [0.0, 1.0]. Received ({L}, {a}, {b}).",
        )

        self.L = L
        self.a = a
        self.b = b

    def to_xyz(self, white_ref: Array[Float64, 3] = D65) -> xyz:
        """Use a given reference white point to convert the given L*a*b* color to XYZ space.

        Args:
            white_ref: The reference white.

        Returns:
            The X, Y, and Z values.
        """
        var l2 = (self.L + 0.16) / 1.16
        var x = white_ref[0] * lab_finv(l2 + self.a / 5.0)
        var y = white_ref[1] * lab_finv(l2)
        var z = white_ref[2] * lab_finv(l2 - self.b / 2.0)
        return xyz(x, y, z)

    def to_hcl(self) -> hcl:
        """Converts the given L*a*b* color to HCL space.

        Returns:
            The Hue, Chroma, and Luminance values.
        """
        var c = math.sqrt(sq(self.a) + sq(self.b))
        # Hue is undefined for grays, so it's 0 when chroma is negligible. The test is
        # relative to lightness: chroma shrinks toward black (#000001 has C = 8e-4 but a
        # clear hue), and sRGB grays carry rounding chroma of at most 3.7e-4 * L. go-colorful
        # tests `|b - a|` and `|a|` instead, which also zeroes the hue of saturated colors
        # whose a ~= b or a ~= 0.
        var h = 0.0
        if c > 1e-3 * self.L:
            h = (57.29577951308232087721 * math.atan2(self.b, self.a) + 360.0) % 360.0  # Rad2Deg

        var l = self.L
        return hcl(h, c, l)
