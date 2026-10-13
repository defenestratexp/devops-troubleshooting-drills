"""A VPC reachability checker, reduced to the layers that drop these packets.

This is the grader, and it is meant to be read. Each flow is walked through the
layers in the order AWS applies them, and the first layer that drops the packet
is named.

The two asymmetries it models, because they are where the bugs live:

  * **Security groups are stateful.** An allowed outbound connection's return
    traffic is allowed back automatically, whatever the inbound rules say.
  * **Network ACLs are stateless.** Every packet is evaluated on its own, so
    the return packet needs its own rule -- and its source port is ephemeral,
    not the port the connection was opened to.

Scope: TCP only; no transit gateways, VPC endpoints, peering, or prefix lists.
"""
import ipaddress
import json
import os
import sys

INTERNET = "internet"
INTERNET_IP = ipaddress.ip_address("203.0.113.10")
EPHEMERAL_SRC = 49152  # a representative ephemeral source port


class Drop(Exception):
    def __init__(self, layer, detail):
        super().__init__("%s: %s" % (layer, detail))
        self.layer = layer
        self.detail = detail


def ports_of(spec):
    spec = str(spec)
    if "-" in spec:
        lo, hi = spec.split("-", 1)
        return int(lo), int(hi)
    return int(spec), int(spec)


def port_in(spec, port):
    lo, hi = ports_of(spec)
    return lo <= port <= hi


def proto_ok(rule, proto="tcp"):
    p = str(rule.get("protocol", "-1")).lower()
    return p in (proto, "-1", "all")


class Net:
    def __init__(self, data):
        self.d = data
        self.vpc = ipaddress.ip_network(data["vpc_cidr"])

    # -- endpoints ---------------------------------------------------------
    def ip_of(self, name):
        if name == INTERNET:
            return INTERNET_IP
        inst = self.d["instances"][name]
        net = ipaddress.ip_network(self.d["subnets"][inst["subnet"]]["cidr"])
        return net.network_address + 10

    def subnet_of(self, name):
        if name == INTERNET:
            return None
        return self.d["instances"][name]["subnet"]

    def sg_of(self, name):
        if name == INTERNET:
            return None
        return self.d["instances"][name]["security_group"]

    # -- layers ------------------------------------------------------------
    def route_out(self, subnet_name, dst_ip):
        """Longest-prefix match in the subnet's route table."""
        sub = self.d["subnets"][subnet_name]
        table = self.d["route_tables"].get(sub["route_table"], [])
        best, best_len = None, -1
        for route in table:
            net = ipaddress.ip_network(route["dest"])
            if dst_ip in net and net.prefixlen > best_len:
                best, best_len = route, net.prefixlen
        if best is None:
            raise Drop("route table '%s'" % sub["route_table"],
                       "no route matches %s" % dst_ip)
        target = best["target"]
        if target == "local":
            return target
        if target.startswith("igw-") and not sub.get("maps_public_ip"):
            raise Drop("route table '%s'" % sub["route_table"],
                       "0.0.0.0/0 points at %s, but instances in this subnet have "
                       "no public IP, so the gateway has no address to translate "
                       "to -- a private subnet needs a NAT gateway" % target)
        if target.startswith("nat-"):
            nat = self.d.get("nat_gateways", {}).get(target)
            if nat is None:
                raise Drop("route table '%s'" % sub["route_table"],
                           "route points at %s, which does not exist" % target)
            nat_sub = self.d["subnets"][nat["subnet"]]
            if not nat_sub.get("maps_public_ip"):
                raise Drop("nat gateway %s" % target,
                           "the NAT gateway is in a private subnet; it must sit in "
                           "a public subnet with a route to the internet gateway")
        return target

    def route_in(self, subnet_name):
        """Can an unsolicited packet from the internet reach this subnet?"""
        sub = self.d["subnets"][subnet_name]
        table = self.d["route_tables"].get(sub["route_table"], [])
        has_igw = any(r["target"].startswith("igw-") and
                      ipaddress.ip_network(r["dest"]).prefixlen == 0
                      for r in table)
        if not (has_igw and sub.get("maps_public_ip")):
            raise Drop("routing",
                       "subnet '%s' is private -- no internet gateway route and no "
                       "public IP, so it is not reachable from outside" % subnet_name)

    def nacl(self, subnet_name, direction, peer_ip, port, label):
        name = self.d["subnets"][subnet_name]["nacl"]
        rules = sorted(self.d["nacls"][name][direction], key=lambda r: r["rule"])
        for rule in rules:
            if not proto_ok(rule):
                continue
            if peer_ip not in ipaddress.ip_network(rule["cidr"]):
                continue
            if not port_in(rule["ports"], port):
                continue
            if rule["action"] == "allow":
                return
            raise Drop("nacl '%s' %s" % (name, direction),
                       "rule %d denies %s port %d (%s)"
                       % (rule["rule"], peer_ip, port, label))
        raise Drop("nacl '%s' %s" % (name, direction),
                   "no rule allows %s port %d (%s); a network ACL ends in an "
                   "implicit deny" % (peer_ip, port, label))

    def sg(self, sg_name, direction, peer_ip, peer_sg, port, label):
        rules = self.d["security_groups"][sg_name][direction]
        for rule in rules:
            if not proto_ok(rule):
                continue
            if not port_in(rule["ports"], port):
                continue
            src_sg = rule.get("source_sg")
            if src_sg is not None:
                if src_sg == peer_sg:
                    return
                continue
            if peer_ip in ipaddress.ip_network(rule["source"]):
                return
        raise Drop("security group '%s' %s" % (sg_name, direction),
                   "no rule allows %s (sg=%s) port %d (%s)"
                   % (peer_ip, peer_sg, port, label))

    # -- the walk ----------------------------------------------------------
    def check(self, src, dst, port):
        src_ip, dst_ip = self.ip_of(src), self.ip_of(dst)
        src_sub, dst_sub = self.subnet_of(src), self.subnet_of(dst)
        src_sg, dst_sg = self.sg_of(src), self.sg_of(dst)

        if src == INTERNET:
            self.route_in(dst_sub)
            self.nacl(dst_sub, "ingress", src_ip, port, "inbound request")
            self.sg(dst_sg, "ingress", src_ip, src_sg, port, "inbound request")
            # Stateless: the reply needs its own egress rule, to the caller's
            # ephemeral port.
            self.nacl(dst_sub, "egress", src_ip, EPHEMERAL_SRC, "the reply")
            return

        self.route_out(src_sub, dst_ip)
        self.sg(src_sg, "egress", dst_ip, dst_sg, port, "outbound request")
        self.nacl(src_sub, "egress", dst_ip, port, "outbound request")

        if dst != INTERNET:
            self.nacl(dst_sub, "ingress", src_ip, port, "inbound request")
            self.sg(dst_sg, "ingress", src_ip, src_sg, port, "inbound request")
            self.nacl(dst_sub, "egress", src_ip, EPHEMERAL_SRC, "the reply")

        # The reply arriving back at the caller's subnet. Its destination port
        # is ephemeral -- this is the rule people forget.
        self.nacl(src_sub, "ingress", dst_ip, EPHEMERAL_SRC, "the reply")


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    try:
        net = Net(json.load(open("network.json")))
    except json.JSONDecodeError as exc:
        print("FAIL - network.json is not valid JSON: %s" % exc)
        return 1
    flows = json.load(open("flows.json"))

    wrong = 0
    for flow in flows:
        try:
            net.check(flow["from"], flow["to"], flow["port"])
            got, why = "ALLOW", ""
        except Drop as drop:
            got, why = "DENY", str(drop)
        except KeyError as exc:
            print("FAIL - network.json is missing %s" % exc)
            return 1
        ok = got == flow["expect"]
        if not ok:
            wrong += 1
        print("%-5s want %-5s got %-5s  %s -> %s:%d"
              % ("ok" if ok else "WRONG", flow["expect"], got,
                 flow["from"], flow["to"], flow["port"]))
        if why and (not ok or flow["expect"] == "DENY"):
            print("        dropped by %s" % why)
        if not ok:
            print("        requirement: %s" % flow["why"])

    print()
    if wrong:
        print("FAIL - %d of %d flows behave incorrectly" % (wrong, len(flows)))
        return 1
    print("PASS - all %d flows behave as required" % len(flows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
