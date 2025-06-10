from mist.terminal.sgr import OSC, ST, _write_sequence_to_stdout


fn notify(title: StringSlice, body: StringSlice) -> None:
    """Sends a notification to the terminal.

    Args:
        title: The title of the notification.
        body: The body of the notification.
    """
    _write_sequence_to_stdout(OSC, "777;notify;", title, ";", body, ST)
