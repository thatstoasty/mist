from collections import InlineArray
from sys import stdin
from sys._libc import c_int, c_size_t, external_call

from mist.terminal.internal import InternalEvent
from mist.terminal.parser import parse_event


fn read(fd: c_int, buf: MutUnsafePointer[NoneType], size: c_size_t) -> c_int:
    """Libc POSIX `read` function.

    Read `size` bytes from file descriptor `fd` into the buffer `buf`.

    Args:
        fd: A File Descriptor.
        buf: A pointer to a buffer to store the read data.
        size: The number of bytes to read.

    Returns:
        The number of bytes read or -1 in case of failure.

    #### C Function:
    ```c
    ssize_t read(int fildes, void *buf, size_t nbyte);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/read.3p.html.
    """
    return external_call["read", c_int, type_of(fd), type_of(buf), type_of(size)](fd, buf, size)


fn read_events() raises -> Optional[InternalEvent]:
    """Reads a single event from stdin. Read is normally blocking, but the terminal
    is set to non-blocking mode, so this will return immediately if there is no
    data to read. If there is no data to read, this will return a NoMsg message.

    Returns:
        An InternalEvent containing the event read from stdin. This will be a KeyMsg if
        a key was pressed, or a NoMsg if there was no data to read.
    """
    comptime COUNT_TO_READ = 8

    # We use a stack allocation to avoid heap allocations.
    # We don't need to free stack allocated pointers, I guess?
    # Freeing it works when its a heap allocated pointer, but not stack allocated.
    var buffer = InlineArray[Byte, COUNT_TO_READ](uninitialized=True)
    _ = read(stdin.value, buffer.unsafe_ptr().bitcast[NoneType](), COUNT_TO_READ)
    var event = parse_event(Span(buffer).get_immutable(), True)
    return event^
