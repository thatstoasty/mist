from mist.terminal.screen import Screen


fn main() -> None:
    print("Enabling alternate screen tracking...")
    var alternate_screen = Screen.enable_alternate_screen()
    print("Hello World!\n\n\n\n\n\n\n\n\n\n\n\n")
    alternate_screen^.disable()
