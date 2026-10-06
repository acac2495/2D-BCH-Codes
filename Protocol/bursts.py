#!/usr/bin/env python3
"""
Generate every distinct 2-D quasi-cyclic burst pattern of area <= t x t (default 15x15, t=2).

A pattern is "quasi-cyclic t x t" if all its 1s lie inside the intersection of at most t rows and
at most t columns. The rows/columns do NOT have to be adjacent (paper, Sec. II-B).

Because the zero array is a codeword and the code is linear, feeding the pattern itself as the
received word is the same as feeding (codeword ^ pattern): the decoder should output the all-zero
word (corrected) and the pattern itself (error array).

Output files (one 225-bit word per line, 57 hex digits, ready for $readmemh into reg [224:0]):
    codes.hex      received words  (= the error patterns)
    expected.hex   expected corrected words (all zeros here)
    index.txt      line number -> list of (row, col) positions, for debugging a failing line

Bit order matches ccp_top's r_in: bit (N*row + col) is array[row][col].
"""
import argparse
import itertools
import random

N, T = 15, 2

# --- GF(16), same tables as your scripts: a^0..a^14, MSB-first encoding -----------------------
ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]


def alpha_pow(e):
    return ALPHA_POWERS[e % N]


def pack(positions, n=N):
    v = 0
    for r, c in positions:
        v |= 1 << (n * r + c)
    return v


def to_hex(v, n=N):
    return format(v, "0%dX" % ((n * n + 3) // 4))      # 57 hex digits for 225 bits


def all_patterns(n=N, t=T):
    """Every distinct non-empty pattern whose 1s fit in <= t rows x <= t columns (cyclic, any spacing)."""
    seen = set()
    for rows in itertools.combinations(range(n), t):
        for cols in itertools.combinations(range(n), t):
            cells = [(r, c) for r in rows for c in cols]
            for mask in range(1, 1 << len(cells)):
                pos = tuple(cells[k] for k in range(len(cells)) if mask >> k & 1)
                seen.add(pack(pos, n))
    return sorted(seen, key=lambda v: (bin(v).count("1"), v))     # fewest errors first, deterministic


def unpack(v, n=N):
    return [(i, j) for i in range(n) for j in range(n) if v >> (n * i + j) & 1]


def syndrome(v, t=T, n=N):
    """DFFFT at the 2t x 2t null positions (j, j' = 1..2t)."""
    s = []
    for j in range(1, 2 * t + 1):
        for jp in range(1, 2 * t + 1):
            acc = 0
            for i, ip in unpack(v, n):
                acc ^= alpha_pow(i * j + ip * jp)
            s.append(acc)
    return tuple(s)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode", choices=["all", "random"], default="all")
    ap.add_argument("--count", type=int, default=1000, help="random mode: number of patterns")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--pad", type=int, default=0,
                    help="append this many dummy (error-free) words at the end, e.g. to flush the pipeline")
    ap.add_argument("--check-unique", action="store_true",
                    help="verify every pattern has a distinct syndrome (slow-ish, ~10-30 s for 'all')")
    ap.add_argument("--out", default=".")
    a = ap.parse_args()

    pats = all_patterns()
    print("distinct non-empty %dx%d quasi-cyclic patterns: %d" % (T, T, len(pats)))
    if a.mode == "random":
        random.Random(a.seed).shuffle(pats)
        pats = pats[: a.count]

    if a.check_unique:
        seen = {}
        for v in pats:
            s = syndrome(v)
            if s in seen:
                print("SYNDROME COLLISION:", unpack(seen[s]), "vs", unpack(v))
                break
            seen[s] = v
        else:
            print("all %d patterns have distinct syndromes" % len(pats))

    words = pats + [0] * a.pad
    with open(f"{a.out}/codes.hex", "w") as f, open(f"{a.out}/expected.hex", "w") as g, \
         open(f"{a.out}/index.txt", "w") as h:
        for k, v in enumerate(words):
            f.write(to_hex(v) + "\n")
            g.write(to_hex(0) + "\n")
            h.write("%d %s\n" % (k, unpack(v)))
    print("wrote %d words to %s/{codes,expected}.hex  (depth needed in Verilog: %d)" % (len(words), a.out, len(words)))


if __name__ == "__main__":
    main()