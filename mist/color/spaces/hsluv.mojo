"""HSLuv color space, a perceptually uniform alternative to HSL."""
from mist.color.math import in_range


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

    def __init__(out self, h: UInt8, s: UInt8, l: UInt8):
        """Initializes the HSLuv color from 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            h: Hue component of the color, from 0 to 255.
            s: Saturation component of the color, from 0 to 255.
            l: Luminance component of the color, from 0 to 255.
        """
        self.H = Float64(h) / 255.0
        self.S = Float64(s) / 255.0
        self.L = Float64(l) / 255.0

    def __init__(out self, hsl: Tuple[UInt8, UInt8, UInt8]):
        """Initializes the HSLuv color from a tuple of 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            hsl: The (H, S, L) components as 8-bit values.
        """
        self.H = Float64(hsl[0]) / 255.0
        self.S = Float64(hsl[1]) / 255.0
        self.L = Float64(hsl[2]) / 255.0
