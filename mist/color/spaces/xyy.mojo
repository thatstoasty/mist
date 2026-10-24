"""CIE xyY color space."""
from mist.color.math import in_range

from mist.color.spaces.xyz import xyz


struct xyY(Equatable, ImplicitlyCopyable, Writable):
    """A color in the CIE xyY color space."""

    var x: Float64
    """Chromaticity of the color, in the range [0.0, 1.0]."""
    var y: Float64
    """Chromaticity of the color, in the range [0.0, 1.0]."""
    var Y: Float64
    """Luminance/Brightness of the color, in the range [0.0, 1.0]."""

    def __init__(out self, x: Float64, y: Float64, Y: Float64):
        """Initializes the xyY color from its components.

        Args:
            x: Chromaticity of the color, in the range [0.0, 1.0].
            y: Chromaticity of the color, in the range [0.0, 1.0].
            Y: Luminance/Brightness of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(x, 0.0, 1.0) and in_range(y, 0.0, 1.0) and in_range(Y, 0.0, 1.0),
            t"The xyY components must be in the range [0.0, 1.0]. Received ({x}, {y}, {Y}).",
        )
        self.x = x
        self.y = y
        self.Y = Y

    def __init__(out self, xyz: Tuple[Float64, Float64, Float64]):
        """Initializes the xyY color from a tuple of components.

        Args:
            xyz: The (x, y, Y) components.
        """
        var x = xyz[0]
        var y = xyz[1]
        var Y = xyz[2]
        debug_assert(
            in_range(x, 0.0, 1.0) and in_range(y, 0.0, 1.0) and in_range(Y, 0.0, 1.0),
            t"The xyY components must be in the range [0.0, 1.0]. Received ({x}, {y}, {Y}).",
        )

        self.x = x
        self.y = y
        self.Y = Y

    def to_xyz(self) -> xyz:
        """Converts the given CIE xyY color to XYZ space.

        Returns:
            The XYZ values.
        """
        if -1e-14 < self.y and self.y < 1e-14:
            return xyz(0.0, self.Y, 0.0)

        var xout = self.Y / self.y * self.x
        var zout = self.Y / self.y * (1.0 - self.x - self.y)
        return xyz(xout, self.Y, zout)
