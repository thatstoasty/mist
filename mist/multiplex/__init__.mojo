from std.sys import CompilationTarget

from mist.multiplex.select import SelectSelector


comptime if CompilationTarget.is_macos():
	from mist.multiplex.kqueue import KQueueSelector
	from mist.multiplex.kqueue import KQueueSelector as DefaultSelector
else:
	from mist.multiplex.select import SelectSelector as DefaultSelector
