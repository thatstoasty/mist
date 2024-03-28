from .style import bel, csi, reset, osc
from .color import AnyColor, NoColor, ANSIColor, ANSI256Color, RGBColor


# Sequence definitions.
## Cursor positioning.
alias cursor_up_seq = "%dA"
alias cursor_down_seq = "%dB"
alias cursor_forward_seq = "%dC"
alias cursor_back_seq = "%dD"
alias cursor_next_line_seq = "%dE"
alias cursor_previous_line_seq = "%dF"
alias cursor_horizontal_seq = "%dG"
alias cursor_position_seq = "%d;%dH"
alias erase_display_seq = "%dJ"
alias erase_line_seq = "%dK"
alias scroll_up_seq = "%dS"
alias scroll_down_seq = "%dT"
alias save_cursor_position_seq = "s"
alias restore_cursor_position_seq = "u"
alias change_scrolling_region_seq = "%d;%dr"
alias insert_line_seq = "%dL"
alias delete_line_seq = "%dM"

## Explicit values for EraseLineSeq.
alias erase_line_right_seq = "0K"
alias erase_line_left_seq = "1K"
alias erase_entire_line_seq = "2K"

## Mouse
alias enable_mouse_press_seq = "?9h"  # press only (X10)
alias disable_mouse_press_seq = "?9l"
alias enable_mouse_seq = "?1000h"  # press, release, wheel
alias disable_mouse_seq = "?1000l"
alias enable_mouse_hilite_seq = "?1001h"  # highlight
alias disable_mouse_hilite_seq = "?1001l"
alias enable_mouse_cell_motion_seq = "?1002h"  # press, release, move on pressed, wheel
alias disable_mouse_cell_motion_seq = "?1002l"
alias enable_mouse_all_motion_seq = "?1003h"  # press, release, move, wheel
alias disable_mouse_all_motion_seq = "?1003l"
alias enable_mouse_extended_mode_seq = "?1006h"  # press, release, move, wheel, extended coordinates
alias disable_mouse_extended_mode_seq = "?1006l"
alias enable_mouse_pixels_mode_seq = "?1016h"  # press, release, move, wheel, extended pixel coordinates
alias disable_mouse_pixels_mode_seq = "?1016l"

## Screen
alias restore_screen_seq = "?47l"
alias save_screen_seq = "?47h"
alias alt_screen_seq = "?1049h"
alias exit_alt_screen_seq = "?1049l"

## Bracketed paste.
## https:#en.wikipedia.org/wiki/Bracketed-paste
alias enable_bracketed_paste_seq = "?2004h"
alias disable_bracketed_paste_seq = "?2004l"
alias start_bracketed_paste_seq = "200~"
alias end_bracketed_paste_seq = "201~"

## Session
alias set_window_title_seq = "2;%s" + bel
alias set_foreground_color_seq = "10;%s" + bel
alias set_background_color_seq = "11;%s" + bel
alias set_cursor_color_seq = "12;%s" + bel
alias show_cursor_seq = "?25h"
alias hide_cursor_seq = "?25l"


fn __string__mul__(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


fn replace(input_string: String, old: String, new: String, count: Int = -1) -> String:
    if count == 0:
        return input_string

    var output: String = ""
    var start = 0
    var split_count = 0

    for end in range(len(input_string) - len(old) + 1):
        if input_string[end : end + len(old)] == old:
            output += input_string[start:end] + new
            start = end + len(old)
            split_count += 1

            if count >= 0 and split_count >= count and count >= 0:
                break

    output += input_string[start:]
    return output


fn sprintf(text: String, *strs: String) -> String:
    var output: String = text
    for i in range(len(strs)):
        output = replace(output, "%s", strs[i], 1)

    return output


fn sprintf(text: String, *ints: Int) -> String:
    var output: String = text
    for i in range(len(ints)):
        output = replace(output, "%d", String(ints[i]), 1)

    return output


fn sprintf(text: String, *floats: Float64) -> String:
    var output: String = text
    for i in range(len(floats)):
        output = replace(output, "%d", String(floats[i]), 1)

    return output


# Reset the terminal to its default style, removing any active styles.
fn reset_terminal():
    print(csi + reset + "m", end="")


# SetForegroundColor sets the default foreground color.
fn set_foreground_color(color: AnyColor) raises:
    var c: String = ""

    if color.isa[ANSIColor]():
        c = color.get[ANSIColor]()[].sequence(False)
    elif color.isa[ANSI256Color]():
        c = color.get[ANSI256Color]()[].sequence(False)
    elif color.isa[RGBColor]():
        c = color.get[RGBColor]()[].sequence(False)

    print(osc + set_foreground_color_seq, c, end="")


# SetBackgroundColor sets the default background color.
fn set_background_color(color: AnyColor) raises:
    var c: String = ""
    if color.isa[NoColor]():
        pass
    elif color.isa[ANSIColor]():
        c = color.get[ANSIColor]()[].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color.get[ANSI256Color]()[].sequence(True)
    elif color.isa[RGBColor]():
        c = color.get[RGBColor]()[].sequence(True)

    print(osc + set_background_color_seq, c, end="")


# SetCursorColor sets the cursor color.
fn set_cursor_color(color: AnyColor) raises:
    var c: String = ""
    if color.isa[NoColor]():
        pass
    elif color.isa[ANSIColor]():
        c = color.get[ANSIColor]()[].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color.get[ANSI256Color]()[].sequence(True)
    elif color.isa[RGBColor]():
        c = color.get[RGBColor]()[].sequence(True)

    print(osc + set_cursor_color_seq, c, end="")


# restore_screen restores a previously saved screen state.
fn restore_screen():
    print(csi + restore_screen_seq, end="")


# SaveScreen saves the screen state.
fn save_screen():
    print(csi + save_screen_seq, end="")


# AltScreen switches to the alternate screen buffer. The former view can be
# restored with ExitAltScreen().
fn alt_screen():
    print(csi + alt_screen_seq, end="")


# ExitAltScreen exits the alternate screen buffer and returns to the former
# terminal view.
fn exit_alt_screen():
    print(csi + exit_alt_screen_seq, end="")


# ClearScreen clears the visible portion of the terminal.
fn clear_screen():
    print(sprintf(csi + erase_display_seq, 2), end="")
    move_cursor(1, 1)


# MoveCursor moves the cursor to a given position.
fn move_cursor(row: Int, column: Int):
    print(sprintf(csi + cursor_position_seq, row, column), end="")


# TODO: Show and Hide cursor don't seem to work ATM.
# HideCursor hides the cursor.
fn hide_cursor():
    print(csi + hide_cursor_seq, end="")


# ShowCursor shows the cursor.
fn show_cursor():
    print(csi + show_cursor_seq, end="")


# SaveCursorPosition saves the cursor position.
fn save_cursor_position():
    print(csi + save_cursor_position_seq, end="")


# RestoreCursorPosition restores a saved cursor position.
fn restore_cursor_position():
    print(csi + restore_cursor_position_seq, end="")


# CursorUp moves the cursor up a given number of lines.
fn cursor_up(n: Int):
    print(sprintf(csi + cursor_up_seq, n), end="")


# CursorDown moves the cursor down a given number of lines.
fn cursor_down(n: Int):
    print(sprintf(csi + cursor_down_seq, n), end="")


# CursorForward moves the cursor up a given number of lines.
fn cursor_forward(n: Int):
    print(sprintf(csi + cursor_forward_seq, n), end="")


# CursorBack moves the cursor backwards a given number of cells.
fn cursor_back(n: Int):
    print(sprintf(csi + cursor_back_seq, n), end="")


# CursorNextLine moves the cursor down a given number of lines and places it at
# the beginning of the line.
fn cursor_next_line(n: Int):
    print(sprintf(csi + cursor_next_line_seq, n), end="")


# CursorPrevLine moves the cursor up a given number of lines and places it at
# the beginning of the line.
fn cursor_prev_line(n: Int):
    print(sprintf(csi + cursor_previous_line_seq, n), end="")


# ClearLine clears the current line.
fn clear_line():
    print(csi + erase_entire_line_seq, end="")


# ClearLineLeft clears the line to the left of the cursor.
fn clear_line_left():
    print(csi + erase_line_left_seq, end="")


# ClearLineRight clears the line to the right of the cursor.
fn clear_line_right():
    print(csi + erase_line_right_seq, end="")


# ClearLines clears a given number of lines.
fn clear_lines(n: Int):
    var clear_line = sprintf(csi + erase_line_seq, 2)
    var cursor_up = sprintf(csi + cursor_up_seq, 1)
    var movement = __string__mul__(cursor_up + clear_line, n)
    print(clear_line + movement, end="")


# ChangeScrollingRegion sets the scrolling region of the terminal.
fn change_scrolling_region(top: Int, bottom: Int):
    print(sprintf(csi + change_scrolling_region_seq, top, bottom), end="")


# InsertLines inserts the given number of lines at the top of the scrollable
# region, pushing lines below down.
fn insert_lines(n: Int):
    print(sprintf(csi + insert_line_seq, n), end="")


# DeleteLines deletes the given number of lines, pulling any lines in
# the scrollable region below up.
fn delete_lines(n: Int):
    print(sprintf(csi + delete_line_seq, n), end="")


# EnableMousePress enables X10 mouse mode. Button press events are sent only.
fn enable_mouse_press():
    print(csi + enable_mouse_press_seq, end="")


# DisableMousePress disables X10 mouse mode.
fn disable_mouse_press():
    print(csi + disable_mouse_press_seq, end="")


# EnableMouse enables Mouse Tracking mode.
fn enable_mouse():
    print(csi + enable_mouse_seq, end="")


# DisableMouse disables Mouse Tracking mode.
fn disable_mouse():
    print(csi + disable_mouse_seq, end="")


# EnableMouseHilite enables Hilite Mouse Tracking mode.
fn enable_mouse_hilite():
    print(csi + enable_mouse_hilite_seq, end="")


# DisableMouseHilite disables Hilite Mouse Tracking mode.
fn disable_mouse_hilite():
    print(csi + disable_mouse_hilite_seq, end="")


# EnableMouseCellMotion enables Cell Motion Mouse Tracking mode.
fn enable_mouse_cell_motion():
    print(csi + enable_mouse_cell_motion_seq, end="")


# DisableMouseCellMotion disables Cell Motion Mouse Tracking mode.
fn disable_mouse_cell_motion():
    print(csi + disable_mouse_cell_motion_seq, end="")


# EnableMouseAllMotion enables All Motion Mouse mode.
fn enable_mouse_all_motion():
    print(csi + enable_mouse_all_motion_seq, end="")


# DisableMouseAllMotion disables All Motion Mouse mode.
fn disable_mouse_all_motion():
    print(csi + disable_mouse_all_motion_seq, end="")


# EnableMouseExtendedMotion enables Extended Mouse mode (SGR). This should be
# enabled in conjunction with EnableMouseCellMotion, and EnableMouseAllMotion.
fn enable_mouse_extended_mode():
    print(csi + enable_mouse_extended_mode_seq, end="")


# DisableMouseExtendedMotion disables Extended Mouse mode (SGR).
fn disable_mouse_extended_mode():
    print(csi + disable_mouse_extended_mode_seq, end="")


# EnableMousePixelsMotion enables Pixel Motion Mouse mode (SGR-Pixels). This
# should be enabled in conjunction with EnableMouseCellMotion, and
# EnableMouseAllMotion.
fn enable_mouse_pixels_mode():
    print(csi + enable_mouse_pixels_mode_seq, end="")


# DisableMousePixelsMotion disables Pixel Motion Mouse mode (SGR-Pixels).
fn disable_mouse_pixels_mode():
    print(csi + disable_mouse_pixels_mode_seq, end="")


# SetWindowTitle sets the terminal window title.
fn set_window_title(title: String):
    print(osc + set_window_title_seq, title, end="")


# EnableBracketedPaste enables bracketed paste.
fn enable_bracketed_paste():
    print(csi + enable_bracketed_paste_seq, end="")


# DisableBracketedPaste disables bracketed paste.
fn disable_bracketed_paste():
    print(csi + disable_bracketed_paste_seq, end="")
