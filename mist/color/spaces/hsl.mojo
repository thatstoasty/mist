"""HSL (hue, saturation, lightness) color space."""
from mist.color.math import in_range


struct HSL(Equatable, ImplicitlyCopyable, Writable):
    """A color in the HSL color space: the hexcone model of gamma-encoded sRGB, not perceptually uniform."""

    var H: Float64
    """Hue component of the color, in the range [0.0, 360.0]."""
    var S: Float64
    """Saturation component of the color, in the range [0.0, 1.0]."""
    var L: Float64
    """Lightness component of the color, in the range [0.0, 1.0]."""

    def __init__(out self, H: Float64, S: Float64, L: Float64):
        """Initializes the HSL color from its components.

        Args:
            H: Hue component of the color, in the range [0.0, 360.0].
            S: Saturation component of the color, in the range [0.0, 1.0].
            L: Lightness component of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(H, 0.0, 360.0) and in_range(S, 0.0, 1.0) and in_range(L, 0.0, 1.0),
            t"The HSL components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({H}, {S}, {L}).",
        )
        self.H = H
        self.S = S
        self.L = L

    def __init__(out self, HSL: Tuple[Float64, Float64, Float64]):
        """Initializes the HSL color from a tuple of components.

        Args:
            HSL: The (H, S, L) components.
        """
        var H = HSL[0]
        var S = HSL[1]
        var L = HSL[2]
        debug_assert(
            in_range(H, 0.0, 360.0) and in_range(S, 0.0, 1.0) and in_range(L, 0.0, 1.0),
            t"The HSL components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({H}, {S}, {L}).",
        )

        self.H = H
        self.S = S
        self.L = L
