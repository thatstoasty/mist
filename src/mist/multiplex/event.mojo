@fieldwise_init
@register_passable("trivial")
struct Event(Copyable, ExplicitlyCopyable, Movable):
    """Event represents a bitmask for file descriptor events.
    It supports bitwise operations and comparisons.
    """

    var value: Int
    """Event represents a bitmask for file descriptor events."""
    alias READ = Self(1)
    """Event for reading from a file descriptor."""
    alias WRITE = Self(2)
    """Event for writing to a file descriptor."""
    alias READ_WRITE = Self(3)
    """Event for both reading and writing to a file descriptor."""

    fn __eq__(self, other: Self) -> Bool:
        """Equality comparison.

        Args:
            other: The other Event to compare with.

        Returns:
            True if the values are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Inequality comparison.

        Args:
            other: The other Event to compare with.

        Returns:
            True if the values are not equal, False otherwise.
        """
        return self.value != other.value

    fn __or__(self, rhs: Self) -> Self:
        """Bitwise OR operation.

        Args:
            rhs: The other Event to compare bitwise OR with.

        Returns:
            A new Event with the result of the bitwise OR operation.
        """
        return Self(self.value | rhs.value)

    fn __ior__(mut self, rhs: Self) -> None:
        """Bitwise OR operation.

        Args:
            rhs: The other Event to compare bitwise OR with.
        """
        self = Self(self.value | rhs.value)

    fn __ror__(mut self, lhs: Self) -> None:
        """Bitwise OR operation.

        Args:
            lhs: The other Event to compare bitwise OR with.
        """
        self = Self(lhs.value | self.value)

    fn __and__(self, rhs: Self) -> Self:
        """Bitwise AND operation.

        Args:
            rhs: The other Event to AND with.

        Returns:
            A new Event with the result of the AND operation.
        """
        return Self(self.value & rhs.value)

    fn __bool__(self) -> Bool:
        """Boolean conversion.

        Returns:
            True if the value is non-zero, False otherwise.
        """
        return self.value != 0
