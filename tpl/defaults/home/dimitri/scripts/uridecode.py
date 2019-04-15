#!/bin/python3

import fileinput
import urllib.parse

for line in fileinput.input():
    print(urllib.parse.unquote(line), end='')
