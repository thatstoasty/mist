from mist.collections import contains
from mist.color import (
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_ansi256,
    ansi256_to_ansi,
    hex_to_rgb,
)


# Currently not used, but will be in the future once we have a way to check types or have variables in traits.
# For now, we can't really make use of the color degradation functions here.
@value
struct Profile:
    var setting: String

    fn __init__(inout self, setting: String = "TrueColor") raises:
        """
        Initialize a new profile with the given setting.

        Args:
            setting: The setting to use for this profile. Valid values: ["TrueColor", "ANSI256", "ANSI", "ASCII"].
        """
        var valid: DynamicVector[String] = DynamicVector[String]()
        valid.append("TrueColor")
        valid.append("ANSI256")
        valid.append("ANSI")
        valid.append("ASCII")

        if not contains(valid, setting):
            raise Error(
                "Invalid setting, valid values are ['TrueColor', 'ANSI256', 'ANSI',"
                " 'ASCII']"
            )

        self.setting = setting
    
    fn convert(self, color: AnyColor) raises -> AnyColor:
        if self.setting == "ASCII":
            return NoColor()

        if color.isa[NoColor]():
            return color.get[NoColor]()
        elif color.isa[ANSIColor]():
            return color.get[ANSIColor]()
        elif color.isa[ANSI256Color]():
            if self.setting == "ANSI":
                return ansi256_to_ansi(color.get[ANSIColor]().value)
            
            return color.get[ANSIColor]()
        elif color.isa[RGBColor]():
            let h = hex_to_rgb(color.get[RGBColor]().value)

            if self.setting != "TrueColor":
                let ansi256 = hex_to_ansi256(h)
                if self.setting == "ANSI":
                    return ansi256_to_ansi(ansi256.value)

                return ansi256
            
            return color.get[RGBColor]()

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color.get[NoColor]()

    fn color(self, s: String) raises -> AnyColor:
        """Color creates a Color from a string. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255)."""
        if len(s) == 0:
            raise Error("No string passed to color function for formatting!")

        if s[0] == "#":
            let c = RGBColor(s)
            return self.convert(c)
        else:
            let i = atol(s)
            if i < 16:
                let c = ANSIColor(i)
                return self.convert(c)
            elif i < 256:
                let c = ANSI256Color(i)
                return self.convert(c)
            else:
                raise Error("Invalid color code, must be between 0 and 255")
