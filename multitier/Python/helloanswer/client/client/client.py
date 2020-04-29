import sys
import rpyc

def main(args=None):
    """The main routine."""
    if len(sys.argv) != 3:
        print("Bad arguments. Please specify server address and port.")
        sys.exit(1)

    # SlaveService
    conn = rpyc.classic.connect(sys.argv[1], port=int(sys.argv[2]))
    conn.execute("from server.presentation import *")
    print(conn.eval("hello(\"World!\")"))
    print(conn.eval("answer()"))

if __name__ == "__main__":
    main()
