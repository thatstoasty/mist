from mist.terminal import TTY


def main() raises -> None:
    with TTY() as tty:
        tty.write("Hello,", " world!\n")
