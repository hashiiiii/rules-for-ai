#!/usr/bin/env python3
"""Rebuild vendored skills from reviewed release tags, commits, and patches."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import stat
import sys
import tempfile


def git(directory, *args):
    result = subprocess.run(
        ["git", "-C", str(directory), *args], capture_output=True, text=True,
    )
    if result.returncode:
        raise ValueError(result.stderr.strip())
    return result.stdout.strip()


def child(directory, value):
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise ValueError(f"invalid relative path: {value}")
    resolved = directory.joinpath(*path.parts).resolve()
    if not resolved.is_relative_to(directory.resolve()):
        raise ValueError(f"path escapes directory: {value}")
    return resolved


def inventory(directory):
    if not directory.exists():
        return None
    files = {}
    for path in directory.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"symlinks are not supported in bundles: {path}")
        if path.is_file():
            files[path.relative_to(directory).as_posix()] = (
                hashlib.sha256(path.read_bytes()).hexdigest(),
                bool(path.stat().st_mode & stat.S_IXUSR),
            )
    return files


def prepare(root, temporary, bundle):
    destination = bundle["destination"]
    if not re.fullmatch(r"skills/[^/.][^/]*/vendor/[^/.][^/]*", destination):
        raise ValueError(f"invalid bundle destination: {destination}")
    target = child(root, destination)
    revision = bundle["revision"]
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError(f"invalid commit: {revision}")
    version = bundle["version"]
    if not re.fullmatch(r"v?\d+\.\d+\.\d+", version):
        raise ValueError(f"expected a stable release tag: {version}")
    repository = bundle["repository"]
    checkout = temporary / "checkout"
    checkout.mkdir()
    git(checkout, "init", "-q")
    git(checkout, "fetch", "-q", "--depth=1", "--no-tags", "--", repository, f"refs/tags/{version}")
    actual = git(checkout, "rev-parse", "FETCH_HEAD^{commit}")
    if actual != revision:
        raise ValueError(f"commit mismatch for {bundle['name']}: expected {revision}, got {actual}")
    git(checkout, "-c", "advice.detachedHead=false", "checkout", "-q", "--detach", actual)
    source = child(checkout, bundle["source"])
    output = temporary / "output"
    output.mkdir()
    for value in bundle["include"]:
        item = child(source, value)
        if not item.exists():
            raise ValueError(f"missing upstream resource: {value}")
        if item.is_symlink() or (item.is_dir() and any(p.is_symlink() for p in item.rglob("*"))):
            raise ValueError(f"symlinks are not supported in bundles: {value}")
        copied = child(output, value)
        if item.is_dir():
            shutil.copytree(item, copied, dirs_exist_ok=True)
        else:
            copied.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, copied)
    # Apply every patch before publishing any bundle, so failures preserve existing output.
    for patch in bundle["patches"]:
        git(output, "apply", "--check", str(child(root, patch)))
        git(output, "apply", str(child(root, patch)))
    (output / "SKILL.md").rename(output / "INSTRUCTIONS.md")
    if any(p.name.lower() == "skill.md" for p in output.rglob("*")):
        raise ValueError(f"nested skill manifest in {bundle['name']}")
    patches = "\n".join(f"- `{patch}`" for patch in bundle["patches"]) or "None."
    included = ", ".join(f"`{path}`" for path in bundle["include"])
    (output / "UPSTREAM.md").write_text(
        "# Upstream source\n\n"
        f"- Repository: {repository}\n"
        f"- Release: `{version}`\n"
        f"- Commit: `{revision}`\n"
        f"- Source directory: `{bundle['source']}`\n"
        f"- Included paths: {included}\n\n"
        "`SKILL.md` is renamed to `INSTRUCTIONS.md` to expose only the wrapper's skill name.\n"
        "Upstream licenses are retained in this directory.\n\n"
        "## Local patches\n\n"
        f"{patches}\n\n"
        "Update `upstreams.json`, then run `python3 scripts/sync-upstreams.py` from the repository root.\n"
        "This file is generated. Do not edit the bundle directly.\n",
        encoding="utf-8",
    )
    return target, output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--check", action="store_true", help="report drift without modifying bundles")
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        bundles = json.loads((root / "upstreams.json").read_text(encoding="utf-8"))["bundles"]
        with tempfile.TemporaryDirectory(prefix="rules-for-ai-upstreams-") as directory:
            prepared = []
            for index, bundle in enumerate(bundles):
                temporary = Path(directory) / str(index)
                temporary.mkdir()
                target, output = prepare(root, temporary, bundle)
                if any(target == existing for existing, _ in prepared):
                    raise ValueError(f"duplicate destination: {target}")
                prepared.append((target, output))
            changed = [(target, output) for target, output in prepared if inventory(target) != inventory(output)]
            for target, output in changed:
                print(f"{'DRIFT' if args.check else 'UPDATE'}: {target.relative_to(root)}")
                if not args.check:
                    if target.exists():
                        shutil.rmtree(target)
                    shutil.copytree(output, target)
            if not changed:
                print("Bundled skills match the pinned upstream sources and patches.")
            return int(args.check and bool(changed))
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
