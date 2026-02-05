from mist.terminal.sgr import BEL, CSI, OSC


comptime ENABLE_FOCUS_CHANGE = CSI + "?1004h"
"""Enable focus change tracking `CSI + ?1004 + h = \\x1b[?1004h`."""
comptime DISABLE_FOCUS_CHANGE = CSI + "?1004l"
"""Disable focus change tracking `CSI + ?1004 + l = \\x1b[?1004l`."""


fn enable_focus_change() -> None:
    """Enables focus change tracking."""
    print(ENABLE_FOCUS_CHANGE, sep="", end="")


fn disable_focus_change() -> None:
    """Disables focus change tracking."""
    print(DISABLE_FOCUS_CHANGE, sep="", end="")


@fieldwise_init
@explicit_destroy(
    "Calling `disable()` is required to disable focus change tracking and restore normal terminal behavior."
)
struct FocusChange(Movable):
    """Linear struct to enable focus change tracking on creation and guarantee disable on destruction."""

    @staticmethod
    fn enable() -> Self:
        """Enables focus change tracking and returns a `FocusChange` instance, which will disable focus change tracking on destruction.
        """
        enable_focus_change()
        return Self()

    fn disable(deinit self) -> None:
        """Disables focus change tracking."""
        disable_focus_change()
