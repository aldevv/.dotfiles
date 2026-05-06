#!/usr/bin/python3

import sys
items = sys.stdin.read().replace('\t', '').replace('[','').replace(']','').replace('\n','').replace(' ', '')
items = items.split(',')
items = [ int(items[i]) for i in range(len(items)) ]
items = sorted(items)
print(*items, sep=', ', end='')

# pattern = re.compile(r'[0-9]+,?')
# items = sys.stdin.read()
# items = pattern.finditer(items)
# for item in items:
#     print(item.group())
