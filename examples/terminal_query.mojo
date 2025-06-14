from mist.terminal.query import get_terminal_size, get_background_color
from mist.terminal.tty import TTY
from mist.color import RGBColor


fn main() raises -> None:
    var color: RGBColor
    var rows: UInt
    var columns: UInt
    with TTY():
        color = get_background_color()
        rows, columns = get_terminal_size()
    print("Parsed color:", color)
    print("Terminal dimensions:", rows, "x", columns)
