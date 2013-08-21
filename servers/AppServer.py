import werkzeug.serving
from twisted.python import log
from twisted.internet import reactor
from twisted.web.server import Site
from twisted.web.static import File
from autobahn.websocket import listenWS
from autobahn.wamp import exportSub, exportRpc, WampServerFactory, WampServerProtocol
import sys

# Imported apps
from calculator import calculator

class AppServerProtocol(WampServerProtocol):
    def __init__(self):
        self.appsList = {}
    
    def onSessionOpen(self):
        
        # Required availableApps method
        self.registerForRpc(self)
        
        # Our calculator app
        calcApp = calculator.CalculatorAppServer(self.factory)
        self.registerForRpc(calcApp, calcApp.baseUri)
        self.registerForPubSub(calcApp.baseUri, True)
        self.appsList[calcApp.baseName] = calcApp.baseUri
    
    @exportRpc
    def availableApps(self):
        return self.appsList

@werkzeug.serving.run_with_reloader
def runServer():    
    if len(sys.argv) > 1 and sys.argv[1] == 'debug':
        log.startLogging(sys.stdout)
        debug = True
    else:
        debug = False
    
    factory = WampServerFactory("ws://localhost:9000", debugWamp = debug)
    factory.protocol = AppServerProtocol
    factory.setProtocolOptions(allowHixie76 = True)
    listenWS(factory)
    
    webdir = File(".")
    web = Site(webdir)
    reactor.listenTCP(8080, web)
    reactor.run(installSignalHandlers=0)

if __name__ == '__main__':
    runServer()
