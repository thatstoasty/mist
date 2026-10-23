"""CIE LCh(uv) color space, the cylindrical form of CIE L*u*v*."""
from std import math
from mist.color.spaces.hsluv import HSLuv
from mist.color.spaces.hpluv import HPLuv
from mist.color.spaces.luv import Luv
from mist.color.math import clamp01, in_range, max_chroma_for_lh, max_safe_chroma_for_l


struct LuvLCh(Equatable, ImplicitlyCopyable, Writable):
    """A color in the CIE LCh(uv) color space: L*u*v* expressed in cylindrical coordinates."""

    var L: Float64
    """Luminance, perceived brightness. In the range [0.0, 1.0]."""
    var C: Float64
    """Chroma, color intensity/saturation. In the range [0.0, 1.8]."""
    var h: Float64
    """Hue, angular direction of the color in degrees. In the range [0.0, 360.0]."""

    def __init__(out self, L: Float64, C: Float64, h: Float64):
        """Initializes the LuvLCh color from its components.

        Args:
            L: Luminance, perceived brightness. In the range [0.0, 1.0].
            C: Chroma, color intensity/saturation. In the range [0.0, 1.8].
            h: Hue, angular direction of the color in degrees. In the range [0.0, 360.0].
        """
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(C, 0.0, 1.8) and in_range(h, 0.0, 360.0),
            (
                t"The LuvLCh components must be in the range [0.0, 1.0] for L, [0.0, 1.8] for C, and [0.0, 360.0] for"
                t" h. Received ({L}, {C}, {h})."
            ),
        )
        self.L = L
        self.C = C
        self.h = h

    def __init__(out self, LCh: Tuple[Float64, Float64, Float64]):
        """Initializes the LuvLCh color from a tuple of components.

        Args:
            LCh: The (L, C, h) components.
        """
        var L = LCh[0]
        var C = LCh[1]
        var h = LCh[2]
        debug_assert(
            in_range(L, 0.0, 1.0) and in_range(C, 0.0, 1.8) and in_range(h, 0.0, 360.0),
            (
                t"The LuvLCh components must be in the range [0.0, 1.0] for L, [0.0, 1.8] for C, and [0.0, 360.0] for"
                t" h. Received ({L}, {C}, {h})."
            ),
        )

        self.L = L
        self.C = C
        self.h = h

    def to_HSLuv(self) -> HSLuv:
        """Converts the given LuvLCh color to HSLuv.
        [-1..1] but the code expects it to be [-100..100].

        Returns:
            The hue, saturation, and luminance values.
        """
        # [-1..1] but the code expects it to be [-100..100]
        var l = self.L * 100.0
        var c = self.C * 100.0

        var s = 0.0
        if l < 99.9999999 and l > 0.00000001:
            s = c / max_chroma_for_lh(l, self.h) * 100.0

        return HSLuv(self.h, clamp01(s / 100.0), clamp01(l / 100.0))

    def to_HPLuv(self) -> HPLuv:
        """Converts the given LuvLCh color to HPLuv.
        [-1..1] but the code expects it to be [-100..100].

        Returns:
            The hue, saturation, and luminance values.
        """
        var c = self.C * 100.0
        var l = self.L * 100.0

        var s = 0.0 if (l > 99.9999999 or l < 0.00000001) else (c / max_safe_chroma_for_l(l) * 100.0)
        return HPLuv(self.h, s / 100.0, l / 100.0)

    def to_Luv(self) -> Luv:
        """Converts the given LuvLCh color to Luv space.

        Returns:
            The Luminance, u*, and v* values.
        """
        var H = 0.01745329251994329576 * self.h  # Deg2Rad
        return Luv(self.L, self.C * math.cos(H), self.C * math.sin(H))
