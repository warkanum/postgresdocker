#!/usr/bin/env python3
"""Static checks that the basic PG19 image excludes complex extensions."""

from pathlib import Path

IMAGE_DIR = Path(__file__).resolve().parents[1]
EXCLUDED = ["timescaledb", "pg_textsearch", "postgis", "pgrouting", "pgrx"]


def _text(name: str) -> str:
    return (IMAGE_DIR / name).read_text(encoding="utf-8")


def test_dockerfile_does_not_build_excluded_extensions() -> None:
    build_lines = [
        line for line in _text("Dockerfile").splitlines()
        if not line.lstrip().startswith("#")
    ]
    text = "\n".join(build_lines).lower()
    for name in EXCLUDED:
        assert name not in text, f"Dockerfile still builds {name}"
    assert "pgdocker-ext-builder" not in text


def test_init_sql_does_not_create_excluded_extensions() -> None:
    text = _text("init-extensions.sql").lower()
    for name in EXCLUDED:
        assert name not in text, f"init-extensions.sql still creates {name}"


def test_excluded_extensions_are_not_preloaded() -> None:
    preload = [
        line for line in _text("custom.conf").splitlines()
        if line.strip().startswith("shared_preload_libraries")
    ]
    assert len(preload) == 1
    for name in EXCLUDED:
        assert name not in preload[0], f"{name} is still preloaded"


def main() -> None:
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            fn()
            print(f"PASS: {name}")


if __name__ == "__main__":
    main()
    print("basic extension checks passed")
