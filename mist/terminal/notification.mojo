from mist.terminal.sgr import OSC, ST


fn notify(title: StringSlice, body: StringSlice) -> None:
    """Sends a notification to the terminal.

    Args:
        title: The title of the notification.
        body: The body of the notification.
    """
    print(OSC, "777;notify;", title, ";", body, ST, sep="", end="")
