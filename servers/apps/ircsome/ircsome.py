from baseserver import BaseServer, exportRpc
import irc.client, irc.logging
import os, thread, logging

class IRCCat(irc.client.SimpleIRCClient):
    motd = ""

    def __init__(self, nickname, target, console, nicklist):
        irc.client.SimpleIRCClient.__init__(self)
        self.nickname = nickname
        self.target = target
        self.console = console
        self.nicklist = nicklist

    def on_welcome(self, connection, event):
        if irc.client.is_channel(self.target):
            connection.join(self.target)
        else:
            return

    def on_join(self, connection, event):
        print "on_join ", connection.names(channels=self.target)
        print self.target
        connection.names(channels=[self.target,])
        pass

    def on_pubmsg(self, connection, event):
        user = event.source.split('!')[0]
        mesg = event.arguments[0]
        self.console.insertText_(user + "> " + mesg + "\n")

    def on_namreply(self, connection, event):
        print "on_namreply ", event.arguments
        self.nicklist.setString_("")
        for nick in event.arguments[-1].split(" "):
            self.nicklist.insertText_(nick + "\n")

    def on_endofnames(self, connection, event):
        pass

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
        #self.console.insertText_(event.type + " : " + event.arguments[0] + "\n")
        pass

class IrcsomeLogHandler(logging.Handler):
    def __init__(self, console):
        self.console = console
        super(IrcsomeLogHandler, self).__init__()

    def emit(self, record):
        self.console.insertText_(record.getMessage() + "\n")

class IrcsomeServer(BaseServer):
    base_name = "Ircsome"
    base_uri = "http://sarkis.info/simple/ircsome#"
    base_curie = "ircsome:"
    base_path = os.path.dirname(os.path.realpath(__file__))
    GSMainIbFile = "MainMenu"

    def irc_connect(self):
        server = "asimov.freenode.net"
        port = 6667
        nickname = "vernac"
        target = "#vernacular"

        logging_options = type("LoggingOptions", (object,), {"log_level":"INFO"})()
        irc.logging.setup(logging_options)
        logging.getLogger().addHandler(IrcsomeLogHandler(self.consoleView))

        self.irc_conn = IRCCat(nickname, target, self.consoleView, self.nickView)
        try:
            self.irc_conn.connect(server, port, nickname)
            self.consoleView.insertText_("Attempting connection to {}:{}".format(server, port) + '\n')
        except irc.client.ServerConnectionError as x:
            self.consoleView.insertText_(str(x) + '\n')
        self.irc_conn.start()

    @exportRpc
    def applicationDidFinishLaunching(self):
        print "applicationDidFinishLaunching was called!"
        self.consoleView.setEditable_(True)
        self.consoleView.setSelectable_(True)

        """
         FIXME: Currently, our remote object bindings handles
         JSON-able data types. In cases of more complex, unserializable
         data types (like NSTextStorage, below) proxy these calls
         as if they were top-level bound objects, like self.consoleView.
         Get text storage of the NSTextView and append text to it.
        """
        #string = NSAttributedString.alloc.initWithString(str)
        #storage = self.consoleView.textStorage()
        #print storage
        #[storage beginEditing];
        #[storage appendAttributedString:string];
        #[storage endEditing];
        # Scroll to bottom after appending
        # NSRange end_pos = NSMakeRange([storage length], 0);
        # [connectionConsole scrollRangeToVisible:end_pos];

        thread.start_new_thread(self.irc_connect, ())

    @exportRpc
    def sendText_(self, arg):
        self.entryField.setStringValue_("")
        #self.entryField.display()
        self.irc_conn.send_it(arg['value'])
