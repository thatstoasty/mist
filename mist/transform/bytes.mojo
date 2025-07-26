from algorithm.memory import parallel_memcpy
from memory import UnsafePointer


struct ByteWriter(Sized, Stringable, Writable, Writer):
    """Variable-sized buffer of bytes with `write` methods.

    #### Examples:
    ```mojo
    import mist.transform.bytes
    buf = bytes.ByteWriter()
    buf.write("Hello, World!")
    print(buf.consume())  # Output: Hello, World!
    ```
    """

    var _data: UnsafePointer[Byte]
    """The contents of the bytes buffer. Active contents are from buf[offset : len(buf)]."""
    var _size: Int
    """The number of bytes stored in the buffer."""
    var _capacity: Int
    """The maximum capacity of the buffer, eg the allocation of self._data."""
    var offset: Int
    """The read/writer offset of the buffer. read at buf[offset], write at buf[len(buf)]."""

    fn __init__(out self, *, capacity: Int = 4096):
        """Creates a new buffer with the specified capacity.

        Args:
            capacity: The initial capacity of the buffer.
        """
        self._capacity = capacity
        self._size = 0
        self._data = UnsafePointer[Byte].alloc(capacity)
        self.offset = 0

    fn __init__(out self, owned buf: List[Byte, True]):
        """Creates a new buffer with List buffer provided.

        Args:
            buf: The List buffer to initialize the buffer with.
        """
        self._capacity = buf.capacity
        self._size = len(buf)
        self._data = buf.steal_data()
        self.offset = 0

    fn __init__(out self, buf: String):
        """Creates a new buffer with String provided.

        Args:
            buf: The String to initialize the buffer with.
        """
        var bytes = List[Byte, True](buf.as_bytes())
        self._capacity = bytes.capacity
        self._size = len(bytes)
        self._data = bytes.steal_data()
        self.offset = 0

    fn __init__(out self, *, owned data: UnsafePointer[Byte], capacity: Int, size: Int):
        """Creates a new buffer with `UnsafePointer` buffer provided.

        Args:
            data: The List buffer to initialize the buffer with.
            capacity: The initial capacity of the buffer.
            size: The number of bytes stored in the buffer.
        """
        self._capacity = capacity
        self._size = size
        self._data = data
        self.offset = 0

    fn __moveinit__(out self, owned other: Self):
        """Constructs a new `ByteWriter` by taking the content of the other `ByteWriter`.

        Args:
            other: The other `ByteWriter` to take the content from.
        """
        self._data = other._data
        self._size = other._size
        self._capacity = other._capacity
        self.offset = other.offset

    fn __del__(owned self):
        """Frees the internal buffer."""
        if self._data:
            self._data.free()

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the buffer. `self._size - self.offset`.

        Returns:
            The number of bytes of the unread portion of the buffer.
        """
        return self._size - self.offset

    fn as_bytes(ref self) -> Span[Byte, __origin_of(self)]:
        """Returns the internal data as a Byte Span.

        Returns:
            The Span representation of the Byte Span.
        """
        return Span[Byte, __origin_of(self)](ptr=self._data, length=self._size)

    fn as_string_slice(ref self) -> StringSlice[__origin_of(self)]:
        """Return a StringSlice view of the data owned by the builder.

        Returns:
            The StringSlice view of the bytes writer. Returns an empty string if the bytes buffer is empty.
        """
        return StringSlice[__origin_of(self)](ptr=self._data, length=self._size)

    fn _resize(mut self, capacity: Int) -> None:
        """Resizes the Writer's internal buffer.

        Args:
          capacity: The new capacity of the internal buffer.
        """
        new_data = UnsafePointer[Byte]().alloc(capacity)
        parallel_memcpy(new_data, self._data, self._size)
        self._data.free()
        self._data = new_data
        self._capacity = capacity

        return None

    fn _resize_if_needed(mut self, bytes_to_add: Int) -> None:
        """Resizes the buffer if the number of bytes to add exceeds the buffer's capacity.

        Args:
            bytes_to_add: The number of bytes to add to the buffer.
        """
        # TODO: Handle the case where new_capacity is greater than MAX_INT. It should panic.
        # 1 Byte reserved for null terminator.
        if bytes_to_add > self._capacity - self._size - 1:
            new_capacity = Int(self._capacity * 2)
            if new_capacity < self._capacity + bytes_to_add:
                new_capacity = self._capacity + bytes_to_add
            self._resize(new_capacity)

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

    fn consume[reuse: Bool = False](mut self) -> String:
        """Constructs and returns a new `String` by copying the content of the internal buffer.

        Parameters:
            reuse: If `True`, a new internal buffer will be allocated with the same capacity as the previous one.

        Returns:
            The `String` constructed from the `ByteWriter`. Returns an empty string if the internal buffer is empty.
        """
        self._data[self._size] = 0
        result = String(unsafe_from_utf8_ptr=self._data)

        @parameter
        if reuse:
            self._data = UnsafePointer[Byte].alloc(self._capacity)
        else:
            self._data = UnsafePointer[Byte]()
        self._size = 0
        self.offset = 0
        return result^

    fn write_byte(mut self, byte: Byte):
        """Appends a byte to the buffer.

        Args:
            byte: The byte to append.
        """
        self._resize_if_needed(1)
        self._data[self._size] = byte
        self._size += 1

    @always_inline
    fn write_bytes(mut self, bytes: Span[Byte]) -> None:
        """Write `bytes` to the `ByteWriter`.

        Args:
            bytes: The Byte Span to write. Must NOT be null terminated.
        """
        if len(bytes) == 0:
            return

        self._resize_if_needed(len(bytes))
        parallel_memcpy(self._data.offset(self._size), bytes._data, len(bytes))
        self._size += len(bytes)

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
        self._resize_if_needed(codepoint.utf8_byte_length())
        self._size += codepoint.unsafe_write_utf8(self._data.offset(self._size))

    fn empty(self) -> Bool:
        """Reports whether the unread portion of the buffer is empty.

        Returns:
            `True` if the buffer is empty, `False` otherwise.
        """
        return self._size <= self.offset

    fn clear(mut self) -> None:
        """Clears the buffer by resetting the size and offset."""
        for i in range(self._size):
            (self._data + i).destroy_pointee()
        self._size = 0
        self.offset = 0

    fn reset(mut self) -> None:
        """Resets the buffer to be empty."""
        if self._data:
            self._data.free()
        self._data = UnsafePointer[Byte].alloc(self._capacity)
        self._size = 0
        self.offset = 0
