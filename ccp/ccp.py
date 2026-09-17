ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]  # a^0..a^14, MSB-first

EXP_STR = {0: "0"}
for idx, val in enumerate(ALPHA_POWERS):
    EXP_STR[val] = f"a^{idx}"

def alpha_pow(exp, n=15):
    return ALPHA_POWERS[exp % n]

def to_hex(val):
    return format(val, 'X')

def dfft_pt(c, j, jp, n = 15):
    acc = 0
    for i in range(n):
        for ip in range(n):
            if(c[i][ip]):
                acc ^= alpha_pow(i*j + ip * jp)
    return acc

def dfft(c, t, n = 15):
    grid = {}
    for j in range(1, 2*t + 1):
        for jp in range(1, 2*t + 1):
            grid[(j, jp)] = dfft_pt(c, j, jp, n)
    return grid

def print_grid(grid, t):
    for j in range(1, 2*t+1):
        for jp in range(1, 2*t+1):
            val = grid[(j, jp)]
            print(EXP_STR[val], end = " ")
        print("")

def gen_codeword_hex(c, N, fname="codeword.hex"):
    with open(fname, "w") as f:
        for i in range(N):
            row_val = 0
            for j in range(N):
                if c[i][j]:
                    row_val |= (1 << j)
            f.write(format(row_val, 'X') + "\n")


n = 15
c = [[0] * n for i in range(n)]
t = 2

c[7][5] = 1
c[7][6] = 1
c[8][5] = 1
c[8][6] = 1


for row in c:
    print(row)

grid = dfft(c, t, n)
print_grid(grid, t)
gen_codeword_hex(c, n)

