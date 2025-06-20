import mist.termios.c
from mist.termios.c import InputFlag, OutputFlag, ControlFlag, LocalFlag, SpecialCharacter
from mist.termios.terminal import tcgetattr, tcsetattr, FlushOption, FlowOption, WhenOption


fn cfmakeraw(mut mode: c.Termios) -> None:
    """Make Termios mode raw.

    This is roughly equivalent to CPython's `cfmakeraw()`.
    Raw mode sets up the TTY driver to pass every character to the program as it is typed.

    Args:
        mode: Termios instance to modify in place.

    #### Notes:
    - Turns off post-processing of output.
    - Disables parity generation and detection.
    - Sets character size to 8 bits.
    - Blocks until 1 byte is read.
    """
    # Clear all POSIX.1-2017 input mode flags.
    # See chapter 11 "General Terminal Interface"
    # of POSIX.1-2017 Base Definitions.
    mode.c_iflag &= ~(
        InputFlag.IGNBRK.value
        | InputFlag.BRKINT.value
        | InputFlag.IGNPAR.value
        | InputFlag.PARMRK.value
        | InputFlag.INPCK.value
        | InputFlag.ISTRIP.value
        | InputFlag.INLCR.value
        | InputFlag.IGNCR.value
        | InputFlag.ICRNL.value
        | InputFlag.IXON.value
        | InputFlag.IXANY.value
        | InputFlag.IXOFF.value
    )

    # Do not post-process output.
    mode.c_oflag &= ~OutputFlag.OPOST.value

    # Disable parity generation and detection; clear character size mask;
    # let character size be 8 bits.
    mode.c_cflag &= ~(ControlFlag.PARENB.value | ControlFlag.CSIZE.value)
    mode.c_cflag |= ControlFlag.CS8.value

    # Clear all POSIX.1-2017 local mode flags.
    mode.c_lflag &= ~(
        LocalFlag.ECHO.value
        | LocalFlag.ECHOE.value
        | LocalFlag.ECHOK.value
        | LocalFlag.ECHONL.value
        | LocalFlag.ICANON.value
        | LocalFlag.IEXTEN.value
        | LocalFlag.ISIG.value
        | LocalFlag.NOFLSH.value
        | LocalFlag.TOSTOP.value
    )

    # POSIX.1-2017, 11.1.7 Non-Canonical Mode Input Processing,
    # Case B: MIN>0, TIME=0
    # A pending read shall block until MIN (here 1) bytes are received,
    # or a signal is received.
    mode.c_cc[SpecialCharacter.VMIN.value] = 1
    mode.c_cc[SpecialCharacter.VTIME.value] = 0


fn cfmakecbreak(mut mode: c.Termios):
    """Make Termios mode cbreak.
    This is roughly equivalent to CPython's `cfmakecbreak()`.

    - Turns off character echoing.
    - Disables canonical input.
    - Blocks until 1 byte is read.

    Args:
        mode: Termios instance to modify in place.
    """
    # Do not echo characters; disable canonical input.
    mode.c_lflag &= ~(LocalFlag.ECHO.value | LocalFlag.ICANON.value)

    # POSIX.1-2017, 11.1.7 Non-Canonical Mode Input Processing,
    # Case B: MIN>0, TIME=0
    # A pending read shall block until MIN (here 1) bytes are received,
    # or a signal is received.
    mode.c_cc[SpecialCharacter.VMIN.value] = 1
    mode.c_cc[SpecialCharacter.VTIME.value] = 0


fn set_raw(file: FileDescriptor, when: WhenOption = WhenOption.TCSAFLUSH) raises -> c.Termios:
    """Set terminal to raw mode.

    Args:
        file: File descriptor of the terminal.
        when: When to apply the changes. Default is TCSAFLUSH.

    Returns:
        The original terminal attributes, and an error if any.
    """
    var mode = tcgetattr(file)
    var new = mode.copy()
    cfmakeraw(new)
    tcsetattr(file, when, new)

    return mode


fn set_cbreak(file: FileDescriptor, when: WhenOption = WhenOption.TCSAFLUSH) raises -> c.Termios:
    """Set terminal to cbreak mode.

    Args:
        file: File descriptor of the terminal.
        when: When to apply the changes. Default is TCSAFLUSH.

    Returns:
        The original terminal attributes, and an error if any.
    """
    var mode = tcgetattr(file)
    var new = mode.copy()
    cfmakecbreak(new)
    tcsetattr(file, when, new)

    return mode


fn is_terminal_raw(file_descriptor: FileDescriptor) raises -> Bool:
    """Checks if a terminal is in raw mode.

    Args:
        file_descriptor: The file descriptor of the terminal to check.

    Returns:
        True if the terminal is in raw mode, False otherwise.
    """
    var state = termios.tcgetattr(file_descriptor)
    if not (state.c_lflag & LocalFlag.ICANON.value) and not (state.c_lflag & LocalFlag.ECHO.value):
        return True

    return False
