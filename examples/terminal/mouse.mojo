from std.sys import CompilationTarget

from mist.event.read import EventReader
from mist.multiplex.selector import Selector
from mist.terminal.mouse import Mouse
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, KeyEvent, MouseEvent


def handle_events[SelectorType: Selector & ImplicitlyDestructible](mut reader: EventReader[SelectorType]) raises -> None:
    while True:
        var event = reader.read()
        if event.isa[KeyEvent]():
            print(event[KeyEvent].code, end="\r\n")
            if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                print("Exiting on 'q' key press.", end="\r\n")
                break
        elif event.isa[MouseEvent]():
            print(event[MouseEvent], end="\r\n")
        else:
            print("Received event:", event, end="\r\n")


def main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    var mouse_capture = Mouse.enable_capture()
    comptime if CompilationTarget.is_macos():
        from mist.multiplex.kqueue import KQueueSelector
        try:
            with TTY[Mode.RAW]():
                var reader = EventReader[KQueueSelector](KQueueSelector())
                handle_events(reader)
        finally:
            mouse_capture^.disable()
    else:
        from mist.multiplex.select import SelectSelector
        try:
            with TTY[Mode.RAW]():
                var reader = EventReader[SelectSelector](SelectSelector())
                handle_events(reader)
        finally:
            mouse_capture^.disable()
