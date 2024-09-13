from mist.screen import cursor_back, clear_line_right


fn main():
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
