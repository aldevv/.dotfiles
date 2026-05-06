#!/usr/bin/python3
import sys
items = sys.stdin.read().replace('\t', '').replace('[','').replace(']','').replace('\n','').replace(' ', '')
items = items.split(',')
items = [ int(items[i]) for i in range(len(items)) ]
items = sorted(items, reverse=True)
print(*items, sep=', ', end='')

