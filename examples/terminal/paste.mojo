from mist.event.read import EventReader
from mist.terminal.paste import BracketedPaste
from mist.terminal.tty import TTY, Mode

from mist.event.event import Char, KeyEvent


fn handle_events(mut reader: EventReader) raises -> None:
    while True:
        var event = reader.read()
        if event.isa[KeyEvent]():
            print(event[KeyEvent].code, end="\r\n")
            if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
                print("Exiting on 'q' key press.", end="\r\n")
                break
        else:
            print("Received event:", event, end="\r\n")


fn main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    var bracketed_paste = BracketedPaste.enable()
    try:
        var reader = EventReader()
        with TTY[Mode.RAW]():
            handle_events(reader)
    finally:
        bracketed_paste^.disable()
