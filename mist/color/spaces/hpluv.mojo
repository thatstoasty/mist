"""HPLuv color space, a pastel-only variant of HSLuv."""
from mist.color.math import in_range, max_safe_chroma_for_l
from mist.color.spaces.luvlch import LuvLCh


struct HPLuv(Equatable, ImplicitlyCopyable, Writable):
    """A color in the HPLuv color space."""

    var H: Float64
    """Hue component of the color, in the range [0.0, 360.0]."""
    var P: Float64
    """Perpendicular/Saturation component of the color, 0.0 or greater. Exceeds 1.0 for colors HPLuv cannot represent."""
    var L: Float64
    """Luminance component of the color, in the range [0.0, 1.0]."""

    def __init__(out self, h: Float64, p: Float64, l: Float64):
        """Initializes the HPLuv color from its components.

        Args:
            h: Hue component of the color, in the range [0.0, 360.0].
            p: Perpendicular/Saturation component of the color, 0.0 or greater. Exceeds 1.0 for colors HPLuv cannot represent.
            l: Luminance component of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(h, 0.0, 360.0) and p >= 0.0 and in_range(l, 0.0, 1.0),
            (
                t"The HPLuv components must be in the range [0.0, 360.0], [0.0, inf), [0.0, 1.0]. Received ({h}, {p},"
                t" {l})."
            ),
        )
        self.H = h
        self.P = p
        self.L = l

    def __init__(out self, hpl: Tuple[Float64, Float64, Float64]):
        """Initializes the HPLuv color from a tuple of components.

        Args:
            hpl: The (H, P, L) components.
        """
        var h = hpl[0]
        var p = hpl[1]
        var l = hpl[2]
        debug_assert(
            in_range(h, 0.0, 360.0) and p >= 0.0 and in_range(l, 0.0, 1.0),
            (
                t"The HPLuv components must be in the range [0.0, 360.0], [0.0, inf), [0.0, 1.0]. Received ({h}, {p},"
                t" {l})."
            ),
        )

        self.H = h
        self.P = p
        self.L = l

    def to_LuvLCh(self) -> LuvLCh:
        """Converts the HPLuv color to CIE LCh(uv), the inverse of `LuvLCh.to_HPLuv`.

        `P` is the chroma as a fraction of the largest chroma in gamut for every hue at this lightness.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        # The gamut bounds are computed with L and C in [0, 100], as in the HSLuv reference.
        var l = self.L * 100.0
        var c = 0.0
        if l < 99.9999999 and l > 0.00000001:
            c = max_safe_chroma_for_l(l) * self.P
        return LuvLCh(l / 100.0, c / 100.0, self.H)
