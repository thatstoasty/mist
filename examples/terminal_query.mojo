from mist.terminal.query import get_terminal_size, get_background_color, has_dark_background
from mist.terminal.tty import TTY
from mist.color import RGBColor


fn main() raises -> None:
    var color: RGBColor
    var rows: UInt
    var columns: UInt
    var is_dark_background: Bool
    with TTY():
        color = get_background_color()
        rows, columns = get_terminal_size()
        is_dark_background = has_dark_background()
    print("Parsed color:", color, "Is dark background:", is_dark_background)
    print("Terminal dimensions:", rows, "x", columns)
