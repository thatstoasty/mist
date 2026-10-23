"""CIE L*u*v* color space."""
from std import math
from mist.color.math import D65, in_range, sq, xyz_to_uv
from mist.color.spaces.xyz import xyz
from mist.color.spaces.luvlch import LuvLCh


struct Luv(Equatable, ImplicitlyCopyable, Writable):
    """A color in the CIE L*u*v* color space."""

    var L: Float64
    """Luminance. In the range [0.0, 1.0]."""
    var u: Float64
    """Chromaticity - Green/Red axis equivalent. Approximately -134 to 220, which this library scales to roughly [-0.9, 1.8]."""
    var v: Float64
    """Chromaticity - Blue/Yellow axis equivalent. Approximately -140 to 122, which this library scales to roughly [-1.4, 1.1]."""

    def __init__(out self, L: Float64, u: Float64, v: Float64):
        """Initializes the L*u*v* color from its components.

        Args:
            L: Luminance. In the range [0.0, 1.0].
            u: Chromaticity - Green/Red axis equivalent. Approximately -134 to 220, which this library scales to roughly [-0.9, 1.8].
            v: Chromaticity - Blue/Yellow axis equivalent. Approximately -140 to 122, which this library scales to roughly [-1.4, 1.1].
        """
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(u, -0.9, 1.8) and in_range(v, -1.4, 1.1),
            (
                t"The Luv components must be in the range [0.0, 1.0] for L and [-0.9, 1.8] for u and [-1.4, 1.1] for v."
                t" Received ({L}, {u}, {v})."
            ),
        )
        self.L = L
        self.u = u
        self.v = v

    def __init__(out self, Luv: Tuple[Float64, Float64, Float64]):
        """Initializes the L*u*v* color from a tuple of components.

        Args:
            Luv: The (L, u, v) components.
        """
        var L = Luv[0]
        var u = Luv[1]
        var v = Luv[2]
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(u, -0.9, 1.8) and in_range(v, -1.4, 1.1),
            (
                t"The Luv components must be in the range [0.0, 1.0] for L and [-0.9, 1.8] for u and [-1.4, 1.1] for v."
                t" Received ({L}, {u}, {v})."
            ),
        )

        self.L = L
        self.u = u
        self.v = v

    def to_xyz(self, white_ref: Array[Float64, 3] = D65) -> xyz:
        """Converts the given CIE L*u*v* color to XYZ space, taking into account
        a given reference white. (i.e. the monitor's white).

        Args:
            white_ref: The reference white.

        Returns:
            The X, Y, and Z values.
        """
        var y: Float64
        if self.L <= 0.08:
            y = white_ref[1] * self.L * 100.0 * 3.0 / 29.0 * 3.0 / 29.0 * 3.0 / 29.0
        else:
            y = white_ref[1] * ((self.L + 0.16) / 1.16) ** 3

        var un, vn = xyz_to_uv(white_ref[0], white_ref[1], white_ref[2])

        var x = 0.0
        var z = 0.0
        if self.L != 0.0:
            var ubis = (self.u / (13.0 * self.L)) + un
            var vbis = (self.v / (13.0 * self.L)) + vn
            x = y * 9.0 * ubis / (4.0 * vbis)
            z = y * (12.0 - (3.0 * ubis) - (20.0 * vbis)) / (4.0 * vbis)
        else:
            y = 0.0

        return xyz(x, y, z)

    def to_LuvLCh(self) -> LuvLCh:
        """Converts the given Luv color to LuvLCh space.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        # Oops, floating point workaround necessary if u ~= v and both are very small (i.e. almost zero).
        var h: Float64
        if abs(self.v - self.u) > 1e-4 and abs(self.u) > 1e-4:
            h = (57.29577951308232087721 * math.atan2(self.v, self.u) + 360.0) % 360.0  # Rad2Deg
        else:
            h = 0.0

        var l = self.L
        var c = math.sqrt(sq(self.u) + sq(self.v))

        return LuvLCh(l, c, h)
