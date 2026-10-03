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
    seeds = set(zero_positions(t))

    zero_classes = []
    message_classes = []
    message_IPs = {}

    for cls in classes:
        if any(pt in seeds for pt in cls):
            zero_classes.append(cls)
        else:
            message_classes.append(cls)
            message_IPs[cls[0]] = len(cls)

    return zero_classes, message_classes, message_IPs

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

zero_classes, message_classes, message_IPs = classify(n, t)
message_IPs = sorted(message_IPs.items(), key = lambda item : item[1])
count_4, count_2, count_1 = class_sizes(message_IPs)

def msg_encode(msg, count_1, count_2, count_4, message_IPs):
    i = 0
    j = 0
    poly = {}
    stage1_end = count_1
    stage2_end = stage1_end + 2*count_2
    stage3_end = stage2_end + 4*count_4

    while i < stage1_end:
        poly[message_IPs[j]] = msg[i]
        i += 1; j += 1
    while i < stage2_end:
        poly[message_IPs[j]] = msg[i:i+2]
        i += 2; j += 1
    while i < stage3_end:
        poly[message_IPs[j]] = msg[i:i+4]
        i += 4; j += 1
    return poly

def map2_4(in_list):
    if(in_list == [0,0]):return 0
    elif(in_list == [0,1]):return 6
    elif(in_list == [1,0]):return 8
    elif(in_list == [1,1]):return 14

msg = [
    # bits 1-65 (65 bits)
    1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0,
    # bits 66-129 (64 bits)
    0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0,
    # bits 130-181 (52 bits)
    0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1
]

poly_a = msg_encode(msg, count_1, count_2, count_4, message_IPs)

for key, value in list(poly_a.items()):
    (x, y), label = key
    if label == 1:
        pass
    elif label == 2:
        poly_a[key] = map2_4(list(reversed(value)))
    elif label == 4:
        binary_str = "".join(map(str, reversed(value)))
        poly_a[key] = int(binary_str, 2)

#for ((x, y), label), value in poly_a.items():
#    print(f"Coordinates: ({x}, {y}), Label: {label} -> Value: {value}")

#for((j, jp), label) in message_IPs:
#    print((j, jp), ":", label)

def get_codeword(n, poly_a):
    c = []
    for i in range(n):
        c_r = []
        for ip in range(n):
            poly = {}
            c_i_ip = 0
            for ((j, jp), label), value in poly_a.items():
                poly_b = gf_inv(gf_pow(4, i*j + ip*jp))
                prod = gf_mul(poly_b, value)
                poly[(j, jp), label] = prod
                if(label == 1):
                    c_i_ip ^= (prod & 8) >> 3
                elif(label == 2):
                    c_i_ip ^= (prod & 2) >> 1
                elif(label == 4):
                    c_i_ip ^= (prod & 1)
                #if((i, ip) == (1,0)):
                    #print((j, jp), " ", EXP_STR[value], " ", EXP_STR[poly_b], " ", EXP_STR[prod], " ", bin(prod), "label : ", label, "  ", prod&2)
                    #print(c_i_ip)
            c_r.append(c_i_ip)
        c.append(c_r)
    return c

def get_LUTs(n, poly_a):
    for i in range(n):
        for ip in range(n):
            fname = f"alpha_{i}_{ip}.hex"
            with open(fname, "w") as f:
                for((j, jp), label), value in poly_a.items():
                    poly_b = gf_inv(gf_pow(4, i*j + ip*jp))
                    f.write(to_hex(poly_b) + "\n")
                            

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

c = get_codeword(n, poly_a)
code = flatten_code(c, n)

get_LUTs(n, poly_a)

#for((j, jp), label), value in poly_a.items():
#    print((j, jp), " ", label, " ", EXP_STR[value])

#print(message_IPs)

def gen_msg_hex(msg, fname="msg.hex"):
    """
    Packs msg (list of bits) into a single hex value such that
    msg[0] -> bit 0 (LSB) of the packed register, msg[-1] -> top bit (MSB).
    This matches Verilog's own reg[N-1:0] convention (bit 0 = rightmost = LSB)
    directly against msg's own index order, so msg[i] == reg[i] with no
    extra reversal needed downstream, consistent with how msg_encode
    slices msg[i:i+d] sequentially by increasing index.
    """
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

#C = dffft(c, n)

#print("spectrum : ")
#for row in C:
#    print(row)