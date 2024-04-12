from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var profile = Profile()

    print("\n\t",
        TerminalStyle.new().bold().render("bold"), 
        TerminalStyle.new().faint().render("faint"), 
        TerminalStyle.new().italic().render("italic"), 
        TerminalStyle.new().underline().render("underline"), 
        TerminalStyle.new().faint().render("faint"),
        TerminalStyle.new().crossout().render("crossout"),
        end=""
    )

    print("\n\t",
        TerminalStyle.new().foreground(profile.color("#E88388")).render("red"), 
        TerminalStyle.new().foreground(profile.color("#A8CC8C")).render("green"), 
        TerminalStyle.new().foreground(profile.color("#DBAB79")).render("yellow"), 
        TerminalStyle.new().foreground(profile.color("#71BEF2")).render("blue"), 
        TerminalStyle.new().foreground(profile.color("#D290E4")).render("magenta"),
        TerminalStyle.new().foreground(profile.color("#66C2CD")).render("cyan"),
        TerminalStyle.new().foreground(profile.color("#B9BFCA")).render("gray"),
        end="",
    )

    print("\n\t",
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#E88388")).render("red"), 
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#A8CC8C")).render("green"), 
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#DBAB79")).render("yellow"), 
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#71BEF2")).render("blue"), 
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#D290E4")).render("magenta"),
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#66C2CD")).render("cyan"),
        TerminalStyle.new().foreground(profile.color("0")).background(profile.color("#B9BFCA")).render("gray"),
        "\n\n",
        end=""
    )
