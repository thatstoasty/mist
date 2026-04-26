from std.sys import CompilationTarget

from mist.event import EventReader, Char, FocusGained, FocusLost, KeyEvent
from mist.terminal import FocusChange, TTY, Mode
from mist.multiplex import KQueueSelector, SelectSelector, Selector


def handle_events[T: Selector, //](mut reader: EventReader[T]) raises:
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


def main() raises -> None:
    print("Enabling focus change tracking...")
    var focus_change = FocusChange.enable()
    print("Focus change tracking enabled. Try switching to another window and back to see the effect.")
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    try:
        with TTY[Mode.RAW]():
            comptime if CompilationTarget.is_macos():
                var reader = EventReader(KQueueSelector())
                handle_events(reader)
            else:
                var reader = EventReader(SelectSelector())
                handle_events(reader)
    finally:
        print("Disabling focus change tracking...")
        focus_change^.disable()
        print("Focus change tracking disabled.")
