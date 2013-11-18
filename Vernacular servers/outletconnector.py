#!/usr/bin/env python

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
    def __init__(self, base_uri, dispatch, classname, methodname, is_instance_method, receiver=None):
        self._base_uri = base_uri
        self._dispatch = dispatch
        self.selector = methodname
        self.receiver = receiver
        return None

    def __call__(self, *args):
        if self._base_uri == None or self._dispatch == None: return
        # e.g. http://sarkis.info/simple/calculator#textField.iboutlet
        self._dispatch(self._base_uri + self.receiver.objectname +".iboutlet", {"selector":self.selector, "parameters":args}, exclude = [], eligible = None)
        return

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

    def __init__(self, objname):
        # Each instance of this base class will contain the name of the object,
        # i.e. the key in Cocoa's Key-Value Coding.
        self.objectname = objname

    # Instance methods
    def __getattr__(self, name):
        if name not in self._methods:
            raise RuntimeError("No such proxy instance method: {}".format(name))
        return self._methods[name]


class OutletConnector(object):
    def __init__(self, outerself, base_uri, ws_dispatch):
        self._outerself = outerself
        self._base_uri = base_uri
        self._dispatch = ws_dispatch
        self._classes = _Classes() # class name -> Python class
        self._instances = {} # ObjC instance -> Python instance

    def setupProxyClassAndMethods(self, objectname, classname, methodsignatures):
        # Create (if necessary) and get our proxy NS class proxy
        NSProxyClass = self._classes[classname]

        # Create an instance of our NS proxy class, and
        # keep track of them in _instances (but currently unused)
        nsproxyobj = NSProxyClass(objectname)
        self._instances[objectname] = nsproxyobj

        # Add only instance methods (no class methods are used)
        # Format the method names according to PyObjC style, where m all ":" are replaced with "_".
        for methodname in methodsignatures:
            nsproxyobj._methods[methodname.replace(':', '_')] = _Method(self._base_uri, self._dispatch, nsproxyobj.__class__.__name__, methodname, True, nsproxyobj)

        """
        Add our instance to the current namespace.
        We store the instances in _instances also, but at the moment there is no way to not pollute the current namespace.
        """
        setattr(self._outerself, objectname, nsproxyobj)
        print "Created proxy class for {} with the name {}".format(classname, objectname)



"""
_nil = None
_type_decodings = {
    'c': 'BOOL',
    '^c': 'BOOL *',
    'i': 'int',
    's': 'short',
    'l': 'long',
    'q': 'long long',
    '^q': 'long long *',
    'C': 'unsigned char',
    'I': 'unsigned int',
    'S': 'unsigned short',
    '^S': 'unsigned short *',
    'r^S': 'const unsigned short *',
    'L': 'unsigned long',
    'Q': 'unsigned long long',
    '^Q': 'unsigned long long *',
    'f': 'float',
    'd': 'double',
    '^d': 'double *',
    'v': 'void',
    '^v': 'void *',
    '^^v': 'void **',
    '@?': 'void (^)',
    'v': 'void',
    'r^v': 'const void *',
    '*': 'char *',
    '^*': 'char **',
    'r*': 'const char *',
    '@': 'id',
    '^@': 'id *',
    '#': 'Class',
    ':': 'SEL',
    '{_NSRange=QQ}': 'NSRange',
    '^{_NSRange=QQ}': 'NSRange *',
    '{CGPoint=dd}': 'CGPoint',
    'r^{CGPoint=dd}': 'const CGPoint *',
    '{CGSize=dd}': 'CGSize',
    '^^{CGRect}': 'CGRect **',
    '{CGRect={CGPoint=dd}{CGSize=dd}}': 'CGRect',
    'r^{CGRect={CGPoint=dd}{CGSize=dd}}': 'const CGRect *',
    '^{CGRect={CGPoint=dd}{CGSize=dd}}':'CGRect',
    '^?': '(*)()',
    'Vv': 'oneway void',
     'B': 'BOOL',
     'b': ':',}





class types(object):
    @staticmethod
    def decode(string):
        try:
            return [_type_decodings[s] for s in _re.split(r'\d+', string)[:-1]]
        except KeyError:
            return "FIXME"

    @staticmethod
    def signature(ret, args, variadic=False):
        return ('%s (*)(%s, ...)' if variadic else '%s (*)(%s)') % (
            ret, ', '.join(args))

    def __init__(self, ret, *args):
        t = {
            'NSInteger': 'long',
            'NSUInteger': 'unsigned long',
            'unichar *': 'unsigned short *',
            'const unichar *': 'const unsigned short *',
            'NSRangePointer': 'NSRange *',
            'NSPoint': 'CGPoint',
            'NSSize': 'CGSize',
            'NSRect': 'CGRect'}
        self.ret = t.get(ret, ret)
        self.args = ('id', 'SEL') + tuple(t.get(a, a) for a in args)

    def __call__(self, f):
        return _Callback(f, self.ret, self.args)

def myexcepthook(exctype, value, traceback):
    if exctype == NameError:
        print "Handler code goes here"
    else:
        sys.__excepthook__(exctype, value, traceback)

sys.excepthook = myexcepthook
"""
