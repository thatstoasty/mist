# from sys.ffi import external_call, os_is_windows, os_is_macos
# from collections import Optional, Set
# from sys import exit, stdin
# from time.time import _CTimeSpec
# from memory import UnsafePointer

# from mist.termios.c import c_void, c_int
# import mist.termios.c
# from mist.multiplex.selector import Selector
# from mist.multiplex.select import EVENT_READ, EVENT_WRITE, FileDescriptorBitSet, TimeValue
# from mist._bitset import BitSet


# fn kqueue() -> c_int:
#     """int kqueue(void)."""
#     return external_call["kqueue", c_int]()


# @value
# struct Kevent:
#     var ident: UInt
#     var filter: Int16
#     var flags: UInt16
#     var fflags: UInt32
#     var data: Int64
#     var udata: UnsafePointer[c_void]

#     fn __init__(out self, fd: UInt, filter: Int16, flags: UInt16, fflags: UInt32 = 0, data: Int64 = 0):
#         self.ident = fd
#         self.filter = filter
#         self.flags = flags
#         self.fflags = fflags
#         self.data = data
#         self.udata = UnsafePointer[c_void]()


# fn kevent(
#     kq: c_int,
#     change_list: UnsafePointer[Kevent],
#     nchanges: c_int,
#     event_list: UnsafePointer[Kevent],
#     nevents: c_int,
#     timeout: UnsafePointer[_CTimeSpec],
# ) -> c_int:
#     """int kevent(int kq, const struct kevent *changelist, int nchanges,
#     struct kevent *eventlist, int nevents,
#     const struct timespec *timeout);"""
#     return external_call[
#         "kevent", c_int, c_int, UnsafePointer[Kevent], c_int, UnsafePointer[Kevent], c_int, UnsafePointer[_CTimeSpec]
#     ](kq, change_list, nchanges, event_list, nevents, timeout)

# alias KQ_EV_ADD = 1
# alias KQ_EV_CLEAR = 32
# alias KQ_EV_DELETE = 2
# alias KQ_EV_DISABLE = 8
# alias KQ_EV_ENABLE = 4
# alias KQ_EV_EOF = 32768
# alias KQ_EV_ERROR = 16384
# alias KQ_EV_FLAG1 = 8192
# alias KQ_EV_ONESHOT = 16
# alias KQ_EV_SYSFLAGS = 61440
# alias KQ_FILTER_AIO = -3
# alias KQ_FILTER_PROC = -5
# alias KQ_FILTER_READ = -1
# alias KQ_FILTER_SIGNAL = -6
# alias KQ_FILTER_TIMER = -7
# alias KQ_FILTER_VNODE = -4
# alias KQ_FILTER_WRITE = -2
# alias KQ_NOTE_ATTRIB = 8
# alias KQ_NOTE_CHILD = 4
# alias KQ_NOTE_DELETE = 1
# alias KQ_NOTE_EXEC = 536870912
# alias KQ_NOTE_EXIT = 2147483648
# alias KQ_NOTE_EXTEND = 4
# alias KQ_NOTE_FORK = 1073741824
# alias KQ_NOTE_LINK = 16
# alias KQ_NOTE_LOWAT = 1
# alias KQ_NOTE_PCTRLMASK = -1048576
# alias KQ_NOTE_PDATAMASK = 1048575
# alias KQ_NOTE_RENAME = 32
# alias KQ_NOTE_REVOKE = 64
# alias KQ_NOTE_TRACK = 1
# alias KQ_NOTE_TRACKERR = 2
# alias KQ_NOTE_WRITE = 2


# struct KQueueSelector:
#     var _selector: Int32
#     var _max_events: Int

#     fn __init__(out self):
#         self._selector = kqueue()
#         if self._selector == -1:
#             _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kqueue").unsafe_ptr())
#             exit(1)
#         self._max_events = 0

#     fn __moveinit__(out self, owned other: KQueueSelector):
#         self._selector = other._selector
#         self._max_events = other._max_events

#     fn register(mut self, fd: Int, events: Int) raises -> None:
#         """Register a file object.

#         Args:
#             fd: File object or file descriptor.
#             events: Events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE).

#         Raises:
#             ValueError if events is invalid.
#         """
#         if (not events) or (events & ~(EVENT_READ | EVENT_WRITE)):
#             raise Error("ValueError: Invalid events: ", events)

#         if events & EVENT_READ:
#             var timeout = _CTimeSpec(0, 0)
#             var change_list = Kevent(
#                 fd=fd,
#                 filter=KQ_FILTER_READ,
#                 flags=KQ_EV_ADD | KQ_EV_ENABLE,
#             )
#             var event_list = UnsafePointer[Kevent]()

#             var kev = kevent(self._selector, UnsafePointer(to=change_list), 1, event_list, 0, UnsafePointer(to=timeout))
#             if kev == -1:
#                 _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kevent").unsafe_ptr())
#                 exit(1)
#             self._max_events += 1
#             print("Kevent response", kev)

#         # if events & EVENT_WRITE:
#         #     kev = kevent(fd, KQ_FILTER_WRITE,
#         #                         KQ_EV_ADD)
#         #     self._selector.control([kev], 0, 0)
#         #     self._max_events += 1

#     fn unregister(mut self, fd: Int, events: Int) raises -> None:
#         """Unregister a file object.

#         Args:
#             fd: File object or file descriptor.

#         Raises:
#             KeyError if fileobj is not registered.

#         Note:
#             If fileobj is registered but has since been closed this does
#         """
#         if events & EVENT_READ:
#             var timeout = _CTimeSpec(0, 0)
#             var change_list = Kevent(fd, KQ_FILTER_READ, KQ_EV_DELETE)
#             var event_list = UnsafePointer[Kevent]()
#             var kev = kevent(self._selector, UnsafePointer(to=change_list), 1, event_list, 0, UnsafePointer(to=timeout))
#             if kev == -1:
#                 _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kevent").unsafe_ptr())
#                 exit(1)
#             self._max_events -= 1

#     fn select(mut self, timeout: Optional[Int] = None) -> List[InlineArray[Int, 2]]:
#         """Perform the actual selection, until some monitored file objects are
#         ready or a timeout expires.

#         Args:
#             timeout: if timeout > 0, this specifies the maximum wait time, in seconds.
#                     if timeout <= 0, the select() call won't block, and will
#                     report the currently ready file objects
#                     if timeout is None, select() will block until a monitored
#                     file object becomes ready.

#         Returns:
#             List of (key, events) for ready file objects
#             `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
#         """

#         var tv = _CTimeSpec(0, 0)
#         if timeout:
#             tv.tv_sec = timeout.value()

#         var change = Kevent(
#             fd=0,
#             filter=KQ_FILTER_READ,
#             flags=KQ_EV_ADD | KQ_EV_ENABLE,
#         )
#         var event = Kevent(
#             fd=0,
#             filter=0,
#             flags=0,
#         )
#         print("Calling kevent")
#         var number_of_events = kevent(
#             self._selector,
#             UnsafePointer(to=change),
#             0,
#             UnsafePointer(to=event),
#             self._max_events,
#             UnsafePointer(to=tv),
#         )
#         print("Checking result", number_of_events)
#         if number_of_events < 0:
#             _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kevent").unsafe_ptr())
#             exit(1)

#         var ready = List[InlineArray[Int, 2]]()
#         if number_of_events > 0:
#             if (event.flags & KQ_EV_ERROR):
#                 print("Failed to read from fd", event.ident)
#                 exit(1)

#         # for fd in self.readers:
#         #     var events = 0
#         #     if readers.is_set(fd[]):
#         #         events |= EVENT_READ
#         #     ready.append(InlineArray[Int, 2](fd[], events))

#         # for fd in self.writers:
#         #     var events = 0
#         #     if writers.is_set(fd[]):
#         #         print(self._highest_fd)
#         #         events |= EVENT_WRITE
#         #     ready.append(InlineArray[Int, 2](fd[], events))

#         return ready
