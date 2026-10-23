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
    """Green-red axis. In the range [-1.1, 1.1]."""
    var b: Float64
    """Blue-yellow axis. In the range [-1.1, 1.1]."""

    def __init__(out self, L: Float64, a: Float64, b: Float64):
        """Initializes the L*a*b* color from its components.

        Args:
            L: Luminance, perceived brightness. In the range [0.0, 1.0].
            a: Green-red axis. In the range [-1.1, 1.1].
            b: Blue-yellow axis. In the range [-1.1, 1.1].
        """
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(a, -1.1, 1.1) and in_range(b, -1.1, 1.1),
            (
                t"The Lab components must be in the range [0.0, 1.0] for L and [-1.1, 1.1] for a and b. Received ({L},"
                t" {a}, {b})."
            ),
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
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(a, -1.1, 1.1) and in_range(b, -1.1, 1.1),
            (
                t"The Lab components must be in the range [0.0, 1.0] for L and [-1.1, 1.1] for a and b. Received ({L},"
                t" {a}, {b})."
            ),
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
        var h = 0.0
        if abs(self.b - self.a) > 1e-4 and abs(self.a) > 1e-4:
            h = (57.29577951308232087721 * math.atan2(self.b, self.a) + 360.0) % 360.0  # Rad2Deg

        var c = math.sqrt(sq(self.a) + sq(self.b))
        var l = self.L
        return hcl(h, c, l)
