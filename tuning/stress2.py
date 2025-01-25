#!/usr/bin/python3
import os
import sys
from contextlib import contextmanager

@contextmanager
def silence_stdout():
    new_target = open(os.devnull, "w")
    old_target = sys.stdout
    sys.stdout = new_target
    try:
        yield new_target
    finally:
        sys.stdout = old_target

def factorial(n):
    num = 1
    while n >= 1:
        num = num * n
        n = n - 1
    return num

if __name__ == '__main__':
    big_number = 98000

    for i in range(1, big_number+1):
        with silence_stdout():
            print("factorial(%d)"%(i))
        factorial(i)


