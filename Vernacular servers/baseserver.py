from autobahn.wamp import exportRpc, WampServerProtocol
from outletconnector import OutletConnector

class BaseServer(WampServerProtocol):
    def __init__(self, app_server_protocol):
        self.factory = app_server_protocol.factory
        app_server_protocol.registerForRpc(self, self.baseUri)
        app_server_protocol.registerForPubSub(self.baseUri, True)
        app_server_protocol.registerHandlerForPubSub(self, self.baseUri)
        self.outlet_connector = OutletConnector(self, self.baseUri, self.dispatch) # Wrap proxy outlet objects
        if hasattr(self, "__postinit__"): self.__postinit__()

    @exportRpc
    def setRemoteMethodBindingsForObject_(self, arg_dict):
        objectName = arg_dict['object']
        objectClass = arg_dict['methodSignatures'].keys()[0]
        methodSignatures = arg_dict['methodSignatures'][objectClass]
        self.outlet_connector.setupProxyClassAndMethods(objectName, objectClass, methodSignatures)

    def loadIbNamed(self, arg):
        f = open(self.basePath + "/Views/" + arg + ".gsmarkup")
        markup = f.read()
        self.dispatch(self.baseUri + "GSMarkupEvent", {"ibname": arg, "markup": markup}, exclude=[], eligible=None)

    @exportRpc
    def loadMainIbFile(self):
        self.loadIbNamed(self.GSMainIbFile)

    @exportRpc
    def applicationDidFinishLaunching(self):
        pass
