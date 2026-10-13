#!/usr/bin/env python3
"""Build UnRen-DDAC V145 BAT from its editable Python payload.
Usage: python build_v145_payload.py [input.bat] [source.py] [output.bat]
"""
from pathlib import Path
import base64, sys, py_compile, hashlib
DEFAULT_BAT = Path(__file__).with_name("UnRen-DDAC-v145.bat")
DEFAULT_PY = Path(__file__).with_name("UnRen-DDAC-v145-python.py")
DEFAULT_OUT = DEFAULT_BAT
in_bat = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_BAT
src_py = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_PY
out_bat = Path(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_OUT
source = src_py.read_text(encoding="utf-8")
compile(source, str(src_py), "exec")
text = in_bat.read_bytes().decode("utf-8-sig").replace("\r\n", "\n")
lines = text.splitlines()
start = next(i for i, line in enumerate(lines) if line.strip() == "REM ##DDAC_DIALOGOS_PYTHON_START##")
end = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "REM ##DDAC_DIALOGOS_PYTHON_END##")
encoded = base64.b64encode(source.encode("utf-8")).decode("ascii")
payload = ["REM " + encoded[i:i+72] for i in range(0, len(encoded), 72)]
result = "\r\n".join(lines[:start+1] + payload + ["REM ##DDAC_DIALOGOS_PYTHON_END##"] + lines[end+1:]) + "\r\n"
out_bat.write_bytes(b"\xef\xbb\xbf" + result.encode("utf-8"))
print("BAT:", out_bat)
print("Python:", src_py)
print("Python bytes:", len(source.encode("utf-8")))
print("BAT SHA256:", hashlib.sha256(out_bat.read_bytes()).hexdigest())
