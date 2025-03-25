from mist.terminal.screen import cursor_back, clear_line_right


fn main() raises:
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
