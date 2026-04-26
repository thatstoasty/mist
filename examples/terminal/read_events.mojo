from std.sys import CompilationTarget

from mist.event.read import EventReader
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, KeyEvent
from mist.multiplex.kqueue import KQueueSelector
from mist.multiplex.select import SelectSelector


def main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    comptime if CompilationTarget.is_macos():
        with TTY[Mode.RAW]():
            var reader = EventReader[KQueueSelector](KQueueSelector())
            while True:
                var event = reader.read()
                if event.isa[KeyEvent]():
                    print(event[KeyEvent].code, end="\r\n")
                    if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                        print("Exiting on 'q' key press.", end="\r\n")
                        break
                else:
                    print("Received event:", event, end="\r\n")
    else:
        with TTY[Mode.RAW]():
            var reader = EventReader[SelectSelector](SelectSelector())
            while True:
                var event = reader.read()
                if event.isa[KeyEvent]():
                    print(event[KeyEvent].code, end="\r\n")
                    if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                        print("Exiting on 'q' key press.", end="\r\n")
                        break
                else:
                    print("Received event:", event, end="\r\n")
