from std.builtin.globals import global_constant


comptime StackArray[T: Copyable & Deinitable, length: Int] = Array[T, length]
"""A stack-allocated array of fixed size.

Parameters:
    T: The type of the elements in the array.
    length: The length of the array.
"""


@always_inline
def lut[I: Indexer, //, A: StackArray](i: I) -> A.T:
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


def as_codepoint[char: ImmStringSpan[...]]() -> Codepoint:
    comptime assert char.byte_length() > 0 and char.byte_length() < 5, "`char` must be 1-4 bytes."
    return Codepoint.ord(char)


def as_byte[char: ImmStringSpan[...]]() -> Byte:
    comptime assert char.byte_length() == 1, "`char` must be 1 byte."
    return char.as_bytes()[0]
