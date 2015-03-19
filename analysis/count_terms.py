#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import itertools
import math
from collections import Counter, defaultdict
from csvfile import CsvFile
import numpy

from set_similarity import SetSimilarity

class Main(object):
    
    def __init__(self):
        pass

    # def solve(self):
    #     cf = CsvFile()
    #     orig_data = cf.read('query_overlap.csv', delimiter='|')

    #     # 各タスクIDごとに，入力されたクエリとその頻度分布を習得
    #     data = defaultdict(Counter)
    #     for task_id, query in orig_data:
    #         query = query.strip('\"')
    #         for term in query.split():
    #             data[task_id][term] += 1

    #     # 研究分野ごとに集計
    #     print 'Research Field 1:'
    #     self.calculate_overlap_of_terms(data, ['5', '6', '10', '13', '17', '20'])
    #     print 'Research Field 2:'
    #     self.calculate_overlap_of_terms(data, ['8', '14', '19', '7', '12', '16'])
    #     print 'Research Field 3:'
    #     self.calculate_overlap_of_terms(data, ['9', '11', '15', '18', '21', '22'])

    #     # インタフェースごとに集計
    #     print 'Interface (a):'
    #     self.calculate_overlap_of_terms(data, ['5', '6', '8', '10', '13', '14', '17', '19', '20'])
    #     print 'Interface (b):'
    #     self.calculate_overlap_of_terms(data, ['7', '9', '11', '12', '15', '16', '18', '21', '22'])

    #     # 研究分野，インタフェースごとに集計
    #     print 'Reserch Field 1, Interface (a):'
    #     self.calculate_overlap_of_terms(data, ['5', '6', '10'])
    #     print 'Reserch Field 1, Interface (b):'
    #     self.calculate_overlap_of_terms(data, ['9', '11', '15'])
    #     print 'Reserch Field 2, Interface (a):'
    #     self.calculate_overlap_of_terms(data, ['8', '14', '19'])
    #     print 'Reserch Field 2, Interface (b):'
    #     self.calculate_overlap_of_terms(data, ['7', '12', '16'])
    #     print 'Reserch Field 3, Interface (a):'
    #     self.calculate_overlap_of_terms(data, ['13', '17', '20'])
    #     print 'Reserch Field 3, Interface (b):'
    #     self.calculate_overlap_of_terms(data, ['18', '21', '22'])
    #     return None

    # # あるタスクIDにおけるクエリの頻度分布について，その平均と標準偏差を求める
    # def calculate_overlap_of_terms(self, data, task_ids):
    #     rf = [v for k, v in data.items() if k in task_ids]
    #     rf_elems = []
    #     for elem in rf:
    #         for k, v in elem.items():
    #             rf_elems.append(v)
    #     a = numpy.array(rf_elems)
    #     print 'avg: {0}'.format(numpy.average(a))
    #     print 'std: {0}'.format(numpy.std(a))
    #     print 

    def solve(self):
        cf = CsvFile()
        orig_data = cf.read('query_overlap.csv', delimiter='|')

        # 各タスクIDごとに，入力されたクエリとその頻度分布を習得
        data = defaultdict(set)
        for task_id, query in orig_data:
            query = query.strip('\"')
            for term in query.split():
                data[task_id].add(term)

        # 研究分野ごとに集計
        print 'Research Field 1:'
        self.calculate_overlap_of_terms(data, ['5', '6', '10', '13', '17', '20'])
        print 'Research Field 2:'
        self.calculate_overlap_of_terms(data, ['8', '14', '19', '7', '12', '16'])
        print 'Research Field 3:'
        self.calculate_overlap_of_terms(data, ['9', '11', '15', '18', '21', '22'])

        # 研究分野，インタフェースごとに集計
        print 'Reserch Field 1, Interface (a):'
        self.calculate_overlap_of_terms(data, ['5', '6', '10'])
        print 'Reserch Field 1, Interface (b):'
        self.calculate_overlap_of_terms(data, ['11', '15', '18'])
        print 'Reserch Field 2, Interface (a):'
        self.calculate_overlap_of_terms(data, ['8', '14', '19'])
        print 'Reserch Field 2, Interface (b):'
        self.calculate_overlap_of_terms(data, ['7', '12', '16'])
        print 'Reserch Field 3, Interface (a):'
        self.calculate_overlap_of_terms(data, ['13', '17', '20'])
        print 'Reserch Field 3, Interface (b):'
        self.calculate_overlap_of_terms(data, ['18', '21', '22'])
        return None

    def calculate_overlap_of_terms(self, data, task_ids):
        ans = []
        for elem in itertools.combinations(task_ids, 2):
            # print elem[0], elem[1]
            # print data[elem[0]], data[elem[1]]
            ans.append(len(data[elem[0]] & data[elem[1]]) * 1.0 / len(data[elem[0]] | data[elem[1]]))
        a = numpy.array(ans)
        print numpy.mean(a)
        print numpy.std(a)
        
if __name__ == '__main__':
    m = Main()
    m.solve()
