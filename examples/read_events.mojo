from mist.terminal.event import Char, Event, KeyEvent, Resize
from mist.terminal.read import read_events
from mist.terminal.tty import TTY, Mode


fn main() raises -> None:
    print("Reading events from terminal. Press keys or click mouse (Ctrl+C to exit)...")
    with TTY[Mode.CBREAK]():
        while True:
            if event := read_events():
                if event.value()[Event].isa[KeyEvent]():
                    print(event.value()[Event][KeyEvent].code[Char])
                    if event.value()[Event][KeyEvent].code[Char] == "q":
                        print("Exiting on 'q' key press.")
                        break
                elif event.value()[Event].isa[Resize]():
                    print("Resized", event.value()[Event][Resize])
                else:
                    print("Received event:", event.value())
