"""HPLuv color space, a pastel-only variant of HSLuv."""
from mist.color.math import in_range


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

    def __init__(out self, h: UInt8, p: UInt8, l: UInt8):
        """Initializes the HPLuv color from 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            h: Hue component of the color, from 0 to 255.
            p: Perpendicular/Saturation component of the color, from 0 to 255.
            l: Luminance component of the color, from 0 to 255.
        """
        self.H = Float64(h) / 255.0
        self.P = Float64(p) / 255.0
        self.L = Float64(l) / 255.0

    def __init__(out self, hpl: Tuple[UInt8, UInt8, UInt8]):
        """Initializes the HPLuv color from a tuple of 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            hpl: The (H, P, L) components as 8-bit values.
        """
        self.H = Float64(hpl[0]) / 255.0
        self.P = Float64(hpl[1]) / 255.0
        self.L = Float64(hpl[2]) / 255.0
