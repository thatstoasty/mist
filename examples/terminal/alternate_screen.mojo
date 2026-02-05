from mist.terminal.screen import AlternateScreen


fn main() -> None:
    print("Enabling alternate screen tracking...")
    var alternate_screen = AlternateScreen.enable()
    print("Hello World!\n\n\n\n\n\n\n\n\n\n\n\n")
    alternate_screen^.disable()
