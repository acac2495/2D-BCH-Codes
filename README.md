# 2-D BCH Codec in the Frequency Domain

A Verilog implementation of a hardware encoder and decoder for two-dimensional
Bose–Chaudhuri–Hocquenghem (BCH) codes, following the frequency-domain
architecture described in:

> A. Mondal and S. S. Garani, "Efficient Hardware Architectures for 2-D BCH
> Codes in the Frequency Domain for Two-Dimensional Data Storage
> Applications," *IEEE Transactions on Magnetics*, vol. 57, no. 5, May 2021.

The design targets a 15×15, *t*=2 quasi-cyclic-burst-correcting 2-D BCH code
over GF(2⁴), matching the paper's own worked example, and is built to
generalize to other (*n*, *t*) parameters where noted.

## What this code does

Given an *n*×*n* binary array containing a quasi-cyclic burst error of size
up to *t*×*t* — meaning **at most *t* distinct rows and *t* distinct columns**
are affected, not necessarily physically adjacent — the decoder recovers the
original error-free codeword. The encoder maps a message bit vector into a
valid 2-D BCH codeword satisfying the code's spectral null constraints.

Both directions operate entirely in the frequency domain, using the 2-D
discrete finite-field Fourier transform (DFFFT) and its inverse (IDFFFT), per
Blahut's transform-domain approach as extended to two dimensions by the
reference paper.

## Pipeline overview

**Encoder**
```
message bits → sub-message splitting (per conjugate class)
             → spectrum assembly (conjugacy-constrained)
             → 2-D IDFFFT
             → codeword
```

**Decoder**
```
received codeword → 2-D DFFFT (syndromes, 2t×2t window)
                   → Berlekamp–Massey (row + column connection polynomials)
                   → root finding (Chien-search-style)
                   → root-to-coefficient reconstruction (common connection polynomial)
                   → recursive extension (columns, then rows → full n×n spectrum)
                   → 2-D IDFFFT (error array)
                   → codeword XOR error array → corrected result
```

## Repository structure

```
common/             GF(2^4) arithmetic primitives, generic reduction trees
  GF_2_4_mult.v        GF(2^4) multiplier
  GF_2_4_inv.v         GF(2^4) inverse (LUT-based)
  gf16_square.v        GF(2^4) squaring (Frobenius)
  xor_tree.v           Parameterized balanced XOR reduction tree
  or_tree.v            Parameterized balanced OR reduction tree
  roots_to_coeffs.v    Sequential, general-T root -> polynomial reconstruction
  root_to_coeff_comb.v Combinational, num_found-aware reconstruction (T=2)

BM_engine/          Berlekamp-Massey decoder
  BM_top.v             Core BM iteration (2t cycles, pipelined FSM)
  BM_interface.v        Streams a 2t-wide syndrome bus into BM_top one symbol/cycle

DFFFT/               Forward transform (decoder syndrome computation)
  dffft_unit.v         Single spectral-point DFFFT unit (mux + XOR tree)
  dffft_top.v          Reduced-complexity 2t x 2t syndrome array,
                        using conjugacy-class squaring to cut redundant computation

root_finder/         Error-locator root finding
  poly_i.v             Tests one field element as a root of sigma(X)
  root_top.v           n parallel poly_i instances -> root-position bitmap
  root_lookup.v        Extracts up to T actual root values from a position bitmap

recursive_extension/
  RE_chain.v           Cascaded RE_base stages; extends a known syndrome
                        window to the full n-length sequence

IDFFFT/               Inverse transform (both encoder and decoder use this style)
  class_1.v, class_2.v, class_4.v
                       Per-conjugate-class reduced multiply/XOR units
                       (derived from the paper's eq. 9-11 algebraic reduction)
  idffft_top.v          Single output-point IDFFFT unit
  idffft_synd.v         Full n x n error-array reconstruction

encoder/              Message encoding
  sub_msg.v             Splits the message bit vector across conjugate classes
  (uses IDFFFT/ modules for spectrum -> codeword)

ccp_top.v            Top-level decoder: wires DFFFT -> BM -> root finding ->
                      RE -> IDFFFT into a full pipelined decode path
```

## Design notes

- **GF(2⁴) convention**: field elements are represented MSB-first as 4-bit
  vectors (`a0 a1 a2 a3`, with `a0` the most significant bit), using the
  primitive polynomial `x⁴ + x + 1`.
- **Conjugacy-based reduction**: per the paper's Theorem 1 and Remark 6, both
  the DFFFT/IDFFFT units and the BM engine exploit the fact that conjugate
  spectral positions (related by repeated squaring, `C_{2j,2j'} = C_{j,j'}²`)
  share structure — only one representative per conjugate class needs full
  computation, with the rest derived via GF(2⁴) squaring. This is proved
  directly in the decoder context (conjugate rows/columns share the same
  connection polynomial) rather than just assumed from the paper.
- **Recursive extension applies to *all* known rows/columns**, not just the
  BM-optimized non-conjugate representatives — conjugacy only reduces the
  *Berlekamp-Massey* work, not the recursive-extension work, since RE needs
  the actual syndrome values for every known row/column, not just one
  representative per class.
- **Root-to-coefficient reconstruction** is provided in two forms: a general
  sequential version (`roots_to_coeffs.v`, any *T*, multi-cycle) and a
  combinational, `num_found`-aware version for *T*=2
  (`root_to_coeff_comb.v`), which avoids the sequential version's latency at
  the cost of hand-derived per-case formulas that would need re-deriving for
  larger *T*.

## Simulation

All modules have been developed and cross-checked with
[Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` / `vvp`).

Most modules that depend on precomputed GF(2⁴) power-table constants
(`dffft_unit`, `poly_i`, `idffft_top`, etc.) load their lookup tables at
runtime via `$readmemh`/`$sformat`, from `.hex` files generated by
accompanying Python scripts (not yet included in this structure listing —
see individual module comments for the expected filename convention, e.g.
`dfft_<J>_<JP>.hex`, `poly_<i>.hex`).

Each core module (`GF_2_4_mult`, `GF_2_4_inv`, `BM_top`, `dffft_top`,
`poly_i`/`root_top`, `RE_chain`, `roots_to_coeffs`) has been validated against
an independent Python reference implementation and/or the paper's own worked
examples (Section III-B's 15×15 message-encoding example, Table 3.4 in Lin &
Costello's BM worked example) before being wired into the full pipeline.

## Status / known limitations

- The combinational root-to-coefficient module (`root_to_coeff_comb.v`) is
  specific to *T*=2; larger *T* would need its case-split formulas
  regenerated.
- Post-synthesis resource usage (Vivado) is dominated by `idffft_synd`, whose
  instance count scales as `N × N × TOTAL_CLASSES` — this matches the
  paper's own characterization of the decoder's IDFFFT unit as one of its
  largest blocks (Section V, Table IV), not an implementation regression.
- Full end-to-end pipelined throughput (back-to-back decodes with no idle
  gap between them) has surfaced real pipeline-depth mismatches during
  development; timing/latency across all stages should be re-verified after
  any change to a module's cycle count.

## Acknowledgments

Architecture and algorithms follow Mondal & Garani (2021); any
implementation errors, simplifications, or deviations from the paper are
the author's own and are noted inline in module comments where significant.
