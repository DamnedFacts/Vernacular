from baseserver import BaseServer
from autobahn.wamp import exportRpc
import irc.client, irc.logging
import os, thread, logging

def init(factory):
    return IrcsomeServer(factory)

class IRCCat(irc.client.SimpleIRCClient):
    motd = ""

    def __init__(self, nickname, target, console):
        irc.client.SimpleIRCClient.__init__(self)
        self.nickname = nickname
        self.target = target
        self.console = console

    def on_welcome(self, connection, event):
        if irc.client.is_channel(self.target):
            connection.join(self.target)
        else:
            return

    def on_join(self, connection, event):
        print connection.names(channels=self.target)
        pass

    def on_pubmsg(self, connection, event):
        user = event.source.split('!')[0]
        mesg = event.arguments[0]
        self.console.insertText_(user + "> " + mesg + "\n")

    def on_endofnames(self, connection, event):
        print event.arguments

    def on_motd(self, connection, event):
        self.motd += event.arguments[0] + "\n"

    def on_endofmotd(self, connection, event):
        self.console.insertText_(self.motd)

    def on_disconnect(self, connection, event):
        pass

    def send_it(self, msg):
        self.console.insertText_(self.nickname + "> " + msg + "\n")
        self.connection.privmsg(self.target, msg)

    def on_all_raw_messages(self, connection, event):
        self.console.insertText_(event.type + " : " + event.arguments[0] + "\n")

class IrcsomeLogHandler(logging.Handler):
    def __init__(self, console):
        self.console = console
        super(IrcsomeLogHandler, self).__init__()

    def emit(self, record):
        self.console.insertText_(record.getMessage() + "\n")

class IrcsomeServer(BaseServer):
    baseName = "Ircsome"
    baseUri = "http://sarkis.info/simple/ircsome#"
    baseCurie = "ircsome:"
    GSMainIbFile = "MainMenu"
    basePath = os.path.dirname(os.path.realpath(__file__))

    def irc_connect(self):
        server = "irc.he.net"
        port = 6667
        nickname = "vernac"
        target = "#vernacular"

        logging_options = type("LoggingOptions", (object,), {"log_level":"INFO"})()
        irc.logging.setup(logging_options)
        logging.getLogger().addHandler(IrcsomeLogHandler(self.textView))

        self.irc_conn = IRCCat(nickname, target, self.textView)
        try:
            self.irc_conn.connect(server, port, nickname)
            self.textView.insertText_("Attempting connection to {}:{}".format(server, port) + '\n')
        except irc.client.ServerConnectionError as x:
            self.textView.insertText_(str(x) + '\n')
        self.irc_conn.start()

    @exportRpc
    def applicationDidFinishLaunching(self):
        print "applicationDidFinishLaunching was called!"
        self.textView.setEditable_(False) #FIXME: not working
        self.textView.setSelectable_(True) #FIXME: not working
        thread.start_new_thread(self.irc_connect, ())

    @exportRpc
    def sendText_(self, arg):
        self.entryField.setStringValue_("")
        #self.entryField.display()
        self.irc_conn.send_it(arg['value'])
