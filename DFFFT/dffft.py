ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]  

EXP_STR = {0: "0"}
for idx, val in enumerate(ALPHA_POWERS):
    EXP_STR[val] = f"a^{idx}"

def alpha_pow(exp, n=15):
    return ALPHA_POWERS[exp % n]

def to_hex(val):
    return format(val, 'X')

def gen_dfft_factors(J, Jp, N=15, prefix="dfft"):
    fname = f"{prefix}_{J}_{Jp}.hex"
    with open(fname, "w") as f:
        for i in range(N):
            for j in range(N):
                exponent = i*J + j*Jp
                val = alpha_pow(exponent, N)
                f.write(to_hex(val) + "\n")
    return fname

def gen_all(points, N=15, prefix="dfft"):
    for (J, Jp) in points:
        fname = gen_dfft_factors(J, Jp, N, prefix)
        print(f"{fname}: (J,J')=({J},{Jp})  -> {N*N} entries written")

N = 15
t = 3

points = [(J, Jp) for J in range(1, 2*t+1) for Jp in range(1, 2*t+1)]
gen_all(points, N=N)




