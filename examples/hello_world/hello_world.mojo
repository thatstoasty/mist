from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor

fn main() raises:
    let profile = Profile("TrueColor")

    var a = TerminalStyle(profile)
    a.bold()

    var b = TerminalStyle(profile)
    b.faint()

    var c = TerminalStyle(profile)
    c.italic()

    var d = TerminalStyle(profile)
    d.faint()

    var e = TerminalStyle(profile)
    e.underline()

    var f = TerminalStyle(profile)
    f.crossout()

    print_no_newline("\n\t",
        a.render("bold"), 
        b.render("faint"), 
        c.render("italic"), 
        d.render("underline"), 
        e.render("faint"),
        f.render("crossout")
    )

    var red = TerminalStyle(profile)
    red.foreground(RGBColor("#E88388"))

    var green = TerminalStyle(profile)
    green.foreground(RGBColor("#A8CC8C"))

    var yellow = TerminalStyle(profile)
    yellow.foreground(RGBColor("#DBAB79"))

    var blue = TerminalStyle(profile)
    blue.foreground(RGBColor("#71BEF2"))

    var magenta = TerminalStyle(profile)
    magenta.foreground(RGBColor("#D290E4"))

    var cyan = TerminalStyle(profile)
    cyan.foreground(RGBColor("#66C2CD"))

    var gray = TerminalStyle(profile)
    gray.foreground(RGBColor("#B9BFCA"))

    print_no_newline("\n\t",
        red.render("red"), 
        green.render("green"), 
        yellow.render("yellow"), 
        blue.render("blue"), 
        magenta.render("magenta"),
        cyan.render("cyan"),
        gray.render("gray"),
    )

    var red_bg = TerminalStyle(profile)
    red_bg.foreground(ANSIColor(0))
    red_bg.background(RGBColor("#E88388"))

    var green_bg = TerminalStyle(profile)
    green_bg.foreground(ANSIColor(0))
    green_bg.background(RGBColor("#A8CC8C"))

    var yellow_bg = TerminalStyle(profile)
    yellow_bg.foreground(ANSIColor(0))
    yellow_bg.background(RGBColor("#DBAB79"))

    var blue_bg = TerminalStyle(profile)
    blue_bg.foreground(ANSIColor(0))
    blue_bg.background(RGBColor("#71BEF2"))

    var magenta_bg = TerminalStyle(profile)
    magenta_bg.foreground(ANSIColor(0))
    magenta_bg.background(RGBColor("#D290E4"))

    var cyan_bg = TerminalStyle(profile)
    cyan_bg.foreground(ANSIColor(0))
    cyan_bg.background(RGBColor("#66C2CD"))

    var gray_bg = TerminalStyle(profile)
    gray_bg.foreground(ANSIColor(0))
    gray_bg.background(RGBColor("#B9BFCA"))

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
