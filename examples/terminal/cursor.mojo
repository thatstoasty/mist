from mist.terminal.cursor import cursor_back
from mist.terminal.screen import clear_line_right


def main() raises:
    print("hello", end="")
    cursor_back(2)
    clear_line_right()
