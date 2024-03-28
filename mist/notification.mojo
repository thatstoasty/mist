from .style import osc, st


fn notify(title: String, body: String):
    print(osc + "777;notify;" + title + ";" + body + st, end="")
