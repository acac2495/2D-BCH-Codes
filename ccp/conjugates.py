def find_conjugate_classes(n, t):
    """
    For indices 1..2t (mod n), find the conjugate classes under the
    doubling map k -> 2k mod n, restricted to reporting membership
    within the 1..2t window (the range relevant to BM/syndrome null block).

    Returns:
        classes: list of lists, each the full set of indices (within 1..2t)
                 belonging to one conjugate class
        reps:    one representative (IP) index per class -- these are the
                 indices you actually run BM on
    """
    def full_orbit(start):
        o = [start]
        x = (2 * start) % n
        while x != start:
            o.append(x)
            x = (2 * x) % n
        return o

    visited = set()
    classes = []
    for k in range(1, 2 * t + 1):
        if k in visited:
            continue
        orbit = full_orbit(k)
        in_range = sorted(x for x in orbit if 1 <= x <= 2 * t)
        classes.append(in_range)
        visited.update(in_range)

    reps = [cls[0] for cls in classes]
    return classes, reps


if __name__ == "__main__":
    n, t = 15, 3

    col_classes, col_reps = find_conjugate_classes(n, t)
    row_classes, row_reps = find_conjugate_classes(n, t)  # identical relation for rows

    print(f"n={n}, t={t}\n")
    print("Column conjugate classes (within 1..2t):", col_classes)
    print("Column IPs (BM runs needed):", col_reps, f"(c_p = {len(col_reps)})\n")

    print("Row conjugate classes (within 1..2t):", row_classes)
    print("Row IPs (BM runs needed):", row_reps, f"(c_p = {len(row_reps)})")