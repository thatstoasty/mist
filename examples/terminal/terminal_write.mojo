from mist.terminal.tty import TTY


def main() raises -> None:
    with TTY() as tty:
        tty.write("Hello,", " world!\n")
