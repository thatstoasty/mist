from mist.style import RGBColor
from mist.terminal import TTY, Mode, Cursor, set_cursor_color, get_cursor_color


def main() raises:
    var color: RGBColor
    with TTY[Mode.RAW]():
        color = get_cursor_color()

    print(t"Current cursor color: {color}")
    set_cursor_color(RGBColor(0x1793d0))
    print("The cursor is blue now!")
    print("Resetting cursor color...")
    set_cursor_color(color)

    # alternatively, using Cursor struct to enforce resetting the color
    var cursor_color = Cursor.set_color(RGBColor(0xd01793), initial_color=color)
    print("The cursor is pink now!", end="\r\n")
    print("Resetting cursor color...", end="\r\n")
    cursor_color^.reset()
