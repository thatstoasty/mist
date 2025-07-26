"""The termios library provides an interface for controlling asynchronous communications ports, including terminal devices. It allows you to modify the behavior of standard input (stdin), standard output (stdout), and standard error (stderr), which are the standard streams that processes use to interact with the operating system.

Here's how termios relates to stdin, stdout, and stderr:
* **stdin**: The termios library can be used to modify how data is read from standard input. This includes settings like:
  * Canonical vs. Non-canonical mode: You can configure stdin to operate in either canonical mode (buffered line input) or non-canonical mode (unbuffered character input).
  * Special character processing: You can define or change special characters like backspace, erase, interrupt, etc., that control input editing and signal handling.
  * Input flags: You can control input parity checking, ignore break conditions, or map characters like carriage return to newline on input.
* **stdout**: termios can be used to control how data is written to standard output. This involves settings like:
  * Output flags: You can configure output post-processing, map characters like newline to carriage return-newline on output, or control horizontal tab delays.
  * Flushing output: You can use functions like tcflush() with TCOFLUSH to discard untransmitted output.
* **stderr**: Standard error is typically treated similarly to stdout, although it's used for error messages.

In summary, termios allows you to customize the behavior of terminal devices,
including their handling of input (stdin) and output (stdout and stderr) by manipulating
the termios structure and using functions like `tcgetattr()` and `tcsetattr()`.
"""
from mist.termios.c import ControlFlag, InputFlag, LocalFlag, OutputFlag, SpecialCharacter, Termios
from mist.termios.terminal import is_a_tty, tcdrain, tcflow, tcflush, tcgetattr, tcsendbreak, tcsetattr, tty_name
from mist.termios.tty import FlowOption, FlushOption, WhenOption, cfmakecbreak, cfmakeraw, set_cbreak, set_raw
