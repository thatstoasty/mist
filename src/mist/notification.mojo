from .style import OSC, ST


fn notify(title: String, body: String) -> None:
    """Sends a notification to the terminal.

    Args:
        title: The title of the notification.
        body: The body of the notification.
    """
    print(String(OSC, "777;notify;", title, ";", body, ST), end="")
