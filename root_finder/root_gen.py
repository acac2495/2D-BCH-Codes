ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]  # a^0 .. a^14, MSB-first (a0=bit3)

EXP_STR = {0: "0"}
for idx, val in enumerate(ALPHA_POWERS):
    EXP_STR[val] = f"a^{idx}"

def gf_pow(a, p):
    if a == 0:
        return 8  # 0^0 convention unused here since a is always nonzero (alpha^i)
    idx_a = ALPHA_POWERS.index(a)
    return ALPHA_POWERS[(idx_a * p) % 15]

def to_hex(val):
    return format(val, 'X')

def gen_root_factors(T, n=15, prefix="poly"):
    """
    T : degree bound (poly_i expects T+1 coefficients, indices 0..T)
    n : number of field elements to test (15 for GF(2^4)*)
    """
    for file_idx in range(1, n + 1):
        exponent = file_idx - 1          # poly_1 -> alpha^0, poly_2 -> alpha^1, ...
        e = ALPHA_POWERS[exponent]

        coeffs = [gf_pow(e, j) for j in range(0, T + 1)]  # e^0 .. e^T

        fname = f"{prefix}_{file_idx}.hex"
        with open(fname, "w") as f:
            for c in coeffs:
                f.write(to_hex(c) + "\n")

        print(f"{fname}: testing alpha^{exponent} = {EXP_STR[e]}  "
              f"-> coeffs (e^0..e^{T}) = {[EXP_STR[c] for c in coeffs]}")

if __name__ == "__main__":
    T = 2  # match poly_i's T parameter as instantiated in root_top
    gen_root_factors(T)