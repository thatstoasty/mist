from collections.string import StringSlice


trait AsStringSlice:
    """A trait for objects that can be converted to a StringSlice."""

    fn as_string_slice(ref self) -> StringSlice[__origin_of(self)]:
        """Returns the StringSlice representation of the object.

        Returns:
            The StringSlice representation of the object.
        """
        ...
