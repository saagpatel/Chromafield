#!/usr/bin/env python3
"""Check that Fastlane metadata matches the App Store copy source."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "APPSTORE-METADATA.md"
METADATA = ROOT / "fastlane" / "metadata"


def section(document: str, title: str) -> str:
    match = re.search(
        rf"^## {re.escape(title)}\s*\n(.*?)(?=^## |\Z)",
        document,
        flags=re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError(f"missing section: {title}")
    content = match.group(1).strip()
    if content.endswith("\n---"):
        content = content[:-4].rstrip()
    return content


def fenced_text(content: str, title: str) -> str:
    match = re.search(r"```\s*\n(.*?)\n```", content, flags=re.DOTALL)
    if not match:
        raise ValueError(f"missing fenced text in section: {title}")
    return match.group(1)


def identity_value(content: str, field: str) -> str:
    match = re.search(rf"^\| \*\*{re.escape(field)}\*\* \| (.*?) \|$", content, re.MULTILINE)
    if not match:
        raise ValueError(f"missing identity field: {field}")
    return match.group(1)


def plain_description(content: str) -> str:
    # The source uses Markdown bold for short section labels. Keep its text and
    # bullet glyphs while removing the Markdown emphasis markers.
    return re.sub(r"\*\*(.*?)\*\*", r"\1", content)


def expected_files(document: str) -> dict[str, str]:
    identity = section(document, "Identity")
    keywords = fenced_text(section(document, "Keywords"), "Keywords")
    promotional = fenced_text(section(document, "Promotional Text"), "Promotional Text")
    description = plain_description(section(document, "Description"))

    expected = {
        "default/copyright.txt": section(document, "Copyright"),
        "en-US/name.txt": identity_value(identity, "Name"),
        "en-US/subtitle.txt": identity_value(identity, "Subtitle"),
        "en-US/description.txt": description,
        "en-US/keywords.txt": keywords,
        "en-US/promotional_text.txt": promotional,
        "en-US/support_url.txt": section(document, "Support URL"),
        "en-US/privacy_url.txt": section(document, "Privacy Policy URL"),
        "en-US/release_notes.txt": "Initial release.",
    }
    if re.search(r"^## Marketing URL\s*$", document, flags=re.MULTILINE):
        expected["en-US/marketing_url.txt"] = section(document, "Marketing URL")
    return {path: value.rstrip("\n") + "\n" for path, value in expected.items()}


def main() -> int:
    document = SOURCE.read_text(encoding="utf-8")
    expected = expected_files(document)
    actual_paths = {path.relative_to(METADATA).as_posix() for path in METADATA.rglob("*.txt")}
    expected_paths = set(expected)
    errors = []

    for missing in sorted(expected_paths - actual_paths):
        errors.append(f"missing {missing}")
    for unexpected in sorted(actual_paths - expected_paths):
        errors.append(f"unexpected metadata file {unexpected}")

    for relative_path, value in expected.items():
        path = METADATA / relative_path
        if not path.is_file():
            continue
        expected_bytes = value.encode("utf-8")
        actual_bytes = path.read_bytes()
        if actual_bytes != expected_bytes:
            errors.append(f"mismatch {relative_path} (expected {len(expected_bytes)} bytes, got {len(actual_bytes)})")
        else:
            print(f"MATCH {relative_path}: {len(actual_bytes)} bytes")

    if errors:
        for error in errors:
            print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS: {len(expected)} Fastlane metadata files match APPSTORE-METADATA.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
