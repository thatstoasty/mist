from mist.event.read import EventReader
from mist.terminal.focus import FocusChange
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, FocusGained, FocusLost, KeyEvent


fn main() raises -> None:
    print("Enabling focus change tracking...")
    var focus_change = FocusChange.enable()
    print("Focus change tracking enabled. Try switching to another window and back to see the effect.")

    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    try:
        var reader = EventReader()
        with TTY[Mode.RAW]():
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
