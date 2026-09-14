ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]
m = 4  

EXP_STR = {0 : "0"}
for (idx, val) in enumerate(ALPHA_POWERS):
    EXP_STR[val] = f"a^{idx}"

EXPONENT = {}
for idx in range(0, 15):
    EXPONENT[f"a^{idx}"] = idx

def to_hex(val):
    return format(val, 'X')

def gf_mul(a, b):
    if(a == 0 or b == 0):
        return 0
    idx_a = ALPHA_POWERS.index(a)
    idx_b = ALPHA_POWERS.index(b)
    return ALPHA_POWERS[(idx_a + idx_b) % 15]

def gf_pow(a, pow):
    if(a == 0):
        return 8
    idx_a = ALPHA_POWERS.index(a)
    return ALPHA_POWERS[(idx_a * pow) % 15]

def gf_inv(a):
    if(a == 0):
        return 0
    idx_a = ALPHA_POWERS.index(a)
    return ALPHA_POWERS[(15 - idx_a) % 15]

def orbit(j, jp, n):
    seen = []
    cur = (j, jp)
    while cur not in seen:
        seen.append(cur)
        cur = ((2 * cur[0]) % n, (2 * cur[1]) % n)
    return seen

def conjugacy_classes(n):
    visited = set()
    classes = []
    for j in range(n):
        for jp in range(n):
            if((j, jp) in visited):
                continue 
            cls = orbit(j, jp, n)
            classes.append(cls)
            visited.update(cls)
    return classes

def zero_positions(t):
    return [(j, jp) for j in range (1, 2*t + 1) for jp in range (1, 2*t + 1)]

def classify(n, t):
    classes = conjugacy_classes(n)

    message_IPs = {}

    for cls in classes:
        message_IPs[cls[0]] = len(cls)

    return message_IPs

def class_sizes(message_IPs):
    count_1 = 0
    count_2 = 0
    count_4 = 0
    for IP, size in message_IPs:
        if(size == 4):
            count_4 += 1
        elif(size == 2):
            count_2 += 1
        elif(size == 1):
            count_1 += 1
    return count_4, count_2, count_1

n = 15
t = 2

message_IPs = classify(n, t)
message_IPs = sorted(message_IPs.items(), key = lambda item : item[1])
count_4, count_2, count_1 = class_sizes(message_IPs)
print(count_4, " ", count_2, " ", count_1)

def get_LUTs(n, message_IPs):
    for i in range(n):
        for ip in range(n):
            if(i < 10 and ip < 10):
                fname = f"alpha_0{i}_0{ip}.hex"
            elif(i < 10 and ip >= 10):
                fname = f"alpha_0{i}_{ip}.hex"
            elif(i >= 10 and ip < 10):
                fname = f"alpha_{i}_0{ip}.hex"
            else:
                fname = f"alpha_{i}_{ip}.hex"
            with open(fname, "w") as f:
                for((j, jp), size) in message_IPs:
                    poly_b = gf_inv(gf_pow(4, i*j + ip*jp))
                    f.write(to_hex(poly_b) + "\n")

get_LUTs(n, message_IPs)
                            

"""
def dffft(c, n):
    C = []
    for j in range(n):
        C_r = []
        for jp in range(n):
            C_j_jp = 0
            for i in range(n):
                for ip in range(n):
                    c_i_ip = c[i][ip]
                    if(c_i_ip == 1):
                        C_j_jp ^= gf_pow(4, i*j + ip * jp)
            C_r.append(EXP_STR[C_j_jp])
        C.append(C_r)
    return C

def flatten_code(c, n):
    c_flat = []
    for i in range(n):
        for ip in range(n):
            c_flat.append(c[i][ip])
    return c_flat
"""
"""
c = get_codeword(n, poly_a)
code = flatten_code(c, n)

get_LUTs(n, poly_a)
"""

#for((j, jp), label), value in poly_a.items():
#    print((j, jp), " ", label, " ", EXP_STR[value])

#print(message_IPs)
"""
def gen_msg_hex(msg, fname="msg.hex"):

    width = len(msg)
    val = 0
    for bit in reversed(msg):
        val = (val << 1) | bit
    hex_digits = (width + 3) // 4
    with open(fname, "w") as f:
        f.write(format(val, f'0{hex_digits}X') + "\n")

gen_msg_hex(msg, "msg.hex")
gen_msg_hex(code, "code.hex")

print("codeword : ")
for row in c:
    print(row)

C = dffft(c, n)

print("spectrum : ")
for row in C:
    print(row)
"""