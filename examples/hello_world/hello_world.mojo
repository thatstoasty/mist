from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var profile = Profile("TrueColor")

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
        TerminalStyle.new().foreground("#E88388").render("red"), 
        TerminalStyle.new().foreground("#A8CC8C").render("green"), 
        TerminalStyle.new().foreground("#DBAB79").render("yellow"), 
        TerminalStyle.new().foreground("#71BEF2").render("blue"), 
        TerminalStyle.new().foreground("#D290E4").render("magenta"),
        TerminalStyle.new().foreground("#66C2CD").render("cyan"),
        TerminalStyle.new().foreground("#B9BFCA").render("gray"),
        end="",
    )

    print("\n\t",
        TerminalStyle.new().foreground("0").background("#E88388").render("red"), 
        TerminalStyle.new().foreground("0").background("#A8CC8C").render("green"), 
        TerminalStyle.new().foreground("0").background("#DBAB79").render("yellow"), 
        TerminalStyle.new().foreground("0").background("#71BEF2").render("blue"), 
        TerminalStyle.new().foreground("0").background("#D290E4").render("magenta"),
        TerminalStyle.new().foreground("0").background("#66C2CD").render("cyan"),
        TerminalStyle.new().foreground("0").background("#B9BFCA").render("gray"),
        "\n\n",
        end=""
    )
