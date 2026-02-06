from mist.multiplex.event import Event


trait Selector(Movable):
    """Selector abstract base class.

    A selector supports registering file objects to be monitored for specific
    I/O events.

    A file object is a file descriptor or any object with a `fileno()` method.
    An arbitrary object can be attached to the file object, which can be used
    for example to store context information, a callback, etc.

    A selector can use various implementations (select(), poll(), epoll()...)
    depending on the platform. The default `Selector` class uses the most
    efficient implementation on the current platform.
    """

    fn register(mut self, file_descriptor: FileDescriptor, events_to_monitor: Event) -> None:
        """Register a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_monitor: Events to monitor.
        """
        ...

    fn unregister(mut self, file_descriptor: FileDescriptor, events_to_stop: Event) -> None:
        """Unregister a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_stop: Events to stop monitoring.

        Note:
            If fileobj is registered but has since been closed this does.
        """
        ...

    # fn modify(self, fileobj: Int32, events: Int, data):
    #     """Change a registered file object monitored events or attached data.

    #     Args:
    #         fileobj: file object or file descriptor
    #         events: events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE)
    #         data: attached data

    #     Returns:
    #         SelectorKey instance

    #     Raises:
    #         Anything that unregister() or register() raises
    #     """
    #     ...

    fn select(mut self, timeout: Int = 0) raises -> Dict[Int, Event]:
        """Perform the actual selection, until some monitored file objects are
        ready or a timeout expires.

        Args:
            timeout: If timeout > 0, this specifies the maximum wait time, in seconds.
                if timeout <= 0, the select() call won't block, and will
                report the currently ready file objects
                if timeout is None, select() will block until a monitored
                file object becomes ready.

        Returns:
            List of (key, events) for ready file objects
            `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
        """
        ...

    fn close(self):
        """Close the selector.

        This must be called to make sure that any underlying resource is freed.
        """
        ...

    # fn get_key(self, fileobj: Int32):
    #     """Return the key associated to a registered file object.

    #     Returns:
    #         SelectorKey for this file object.
    #     """
    #     ...

    # fn get_map(self):
    #     """Return a mapping of file objects to selector keys."""
    #     ...


# struct SelectorKey():
#     """Key for a file object in a Selector.

#     A key can be used to identify a registered file object in a Selector.
#     """

#     var fileobj: Int32
#     var fd: Int32
#     var events: Int32
#     var data: Any

#     fn __init__(out self, fileobj: Int32, fd: Int32, events: Int32, data: Any):
#         self.fileobj = fileobj
#         self.fd = fd
#         self.events = events
#         self.data = data

#     fn __repr__(self) -> String:
#         return String("SelectorKey(fileobj={}, fd={}, events={}, data={})").format(
#             self.fileobj, self.fd, self.events, self.data
#         )
