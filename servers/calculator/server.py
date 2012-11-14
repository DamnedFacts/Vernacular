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

import sys, decimal

import werkzeug.serving

from twisted.python import log
from twisted.internet import reactor
from twisted.web.server import Site
from twisted.web.static import File

from autobahn.websocket import listenWS
from autobahn.wamp import exportSub, exportRpc, WampServerFactory, WampServerProtocol


class CalculatorServerProtocol(WampServerProtocol):

    def onSessionOpen(self):
        self.total = 0
        self.operand_1 = 0
        self.operand_2 = 0
        self.registerForRpc(self, "http://example.com/simple/calculator#")
        self.registerForPubSub("http://example.com/simple/calculator#", True)
        self.clear()

        #self.prefix("calculator", "http://example.com/simple/calculator#")
        #self.subscribe("http://example.com/simple/calculator#")`


    def clear(self, arg = None):
        self.op = None
        self.current = decimal.Decimal(0)

    @exportRpc
    def mainRibData(self):
        print "Called mainRibData"
        f = open("calculator.gsmarkup")
        rib_data = f.read()
        return rib_data

    # Defined in calculator.gsmarkup
    @exportRpc
    def digit(self, arg):
        if not self.operand_1:
            self.operand_1 = float(arg["value"])
            self.dispatch("http://example.com/simple/calculator#textField.setStringValue", self.operand_1, exclude = [], eligible = None)
        elif self.operand_1:
            self.operand_2 = float(arg["value"])
            self.dispatch("http://example.com/simple/calculator#textField.setStringValue", self.operand_2, exclude = [], eligible = None)

    # Defined in calculator.gsmarkup
    @exportRpc
    def add(self,arg):
        self.operator = arg["value"]

    # Defined in calculator.gsmarkup
    @exportRpc
    def total(self,arg):
        if self.operand_1 and self.operand_2:
            self.total = self.operand_1 + self.operand_2
            self.operand_1 = 0
            self.operand_2 = 0
            print self.total
        self.dispatch("http://example.com/simple/calculator#textField.setStringValue", self.total, exclude = [], eligible = None)
        return self.total

'''
    @exportRpc
    def calc(self, arg):

        op = arg["op"]

        if op == "C":
            self.clear()
            return str(self.current)

        num = decimal.Decimal(arg["num"])
        if self.op:
            if self.op == "+":
                self.current += num
            elif self.op == "-":
                self.current -= num
            elif self.op == "*":
                self.current *= num
            elif self.op == "/":
                self.current /= num
            self.op = op
        else:
            self.op = op
            self.current = num

        res = str(self.current)
        if op == "=":
            self.clear()

        return res
'''

@werkzeug.serving.run_with_reloader
def runServer():
    decimal.getcontext().prec = 20

    if len(sys.argv) > 1 and sys.argv[1] == 'debug':
        log.startLogging(sys.stdout)
        debug = True
    else:
        debug = False

    factory = WampServerFactory("ws://localhost:9000", debugWamp = debug)
    factory.protocol = CalculatorServerProtocol
    factory.setProtocolOptions(allowHixie76 = True)
    listenWS(factory)

    webdir = File(".")
    web = Site(webdir)
    reactor.listenTCP(8080, web)
    reactor.run(installSignalHandlers=0)

if __name__ == '__main__':
    runServer()
