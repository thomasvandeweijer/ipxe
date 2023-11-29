#!/usr/bin/env python3

import sys
import xmlrunner
import unittest
import json
import dns.resolver
import dns.exception

# Flag for verbose output should be False after development, but can be set True by using -v
verbose_flag = False
if '-v' in sys.argv:
    verbose_flag = True

ips_zones = {}
node_data_file = '/etc/sidn/node_data.json'

# for debugging when developing, or error analysis when in production
def verbose(title, msg):
    if verbose_flag:
        print(f'################ {title} ##################')
        print(msg)

# read node data such as zones from file
def read_node_data():
    with open(node_data_file, 'r') as f:
        node_data = json.load(f)
    verbose('node_data (dict)', node_data)
    return node_data

def prepare_resolver_stub(ip):
    try:
        # Create our own resolver stub & config, so we can bypass resolv.conf
        resolver_stub = dns.resolver.Resolver(filename='/dev/null',
                                              configure=False)
        resolver_stub.nameservers = [ip]
        dns.resolver.override_system_resolver(resolver=resolver_stub)
    except Exception as e:
        verbose('ERROR', e)
        return False, e
    return resolver_stub, None

def query(resolver_stub, ip, zone, protocol, rrtype):
    try:
        if protocol == 'udp':
            result_object = resolver_stub.resolve(zone, rrtype, tcp=False)
            verbose(f'response {ip} {zone}, {protocol} {rrtype}',
                    result_object[0])
        else:
            result_object = resolver_stub.resolve(zone, rrtype, tcp=True)
            verbose(f'response {ip} {zone}, {protocol} {rrtype}',
                    result_object[0])
    except dns.exception.DNSException as e:
        return False, e
    return result_object[0], None

def fill_ips_zones():
    node_data = read_node_data()
    for customer in node_data:
        customer_name = customer['customer']['name']
        customer_group_list = customer['customer']['group']
        for group in customer_group_list:
            ips_zones[group['IPv4']] = []
            ips_zones[group['IPv6']] = []
            for dom in group['domains']:
                verbose(customer_name, group['IPv4'] + ' ' + dom)
                verbose(customer_name, group['IPv6'] + ' ' + dom)
                ips_zones[group['IPv4']].append(dom)
                ips_zones[group['IPv6']].append(dom)
    verbose('IP-Zone combinations from node_data.json', ips_zones)
    return ips_zones


class Test(unittest.TestCase):

    def test_if_knot_containers_serve_soa_for_zone_on_designated_ip(self):
        rrtype = 'SOA'
        for ip in ips_zones.keys():
            resolver_stub, error = prepare_resolver_stub(ip)
            if not resolver_stub:
                msg = f'Failed to create resolver stub {error}'
                with self.subTest(msg=msg):
                    self.assertTrue(resolver_stub)
            else:
                for zone in ips_zones[ip]:
                    for protocol in ['udp', 'tcp']:
                        answer, error = query(resolver_stub,
                                              ip, zone, protocol, rrtype)
                        msg = f'Failed query: {ip} {protocol} {zone} {rrtype}, \
                                {error}'
                        with self.subTest(msg=msg):
                            self.assertTrue(answer)
                # unconfigure the stub between ip's to prevent reuse
                resolver_stub.nameservers = []


if __name__ == "__main__":
    node_data = read_node_data()
    ips_zones = fill_ips_zones()
    unittest.main(testRunner=xmlrunner.XMLTestRunner(output='results'))
    sys.exit(0)

# vim: set ts=4 sts=4 et ai nohlsearch sw=4
