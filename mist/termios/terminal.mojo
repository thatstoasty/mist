import sys._libc as libc
from sys import CompilationTarget
from sys._libc_errno import get_errno

import mist.termios.c


@fieldwise_init
@register_passable("trivial")
struct WhenOption:
    """TTY when values."""

    var value: Int32
    """Value for the option."""
    comptime TCSANOW = Self(0)
    """Change attributes immediately."""
    comptime TCSADRAIN = Self(1)
    """Change attributes after transmitting all queued output."""
    comptime TCSAFLUSH = Self(2)
    """Change attributes after transmitting all queued output and discarding all queued input."""
    comptime TCSASOFT = Self(16)
    """Change attributes without changing the terminal state."""


@fieldwise_init
@register_passable("trivial")
struct FlowOption:
    """TTY flow values."""

    var value: Int32
    """Value for the option."""
    comptime TCOOFF = Self(1) if CompilationTarget.is_macos() else Self(0)
    """Suspends output."""
    comptime TCOON = Self(2) if CompilationTarget.is_macos() else Self(1)
    """Transmits a STOP character, which stops the terminal device from transmitting data to the system."""
    comptime TCOFLUSH = Self(2) if CompilationTarget.is_macos() else Self(1)
    """Transmits a START character, which starts the terminal device transmitting data to the system."""
    comptime TCIOFLUSH = Self(3) if CompilationTarget.is_macos() else Self(2)
    """Flushes both data received but not read, and data written but not transmitted."""


@fieldwise_init
@register_passable("trivial")
struct FlushOption:
    """TTY flow values."""

    var value: Int32
    """Value for the option."""
    comptime TCIFLUSH = Self(0)
    """Flushes data received, but not read."""
    comptime TCOFLUSH = Self(1)
    """Flushes data written, but not transmitted."""
    comptime TCIOFLUSH = Self(2)
    """Flushes both data received, but not read. And data written, but not transmitted."""


fn tcgetattr(file: FileDescriptor) raises -> c.Termios:
    """Return the tty attributes for file descriptor.
    This is a wrapper around `c.tcgetattr()`.

    Args:
        file: File descriptor.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.

    Returns:
        Termios struct.
    """
    var terminal_attributes = c.Termios()
    # tcgetattr expects a mutable pointer, dunno why.
    var status = c.tcgetattr(file.value, Pointer(to=terminal_attributes))
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error("[EBADF] Failed to get tty attributes. The `file` argument is not a valid file descriptor.")
        elif errno == errno.ENOTTY:
            raise Error("[ENOTTY] Failed to get tty attributes. The file associated with `file` is not a terminal.")
        else:
            raise Error("Failed c.tcgetattr. Status: ", status)

    return terminal_attributes


fn tcsetattr(file: FileDescriptor, optional_actions: WhenOption, terminal_attributes: c.Termios) raises -> None:
    """Set the tty attributes for file descriptor `file` from the attributes,
    which is a list like the one returned by c.tcgetattr(). The when argument determines when the attributes are changed:
    This is a wrapper around `c.tcsetattr()`.

    Args:
        file: File descriptor.
        optional_actions: When to change the attributes.
        terminal_attributes: Termios struct containing the attributes to set.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [EINTR] If the call was interrupted by a signal.
        * Error: [EINVAL] If the `optional_actions` argument is not a supported value, or an attempt was made to change an attribute represented in the termios structure to an unsupported value.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.

    #### Notes:
    * `WhenOption.TCSANOW`: Change attributes immediately.
    * `WhenOption.TCSADRAIN`: Change attributes after transmitting all queued output.
    * `WhenOption.TCSAFLUSH`: Change attributes after transmitting all queued output and discarding all queued input.
    """
    var status = c.tcsetattr(file.value, optional_actions.value, Pointer(to=terminal_attributes))
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error("[EBADF] Failed to set tty attributes. The `file` argument is not a valid file descriptor.")
        elif errno == errno.EINTR:
            raise Error("[EINTR] Failed to set tty attributes. The call was interrupted by a signal.")
        elif errno == errno.EINVAL:
            raise Error(
                "[EINVAL] Failed to set tty attributes. The `optional_actions` argument is not a supported value, or an"
                " attempt was made to change an attribute represented in the termios structure to an unsupported value."
            )
        elif errno == errno.ENOTTY:
            raise Error("[ENOTTY] Failed to set tty attributes. The file associated with `file` is not a terminal.")
        elif errno == errno.EIO:
            raise Error(
                "[EIO] Failed to set tty attributes. The process group of the writing process is orphaned, and the"
                " writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to set tty attributes. ERRNO: ", errno)


fn tcsendbreak(file: FileDescriptor, duration: c.c_int) raises -> None:
    """Send a break on file descriptor `file`.
    A zero duration sends a break for 0.25 - 0.5 seconds; a nonzero duration has a system dependent meaning.

    Args:
        file: File descriptor.
        duration: Duration of break.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.
    """
    var status = c.tcsendbreak(file.value, duration)
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error(
                "[EBADF] Failed to send break to file descriptor. The `file` argument is not a valid file descriptor."
            )
        elif errno == errno.ENOTTY:
            raise Error(
                "[ENOTTY] Failed to send break to file descriptor. The file associated with `file` is not a terminal."
            )
        elif errno == errno.EIO:
            raise Error(
                "[EIO] Failed to send break to file descriptor. The process group of the writing process is orphaned,"
                " and the writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to send break to file descriptor. ERRNO: ", errno)


fn tcdrain(file: FileDescriptor) raises -> None:
    """Wait until all output written to the object referred to by `file` has been transmitted.

    Args:
        file: File descriptor of the file to drain.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [EINTR] If the call was interrupted by a signal.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.
    """
    var status = c.tcdrain(file.value)
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error(
                "[EBADF] Failed to wait for output transmission. The `file` argument is not a valid file descriptor."
            )
        elif errno == errno.EINTR:
            raise Error("[EINTR] Failed to wait for output transmission. The call was interrupted by a signal.")
        elif errno == errno.ENOTTY:
            raise Error(
                "[ENOTTY] Failed to wait for output transmission. The file associated with `file` is not a terminal."
            )
        elif errno == errno.EIO:
            raise Error(
                "[EIO] Failed to wait for output transmission. The process group of the writing process is orphaned,"
                " and the writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to wait for output transmission. ERRNO: ", errno)


fn tcflush(file: FileDescriptor, queue_selector: FlushOption) raises -> None:
    """Discard queued data on file descriptor `file`.

    Args:
        file: File descriptor to flush.
        queue_selector: Queue selector option.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [EINVAL] If the `queue_selector` argument is not a supported value.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.

    #### Notes:
    * The queue selector specifies which queue:
        - `FlushOption.TCIFLUSH` for the input queue.
        - `FlushOption.TCOFLUSH` for the output queue.
        - `FlushOption.TCIOFLUSH` for both queues.
    """
    var status = c.tcflush(file.value, queue_selector.value)
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error("[EBADF] Failed to flush queued data. The `file` argument is not a valid file descriptor.")
        elif errno == errno.EINVAL:
            raise Error("[EINVAL] Failed to flush queued data. The `queue_selector` argument is not a supported value.")
        elif errno == errno.ENOTTY:
            raise Error("[ENOTTY] Failed to flush queued data. The file associated with `file` is not a terminal.")
        elif errno == errno.EIO:
            raise Error(
                "[EIO] Failed to flush queued data. The process group of the writing process is orphaned, and the"
                " writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to flush queued data. ERRNO: ", errno)


fn tcflow(file: FileDescriptor, action: FlowOption) raises -> None:
    """Suspend or resume input or output on file descriptor `file`.

    Args:
        file: File descriptor to suspend or resume I/O.
        action: Action to perform.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [EINVAL] If the `action` argument is not a supported value.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.

    #### Notes:
    * `FlowOption.TCOOFF`: Suspends output.
    * `FlowOption.TCOON`: Restarts suspended output.
    * `FlowOption.TCIOFF`: Transmits a STOP character, which stops the terminal device from transmitting data to the system.
    * `FlowOption.TCION`: Transmits a START character, which starts the terminal device transmitting data to the system.
    """
    var status = c.tcflow(file.value, action.value)
    if status != 0:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error("[EBADF] Failed to suspend or resume I/O. The `file` argument is not a valid file descriptor.")
        elif errno == errno.EINVAL:
            raise Error("[EINVAL] Failed to suspend or resume I/O. The `action` argument is not a supported value.")
        elif errno == errno.ENOTTY:
            raise Error("[ENOTTY] Failed to suspend or resume I/O. The file associated with `file` is not a terminal.")
        elif errno == errno.EIO:
            raise Error(
                "[EIO] Failed to suspend or resume I/O. The process group of the writing process is orphaned, and the"
                " writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to suspend or resume I/O. ERRNO: ", errno)


fn tty_name(file_descriptor: FileDescriptor) raises -> String:
    """Return the name of the terminal associated with the file descriptor.

    Args:
        file_descriptor: File descriptor to get the terminal name from.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [ENODEV] If the file descriptor refers to a slave pseudoterminal device,
        but the corresponding pathname could not be found.
        * Error: [ENOTTY] If the file associated with `file_descriptor` is not a terminal.

    Returns:
        The name of the terminal as a string.
    """
    var name = c.ttyname(file_descriptor.value)
    if not name:
        var errno = get_errno()
        if errno == errno.EBADF:
            raise Error("[EBADF] The `file_descriptor` argument is not a valid file descriptor.")
        elif errno == errno.ENODEV:
            raise Error(
                "[ENODEV] The file descriptor refers to a slave pseudoterminal device, but the corresponding pathname"
                " could not be found."
            )
        elif errno == errno.ENOTTY:
            raise Error("[ENOTTY] The file associated with `file_descriptor` is not a terminal.")
        else:
            raise Error("Failed to get tty name. ERRNO: ", errno)

    # Copy the contents of the C string to a Mojo string.
    # Then free the C string to avoid memory leaks.
    var result = String(unsafe_from_utf8_ptr=name)
    libc.free(name.bitcast[NoneType]())

    return result


# Not available from libc
# fn tc_getwinsize(file_descriptor: c.c_int) raises -> winsize:
#     """Return the window size of the terminal associated to file descriptor file_descriptor as a winsize object. The winsize object is a named tuple with four fields: ws_row, ws_col, ws_xpixel, and ws_ypixel.
#     """
#     var winsize_p = winsize()
#     var status = tcgetwinsize(file_descriptor, Pointer(to=winsize_p))
#     if status != 0:
#         raise Error("Failed tcgetwinsize." + String(status))

#     return winsize_p


# fn tc_setwinsize(file_descriptor: c.c_int, winsize: Int32) raises -> Int32:
#     var status = tcsetwinsize(file_descriptor, winsize)
#     if status != 0:
#         raise Error("Failed tcsetwinsize." + String(status))

#     return status
