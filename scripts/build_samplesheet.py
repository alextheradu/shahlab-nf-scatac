import csv
import sys

def build(sample_id, fastqs_csv_path, markdup_bam_path, output_path):
    rows = []
    with open(fastqs_csv_path) as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append([sample_id, r["fastq2"], markdup_bam_path])

    with open(output_path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["sample", "fastq_r2", "markdup_bam"])
        w.writerows(rows)

    print(f"wrote {len(rows)} rows to {output_path}")

if __name__ == "__main__":
    sample_id, fastqs_csv, markdup_bam, output = sys.argv[1:5]
    build(sample_id, fastqs_csv, markdup_bam, output)
