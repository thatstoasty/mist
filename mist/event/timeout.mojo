from std.time import perf_counter_ns


def _get_time_ns() -> Int:
    """Get current time in nanoseconds.

    Returns:
        Current time in nanoseconds since some epoch.
    """
    return Int(perf_counter_ns())


struct PollTimeout(ImplicitlyCopyable, Writable):
    """Helper for tracking poll timeout remaining time.

    This is a simplified version that tracks elapsed time to determine
    how much timeout remains for subsequent poll/select calls.
    """

    var timeout_micros: Optional[Int]
    """Original timeout in microseconds, or None for indefinite."""
    var start_time_ns: Int
    """Start time in nanoseconds."""

    def __init__(out self, timeout_micros: Optional[Int]):
        """Initialize a poll timeout.

        Args:
            timeout_micros: Timeout in microseconds, or None for indefinite wait.
        """
        self.timeout_micros = timeout_micros
        self.start_time_ns = _get_time_ns()

    def leftover(self) -> Optional[Int]:
        """Get the remaining timeout in microseconds.

        Returns:
            Remaining time in microseconds, or None for indefinite.
            Returns 0 if timeout has elapsed.
        """
        if not self.timeout_micros:
            return None

        var elapsed_ns = _get_time_ns() - self.start_time_ns
        var elapsed_micros = elapsed_ns // 1000
        var remaining = self.timeout_micros.value() - elapsed_micros

        if remaining <= 0:
            return 0
        return remaining

    def elapsed(self) -> Bool:
        """Check if the timeout has elapsed.

        Returns:
            True if timeout has elapsed, False otherwise.
        """
        if not self.timeout_micros:
            return False

        var remaining = self.leftover()
        if not remaining:
            return False
        return remaining.value() == 0

    def is_zero(self) -> Bool:
        """Check if the remaining timeout is zero.

        Returns:
            True if remaining time is zero, False otherwise.
        """
        var remaining = self.leftover()
        if not remaining:
            return False
        return remaining.value() == 0
