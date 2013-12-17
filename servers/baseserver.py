from autobahn.wamp import WampServerProtocol
from outletconnector import OutletConnector
from twisted.internet.threads import deferToThread
from twisted.internet.defer import DeferredLock
import autobahn.wamp

def exportThreadedRpc(func = None):
    """
    Decorator for RPC'ed callables.
    """
    lock = DeferredLock()
    def inner(*args, **kwargs):
        result = lock.run(deferToThread, func, *args, **kwargs)
        return result
    # Mimic function of autobahn.wamp.exportRpc()
    inner._autobahn_rpc_id = func.__name__
    return inner

exportRpc = exportThreadedRpc

class BaseServer(WampServerProtocol):
    def __getattr__(self, attr):
        # only called what self.attr doesn't existdefer.DeferredLock
        # FIXME Hack to work with chained WampServerProtocol instances
        # (AppServerProtocol and BaseServer instances
        return getattr(self.protocol, attr)

    def __init__(self, protocol):
        self.protocol = protocol
        self.factory = protocol.factory
        self.protocol.registerForRpc(self, self.base_uri)
        self.protocol.registerForPubSub(self.base_uri, True)
        self.protocol.registerHandlerForPubSub(self, self.base_uri)
        self.outlet_connector = OutletConnector(self, self.base_uri, self.protocol) # Wrap proxy outlet objects
        if hasattr(self, "__postinit__"): self.__postinit__()

    @autobahn.wamp.exportRpc
    def setRemoteMethodBindingsForObject_(self, arg_dict):
        objectName = arg_dict['object']
        objectClass = arg_dict['methodSignatures'].keys()[0]
        methodSignatures = arg_dict['methodSignatures'][objectClass]
        self.outlet_connector.setupProxyClassAndMethods(objectName, objectClass, methodSignatures)

    def loadIbNamed(self, arg):
        f = open(self.base_path + "/Views/" + arg + ".gsmarkup")
        markup = f.read()
        return {"ibname": arg, "markup": markup}

    @autobahn.wamp.exportRpc
    def loadMainIbFile(self):
        return self.loadIbNamed(self.GSMainIbFile)

    @exportRpc
    def applicationDidFinishLaunching(self):
        # To be implemented by the subclass
        pass

    def interactive(self):
        print "Dropping to interactive prompt"
        import inspect, code
        code.interact(local={name:obj for (name, obj) in inspect.getmembers(self)})
