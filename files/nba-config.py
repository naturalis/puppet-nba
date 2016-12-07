#!/usr/bin/python2.7
#Creates config file for nba
from os import environ
config_array = [
{'elasticsearch.cluster.name': 'nba-cluster'},
{'elasticsearch.transportaddress.host': '127.0.0.1'},
{'elasticsearch.transportaddress.port': 9300},
{'elasticsearch.index.default.shards': 1},
{'elasticsearch.index.default.replicas': 0},
{'elasticsearch.index.0.name': 'specimens'},
{'elasticsearch.index.0.types' : 'Specimen'},
{'elasticsearch.index.1.name':'taxa'},
{'elasticsearch.index.1.types':'Taxon'},
{'elasticsearch.index.2.name':'multimedia'},
{'elasticsearch.index.2.types':'MultiMediaObject'},
{'elasticsearch.index.3.name':'geoareas'},
{'elasticsearch.index.3.types':'GeoArea'}]



for i in config_array:
    k = i.keys()[0]
    v = i[i.keys()[0]]
    try:
        v = environ[k.replace('.','_')]
    except:
        pass
    print "%s=%s" % (k,v)
