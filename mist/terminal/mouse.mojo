from mist.terminal.sgr import CSI


comptime ENABLE_MOUSE_PRESS = CSI + "?9h"
"""Enable press only (X10) `CSI + ?9 + h = \\x1b[?9h`."""
comptime DISABLE_MOUSE_PRESS = CSI + "?9l"
"""Disable press only (X10) `CSI + ?9 + l = \\x1b[?9l`."""
comptime ENABLE_MOUSE = CSI + "?1000h"
"""Enable press, release, wheel `CSI + ?1000 + h = \\x1b[?1000h`."""
comptime DISABLE_MOUSE = CSI + "?1000l"
"""Disable press, release, wheel `CSI + ?1000 + l = \\x1b[?1000l`."""
comptime ENABLE_MOUSE_HILITE = CSI + "?1001h"
"""Enable highlight `CSI + ?1001 + h = \\x1b[?1001h`."""
comptime DISABLE_MOUSE_HILITE = CSI + "?1001l"
"""Disable highlight `CSI + ?1001 + l = \\x1b[?1001l`."""
comptime ENABLE_MOUSE_ALL_MOTION = CSI + "?1003h"
"""Enable press, release, move on pressed, wheel `CSI + ?1003 + h = \\x1b[?1003h`."""
comptime DISABLE_MOUSE_ALL_MOTION = CSI + "?1003l"
"""Disable press, release, move on pressed, wheel `CSI + ?1003 + l = \\x1b[?1003l`."""
comptime ENABLE_MOUSE_CELL_MOTION = CSI + "?1002h"
"""Enable press, release, move on pressed, wheel `CSI + ?1002 + h = \\x1b[?1002h`."""
comptime DISABLE_MOUSE_CELL_MOTION = CSI + "?1002l"
"""Enable press, release, move on pressed, wheel `CSI + ?1002 + l = \\x1b[?1002l`."""
comptime ENABLE_MOUSE_EXTENDED_MODE = CSI + "?1006h"
"""Enable press, release, move, wheel, extended coordinates `CSI + ?1006 + h = \\x1b[?1006h`."""
comptime DISABLE_MOUSE_EXTENDED_MODE = CSI + "?1006l"
"""Disable press, release, move, wheel, extended coordinates `CSI + ?1006 + l = \\x1b[?1006l`."""
comptime ENABLE_MOUSE_PIXELS_MODE = CSI + "?1016h"
"""Enable press, release, move, wheel, extended pixel coordinates `CSI + ?1016 + h = \\x1b[?1016h`."""
comptime DISABLE_MOUSE_PIXELS_MODE = CSI + "?1016l"
"""Disable press, release, move, wheel, extended pixel coordinates `CSI + ?1016 + l = \\x1b[?1016l`."""


fn enable_mouse_press() -> None:
    """Enables X10 mouse mode. Button press events are sent only."""
    print(ENABLE_MOUSE_PRESS, sep="", end="")


fn disable_mouse_press() -> None:
    """Disables X10 mouse mode."""
    print(DISABLE_MOUSE_PRESS, sep="", end="")


fn enable_mouse() -> None:
    """Enables Mouse Tracking mode."""
    print(ENABLE_MOUSE, sep="", end="")


fn disable_mouse() -> None:
    """Disables Mouse Tracking mode."""
    print(DISABLE_MOUSE, sep="", end="")


fn enable_mouse_hilite() -> None:
    """Enables Hilite Mouse Tracking mode."""
    print(ENABLE_MOUSE_HILITE, sep="", end="")


fn disable_mouse_hilite() -> None:
    """Disables Hilite Mouse Tracking mode."""
    print(DISABLE_MOUSE_HILITE, sep="", end="")


fn enable_mouse_cell_motion() -> None:
    """Enables Cell Motion Mouse Tracking mode."""
    print(ENABLE_MOUSE_CELL_MOTION, sep="", end="")


fn disable_mouse_cell_motion() -> None:
    """Disables Cell Motion Mouse Tracking mode."""
    print(DISABLE_MOUSE_CELL_MOTION, sep="", end="")


fn enable_mouse_all_motion() -> None:
    """Enables All Motion Mouse mode."""
    print(ENABLE_MOUSE_ALL_MOTION, sep="", end="")


fn disable_mouse_all_motion() -> None:
    """Disables All Motion Mouse mode."""
    print(DISABLE_MOUSE_ALL_MOTION, sep="", end="")


fn enable_mouse_extended_mode() -> None:
    """Enables Extended Mouse mode (SGR).

    This should be enabled in conjunction with `enable_mouse_cell_motion`, and `enable_mouse_all_motion`.
    """
    print(ENABLE_MOUSE_EXTENDED_MODE, sep="", end="")


fn disable_mouse_extended_mode() -> None:
    """Disables Extended Mouse mode (SGR)."""
    print(DISABLE_MOUSE_EXTENDED_MODE, sep="", end="")


@fieldwise_init
@explicit_destroy("Calling `disable()` is required to disable mouse capture and restore normal terminal behavior.")
struct MouseCapture(Movable):
    """Linear struct to enable mouse capture on creation and guarantee disable on destruction."""

    @staticmethod
    fn enable() -> Self:
        """Enables mouse capture and returns a `MouseCapture` instance, which will disable mouse capture on destruction.
        """
        enable_mouse_all_motion()
        return Self()

    fn disable(deinit self) -> None:
        """Disables mouse capture."""
        disable_mouse_all_motion()


fn enable_mouse_pixels_mode() -> None:
    """Enables Pixel Motion Mouse mode (SGR-Pixels).

    This should be enabled in conjunction with `enable_mouse_cell_motion`, and
    `enable_mouse_all_motion`.
    """
    print(ENABLE_MOUSE_PIXELS_MODE, sep="", end="")


fn disable_mouse_pixels_mode() -> None:
    """Disables Pixel Motion Mouse mode (SGR-Pixels)."""
    print(DISABLE_MOUSE_PIXELS_MODE, sep="", end="")
