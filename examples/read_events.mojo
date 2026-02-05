from mist.terminal.event import Char, Event, KeyEvent
from mist.terminal.read import read_events
from mist.terminal.tty import TTY, Mode


fn main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    with TTY[Mode.CBREAK]():
        while True:
            if event := read_events():
                print(event.value()[Event][KeyEvent].code[Char])
                if event.value()[Event][KeyEvent].code[Char] == "q":
                    print("Exiting on 'q' key press.")
                    break
