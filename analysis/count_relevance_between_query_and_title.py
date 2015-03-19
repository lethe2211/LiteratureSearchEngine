#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import itertools
import math
from collections import Counter, defaultdict
import numpy as np

from filecache import Client
from msacademic_api_wrapper import MsacademicApiWrapper
from csvfile import CsvFile
from set_similarity import SetSimilarity

class Main(object):
    
    def __init__(self):
        pass

    def solve(self):
        cache = Client()
        
        if cache.get('query_relevant_and_partially_relevant'):
            sim_for_task = cache.get('query_relevant_and_partially_relevant')
        else:
            cf = CsvFile()
            data = cf.read('query_relevant_and_partially_relevant.csv', delimiter='|')
            # print data
            sim_for_task = defaultdict(list)
            for elem in data:
                task_id = elem[1]
                query = elem[2]
                query_terms = set(query.split())
                literature_id = elem[3]
                title = MsacademicApiWrapper.get_title(literature_id)
                title_terms = set(title.split())
                sim = SetSimilarity.jaccard_similarity(query_terms, title_terms)
                sim = query_terms & title_terms
                print task_id, sim
                sim_for_task[task_id].append(len(sim))

            cache.set('query_relevant_and_partially_relevant', sim_for_task)
        print sim_for_task
        
        # 研究分野ごとに集計
        print 'Research Field 1:'
        self.calculate(sim_for_task, ['5', '6', '10', '13', '17', '20'])
        print 'Research Field 2:'
        self.calculate(sim_for_task, ['8', '14', '19', '7', '12', '16'])
        print 'Research Field 3:'
        self.calculate(sim_for_task, ['9', '11', '15', '18', '21', '22'])

        # インタフェースごとに集計
        print 'Interface (a):'
        self.calculate(sim_for_task, ['5', '6', '8', '10', '13', '14', '17', '19', '20'])
        print 'Interface (b):'
        self.calculate(sim_for_task, ['7', '9', '11', '12', '15', '16', '18', '21', '22'])

        # 研究分野，インタフェースごとに集計
        print 'Reserch Field 1, Interface (a):'
        self.calculate(sim_for_task, ['5', '6', '10'])
        print 'Reserch Field 1, Interface (b):'
        self.calculate(sim_for_task, ['9', '11', '15'])
        print 'Reserch Field 2, Interface (a):'
        self.calculate(sim_for_task, ['8', '14', '19'])
        print 'Reserch Field 2, Interface (b):'
        self.calculate(sim_for_task, ['7', '12', '16'])
        print 'Reserch Field 3, Interface (a):'
        self.calculate(sim_for_task, ['13', '17', '20'])
        print 'Reserch Field 3, Interface (b):'
        self.calculate(sim_for_task, ['18', '21', '22'])
            
        return None

    def calculate(self, sim_for_task, task_ids):
        ans = []
        for key, value in sim_for_task.items():
            if key in task_ids:
                ans += value
        a = np.array(ans)
        print 'avg: {0}'.format(np.average(a))
        print 'std: {0}'.format(np.std(a))
        print 

if __name__ == '__main__':
    m = Main()
    m.solve()
