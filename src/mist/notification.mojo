from .style import OSC, ST


fn notify(title: String, body: String) -> None:
    """Sends a notification to the terminal.

    Args:
        title: The title of the notification.
        body: The body of the notification.
    """
    var output = String(capacity=14 + len(title) + len(body))
    output.write(OSC, "777;notify;", title, ";", body, ST)
    print(output, end="")
