###############################################################################
##
##  Copyright 2011,2012 Tavendo GmbH
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##        http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
##
###############################################################################

import decimal, os
from autobahn.wamp import exportSub, exportRpc, WampServerProtocol

class CalculatorAppServer(WampServerProtocol):
    def __init__(self, factory):
        self.factory = factory
        self.baseName = "Calculator"
        self.baseUri = "http://sarkis.info/simple/calculator#"
        self.baseCurie = "calculator:"
        self.totaled = 0.0
        self.operator = False
        self.operand_1 = u''
        self.operand_2 = u''
        self.memory = 0
        self.negate = False
    
    @exportRpc
    def mainRibData(self):
        print "Calculator started..."
        print "Called mainRibData"
        f = open(os.path.dirname(os.path.realpath(__file__)) + "/Views/calculator.gsmarkup")
        rib_data = f.read()
        return rib_data

    @exportRpc
    def applicationDidFinishLaunching(self):
        self.totaled = 0.0
        self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.totaled]}, exclude = [], eligible = None)

    # Defined in calculator.gsmarkup
    @exportRpc
    def clearMemory(self, arg):
        self.memory = 0

    @exportRpc
    def addToMemory(self, arg):
        self.memory = self.memory + float(arg["value"])

    @exportRpc
    def subToMemory(self, arg):
        self.memory = self.memory - float(arg["value"])
    
    @exportRpc
    def recallMemory(self, arg):
        self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.memory]}, exclude = [], eligible = None)

    @exportRpc
    def clearDisplay(self, arg):
        self.operand_1 = u''
        self.operand_2 = u''
        self.operator = False
        self.totaled = 0.0
        self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[0.0]}, exclude = [], eligible = None)
    
    @exportRpc
    def operator(self, arg):
        if arg["value"] == u'\u2a09': self.operator = u'*' # Multiplication character
        elif arg["value"] == u'\u00f7': self.operator = u'/' # Division character
        elif arg["value"] == u'\u00B1': # Negation character
            if self.operand_2:
                self.operand_2 = float(self.operand_2) * -1
                self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.operand_2]} , exclude = [], eligible = None)
            elif self.operand_1:
                self.operand_1 = float(self.operand_1) * -1
                self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.operand_1]} , exclude = [], eligible = None)
        else: self.operator = arg["value"]
    
    @exportRpc
    def digit(self, arg):
        # Args are passed as UTF-8 strings, so we string concatenate each digit of each operand as we move along.            
        if not self.operator:
            self.operand_1 = self.operand_1 + arg["value"]
            self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.operand_1]} , exclude = [], eligible = None)
        elif self.operator:
            self.operand_2 = self.operand_2 + arg["value"]
            self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.operand_2]} , exclude = [], eligible = None)

    # Defined in calculator.gsmarkup
    @exportRpc
    def total(self, arg):
        self.totaled = eval("{0} {1} {2}".format(float(self.operand_1), self.operator, float(self.operand_2)))
        self.operator = False
        self.operand_1 = str(self.totaled)
        self.operand_2 = ""
        self.dispatch(self.baseUri + "textField.iboutlet", {"selector":"setStringValue:", "parameters":[self.totaled]} , exclude = [], eligible = None)

            