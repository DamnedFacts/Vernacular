import sys
import argparse

from twisted.python import log
from twisted.internet import reactor
from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS
  
class EchoServerProtocol(WebSocketServerProtocol):
   def onMessage(self, msg, binary):
      self.sendMessage(msg, binary)
 
class EchoServerFactory(WebSocketServerFactory):
    protocol = EchoServerProtocol
    
    def __init__(self, url, debug = False):
        WebSocketServerFactory.__init__(self, url, debug=debug, debugCodePaths=debug)
        self.debug = debug
 
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run a Vernacular WebSocket echo server')

    parser.add_argument('--debug', dest='debug', action='store_true',
                       default=False, help='Enable echo server debug')

    args = parser.parse_args()

    if args.debug:
        log.startLogging(sys.stdout)
    
    factory = EchoServerFactory("ws://localhost:9000", debug = args.debug)
    
    listenWS(factory)
    reactor.run()