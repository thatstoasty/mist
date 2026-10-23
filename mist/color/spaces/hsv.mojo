"""HSV (hue, saturation, value) color space."""
from mist.color.math import in_range


struct HSV(Equatable, ImplicitlyCopyable, Writable):
    """A color in the HSV color space."""

    var H: Float64
    """Hue component of the color, in the range [0.0, 360.0]."""
    var S: Float64
    """Saturation component of the color, in the range [0.0, 1.0]."""
    var V: Float64
    """Value component of the color, in the range [0.0, 1.0]."""

    def __init__(out self, H: Float64, S: Float64, V: Float64):
        """Initializes the HSV color from its components.

        Args:
            H: Hue component of the color, in the range [0.0, 360.0].
            S: Saturation component of the color, in the range [0.0, 1.0].
            V: Value component of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(H, 0.0, 360.0) and in_range(S, 0.0, 1.0) and in_range(V, 0.0, 1.0),
            t"The HSV components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({H}, {S}, {V}).",
        )
        self.H = H
        self.S = S
        self.V = V

    def __init__(out self, HSV: Tuple[Float64, Float64, Float64]):
        """Initializes the HSV color from a tuple of components.

        Args:
            HSV: The (H, S, V) components.
        """
        var H = HSV[0]
        var S = HSV[1]
        var V = HSV[2]
        debug_assert(
            in_range(H, 0.0, 360.0) and in_range(S, 0.0, 1.0) and in_range(V, 0.0, 1.0),
            t"The HSV components must be in the range [0.0, 360.0], [0.0, 1.0], [0.0, 1.0]. Received ({H}, {S}, {V}).",
        )

        self.H = H
        self.S = S
        self.V = V

    def __init__(out self, H: UInt8, S: UInt8, V: UInt8):
        """Initializes the HSV color from 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            H: Hue component of the color, from 0 to 255.
            S: Saturation component of the color, from 0 to 255.
            V: Value component of the color, from 0 to 255.
        """
        self.H = Float64(H) / 255.0
        self.S = Float64(S) / 255.0
        self.V = Float64(V) / 255.0

    def __init__(out self, HSV: Tuple[UInt8, UInt8, UInt8]):
        """Initializes the HSV color from a tuple of 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            HSV: The (H, S, V) components as 8-bit values.
        """
        self.H = Float64(HSV[0]) / 255.0
        self.S = Float64(HSV[1]) / 255.0
        self.V = Float64(HSV[2]) / 255.0
