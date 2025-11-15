from __future__ import annotations

from pathlib import Path

PROJECT_FILE = Path("ProgressTracker.xcodeproj/project.pbxproj")


def determine_source_tree(isa: str | None, path: str | None) -> str:
    """Return the appropriate sourceTree value for the given object."""
    if isa == "PBXFileReference":
        if path == "ProgressTracker.app":
            return "BUILT_PRODUCTS_DIR"
        if path == "ProgressTrackerApp.swift":
            return "SOURCE_ROOT"
        return "<group>"
    if isa in {"PBXGroup", "XCVersionGroup"}:
        return "<group>"
    # Fallback to <group> for any other objects that unexpectedly declare sourceTree
    return "<group>"


def fix_source_tree() -> bool:
    text = PROJECT_FILE.read_text()
    lines = text.splitlines()

    current_isa: str | None = None
    current_path: str | None = None
    updated = False

    for idx, line in enumerate(lines):
        stripped = line.strip()

        if stripped.endswith("= {"):
            current_isa = None
            current_path = None

        if "isa =" in line:
            current_isa = line.split("isa =", 1)[1].split(";", 1)[0].strip()
        elif "path =" in line:
            raw_path = line.split("path =", 1)[1].split(";", 1)[0].strip()
            current_path = raw_path.strip('"')

        if "sourceTree =" in line:
            value = line.split("sourceTree =", 1)[1].split(";", 1)[0].strip()
            replacement = None

            if value == "":
                replacement = determine_source_tree(current_isa, current_path)
            elif current_isa == "PBXFileReference" and current_path == "ProgressTrackerApp.swift" and value != "SOURCE_ROOT":
                replacement = "SOURCE_ROOT"

            if replacement is not None:
                prefix = line.split("sourceTree =", 1)[0]
                lines[idx] = f"{prefix}sourceTree = {replacement};"
                updated = True

        if stripped == "};":
            current_isa = None
            current_path = None

    if updated:
        PROJECT_FILE.write_text("\n".join(lines) + "\n")
    return updated


if __name__ == "__main__":
    changed = fix_source_tree()
    if changed:
        print("Updated sourceTree values in project.pbxproj")
    else:
        print("No sourceTree updates were necessary")
