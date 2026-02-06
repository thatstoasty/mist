from mist.event.internal import InternalEvent


trait EventSource:
    """Tries to read an `InternalEvent` within the given duration."""

    fn try_read(mut self, timeout: Optional[Int]) raises -> Optional[InternalEvent]:
        ...
