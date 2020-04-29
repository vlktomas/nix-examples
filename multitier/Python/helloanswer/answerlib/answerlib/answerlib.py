import sys
from numpy import array

def answer():
    x = array([[0, 0, 0],[0, 42, 0],[0, 0, 0]])
    return x.item((1, 1))
