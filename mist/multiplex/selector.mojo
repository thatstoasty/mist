from mist.multiplex.event import Event


trait Selector(Movable, ImplicitlyDestructible):
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

    def register(mut self, file_descriptor: FileDescriptor, events_to_monitor: Event) raises -> None:
        """Register a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_monitor: Events to monitor.

        Raises:
            Error: If the selector backend cannot register the file descriptor.
        """
        ...

    def unregister(mut self, file_descriptor: FileDescriptor, events_to_stop: Event) raises -> None:
        """Unregister a file object.

        Args:
            file_descriptor: File object or file descriptor.
            events_to_stop: Events to stop monitoring.

        Raises:
            Error: If the selector backend cannot update the registration.

        Note:
            If `file_descriptor` is registered but has since been closed this does.
        """
        ...

    # def modify(self, file_descriptor: Int32, events: Int):
    #     """Change a registered file object monitored events or attached data.

    #     Args:
    #         file_descriptor: A file descriptor registered with the selector.
    #         events: events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE).
    #         data: attached data

    #     Returns:
    #         SelectorKey instance

    #     Raises:
    #         Anything that unregister() or register() raises
    #     """
    #     ...

    def select(mut self, timeout: Int = 0) raises -> Dict[Int, Event]:
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

        Raises:
            Error: If the selector backend fails while waiting for readiness.
        """
        ...

    def close(mut self) raises:
        """Close the selector.

        This must be called to make sure that any underlying resource is freed.

        Raises:
            Error: If the selector backend fails while releasing resources.
        """
        ...
