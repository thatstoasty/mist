from mist.event.internal import InternalEvent


trait EventSource:
    """Tries to read an `InternalEvent` within the given duration."""

    def try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
        """Tries to read an `InternalEvent` within the given duration.

        Args:
            timeout: An optional timeout for the read operation. If None, this will block indefinitely until an event is received.

        Returns:
            An Optional[InternalEvent] containing the event read from the event source, or None if no events are available.

        Raises:
            Any errors raised by the event source while trying to read an event.
        """
        ...
