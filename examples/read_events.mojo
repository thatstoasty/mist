from mist.event.internal import InternalEvent
from mist.event.read import EventReader
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, Event, KeyEvent, Resize


fn main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    var reader = EventReader()
    with TTY[Mode.CBREAK]():
        while True:
            var event = reader.read()
            if event.isa[KeyEvent]():
                print(event[KeyEvent].code[Char])
                if event[KeyEvent].code[Char] == "q":
                    print("Exiting on 'q' key press.")
                    break
            elif event.isa[Resize]():
                print("Resized", event[Resize])
            else:
                print("Received event:", event)
