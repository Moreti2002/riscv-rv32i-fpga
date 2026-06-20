#!/usr/bin/env python3
"""plot_sweep.py — Gráficos do experimento de escalabilidade da ULA (Frente A).

Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.

Lê reports/alu_sweep.csv (gerado por scripts/sweep_alu.tcl) e produz:
  docs/alu_le_vs_width.png    — Logic Elements x largura (escala dupla)
  docs/alu_fmax_vs_width.png  — Fmax x largura

Uso (a partir da raiz do repo):
  python scripts/plot_sweep.py
"""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CSV = os.path.join(ROOT, "reports", "alu_sweep.csv")
DOCS = os.path.join(ROOT, "docs")


def load():
    rows = []
    with open(CSV, newline="") as f:
        for r in csv.DictReader(f):
            try:
                w = int(r["width"])
                le = int(str(r["logic_elements"]).replace(",", ""))
            except (ValueError, KeyError):
                continue
            try:
                fmax = float(r["fmax_mhz"])
            except (ValueError, KeyError):
                fmax = None
            rows.append((w, le, fmax))
    rows.sort()
    return rows


def main():
    if not os.path.exists(CSV):
        sys.exit(f"CSV nao encontrado: {CSV}\nRode antes: quartus_sh -t scripts/sweep_alu.tcl")
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        sys.exit("matplotlib ausente. Instale: python -m pip install matplotlib")

    rows = load()
    if not rows:
        sys.exit("CSV sem dados validos.")
    os.makedirs(DOCS, exist_ok=True)

    widths = [r[0] for r in rows]
    les = [r[1] for r in rows]

    # --- LEs x largura ---
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.plot(widths, les, "o-", color="#1f77b4", linewidth=2, markersize=7)
    for w, le in zip(widths, les):
        ax.annotate(str(le), (w, le), textcoords="offset points", xytext=(0, 8), ha="center")
    ax.set_xlabel("Largura da ULA (bits)")
    ax.set_ylabel("Logic Elements (LEs)")
    ax.set_title("Escalabilidade da ULA RV32I — LEs x largura (MAX 10)")
    ax.set_xscale("log", base=2)
    ax.set_xticks(widths)
    ax.get_xaxis().set_major_formatter(plt.ScalarFormatter())
    ax.grid(True, which="both", linestyle=":", alpha=0.6)
    fig.tight_layout()
    out1 = os.path.join(DOCS, "alu_le_vs_width.png")
    fig.savefig(out1, dpi=130)
    print("gerado:", out1)

    # --- Fmax x largura (se houver) ---
    fmaxes = [(w, fm) for w, _, fm in rows if fm is not None]
    if fmaxes:
        fig2, ax2 = plt.subplots(figsize=(7, 4.5))
        ws = [w for w, _ in fmaxes]
        fs = [fm for _, fm in fmaxes]
        ax2.plot(ws, fs, "s-", color="#d62728", linewidth=2, markersize=7)
        for w, fm in fmaxes:
            ax2.annotate(f"{fm:.0f}", (w, fm), textcoords="offset points", xytext=(0, 8), ha="center")
        ax2.set_xlabel("Largura da ULA (bits)")
        ax2.set_ylabel("Fmax (MHz)")
        ax2.set_title("Escalabilidade da ULA RV32I — Fmax x largura (MAX 10)")
        ax2.set_xscale("log", base=2)
        ax2.set_xticks(ws)
        ax2.get_xaxis().set_major_formatter(plt.ScalarFormatter())
        ax2.grid(True, which="both", linestyle=":", alpha=0.6)
        fig2.tight_layout()
        out2 = os.path.join(DOCS, "alu_fmax_vs_width.png")
        fig2.savefig(out2, dpi=130)
        print("gerado:", out2)
    else:
        print("aviso: sem dados de Fmax no CSV (pulei o grafico de Fmax).")


if __name__ == "__main__":
    main()
