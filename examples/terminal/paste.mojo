from std.sys import CompilationTarget

from mist.event import EventReader, Char, KeyEvent, MouseEvent
from mist.multiplex import Selector, SelectSelector, KQueueSelector
from mist.terminal import TTY, Mode, BracketedPaste


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
    var bracketed_paste = BracketedPaste.enable()
    try:
        with TTY[Mode.RAW]():
            comptime if CompilationTarget.is_macos():
                var reader = EventReader(KQueueSelector())
                handle_events(reader)
            else:
                var reader = EventReader(SelectSelector())
                handle_events(reader)
    finally:
        bracketed_paste^.disable()
