"""A deliberately boring DNS server that writes down every question it is asked.

It is an instrument, not part of the puzzle: two names exist, everything else
is NXDOMAIN, and every query is appended to /var/log/dns/queries.log as
"<name> <qtype>". Counting those lines is how the drill is graded.
"""
import os
import socket
import struct

# Both address families are answered on purpose. With no AAAA to return, a
# NOERROR-with-no-answer makes glibc carry on down the search list looking for
# one -- which adds queries that have nothing to do with ndots and muddies
# what the drill is measuring.
QTYPE_A = 1
QTYPE_AAAA = 28

ZONE = {
    "api.vendor.test.": {QTYPE_A: "10.9.9.9", QTYPE_AAAA: "2001:db8::9"},
    "payments.svc.drill.local.": {QTYPE_A: "10.9.77.20", QTYPE_AAAA: "2001:db8::77:20"},
}
LOG = "/var/log/dns/queries.log"

FLAGS_NOERROR = 0x8180
FLAGS_NXDOMAIN = 0x8183


def parse_name(data, off):
    labels = []
    while True:
        length = data[off]
        if length == 0:
            off += 1
            break
        if length & 0xC0:  # a compression pointer in a question; not expected
            off += 2
            break
        labels.append(data[off + 1:off + 1 + length].decode("ascii", "replace"))
        off += 1 + length
    return ".".join(labels) + ".", off


def main():
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", 53))
    print("dnsd listening on 53", flush=True)

    while True:
        try:
            data, addr = sock.recvfrom(1024)
            if len(data) < 13:
                continue
            tid = data[:2]
            qname, off = parse_name(data, 12)
            qtype, _qclass = struct.unpack("!HH", data[off:off + 4])
            off += 4
            question = data[12:off]

            with open(LOG, "a") as fh:
                fh.write("%s %d\n" % (qname, qtype))

            records = ZONE.get(qname)
            if records is not None and qtype in records:
                if qtype == QTYPE_A:
                    rdata = socket.inet_aton(records[qtype])
                else:
                    rdata = socket.inet_pton(socket.AF_INET6, records[qtype])
                answer = b"\xc0\x0c" \
                    + struct.pack("!HHIH", qtype, 1, 30, len(rdata)) + rdata
                flags, ancount = FLAGS_NOERROR, 1
            elif records is not None:
                # The name exists but has no record of this type: NOERROR with
                # no answers, which is not the same as NXDOMAIN.
                answer, flags, ancount = b"", FLAGS_NOERROR, 0
            else:
                answer, flags, ancount = b"", FLAGS_NXDOMAIN, 0

            header = tid + struct.pack("!HHHHH", flags, 1, ancount, 0, 0)
            sock.sendto(header + question + answer, addr)
        except Exception as exc:  # an instrument that dies is worse than useless
            print("dnsd error: %r" % (exc,), flush=True)


if __name__ == "__main__":
    main()
