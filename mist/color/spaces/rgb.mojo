"""Standard (sRGB) and linear RGB color spaces."""
from mist.color.math import in_range, linearize, linearize_fast
from mist.color.spaces.xyz import xyz


struct RGB[linear: Bool = False](Equatable, ImplicitlyCopyable, Writable):
    """A color in the sRGB color space, or in linear RGB when `linear` is True.

    Parameters:
        linear: Whether the components are linear rather than gamma-encoded sRGB."""

    var R: Float64
    """Red component of the color, in the range [0.0, 1.0]."""
    var G: Float64
    """Green component of the color, in the range [0.0, 1.0]."""
    var B: Float64
    """Blue component of the color, in the range [0.0, 1.0]."""

    def __init__(out self, r: Float64, g: Float64, b: Float64):
        """Initializes the RGB color from its components.

        Args:
            r: Red component of the color, in the range [0.0, 1.0].
            g: Green component of the color, in the range [0.0, 1.0].
            b: Blue component of the color, in the range [0.0, 1.0].
        """
        debug_assert(
            in_range(r, 0.0, 1.0) and in_range(g, 0.0, 1.0) and in_range(b, 0.0, 1.0),
            t"The RGB components must be in the range [0.0, 1.0]. Received ({r}, {g}, {b}).",
        )
        self.R = r
        self.G = g
        self.B = b

    def __init__(out self, rgb: Tuple[Float64, Float64, Float64]):
        """Initializes the RGB color from a tuple of components.

        Args:
            rgb: The (R, G, B) components.
        """
        var r = rgb[0]
        var g = rgb[1]
        var b = rgb[2]
        debug_assert(
            in_range(r, 0.0, 1.0) and in_range(g, 0.0, 1.0) and in_range(b, 0.0, 1.0),
            t"The RGB components must be in the range [0.0, 1.0]. Received ({r}, {g}, {b}).",
        )

        self.R = r
        self.G = g
        self.B = b

    def __init__(out self, r: UInt8, g: UInt8, b: UInt8):
        """Initializes the RGB color from 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            r: Red component of the color, from 0 to 255.
            g: Green component of the color, from 0 to 255.
            b: Blue component of the color, from 0 to 255.
        """
        self.R = Float64(r) / 255.0
        self.G = Float64(g) / 255.0
        self.B = Float64(b) / 255.0

    def __init__(out self, rgb: Tuple[UInt8, UInt8, UInt8]):
        """Initializes the RGB color from a tuple of 8-bit components, each scaled from [0, 255] to [0.0, 1.0].

        Args:
            rgb: The (R, G, B) components as 8-bit values.
        """
        self.R = Float64(rgb[0]) / 255.0
        self.G = Float64(rgb[1]) / 255.0
        self.B = Float64(rgb[2]) / 255.0

    def linearize[fast: Bool = False](self) -> RGB[linear=True] where not Self.linear:
        """Converts the RGB values to linear RGB values.

        Parameters:
            fast: If True, uses a faster but less accurate linearization method.

        Returns:
            The linear RGB values.
        """
        comptime if fast:
            return RGB[linear=True](linearize_fast(self.R), linearize_fast(self.G), linearize_fast(self.B))
        else:
            return RGB[linear=True](linearize(self.R), linearize(self.G), linearize(self.B))

    def to_xyz(self) -> xyz where Self.linear:
        """Converts the linear RGB values to xyz color space.

        Returns:
            The xyz representation of the color.
        """
        return xyz(
            0.41239079926595948 * self.R + 0.35758433938387796 * self.G + 0.18048078840183429 * self.B,
            0.21263900587151036 * self.R + 0.71516867876775593 * self.G + 0.072192315360733715 * self.B,
            0.019330818715591851 * self.R + 0.11919477979462599 * self.G + 0.95053215224966058 * self.B,
        )
