from memory import memcpy


comptime ExternalMutPointer = UnsafePointer[origin = MutOrigin.external]


struct ByteWriter(Copyable, Movable, Sized, Stringable, Writable, Writer):
    """Variable-sized buffer of bytes with `write` methods.

    #### Examples:
    ```mojo
    import mist.transform.bytes
    buf = bytes.ByteWriter()
    buf.write("Hello, World!")
    print(String(buf))  # Output: Hello, World!
    ```
    """

    var _data: List[Byte]

    fn __init__(out self, *, capacity: Int = 4096):
        """Creates a new buffer with the specified capacity.

        Args:
            capacity: The initial capacity of the buffer.
        """
        self._data = List[Byte](capacity=capacity)

    fn __init__(out self, var buf: List[Byte]):
        """Creates a new buffer with List buffer provided.

        Args:
            buf: The List buffer to initialize the buffer with.
        """
        self._data = buf^

    fn __init__(out self, buf: String):
        """Creates a new buffer with String provided.

        Args:
            buf: The String to initialize the buffer with.
        """
        self._data = List[Byte](buf.as_bytes())

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the buffer. `self._size - self.offset`.

        Returns:
            The number of bytes of the unread portion of the buffer.
        """
        return len(self._data)

    fn as_bytes(self) -> Span[Byte, origin_of(self._data)]:
        """Returns the internal data as a Byte Span.

        Returns:
            The Span representation of the Byte Span.
        """
        return Span(self._data)

    fn as_string_slice(self) -> StringSlice[origin_of(self._data)]:
        """Return a StringSlice view of the data owned by the builder.

        Returns:
            The StringSlice view of the bytes writer. Returns an empty string if the bytes buffer is empty.
        """
        return StringSlice(unsafe_from_utf8=self.as_bytes())

    fn __str__(self) -> String:
        """Constructs and returns a new `String` by copying the content of the internal buffer.

        Returns:
            The string representation of the buffer. Returns an empty string if the buffer is empty.
        """
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write_bytes(self.as_bytes())

    fn write_byte(mut self, var byte: Byte):
        """Appends a byte to the buffer.

        Args:
            byte: The byte to append.
        """
        self._data.append(byte)

    @always_inline
    fn write_bytes(mut self, bytes: Span[Byte]) -> None:
        """Write `bytes` to the `ByteWriter`.

        Args:
            bytes: The Byte Span to write. Must NOT be null terminated.
        """
        self._data.extend(bytes)

    fn write[*Ts: Writable](mut self, *args: *Ts) -> None:
        """Write data to the buffer.

        Parameters:
            Ts: The types of the `Writable` data to write.

        Args:
            args: The data to write to the buffer.
        """

        @parameter
        for i in range(args.__len__()):
            args[i].write_to(self)

    fn write(mut self, codepoint: Codepoint):
        """Allocates a string using the given character and writes it to the buffer.

        Args:
            codepoint: The character to append.
        """
        # I could use the unsafe codepoint write to write directly to the list ptr,
        # but I'd rather not alter te private state of the list directly.
        self._data.extend(String(codepoint).as_bytes())

    fn clear(mut self) -> None:
        """Clears the buffer by resetting the size and offset."""
        self._data.clear()
