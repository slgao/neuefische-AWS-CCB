#! /usr/bin/env python
# coding=utf-8
# ================================================================
#   Copyright (C) 2025 * Ltd. All rights reserved.
#
#   Editor      : EMACS
#   File name   : test.py
#   Author      : slgao
#   Created date: Fri Jun 06 2025 10:10:23
#   Description : Print numbers from 1 to 100, replacing multiples of 3 with "Fizz," multiples of 5 with "Buzz," and multiples of both with "FizzBuzz."
#
# ================================================================

def FizzBuzz():
    for i in range(1, 101):
        if i % 15 == 0:
            print("FizzBuzz")
        elif i % 3 == 0:
            print("Fizz")
        elif i % 5 == 0:
            print("Buzz")
        else:
            print(i)

if __name__ == '__main__':
    FizzBuzz()
