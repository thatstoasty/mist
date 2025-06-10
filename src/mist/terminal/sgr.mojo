from utils.write import write_buffered
import sys

# ANSI Operations
alias ESC = "\x1b"
"""Escape character."""
alias BEL = "\x07"
"""Bell character."""
alias CSI = "\x1b["
"""Control Sequence Introducer."""
alias OSC = "\x1b]"
"""Operating System Command."""
alias ST = "\x1b\\"
"""String Terminator."""


fn _write_sequence_to_stdout[*Ts: Writable](*args: *Ts) -> None:
    """Writes args to stdout. This is used instead of print to avoid
    allocating a new String for some of the terminal sequences.

    Previously, we wrote the sequence arguments to a String, then wrote the String
    to stdout. With this function, we write the sequence arguments directly to stdout.

    Args:
        args: The string to write.
    """
    var stdout = sys.stdout
    write_buffered(stdout, args, sep="", end="")
