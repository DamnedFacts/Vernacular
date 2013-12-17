#!/usr/bin/env python

from twisted.internet.threads import blockingCallFromThread

class _Classes(dict):
    def __init__(self):
         self['NSObject'] = _MetaClass('NSObject',(NSObject,),{'_classes':self})

    def __getitem__(self, key):
        try:
            return dict.__getitem__(self, key)
        except KeyError:
            self[key] = _MetaClass(str(key),(NSObject,),{'_classes':self})
            return self[key]


class _Method(object):
    def __init__(self, base_uri, protocol, methodname, objectname, is_instance_method):
        self._base_uri = base_uri
        self._protocol = protocol
        self.selector = methodname
        self.objectname = objectname
        self.is_instance_method = is_instance_method
        self.result = None

    def __call__(self, *args):
        if self._base_uri == None or self._protocol == None: return
        self.result = blockingCallFromThread(self._protocol.factory.reactor, self._protocol.call,
                                             self._base_uri + self.objectname +".iboutlet", {"selector":self.selector, "parameters":args})
        return self.result

# MetaClass
class _MetaClass(type):
    def __new__(meta, name, bases, dict):
        _classes = dict['_classes']
        if name not in _classes:
            dict['_methods'] = {} # method name -> Python method
            _classes[name] = type.__new__(meta, name, bases, dict)
        return _classes[name]

    # Class methods, currently not used
    def __getattr__(cls, name):
        if name not in cls._methods:
            raise RuntimeError("No such proxy class method: {}".format(name))
        return cls._methods[name]

class NSObject(object):
    # We manually create NSObject-dervied classes with type() and _MetaClass in
    # class _Classes
    #__metaclass__ = _MetaClass

    def __init__(self, methods):
        # Each instance of this base class will contain the name of the object,
        # i.e. the key in Cocoa's Key-Value Coding.
        self._methods = methods

    # Instance methods
    def __getattr__(self, name):
        if name not in self._methods:
            raise RuntimeError("No such proxy instance method: {}".format(name))
        return self._methods[name]


class OutletConnector(object):
    def __init__(self, outerself, base_uri, ws_protocol):
        self._outerself = outerself
        self._base_uri = base_uri
        self._protocol = ws_protocol
        self._classes = _Classes() # class name -> Python class
        self._instances = {} # ObjC instance -> Python instance

    def setupProxyClassAndMethods(self, objectname, classname, methodsignatures):
        # Create (if necessary) and get our proxy NS class proxy
        NSProxyClass = self._classes[classname]

        # Add only instance methods (no class methods are used)
        # Format the method names according to PyObjC style, where m all ":" are replaced with "_".
        methods_dict = {}
        for methodname in methodsignatures:
            methods_dict[methodname.replace(':', '_')] = _Method(self._base_uri, self._protocol, methodname, objectname, True)

        # Create an instance of our NS proxy class, and
        # keep track of them in _instances (but currently unused)
        nsproxyobj = NSProxyClass(methods_dict)
        self._instances[objectname] = nsproxyobj

        """
        Add our instance to the current namespace.
        We store the instances in _instances also, but at the moment there is no way to not pollute the current namespace.
        """
        setattr(self._outerself, objectname, nsproxyobj)
        print "Created proxy class for {} with the name {}".format(classname, objectname)
