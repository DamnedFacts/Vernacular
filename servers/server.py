import werkzeug.serving
from twisted.python import log
from twisted.internet import reactor
from twisted.web.server import Site
from twisted.web.static import File
from autobahn.websocket import listenWS
from autobahn.wamp import exportRpc, WampServerFactory, WampServerProtocol
import sys
import os
import glob

_app_modules = {}
_app_list = {}

for app in os.listdir(os.path.dirname(os.path.abspath(__file__))+"/apps/"):
    appfile = glob.glob(os.path.dirname(os.path.abspath(__file__))+"/apps/{}/{}.py".format(app,app))
    if appfile:
        appname = os.path.basename(appfile[0])[:-3]
        try:
            appmodule = __import__('apps.'+ appname, globals(), locals(), [appname], -1)
            _app_modules[appname] = eval("appmodule.{}".format(appname,appname))
        except Exception, err:
            print "Invalid app {} skipped ({} : {}).".format(appname, sys.exc_info()[0], err)

class AppServerProtocol(WampServerProtocol):
    # Not necessary, and WampServerProtocol is inexlicably an old-style class
    # super will not work with it.
    #def __init__(self):
    #    self.active_app = None
    #    super(AppServerProtocol, self).__init__()

    def onConnect(self, connRequest):
        pass

    def onSessionOpen(self):
        # Required availableApps method
        for app_name, app_info in _app_modules.items():
            _app_list[app_name] = eval("app_info.{}Server.base_uri".format(app_name.capitalize()))
        self.registerForRpc(self)

    @exportRpc
    def registerAppAsRunning(self, app_name):
        self.active_app = eval("_app_modules[app_name].{}Server(self)".format(app_name.capitalize()))

    @exportRpc
    def availableApps(self):
        return _app_list

@werkzeug.serving.run_with_reloader
def runServer():
    if len(sys.argv) > 1 and sys.argv[1] == 'debug':
        log.startLogging(sys.stdout)
        debug = True
    else:
        debug = False

    factory = WampServerFactory("ws://localhost:9000", debug=False, debugCodePaths=False, debugWamp=debug, debugApp=False)
    factory.protocol = AppServerProtocol
    factory.setProtocolOptions(allowHixie76 = True)
    listenWS(factory)

    webdir = File(".")
    web = Site(webdir)
    reactor.listenTCP(8080, web)
    reactor.run(installSignalHandlers=0)

if __name__ == '__main__':
    runServer()
