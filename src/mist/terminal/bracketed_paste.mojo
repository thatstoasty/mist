from mist.terminal.sgr import CSI, _write_sequence_to_stdout

## https://en.wikipedia.org/wiki/Bracketed-paste
alias ENABLE_BRACKETED_PASTE = CSI + "?2004h"
"""Enable bracketed paste `CSI + ?2004 + h = \\x1b[?2004h`."""
alias DISABLE_BRACKETED_PASTE = CSI + "?2004l"
"""Disable bracketed paste `CSI + ?2004 + l = \\x1b[?2004l`."""
alias START_BRACKETED_PASTE_SEQ = "200~"
alias END_BRACKETED_PASTE_SEQ = "201~"


fn enable_bracketed_paste() -> None:
    """Enables bracketed paste."""
    _write_sequence_to_stdout(ENABLE_BRACKETED_PASTE)


fn disable_bracketed_paste() -> None:
    """Disables bracketed paste."""
    _write_sequence_to_stdout(DISABLE_BRACKETED_PASTE)
