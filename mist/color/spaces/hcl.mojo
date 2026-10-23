"""HCL color space, the cylindrical form of CIE L*a*b*."""
from mist.color.math import in_range

from std import math
from mist.color.spaces.lab import Lab


struct hcl(Equatable, ImplicitlyCopyable, Writable):
    """A color in the HCL color space: L*a*b* expressed in cylindrical coordinates."""

    var h: Float64
    """Hue. In the range [0.0, 360.0]."""
    var c: Float64
    """Chroma. In the range [0.0, 1.4]."""
    var l: Float64
    """Luminance. In the range [0.0, 1.0]."""

    def __init__(out self, h: Float64, c: Float64, l: Float64):
        """Initializes the HCL color from its components.

        Args:
            h: Hue. In the range [0.0, 360.0].
            c: Chroma. In the range [0.0, 1.4].
            l: Luminance. In the range [0.0, 1.0].
        """
        debug_assert(
            in_range(h, 0.0, 360.0) and in_range(c, 0.0, 1.4) and in_range(l, 0.0, 1.0),
            (
                t"The hcl components must be in the range [0.0, 360.0] for h, [0.0, 1.4] for c, and [0.0, 1.0] for l."
                t" Received ({h}, {c}, {l})."
            ),
        )
        self.h = h
        self.c = c
        self.l = l

    def __init__(out self, hcl: Tuple[Float64, Float64, Float64]):
        """Initializes the HCL color from a tuple of components.

        Args:
            hcl: The (h, c, l) components.
        """
        var h = hcl[0]
        var c = hcl[1]
        var l = hcl[2]
        debug_assert(
            in_range(h, 0.0, 360.0) and in_range(c, 0.0, 1.4) and in_range(l, 0.0, 1.0),
            (
                t"The hcl components must be in the range [0.0, 360.0] for h, [0.0, 1.4] for c, and [0.0, 1.0] for l."
                t" Received ({h}, {c}, {l})."
            ),
        )

        self.h = h
        self.c = c
        self.l = l

    def to_Lab(self) -> Lab:
        """Converts the given HCL color to L*a*b* space.

        Returns:
            The L*, a*, and b* values.
        """
        var H = 0.01745329251994329576 * self.h  # Deg2Rad
        var a = self.c * math.cos(H)
        var b = self.c * math.sin(H)
        return Lab(self.l, a, b)
