from mist import TerminalStyle

fn main():
    var base_style = TerminalStyle()
    base_style.color("red")
    base_style.bold()
    base_style.crossout()
    print(base_style.render("Hello World!"))