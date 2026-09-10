#!/usr/bin/env python3
"""
Build a styled interactive HTML QC report: two chart cards, centered on the
page, with a header, info tooltips, and a generation timestamp.
"""

import argparse
import gzip
from datetime import datetime

import numpy as np
import pandas as pd
import plotly.graph_objects as go


PAGE_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>dATAC Report</title>
<style>
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    background: #f5f6f8;
    margin: 0;
    padding: 0;
    color: #1a1a2e;
  }}
  header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 40px;
    background: #ffffff;
    border-bottom: 1px solid #e5e7eb;
  }}
  header h1 {{
    font-size: 20px;
    margin: 0;
  }}
  header .subtitle {{
    color: #6b7280;
    font-size: 13px;
    margin-top: 2px;
  }}
  .cards {{
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 24px;
    padding: 40px 20px 8px 20px;
  }}
  .card {{
    background: #ffffff;
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06);
    padding: 20px 24px 8px 24px;
    width: 560px;
  }}
  .card-header {{
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 4px;
  }}
  .card-header h2 {{
    font-size: 16px;
    margin: 0;
  }}
  .info-btn {{
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    border: 1px solid #9ca3af;
    color: #6b7280;
    font-size: 12px;
    font-style: italic;
    font-family: Georgia, serif;
    cursor: pointer;
  }}
  .info-tooltip {{
    display: none;
    position: absolute;
    bottom: 24px;
    left: 0;
    z-index: 10;
    width: 300px;
    background: #ffffff;
    border-radius: 10px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
    padding: 14px 16px;
    font-size: 13px;
    line-height: 1.5;
    color: #374151;
  }}
  .info-tooltip strong {{
    color: #111827;
  }}
  .info-tooltip ul {{
    margin: 8px 0 0 0;
    padding-left: 18px;
  }}
  .info-btn:hover .info-tooltip {{
    display: block;
  }}

  .hoverlayer {{
    transform: translateY(-36px);
    pointer-events: none;
  }}

  footer {{
    text-align: center;
    color: #9ca3af;
    font-size: 12px;
    padding: 8px 20px 32px 20px;
  }}
</style>
</head>
<body>

<header>
  <div>
    <h1>dATAC Report</h1>
    <div class="subtitle">{sample_name}</div>
  </div>
  <div class="subtitle">n = {n_cells} cells &nbsp;&middot;&nbsp; median TSSE = {median_tsse:.2f}</div>
</header>

<div class="cards">

  <div class="card">
    <div class="card-header">
      <h2>Fragment Size Distribution</h2>
      <span class="info-btn">i
        <div class="info-tooltip">
          <strong>Fragment Size Distribution</strong> shows the size of every sequenced ATAC fragment for this sample.
          <ul>
            <li>Good ATAC data typically shows a periodic pattern reflecting nucleosome spacing.</li>
            <li><strong>Hover</strong> over the histogram to see exact size and count.</li>
          </ul>
        </div>
      </span>
    </div>
    {fragment_div}
  </div>

  <div class="card">
    <div class="card-header">
      <h2>TSS Enrichment vs Unique Fragments</h2>
      <span class="info-btn">i
        <div class="info-tooltip">
          <strong>TSS Enrichment vs Unique Fragments</strong> shows per-cell quality: read pile-up at transcription
          start sites (a sign of real accessible-chromatin signal) versus how many unique fragments each cell has.
          <ul>
            <li>Contour shading shows cell density; individual points are hoverable underneath.</li>
            <li>Higher TSS enrichment generally indicates cleaner, less noisy ATAC signal.</li>
          </ul>
        </div>
      </span>
    </div>
    {tss_div}
  </div>

</div>

<footer>
  Generated {generated_at}
</footer>

</body>
</html>
"""


def load_fragment_sizes(fragments_path, max_fragments=2_000_000):
    sizes = []
    opener = gzip.open if fragments_path.endswith(".gz") else open
    with opener(fragments_path, "rt") as f:
        for i, line in enumerate(f):
            if i >= max_fragments:
                break
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 3:
                continue
            start, end = int(fields[1]), int(fields[2])
            sizes.append(end - start)
    return np.array(sizes)


def build_fragment_fig(fragment_sizes):
    fig = go.Figure()
    fig.add_trace(
        go.Histogram(
            x=fragment_sizes,
            nbinsx=150,
            marker_color="#1C6EDB",
            hovertemplate="Size: %{x} bp<br>Count: %{y}<extra></extra>",
        )
    )
    fig.update_xaxes(title_text="Fragment size (bp)", range=[0, 1000])
    fig.update_yaxes(title_text="Count")
    fig.update_layout(
        showlegend=False,
        height=420,
        width=500,
        template="plotly_white",
        margin=dict(l=50, r=20, t=10, b=50),
        hoverlabel=dict(bgcolor="white"),
    )
    return fig


def build_tss_fig(percell_df):
    log_nfrags = np.log10(percell_df["nFrags"])

    fig = go.Figure()
    fig.add_trace(
        go.Histogram2dContour(
            x=log_nfrags,
            y=percell_df["TSSEnrichment"],
            colorscale="Blues",
            contours=dict(showlabels=False),
            hovertemplate="log10(fragments): %{x:.2f}<br>TSSE: %{y:.2f}<br>Density: %{z}<extra></extra>",
        )
    )
    fig.add_trace(
        go.Scatter(
            x=log_nfrags,
            y=percell_df["TSSEnrichment"],
            mode="markers",
            marker=dict(color="rgba(0,0,0,0.35)", size=4),
            hovertemplate="Cell: %{text}<br>Fragments: %{customdata}<br>TSSE: %{y:.2f}<extra></extra>",
            text=percell_df["cellNames"],
            customdata=percell_df["nFrags"],
            showlegend=False,
        )
    )
    fig.update_xaxes(title_text="Log10(unique fragments)")
    fig.update_yaxes(title_text="TSS enrichment score")
    fig.update_layout(
        showlegend=False,
        height=420,
        width=500,
        template="plotly_white",
        margin=dict(l=50, r=20, t=10, b=50),
        hoverlabel=dict(bgcolor="white"),
    )
    return fig


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--percell-csv", required=True)
    parser.add_argument("--fragments", required=True)
    parser.add_argument("--sample-name", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--max-fragments", type=int, default=2_000_000)
    args = parser.parse_args()

    percell_df = pd.read_csv(args.percell_csv)
    print(f"Loaded {len(percell_df)} cells from {args.percell_csv}")

    fragment_sizes = load_fragment_sizes(args.fragments, max_fragments=args.max_fragments)
    print(f"Loaded {len(fragment_sizes)} fragment sizes")

    fragment_fig = build_fragment_fig(fragment_sizes)
    tss_fig = build_tss_fig(percell_df)

    fragment_div = fragment_fig.to_html(full_html=False, include_plotlyjs="cdn")
    tss_div = tss_fig.to_html(full_html=False, include_plotlyjs=False)

    html = PAGE_TEMPLATE.format(
        sample_name=args.sample_name,
        n_cells=len(percell_df),
        median_tsse=percell_df["TSSEnrichment"].median(),
        fragment_div=fragment_div,
        tss_div=tss_div,
        generated_at=datetime.now().strftime("%Y-%m-%d %H:%M"),
    )

    with open(args.output, "w") as f:
        f.write(html)

    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
