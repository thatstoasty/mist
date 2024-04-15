import os
import external.gojo.io
from external.gojo.fmt import sprintf
from external.gojo.builtins import Result
from .profile import Profile
from .color import Color
from .style import OSC, CSI, ST, ESC, BEL


# timeout for OSC queries
alias OSCTimeout = 5


struct PrintWriter(Movable):
    fn __init__(inout self):
        pass
    
    fn __moveinit__(inout self, owned other: Self):
        pass
    
    fn write(inout self, src: List[Int8]):
        print(String(src.data.value, len(src)))
    
    fn write_string(inout self, src: String):
        print(src)


@value
struct NextResponse():
    var value: String
    var is_osc: Bool


struct Terminal[C: Color, RW: io.ReadWriter](io.Writer, io.StringWriter):
    var profile: Profile
    var fg_color: C
    var bg_color: C
    var writer: RW

    fn __init__(inout self, profile: Profile, fg_color: C, bg_color: C, owned writer: RW):
        self.profile = profile
        self.fg_color = fg_color
        self.bg_color = bg_color
        self.writer = writer ^
    
    fn __moveinit__(inout self, owned other: Self):
        self.profile = other.profile ^
        self.fg_color = other.fg_color ^
        self.bg_color = other.bg_color ^
        self.writer = other.writer ^
    
    fn write(inout self, src: List[Int8]) -> Result[Int]:
        return self.writer.write(src)
    
    fn write_string(inout self, src: String) -> Result[Int]:
        return self.writer.write(src.as_bytes())

    fn term_status_report(inout self, sequence: Int) raises -> String:
        # screen/tmux can't support OSC, because they can be connected to multiple
        # terminals concurrently.
        var term = os.getenv("TERM")
        if term.startswith("screen") or term.startswith("tmux") or term.startswith("dumb"):
            raise Error("Terminal does not support OSC")    

        # TODO: Assume it's unsafe for now
        # if !o.unsafe:
        #     fd = int(tty.Fd())
        #     # if in background, we can't control the terminal
        #     if !isForeground(fd):
        #         return "", ErrStatusReport
            

        #     t, err = unix.IoctlGetTermios(fd, tcgetattr)
        #     if err != nil:
        #         return "", fmt.Errorf("%s: %s", ErrStatusReport, err)
            
        #     defer unix.IoctlSetTermios(fd, tcsetattr, t) #nolint:errcheck

        #     noecho = *t
        #     noecho.Lflag = noecho.Lflag &^ unix.ECHO
        #     noecho.Lflag = noecho.Lflag &^ unix.ICANON
        #     if err = unix.IoctlSetTermios(fd, tcsetattr, &noecho); err != nil:
        #         return "", fmt.Errorf("%s: %s", ErrStatusReport, err)
    
        # first, send OSC query, which is ignored by terminal which do not support it
        var result = self.write_string(sprintf(OSC+"%d;?"+ST, sequence))
        if result.error:
            raise result.unwrap_error().error

        # then, query cursor position, should be supported by all terminals
        result = self.write_string(sprintf(CSI+"6n", sequence))
        if result.error:
            raise result.unwrap_error().error

        # read the next response
        var response = self.read_next_response()

        # if this is not OSC response, then the terminal does not support it
        if not response.is_osc:
            raise Error("Terminal does not support OSC")

        # read the cursor query response next and discard the result
        _ = self.read_next_response()

        return response.value
    
    fn read_next_byte(inout self) raises -> Int8:
        # if not self.unsafe:
        #     var err = o.waitForData(OSCTimeout)
        #     if err:
        #         raise err.value().error
            
        var b = List[Int8](capacity=1)
        var result = self.writer.read(b)
        if result.error:
            raise result.unwrap_error().error
        
        if result.value == 0:
            raise Error("read returned no data")
        
        return b[0]
    
    fn read_next_response(inout self) raises -> NextResponse:
        """Reads either an OSC response or a cursor position response:
        - OSC response: "\x1b]11;rgb:1111/1111/1111\x1b\\"
        - cursor position response: "\x1b[42;1R.
        """
        var start = self.read_next_byte()
        
        #  first byte must be ESC
        while start != ord(ESC):
            start = self.read_next_byte()

        var response: String = ""
        response += chr(int(start))

        # next byte is either '[' (cursor position response) or ']' (OSC response)
        var tpe = self.read_next_byte()
        response += String(tpe)

        var osc_response = False
        if tpe == ord('['):
            osc_response = False
        elif tpe == ord(']'):
            osc_response = True
        else:
            raise Error("Does not support OSC")
        
        while True:
            var b = self.read_next_byte()
            response += chr(int(b))
        
            if osc_response:
                #  OSC can be terminated by BEL (\a) or ST (ESC)
                if b == ord(BEL) or response.endswith(chr(int(ESC))):
                    return NextResponse(response, True)
                
            else:
                #  cursor position response is terminated by 'R'
                if b == ord('R'):
                    return NextResponse(response, False)
            
            #  both responses have less than 25 bytes, so if we read more, that's an error
            if len(response) > 25:
                break
        
        raise Error("Does not support OSC")
    

    fn background_color(self) -> String:
        return ""
    
    fn foreground_color(self) -> String:
        return ""