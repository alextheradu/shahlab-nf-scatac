#!/usr/bin/env python3
"""
Rebuild the Seqera Wave community containers this pipeline depends on.

Two local modules need software combinations that no ready-made public image
provides, so their images are built on the Seqera Wave community registry:

    modules/local/archr_qc         ArchR + the hg19 annotation packages
    modules/local/build_qc_report  python + pandas + numpy + plotly

Each module's environment.yml is the single source of truth. Wave derives the
image tag from a hash of the build request, so an unchanged environment.yml
always yields the same image reference and is served from cache; editing one
produces a new reference that must be pasted back into the module.

Seqera commits to retaining community images for a minimum of five years. This
script exists so the images can be regenerated if that ever lapses, or if you
would rather host them yourself.

Usage:
    scripts/build_wave_containers.py             # submit builds, print refs
    scripts/build_wave_containers.py --wait      # ...and poll until finished
"""

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

WAVE_API = "https://wave.seqera.io"
REGISTRY = "community.wave.seqera.io"
BLOB_BASE = "https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256"

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES = [
    "modules/local/archr_qc",
    "modules/local/build_qc_report",
]


def parse_environment_yml(path):
    """Read the `channels` and `dependencies` lists out of an environment.yml.

    Deliberately minimal: these files are short and flat, so this avoids adding
    a PyYAML dependency just to read two lists of strings.
    """
    channels, dependencies, section = [], [], None
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line or line == "---":
            continue
        if not line.startswith((" ", "\t", "-")):
            section = line.rstrip(":").strip()
            continue
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        item = stripped[2:].strip()
        if section == "channels":
            channels.append(item)
        elif section == "dependencies":
            dependencies.append(item)
    if not dependencies:
        raise ValueError(f"no dependencies found in {path}")
    return channels, dependencies


def post_json(url, payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        url, data=body, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        sys.exit(f"Wave request failed ({exc.code}): {exc.read().decode()[:400]}")


def submit(channels, dependencies, image_format):
    """Ask Wave to build (or return from cache) one image."""
    payload = {
        "packages": {
            "type": "CONDA",
            "entries": dependencies,
            "channels": channels,
        },
        "containerPlatform": "linux/amd64",
        "freeze": True,
        "format": image_format,
    }
    return post_json(f"{WAVE_API}/v1alpha2/container", payload)


def build_status(build_id):
    url = f"{WAVE_API}/v1alpha1/builds/{build_id}/status"
    with urllib.request.urlopen(url, timeout=60) as resp:
        return json.load(resp)


def wait_for(build_id, poll_seconds=20, timeout_seconds=5400):
    """Poll until the build leaves PENDING. Wave returns cached builds as done."""
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        status = build_status(build_id)
        if status.get("status") != "PENDING":
            return status
        time.sleep(poll_seconds)
    raise TimeoutError(f"{build_id} still PENDING after {timeout_seconds}s")


def sif_download_url(image_ref):
    """Resolve a SIF image to the direct-download blob URL the modules use.

    Nextflow can pull the oras:// reference directly, but the plain https blob
    URL matches the convention already used elsewhere in this pipeline and works
    with any Singularity build, ORAS support or not.
    """
    repo, tag = image_ref.removeprefix("oras://").removeprefix(REGISTRY + "/").split(":")
    token_url = (
        f"https://cerbero.seqera.io/auth/token"
        f"?service={REGISTRY}&scope=repository:{repo}:pull"
    )
    with urllib.request.urlopen(token_url, timeout=60) as resp:
        token = json.load(resp)["token"]

    req = urllib.request.Request(
        f"https://{REGISTRY}/v2/{repo}/manifests/{tag}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.oci.image.manifest.v1+json, "
            "application/vnd.docker.distribution.manifest.v2+json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        manifest = json.load(resp)

    digest = manifest["layers"][0]["digest"].split(":")[1]
    return f"{BLOB_BASE}/{digest[:2]}/{digest}/data"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--wait",
        action="store_true",
        help="poll until every build finishes (the ArchR image takes ~20 min cold)",
    )
    args = parser.parse_args()

    for module in MODULES:
        env_file = REPO_ROOT / module / "environment.yml"
        channels, dependencies = parse_environment_yml(env_file)

        print(f"\n=== {module} ===")
        for dep in dependencies:
            print(f"  {dep}")

        docker = submit(channels, dependencies, "docker")
        sif = submit(channels, dependencies, "sif")

        if args.wait:
            for result in (docker, sif):
                status = wait_for(result["buildId"])
                if not status.get("succeeded", False):
                    sys.exit(f"build {result['buildId']} failed: {status}")

        cached = "cached" if docker.get("cached") else "building"
        print(f"\n  docker ({cached}): {docker['targetImage']}")

        if args.wait:
            print("\n  Paste into the module's container directive:\n")
            print(
                "    container \"${workflow.containerEngine in "
                "['singularity', 'apptainer'] && "
                "!task.ext.singularity_pull_docker_container\n"
                f"        ? '{sif_download_url(sif['targetImage'])}'\n"
                f"        : '{docker['targetImage']}'}}\""
            )
        else:
            print(f"  sif    ({'cached' if sif.get('cached') else 'building'}): "
                  f"{sif['targetImage']}")
            print("\n  Re-run with --wait to resolve the SIF download URL.")


if __name__ == "__main__":
    main()
