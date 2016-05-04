#!/usr/bin/env python2.7

import socket
import json
import urllib2

__not_up_text = 'es_not_up'

def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]

def get_node_data(ip):
    url = 'http://%s:9200/_nodes?pretty' % ip
    try:
        return json.load(urllib2.urlopen(url))
    except:
        return __not_up_text

def node_ip_addresses(data):
    array = []
    for node in data['nodes']:
        array.append(data['nodes'][node]['network']['primary_interface']['address'])
    return ','.join(array)

def number_of_nodes(data):
    return str(len(data['nodes']))

def suggested_reps(data):
    return str(len(data['nodes'])-1)

def suggested_master_nodes(data):
    return str(len(data['nodes']))


node_data = get_node_data(get_ip_address())

if node_data == __not_up_text:
    print 'cluster_ips=%s' % node_data
    print 'cluster_nodes=%s' % node_data
    print 'suggested_reps=%s' % node_data
    print 'suggested_master_nodes=%s' % node_data
else:
    print 'cluster_ips=%s' % node_ip_addresses(node_data)
    print 'cluster_nodes=%s' % number_of_nodes(node_data)
    print 'suggested_reps=%s' % suggested_reps(node_data)
    print 'suggested_master_nodes=%s' % suggested_master_nodes(node_data)
