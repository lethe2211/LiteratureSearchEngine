# vim: fileencoding=utf-8
'''
Created on 2009/04/07

@author: tyamamot
'''

import cPickle
import os,time

__all__ = ["Client"]

class Client(object):
    """
    fileをつかったキャッシュ
    """
    dir = ""
    prefix = "cache_"
    postfix = ".dat"
    timeout = 1000 * 60 * 24 * 365   #365日
    
    def __init__(self,dir="cache/",timeout = 1000 * 60 * 24 * 120):
        self.dir = dir
        self.timeout = timeout
    
    def get(self,key,defValue = None):
        filename = self.dir + self.prefix + key  +self.postfix
        if not os.path.exists(filename):
            return None
        create = os.stat(filename)[8]
        now = time.time()
        if now - create >  self.timeout:
            print "FileCache: Timeout"
            print self.timeout + create, now
            return defValue
        f = open(filename,"r")
        unpickle = cPickle.Unpickler(f)
        value = unpickle.load()
        return value
    
    def set(self,key,value):
        filename = self.dir + self.prefix + key  +self.postfix
        try:
            f = open(filename,"w")
            pickle = cPickle.Pickler(f)
            pickle.dump(value)
            f.close()
        except IOError ,e:
            print e
    


if __name__ == "__main__":
    v = "data"
    cache = Client()
    cache.set("hoge",v)
    result = cache.get("hoge","nothing")
    print result
