from mist.terminal.tty import TTY


fn main() raises -> None:
    with TTY() as tty:
        tty.write("Hello,", " world!\n")
