from std.sys import CompilationTarget

from mist.event import EventReader, Char, KeyEvent
from mist.terminal import TTY, Mode
from mist.multiplex import KQueueSelector, SelectSelector, Selector


def handle_events[T: Selector, //](mut reader: EventReader[T]) raises -> None:
    while True:
        var event = reader.read()
        if event.isa[KeyEvent]():
            print(event[KeyEvent].code, end="\r\n")
            if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                print("Exiting on 'q' key press.", end="\r\n")
                break
        else:
            print("Received event:", event, end="\r\n")


def main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    with TTY[Mode.RAW]():
        comptime if CompilationTarget.is_macos():
            var reader = EventReader[KQueueSelector](KQueueSelector())
            handle_events(reader)
        else:
            var reader = EventReader[SelectSelector](SelectSelector())
            handle_events(reader)
