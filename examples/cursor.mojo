from mist.terminal.cursor import clear_line_right, cursor_back


fn main() raises:
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
