from builtin.globals import global_constant


comptime StackArray[T: Copyable, size: Int] = InlineArray[T, size]
"""A stack-allocated array of fixed size.

Parameters:
    T: The type of the elements in the array.
    size: The size of the array.
"""


@always_inline
fn lut[I: Indexer, //, A: StackArray](i: I) -> A.ElementType:
    """Returns the value at the given index from a global constant array.

    Parameters:
        I: The type of the index.
        A: The type of the global constant array.

    Args:
        i: The index to retrieve.

    Returns:
        The value at the given index.
    """
    return global_constant[A]().unsafe_get(i).copy()
