#!/usr/bin/env python3

import snapatac2 as snap
import argparse
import json


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--metrics", required=True)
    args = parser.parse_args()

    metrics = snap.pp.make_fragment_file(
        args.bam,
        args.output,
        is_paired=True,
        barcode_tag="CB",
    )

    with open(args.metrics, "w") as f:
        json.dump(metrics, f, indent=2)


if __name__ == "__main__":
    main()
