import os, thread, code
from autobahn.wamp import exportRpc
from baseserver import BaseServer

def init(factory):
    return CalculatorServer(factory)

class CalculatorServer(BaseServer):
    baseName = "Calculator"
    baseUri = "http://sarkis.info/simple/calculator#"
    baseCurie = "calculator:"
    basePath = os.path.dirname(os.path.realpath(__file__))
    GSMainIbFile = "MainMenu"

    def __postinit__(self):
        self.totaled = 0.0
        self.operator = False
        self.operand_1 = u''
        self.operand_2 = u''
        self.memory = 0
        self.negate = False
        # FIXME: If debug only.
        #thread.start_new_thread(self.interactive, ())

        ## register a single, fixed URI as PubSub topic
        print "Calculator started..."

    def interactive(self):
        print "Dropping to interactive prompt"
        code.InteractiveConsole(globals()).interact()

    @exportRpc
    def showPaperRoll(self, arg):
        self.loadIbNamed("PaperRoll")

    @exportRpc
    def applicationDidFinishLaunching(self):
        self.totaled = 0.0
        self.textField.setStringValue_(str(self.totaled))

    # Defined in calculator.gsmarkup
    @exportRpc
    def clearMemory_(self, arg):
        self.memory = 0

    @exportRpc
    def addToMemory_(self, arg):
        self.memory = self.memory + float(arg["value"])

    @exportRpc
    def subToMemory_(self, arg):
        self.memory = self.memory - float(arg["value"])

    @exportRpc
    def recallMemory_(self, arg):
        self.textField.setStringValue_(str(self.memory))

    @exportRpc
    def clearDisplay_(self, arg):
        self.operand_1 = u''
        self.operand_2 = u''
        self.operator = False
        self.totaled = 0.0
        self.textField.setStringValue_(str(0.0))

    @exportRpc
    def operator_(self, arg):
        if arg["value"] == u'\u2a09': self.operator = u'*' # Multiplication character
        elif arg["value"] == u'\u00f7': self.operator = u'/' # Division character
        elif arg["value"] == u'\u00B1': # Negation character
            if self.operand_2:
                self.operand_2 = float(self.operand_2) * -1
                self.textField.setStringValue_(str(self.operand_2))
            elif self.operand_1:
                self.operand_1 = float(self.operand_1) * -1
                self.textField.setStringValue_(str(self.operand_1))
        else: self.operator = arg["value"]

    @exportRpc
    def digit_(self, arg):
        # Args are passed as UTF-8 strings, so we string concatenate each digit of each operand as we move along.            
        if not self.operator:
            self.operand_1 = self.operand_1 + arg["value"]
            self.textField.setStringValue_(str(self.operand_1))
        elif self.operator:
            self.operand_2 = self.operand_2 + arg["value"]
            self.textField.setStringValue_(str(self.operand_2))

    # Defined in calculator.gsmarkup
    @exportRpc
    def total_(self, arg):
        self.totaled = eval("{0} {1} {2}".format(float(self.operand_1), self.operator, float(self.operand_2)))
        self.operator = False
        self.operand_1 = str(self.totaled)
        self.operand_2 = ""
        self.textField.setStringValue_(str(self.totaled))
