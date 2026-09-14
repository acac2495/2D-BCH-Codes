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

def print_classes(classes):
    points = 0
    num = 0
    size_4 = 0
    size_2 = 0
    size_1 = 0
    for cls in classes:
        if(len(cls) == 4):
            size_4 += 1
        elif(len(cls) == 2):
            size_2 += 1
        elif(len(cls) == 1):
            size_1 += 1
        points += len(cls)
        num += 1
        print(cls)

    print("point count : ", points)
    print("class count : ", num)
    print("size 4 classes : ", size_4)
    print("size 2 classes : ", size_2)
    print("size 1 classes : ", size_1)

def classify(n, t):
    classes = conjugacy_classes(n)
    seeds = set(zero_positions(t))

    print("all classes : ")
    print_classes(classes)

    zero_classes = []
    message_classes = []
    message_IPs = []

    for cls in classes:
        if any(pt in seeds for pt in cls):
            zero_classes.append(cls)
        else:
            message_classes.append(cls)
            message_IPs.append(cls[0])

    return zero_classes, message_classes, message_IPs


n = 15
t = 2
zero_classes, message_classes, message_IPs = classify(n, t)
#print_classes(zero_classes)
#print_classes(message_classes)
print(message_IPs)