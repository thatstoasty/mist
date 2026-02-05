@fieldwise_init
@register_passable("trivial")
struct Event(Boolable, Equatable, ImplicitlyCopyable):
    """Represents an event that can be monitored by the `select` function."""

    var value: Int
    """Internal value representing the event."""
    comptime READ = Self(1)
    """Event for read operations."""
    comptime WRITE = Self(2)
    """Event for write operations."""
    comptime READ_WRITE = Self(3)
    """Event for both read and write operations."""

    fn __eq__(self, other: Self) -> Bool:
        """Equality comparison.

        Args:
            other: The other event to compare with.

        Returns:
            True if the events are equal, False otherwise.
        """
        return self.value == other.value

    fn __or__(self, rhs: Self) -> Self:
        """Bitwise OR operation.

        Args:
            rhs: The right-hand side event to OR with.

        Returns:
            A new `Event` instance representing the result of the OR operation.
        """
        return Self(self.value | rhs.value)

    fn __ior__(mut self, rhs: Self) -> None:
        """Bitwise OR operation.

        Args:
            rhs: The right-hand side event to OR with.
        """
        self = Self(self.value | rhs.value)

    fn __ror__(mut self, lhs: Self) -> None:
        """Bitwise OR operation.

        Args:
            lhs: The left-hand side event to OR with.
        """
        self = Self(lhs.value | self.value)

    fn __and__(self, rhs: Self) -> Self:
        """Bitwise AND operation.

        Args:
            rhs: The right-hand side event to AND with.

        Returns:
            A new `Event` instance representing the result of the AND operation.
        """
        return Self(self.value & rhs.value)

    fn __bool__(self) -> Bool:
        """Boolean conversion.

        Returns:
            True if the event is not zero, False otherwise.
        """
        return self.value != 0
