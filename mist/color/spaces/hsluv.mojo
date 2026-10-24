"""HSLuv color space, a perceptually uniform alternative to HSL."""
from mist.color.math import clamp01, in_range, max_chroma_for_lh
from mist.color.spaces.luvlch import LuvLCh


struct HSLuv(Equatable, ImplicitlyCopyable, Writable):
    """A color in the HSLuv color space."""

    var H: Float64
    """Hue component of the color, in the range [0.0, 360.0]."""
    var S: Float64
    """Saturation component of the color, in the range [0.0, 1.0]."""
    var L: Float64
    """Luminance component of the color, in the range [0.0, 1.0]."""

    def __init__(out self, h: Float64, s: Float64, l: Float64):
        """Initializes the HSLuv color from its components.

        Args:
            h: Hue component of the color, in the range [0.0, 360.0].
            s: Saturation component of the color, in the range [0.0, 1.0].
            l: Luminance component of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(h, 0.0, 360.0) and in_range(s, 0.0, 1.0) and in_range(l, 0.0, 1.0),
            (
                t"The HSLuv components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({h}, {s},"
                t" {l})."
            ),
        )
        self.H = h
        self.S = s
        self.L = l

    def __init__(out self, hsl: Tuple[Float64, Float64, Float64]):
        """Initializes the HSLuv color from a tuple of components.

        Args:
            hsl: The (H, S, L) components.
        """
        var h = hsl[0]
        var s = hsl[1]
        var l = hsl[2]
        debug_assert(
            in_range(h, 0.0, 360.0) and in_range(s, 0.0, 1.0) and in_range(l, 0.0, 1.0),
            (
                t"The HSLuv components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({h}, {s},"
                t" {l})."
            ),
        )

        self.H = h
        self.S = s
        self.L = l

    def to_LuvLCh(self) -> LuvLCh:
        """Converts the HSLuv color to CIE LCh(uv), the inverse of `LuvLCh.to_HSLuv`.

        `S` is the chroma as a fraction of the largest in-gamut chroma for this lightness and hue.

        Returns:
            The Luminance, Chroma, and Hue values.
        """
        # The gamut bounds are computed with L and C in [0, 100], as in the HSLuv reference.
        var l = self.L * 100.0
        var c = 0.0
        if l < 99.9999999 and l > 0.00000001:
            c = max_chroma_for_lh(l, self.H) * self.S
        return LuvLCh(clamp01(l / 100.0), c / 100.0, self.H)
