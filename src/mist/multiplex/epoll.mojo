# ### Monitoring file descriptors ###
# @value
# @register_passable("trivial")
# struct epoll_data:
#     var ptr: UnsafePointer[c_void]
#     var fd: c_int
#     var u32: UInt32
#     var u64: UInt64

#     fn __init__(out self, fd: c_int):
#         self.ptr = UnsafePointer[c_void]()
#         self.fd = fd
#         self.u32 = 0
#         self.u64 = 0


# @value
# @register_passable("trivial")
# struct epoll_event:
#     var events: UInt32
#     """Epoll events."""
#     var data: epoll_data
#     """User data variable."""


# # EPOLL op values
# alias EPOLL_CTL_ADD = 1
# alias EPOLL_CTL_DEL = 2
# alias EPOLL_CTL_MOD = 3

# # EPOLL op values
# alias EPOLLIN = 1
# alias EPOLLOUT = 4
# alias EPOLLRDHUP = 8192
# alias EPOLLPRI = 2
# alias EPOLLERR = 8
# alias EPOLLHUP = 16
# alias EPOLLET = 0x80000000
# alias EPOLLONESHOT = 0x40000000
# alias EPOLLEXCLUSIVE = 0x10000000


# fn epoll_create(size: c_int) -> c_int:
#     return external_call["epoll_create", c_int, c_int](size)


# fn epoll_create1(flags: c_int) -> c_int:
#     return external_call["epoll_create1", c_int, c_int](flags)


# fn epoll_ctl(epfd: c_int, op: c_int, fd: c_int, event: UnsafePointer[epoll_event]) -> c_int:
#     return external_call["epoll_ctl", c_int, c_int, c_int, c_int, UnsafePointer[epoll_event]](epfd, op, fd, event)


# fn epoll_wait(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: c_int) -> c_int:
#     return external_call["epoll_wait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int](
#         epfd, events, maxevents, timeout
#     )


# # fn epoll_pwait(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: c_int, sigmask: UnsafePointer[sigset_t]) -> c_int:
# #     return external_call["epoll_pwait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int, UnsafePointer[sigset_t]](epfd, events, maxevents, timeout, sigmask)


# # fn epoll_pwait2(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: UnsafePointer[_CTimeSpec], sigmask: UnsafePointer[sigset_t]) -> c_int:
# #     return external_call["epoll_pwait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int, UnsafePointer[sigset_t]](epfd, events, maxevents, timeout, sigmask)
