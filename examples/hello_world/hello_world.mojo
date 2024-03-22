from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main() raises:
    var profile = Profile("TrueColor")

    var a = TerminalStyle()
    a.bold()

    var b = TerminalStyle()
    b.faint()

    var c = TerminalStyle()
    c.italic()

    var d = TerminalStyle()
    d.faint()

    var e = TerminalStyle()
    e.underline()

    var f = TerminalStyle()
    f.crossout()

    print_no_newline("\n\t",
        a.render("bold"), 
        b.render("faint"), 
        c.render("italic"), 
        d.render("underline"), 
        e.render("faint"),
        f.render("crossout")
    )

    var red = TerminalStyle()
    red.foreground("#E88388")

    var green = TerminalStyle()
    green.foreground("#A8CC8C")

    var yellow = TerminalStyle()
    yellow.foreground("#DBAB79")

    var blue = TerminalStyle()
    blue.foreground("#71BEF2")

    var magenta = TerminalStyle()
    magenta.foreground("#D290E4")

    var cyan = TerminalStyle()
    cyan.foreground("#66C2CD")

    var gray = TerminalStyle()
    gray.foreground("#B9BFCA")

    print_no_newline("\n\t",
        red.render("red"), 
        green.render("green"), 
        yellow.render("yellow"), 
        blue.render("blue"), 
        magenta.render("magenta"),
        cyan.render("cyan"),
        gray.render("gray"),
    )

    var red_bg = TerminalStyle()
    red_bg.foreground(0)
    red_bg.background("#E88388")

    var green_bg = TerminalStyle()
    green_bg.foreground(0)
    green_bg.background("#A8CC8C")

    var yellow_bg = TerminalStyle()
    yellow_bg.foreground(0)
    yellow_bg.background("#DBAB79")

    var blue_bg = TerminalStyle()
    blue_bg.foreground(0)
    blue_bg.background("#71BEF2")

    var magenta_bg = TerminalStyle()
    magenta_bg.foreground(0)
    magenta_bg.background("#D290E4")

    var cyan_bg = TerminalStyle()
    cyan_bg.foreground(0)
    cyan_bg.background("#66C2CD")

    var gray_bg = TerminalStyle()
    gray_bg.foreground(0)
    gray_bg.background("#B9BFCA")

    print_no_newline("\n\t",
        red_bg.render("red"), 
        green_bg.render("green"), 
        yellow_bg.render("yellow"), 
        blue_bg.render("blue"), 
        magenta_bg.render("magenta"),
        cyan_bg.render("cyan"),
        gray_bg.render("gray"),
        "\n\n",
    )
