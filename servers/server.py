import werkzeug.serving
from twisted.python import log
from twisted.internet import reactor
from twisted.web.server import Site
from twisted.web.static import File
from autobahn.websocket import listenWS
from autobahn.wamp import exportSub, exportRpc, WampServerFactory, WampServerProtocol
import sys
import os
import glob

__apps__ = []

for app in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/apps/"):
    appfile = glob.glob(os.path.dirname(os.path.abspath(__file__))+"/apps/{}/{}.py".format(app,app))
    if appfile:
        appname = os.path.basename(appfile[0])[:-3]
        try:
            appmodule = __import__('apps.'+ appname, globals(), locals(), [appname], -1)
            __apps__.append(eval("appmodule.{}".format(appname,appname)))
        except Exception, err:
            #import traceback
            #print traceback.format_exc()
            print "Invalid app {} skipped ({} : {}).".format(appname, sys.exc_info()[0], err)

class AppServerProtocol(WampServerProtocol):
    def __init__(self):
        self.appsList = {}

    def onSessionOpen(self):
        # Required availableApps method
        self.registerForRpc(self)

        for appmodule in __apps__:
            app = appmodule.init(self)
            self.appsList[app.baseName] = app.baseUri

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
