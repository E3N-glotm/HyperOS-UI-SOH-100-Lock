#!/usr/bin/env python3
"""Build an installable Magisk module ZIP with LF-only shell scripts."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
VERSION = "v1.0.0"
NAMES = (
    "module.prop",
    "customize.sh",
    "ui_soh_core.sh",
    "service.sh",
    "action.sh",
)


def main():
    output = ROOT / "dist" / f"HyperOS-UI-SOH-100-Lock-{VERSION}.zip"
    output.parent.mkdir(exist_ok=True)
    with ZipFile(output, "w", ZIP_DEFLATED, compresslevel=9) as archive:
        for name in NAMES:
            data = (ROOT / name).read_bytes().replace(b"\r\n", b"\n")
            if b"\r" in data:
                raise ValueError(f"Unexpected CR byte in {name}")
            info = ZipInfo(name, (2026, 10, 24, 12, 0, 0))
            info.create_system = 3
            info.external_attr = ((0o100755 if name.endswith(".sh") else 0o100644) << 16)
            info.compress_type = ZIP_DEFLATED
            archive.writestr(info, data)
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(NAMES)
        assert archive.read("module.prop").startswith(b"id=hyperos_ui_soh_100_lock")
    print(output)
    print(f"ZIP size: {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
