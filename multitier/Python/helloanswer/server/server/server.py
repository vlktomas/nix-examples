import sys
import rpyc
from rpyc.utils.server import ThreadedServer # or ForkingServer

def main(args=None):
    """The main routine."""
    if len(sys.argv) != 2:
        print("Bad arguments. Please specify server port.")
        sys.exit(1)

    server = ThreadedServer(rpyc.SlaveService, port=int(sys.argv[1]), protocol_config={"allow_public_attrs": True, "allow_all_attrs": True})
    server.start()

if __name__ == "__main__":
    main()
