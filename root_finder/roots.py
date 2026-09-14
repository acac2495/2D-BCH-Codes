from itertools import combinations

#a^0 to a^14 in GF(2^4)
ALPHA_POWERS = [8, 4, 2, 1, 12, 6, 3, 13, 10, 5, 14, 7, 15, 11, 9]
m = 4  

EXP_STR = {0 : "0"}
for (idx, val) in enumerate(ALPHA_POWERS):
    EXP_STR[val] = f"a^{idx}"

EXPONENT = {}
for idx in range(0, 15):
    EXPONENT[f"a^{idx}"] = idx

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

def get_syndromes(err_locs, t = 2):
    synds = []
    for i in range(1, 2 * t + 1):
        s_i = 0
        for loc in err_locs:
            val = ALPHA_POWERS[(loc * i) % 15]
            s_i ^= val
        synds.append(s_i)
    return synds

def BM(synds, t = 2):
    sigma = [0] * (t + 1)
    sigma_p = [0] * (t + 1)
    d_p = 8
    for i in range (0, t + 1):
        if(i == 0):
            sigma[i] = 8
        if(i == 1):
            sigma_p[i] = 8

    temp_reg = [0] * (t + 1)
    for i in range(2 * t):
        s_in = synds[i]
        temp_reg = [s_in] + temp_reg[0:t]

        d_mu = temp_reg[0]
        for j in range(1, t+1):
            d_mu ^= gf_mul(temp_reg[j], sigma[j])
        
        dmu_dpinv = gf_mul(d_mu, gf_inv(d_p))
        corr = [gf_mul(sigma_p[i], dmu_dpinv) for i in range(t+1)]

        sigma_next = [sigma[j] ^ corr[j] for j in range(t+1)]
        load_sigma = 1 if d_mu != 0 else 0
        sigma_store = sigma[:] if load_sigma else sigma_p[:]

        sigma_p = [0] + sigma_store[0:t]
        sigma = sigma_next

        if(load_sigma):
            d_p = d_mu

    return sigma

def print_poly(sigma):
    powers = []
    for coeff in sigma:
        powers.append(EXP_STR[coeff])
    print(powers)

def extract_errors(sigma):
    powers = []
    for coeff in sigma:
        powers.append(EXP_STR[coeff])
    errors = []
    for power in powers:
        errors.append(EXPONENT[power])
    return errors

def chien_search(sigma, t = 2):
    roots = []
    for i in ALPHA_POWERS:
        res = 8
        for j in range(1, t+1):
            pow = gf_pow(i, j)
            res ^= gf_mul(pow, sigma[j])
        if(res == 0):
            roots.append(gf_inv(i))
    return roots

def get_rpos(sigma, t = 2):
    rpos = []
    for i in ALPHA_POWERS:
        res = 8
        for j in range(1, t+1):
            pow = gf_pow(i, j)
            res ^= gf_mul(pow, sigma[j])
        if(res == 0):
            rpos.append(1)
        else:
            rpos.append(0)
    return rpos

def print_roots(sigma, t = 2):
    for i in ALPHA_POWERS:
        res = 8
        for j in range(1, t+1):
            pow = gf_pow(i, j)
            res ^= gf_mul(pow, sigma[j])
        if(res == 0):
            print(EXP_STR[i], end=" ")

def to_hex(val):
    return format(val, 'X')

def gen_vectors():
    t = 2
    error_locs = [1, 2]
    synds = get_syndromes(error_locs, t)
    sigma = BM(synds, t)
    roots = chien_search(sigma, t)
    for root in roots:
        print(EXP_STR[root])
    rpos = get_rpos(sigma, t)
    print(rpos)
    print_poly(sigma)
    print_roots(sigma, t)

t = 2
synds = [8,4,2,1]
sigma = [8, 2, 15]
print_poly(sigma)
print_roots(sigma, t)