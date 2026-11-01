#!/usr/bin/env bash
# Gate 1 static checks. Run from anywhere; operates on the repository root.
# Later batches append checks where marked "ADDED IN Bxx".
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
python3 - <<'PY'
import os, re, sys

problems = []
def fail(msg):
    problems.append(msg)

APP = "app"
LIB = os.path.join(APP, "lib")

# ---------------------------------------------------------------- Flutter pin
try:
    pin = open("tool/flutter_version.txt", encoding="utf8").read()
    if not re.fullmatch(r"\d+\.\d+\.\d+\n?", pin):
        fail("tool/flutter_version.txt must contain exactly one version line such as 3.47.7")
except OSError:
    fail("tool/flutter_version.txt is missing")

# ---------------------------------------------------------------- exact pins
VERSION = re.compile(r"^\d+\.\d+\.\d+(?:\+\d+)?(?:-[0-9A-Za-z.]+)?$")
def check_pins(path):
    lines = open(path, encoding="utf8").read().splitlines()
    section = None
    for idx, raw in enumerate(lines):
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if not line.startswith(" "):
            m = re.match(r"^(dependencies|dev_dependencies|dependency_overrides):\s*$", line)
            section = m.group(1) if m else None
            continue
        if section is None:
            continue
        m = re.match(r"^  ([A-Za-z0-9_]+):\s*(.*)$", line)
        if not m:
            continue
        name, val = m.group(1), m.group(2).strip().strip("\"'")
        if val == "":
            nested = []
            j = idx + 1
            while j < len(lines) and (lines[j].startswith("    ") or not lines[j].strip()):
                nested.append(lines[j].split("#", 1)[0].strip())
                j += 1
            if "sdk: flutter" not in nested:
                fail(f"{path}: {name} must be `sdk: flutter` or an exact version (no git or path forks)")
        elif not VERSION.match(val):
            fail(f"{path}: {name}: '{val}' is not an exact pinned version")
if os.path.isfile(f"{APP}/pubspec.yaml"):
    check_pins(f"{APP}/pubspec.yaml")
if os.path.isfile("tools/blocklist/pubspec.yaml"):
    check_pins("tools/blocklist/pubspec.yaml")

# ------------------------------------------------- imports: layering + bans
IMPORT = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", re.M)
BANNED = re.compile(r"^package:(flutter/(material|cupertino)\.dart|flutter/src/(material|cupertino)/|material_ui/|cupertino_ui/)")
PURE_PKGS = {"meta", "collection", "cryptography", "intl", "qr"}
CORE_DART = {"async", "convert", "collection", "typed_data", "math"}

def classify(file_path, uri):
    if uri.startswith("dart:"):
        return ("dart", uri[5:].split("/")[0], None)
    if uri.startswith("package:"):
        pkg, _, rest = uri[8:].partition("/")
        if pkg == "tahorbrowser":
            return ("local", None, os.path.normpath(os.path.join(LIB, rest)))
        return ("pkg", pkg, rest)
    return ("local", None, os.path.normpath(os.path.join(os.path.dirname(file_path), uri)))

def under(path, *dirs):
    return any(path == os.path.join(LIB, d) or path.startswith(os.path.join(LIB, d) + os.sep) for d in dirs)

for root, _dirs, files in os.walk(LIB):
    if os.path.join("l10n", "gen") in root:
        continue
    for fn in files:
        if not fn.endswith(".dart"):
            continue
        fp = os.path.join(root, fn)
        text = open(fp, encoding="utf8").read()
        zone = None
        for z in ("core", "widgets", "screens"):
            if under(fp, z):
                zone = z
        for uri in IMPORT.findall(text):
            if BANNED.match(uri):
                fail(f"{fp}: forbidden import '{uri}' (no Material or Cupertino anywhere in lib/)")
            kind, name, rest = classify(fp, uri)
            if zone == "core":
                if kind == "dart" and name not in CORE_DART:
                    fail(f"{fp}: core/ may not import 'dart:{name}'")
                elif kind == "pkg":
                    if name == "flutter":
                        if rest not in ("foundation.dart", "widgets.dart"):
                            fail(f"{fp}: core/ may import only flutter/foundation.dart and flutter/widgets.dart, not '{uri}'")
                    elif name not in PURE_PKGS:
                        fail(f"{fp}: core/ may not import plugin or package '{name}'")
                elif kind == "local" and not under(rest, "core"):
                    fail(f"{fp}: core/ may import only core/, not '{uri}'")
            elif zone in ("widgets", "screens"):
                if kind == "dart" and name == "io":
                    fail(f"{fp}: {zone}/ may not import 'dart:io'")
                elif kind == "pkg":
                    if name == "flutter":
                        if rest == "services.dart" and zone == "screens":
                            fail(f"{fp}: screens/ may not import flutter/services.dart")
                    elif name == "phosphoricons_flutter":
                        if fp != os.path.join(LIB, "widgets", "icons", "semantic_icons.dart"):
                            fail(f"{fp}: only widgets/icons/semantic_icons.dart may name icon glyphs")
                    elif name not in PURE_PKGS:
                        fail(f"{fp}: {zone}/ may not import plugin or package '{name}'")
                elif kind == "local" and not under(rest, "core", "widgets", "screens", "l10n"):
                    fail(f"{fp}: {zone}/ may import only core/, widgets/, screens/ and l10n/, not '{uri}'")

# ------------------------------------------------------------ forbidden tokens
TOKENS = re.compile(r"\b(TODO|FIXME|UnimplementedError|localStorage)\b")
for root, _dirs, files in os.walk(LIB):
    if os.path.join("l10n", "gen") in root:
        continue
    for fn in files:
        if fn.endswith(".dart"):
            fp = os.path.join(root, fn)
            for n, line in enumerate(open(fp, encoding="utf8"), 1):
                m = TOKENS.search(line)
                if m:
                    fail(f"{fp}:{n}: forbidden token '{m.group(1)}'")

# ------------------------------------------------------ workflow trigger audit
WF = ".github/workflows"
TRIGGER = re.compile(r"^\s*(push|pull_request|pull_request_target|schedule|workflow_run|release|create)\s*:", re.M)
USES = re.compile(r"^\s*-?\s*uses:\s*(\S+)", re.M)
if os.path.isdir(WF):
    for fn in sorted(os.listdir(WF)):
        if not fn.endswith((".yml", ".yaml")):
            continue
        fp = os.path.join(WF, fn)
        text = open(fp, encoding="utf8").read()
        for m in TRIGGER.finditer(text):
            if not (fn == "verify.yml" and m.group(1) == "push"):
                fail(f"{fp}: trigger '{m.group(1)}' is not allowed; only verify.yml may use push, on batch/** (D-05)")
        if fn == "verify.yml":
            if "'batch/**'" not in text:
                fail(f"{fp}: the push trigger must be limited to 'batch/**'")
        for ref in USES.findall(text):
            if ref.startswith("./"):
                continue
            if not re.search(r"@[0-9a-f]{40}$", ref):
                fail(f"{fp}: action '{ref}' must be pinned to a full commit SHA")

# ADDED IN B22: permission allowlist and forbidden Info.plist keys
# ADDED IN B36: AdRequest( guard
# ADDED IN B37: hardcoded-string check
# ADDED IN B45: merged-manifest audit

if problems:
    for p in problems:
        print("CI-CHECK FAIL:", p)
    print(f"{len(problems)} problem(s) found.")
    sys.exit(1)
print("ci_checks: all checks passed")
PY
