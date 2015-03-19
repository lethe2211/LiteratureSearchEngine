#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import itertools
import math
from collections import Counter, defaultdict
import csv

class CsvFile(object):
    
    def __init__(self):
        pass

    # Read a file located in ead_filepath and return a two-dimentional array
    def read(self, read_filepath, header=False, delimiter=',', quotechar=None):
        with open(read_filepath, 'r') as f:
            reader = csv.reader(f, delimiter=delimiter, quotechar=quotechar)
            
            # Skip the header
            if header:
                header = next(reader)

            return [row for row in reader]

    # Write a two-dimentional array into write_filepath as a csv file
    def write(self, write_filepath, data, header=None, delimiter=',', quotechar=None):
        with open(write_filepath, 'w') as f:
            writer = csv.writer(f, delimiter=delimiter, quotechar=quotechar, lineterminator='\n')
            if header:
                writer.writerow(header)
            writer.writerows(data)

if __name__ == '__main__':
    cf = CsvFile()
    data = cf.read('test.csv', delimiter='|')
    print data
    cf.write('write.csv', data, delimiter='|')
