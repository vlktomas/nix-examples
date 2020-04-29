import sys
from numpy import array

def main(args=None):
    """The main routine."""
    x = array([[0, 0, 0],[0, 42, 0],[0, 0, 0]])
    print(x.item((1, 1)))

if __name__ == "__main__":
    main()
