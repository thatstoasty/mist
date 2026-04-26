from std.sys import CompilationTarget

from mist.event.read import EventReader
from mist.terminal.focus import FocusChange
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, FocusGained, FocusLost, KeyEvent


def main() raises -> None:
    print("Enabling focus change tracking...")
    var focus_change = FocusChange.enable()
    print("Focus change tracking enabled. Try switching to another window and back to see the effect.")

    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    comptime if CompilationTarget.is_macos():
        from mist.multiplex.kqueue import KQueueSelector
        try:
            with TTY[Mode.RAW]():
                var reader = EventReader[KQueueSelector](KQueueSelector())
                while True:
                    var event = reader.read()
                    if event.isa[KeyEvent]():
                        print(event[KeyEvent].code, end="\r\n")
                        if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                            print("Exiting on 'q' key press.", end="\r\n")
                            break
                    elif event.isa[FocusGained]():
                        print("Focus gained", end="\r\n")
                    elif event.isa[FocusLost]():
                        print("Focus lost", end="\r\n")
                    else:
                        print("Received event:", event, end="\r\n")
        finally:
            print("Disabling focus change tracking...")
            focus_change^.disable()
            print("Focus change tracking disabled.")
    else:
        from mist.multiplex.select import SelectSelector
        try:
            with TTY[Mode.RAW]():
                var reader = EventReader[SelectSelector](SelectSelector())
                while True:
                    var event = reader.read()
                    if event.isa[KeyEvent]():
                        print(event[KeyEvent].code, end="\r\n")
                        if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                            print("Exiting on 'q' key press.", end="\r\n")
                            break
                    elif event.isa[FocusGained]():
                        print("Focus gained", end="\r\n")
                    elif event.isa[FocusLost]():
                        print("Focus lost", end="\r\n")
                    else:
                        print("Received event:", event, end="\r\n")
        finally:
            print("Disabling focus change tracking...")
            focus_change^.disable()
            print("Focus change tracking disabled.")
