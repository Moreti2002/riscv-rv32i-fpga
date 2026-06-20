#!/usr/bin/env python3
"""asm.py — Montador RISC-V RV32I (subconjunto intermediário) -> .hex/.mif.

Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite. Autor: João Moreti.

Gera o arquivo de inicialização da ROM (imem.vhd lê .hex: uma palavra de 8
dígitos hex por linha, palavra 0 = endereço 0). Suporta:

  R    : add sub and or xor sll srl sra slt sltu
  I    : addi andi ori xori slti sltiu slli srli srai
  load : lw lh lb lhu lbu
  store: sw sh sb
  branch: beq bne blt bge bltu bgeu
  jump : jal jalr
  U    : lui auipc
  pseudo: nop, mv, li, j, jr, ret, beqz, bnez, not, neg, seqz, snez

Uso:
  python scripts/asm.py asm/prog.s -o mem/prog.hex [--mif mem/prog.mif] [--words 256]
"""
import argparse
import re
import sys

# --- Nomes de registradores (x0..x31 + ABI) ---
ABI = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9, "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14,
    "a5": 15, "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27, "t3": 28,
    "t4": 29, "t5": 30, "t6": 31,
}

R_OPS = {  # mnemônico -> (funct3, funct7)
    "add": (0x0, 0x00), "sub": (0x0, 0x20), "sll": (0x1, 0x00),
    "slt": (0x2, 0x00), "sltu": (0x3, 0x00), "xor": (0x4, 0x00),
    "srl": (0x5, 0x00), "sra": (0x5, 0x20), "or": (0x6, 0x00), "and": (0x7, 0x00),
}
I_OPS = {"addi": 0x0, "slti": 0x2, "sltiu": 0x3, "xori": 0x4, "ori": 0x6, "andi": 0x7}
SH_OPS = {"slli": (0x1, 0x00), "srli": (0x5, 0x00), "srai": (0x5, 0x20)}
LOAD_OPS = {"lb": 0x0, "lh": 0x1, "lw": 0x2, "lbu": 0x4, "lhu": 0x5}
STORE_OPS = {"sb": 0x0, "sh": 0x1, "sw": 0x2}
BR_OPS = {"beq": 0x0, "bne": 0x1, "blt": 0x4, "bge": 0x5, "bltu": 0x6, "bgeu": 0x7}

OPC = {
    "R": 0x33, "I": 0x13, "LOAD": 0x03, "STORE": 0x23,
    "BRANCH": 0x63, "JAL": 0x6F, "JALR": 0x67, "LUI": 0x37, "AUIPC": 0x17,
}


class AsmError(Exception):
    pass


def reg(tok):
    t = tok.strip().lower()
    if t in ABI:
        return ABI[t]
    if re.fullmatch(r"x([0-9]|[12][0-9]|3[01])", t):
        return int(t[1:])
    raise AsmError(f"registrador inválido: {tok}")


def imm(tok, bits=None, signed=True):
    t = tok.strip()
    try:
        v = int(t, 0)
    except ValueError:
        raise AsmError(f"imediato inválido: {tok}")
    return v


def u32(x):
    return x & 0xFFFFFFFF


# --- Codificadores por formato ---
def enc_r(op, rd, rs1, rs2):
    f3, f7 = R_OPS[op]
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | OPC["R"]


def enc_i(opc, f3, rd, rs1, im):
    return (u32(im) & 0xFFF) << 20 | (rs1 << 15) | (f3 << 12) | (rd << 7) | opc


def enc_sh(op, rd, rs1, shamt):
    f3, f7 = SH_OPS[op]
    return (f7 << 25) | ((shamt & 0x1F) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | OPC["I"]


def enc_load(op, rd, rs1, im):
    return enc_i(OPC["LOAD"], LOAD_OPS[op], rd, rs1, im)


def enc_store(op, rs2, rs1, im):
    im &= 0xFFF
    f3 = STORE_OPS[op]
    return ((im >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((im & 0x1F) << 7) | OPC["STORE"]


def enc_branch(op, rs1, rs2, im):
    f3 = BR_OPS[op]
    im &= 0x1FFF
    b12 = (im >> 12) & 1
    b11 = (im >> 11) & 1
    b10_5 = (im >> 5) & 0x3F
    b4_1 = (im >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) \
        | (b4_1 << 8) | (b11 << 7) | OPC["BRANCH"]


def enc_jal(rd, im):
    im &= 0x1FFFFF
    b20 = (im >> 20) & 1
    b19_12 = (im >> 12) & 0xFF
    b11 = (im >> 11) & 1
    b10_1 = (im >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | OPC["JAL"]


def enc_jalr(rd, rs1, im):
    return enc_i(OPC["JALR"], 0x0, rd, rs1, im)


def enc_u(opc, rd, im):
    return (u32(im) & 0xFFFFF) << 12 | (rd << 7) | opc


# regex para "imm(reg)" de loads/stores
MEMREF = re.compile(r"^\s*(-?\w+)\s*\(\s*(\w+)\s*\)\s*$")


def split_ops(s):
    return [x.strip() for x in s.split(",")] if s.strip() else []


def expand(mnem, ops):
    """Expande pseudo-instruções em instruções reais. Retorna lista de
    (mnem, ops) concretas. Symbol-dependentes ficam com o símbolo no operando."""
    if mnem == "nop":
        return [("addi", ["x0", "x0", "0"])]
    if mnem == "mv":
        return [("addi", [ops[0], ops[1], "0"])]
    if mnem == "not":
        return [("xori", [ops[0], ops[1], "-1"])]
    if mnem == "neg":
        return [("sub", [ops[0], "x0", ops[1]])]
    if mnem == "seqz":
        return [("sltiu", [ops[0], ops[1], "1"])]
    if mnem == "snez":
        return [("sltu", [ops[0], "x0", ops[1]])]
    if mnem == "j":
        return [("jal", ["x0", ops[0]])]
    if mnem == "jr":
        return [("jalr", ["x0", ops[0], "0"])]
    if mnem == "ret":
        return [("jalr", ["x0", "ra", "0"])]
    if mnem == "beqz":
        return [("beq", [ops[0], "x0", ops[1]])]
    if mnem == "bnez":
        return [("bne", [ops[0], "x0", ops[1]])]
    if mnem == "li":
        v = imm(ops[1])
        lo = v & 0xFFF
        if lo >= 0x800:
            lo -= 0x1000
        hi = (v - lo) >> 12 & 0xFFFFF
        if hi == 0:
            return [("addi", [ops[0], "x0", str(lo)])]
        seq = [("lui", [ops[0], str(hi)])]
        if lo != 0:
            seq.append(("addi", [ops[0], ops[0], str(lo)]))
        return seq
    return [(mnem, ops)]


def assemble(text):
    # --- Tokeniza linhas, separa labels ---
    raw = []  # (mnem, ops) ou ("__label__", name)
    for lineno, line in enumerate(text.splitlines(), 1):
        line = line.split("#")[0].split("//")[0].strip()
        if not line:
            continue
        # labels no início (pode haver "label: instr" ou só "label:")
        while True:
            m = re.match(r"^([A-Za-z_.$][\w.$]*)\s*:\s*(.*)$", line)
            if not m:
                break
            raw.append(("__label__", m.group(1)))
            line = m.group(2).strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mnem = parts[0].lower()
        ops = split_ops(parts[1]) if len(parts) > 1 else []
        raw.append((mnem, ops, lineno))

    # --- Pass 1: expande pseudos, atribui endereços, coleta labels ---
    insns = []  # (addr, mnem, ops, lineno)
    labels = {}
    addr = 0
    for item in raw:
        if item[0] == "__label__":
            labels[item[1]] = addr
            continue
        mnem, ops, lineno = item
        for (m, o) in expand(mnem, ops):
            insns.append([addr, m, o, lineno])
            addr += 4

    # --- Pass 2: codifica ---
    words = []
    for addr, mnem, ops, lineno in insns:
        try:
            words.append(encode(mnem, ops, addr, labels))
        except AsmError as e:
            raise AsmError(f"linha {lineno}: {e}")
        except (IndexError, KeyError) as e:
            raise AsmError(f"linha {lineno}: operandos inválidos para '{mnem}' ({e})")
    return words


def sym_or_imm(tok, addr, labels, pc_relative):
    """Resolve um operando que pode ser símbolo (label) ou número.
    Se label e pc_relative, retorna deslocamento (label - addr)."""
    t = tok.strip()
    if t in labels:
        return labels[t] - addr if pc_relative else labels[t]
    return imm(t)


def encode(mnem, ops, addr, labels):
    if mnem in R_OPS:
        return enc_r(mnem, reg(ops[0]), reg(ops[1]), reg(ops[2]))
    if mnem in I_OPS:
        return enc_i(OPC["I"], I_OPS[mnem], reg(ops[0]), reg(ops[1]), imm(ops[2]))
    if mnem in SH_OPS:
        return enc_sh(mnem, reg(ops[0]), reg(ops[1]), imm(ops[2]))
    if mnem in LOAD_OPS:
        m = MEMREF.match(ops[1])
        if not m:
            raise AsmError(f"esperado imm(reg) em load: {ops[1]}")
        return enc_load(mnem, reg(ops[0]), reg(m.group(2)), imm(m.group(1)))
    if mnem in STORE_OPS:
        m = MEMREF.match(ops[1])
        if not m:
            raise AsmError(f"esperado imm(reg) em store: {ops[1]}")
        return enc_store(mnem, reg(ops[0]), reg(m.group(2)), imm(m.group(1)))
    if mnem in BR_OPS:
        off = sym_or_imm(ops[2], addr, labels, pc_relative=True)
        return enc_branch(mnem, reg(ops[0]), reg(ops[1]), off)
    if mnem == "jal":
        off = sym_or_imm(ops[1], addr, labels, pc_relative=True)
        return enc_jal(reg(ops[0]), off)
    if mnem == "jalr":
        # jalr rd, rs1, imm   ou   jalr rd, imm(rs1)
        if len(ops) == 3:
            return enc_jalr(reg(ops[0]), reg(ops[1]), imm(ops[2]))
        m = MEMREF.match(ops[1])
        if m:
            return enc_jalr(reg(ops[0]), reg(m.group(2)), imm(m.group(1)))
        return enc_jalr(reg(ops[0]), reg(ops[1]), 0)
    if mnem == "lui":
        return enc_u(OPC["LUI"], reg(ops[0]), imm(ops[1]))
    if mnem == "auipc":
        return enc_u(OPC["AUIPC"], reg(ops[0]), imm(ops[1]))
    raise AsmError(f"instrução desconhecida: {mnem}")


def write_hex(words, path):
    with open(path, "w") as f:
        for w in words:
            f.write(f"{w & 0xFFFFFFFF:08X}\n")


def write_mif(words, path, depth):
    with open(path, "w") as f:
        f.write(f"DEPTH = {depth};\nWIDTH = 32;\n")
        f.write("ADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT BEGIN\n")
        for i, w in enumerate(words):
            f.write(f"  {i:X} : {w & 0xFFFFFFFF:08X};\n")
        if len(words) < depth:
            f.write(f"  [{len(words):X}..{depth-1:X}] : 00000000;\n")
        f.write("END;\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("-o", "--out", required=True, help="arquivo .hex de saída")
    ap.add_argument("--mif", help="também gera .mif")
    ap.add_argument("--words", type=int, default=256)
    args = ap.parse_args()

    with open(args.src) as f:
        text = f.read()
    try:
        words = assemble(text)
    except AsmError as e:
        sys.exit(f"ERRO de montagem: {e}")

    if len(words) > args.words:
        sys.exit(f"programa ({len(words)} palavras) excede a ROM ({args.words}).")

    write_hex(words, args.out)
    print(f"gerado {args.out}: {len(words)} instruções")
    if args.mif:
        write_mif(words, args.mif, args.words)
        print(f"gerado {args.mif}")


if __name__ == "__main__":
    main()
