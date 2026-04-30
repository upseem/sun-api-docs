#!/usr/bin/env bash
# Sync OpenAPI specs from the new-api project and clean them for Mintlify.
#
# Usage:
#   scripts/sync-openapi.sh                       # default: ../new-api
#   scripts/sync-openapi.sh /path/to/new-api      # custom source path
#   SERVER_URL=https://api.example.com scripts/sync-openapi.sh
#
# Steps:
#   1. Copy docs/openapi/{relay,api}.json from source repo
#   2. Remove malformed Apifox `Combination*` securitySchemes
#      (they lack `openIdConnectUrl` and break Mintlify validation)
#   3. Inject `servers` field with production URL

set -euo pipefail

# Resolve script and repo paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_DIR="$DOCS_REPO/api-reference"

# Source defaults
SOURCE_REPO="${1:-$DOCS_REPO/../new-api}"
SERVER_URL="${SERVER_URL:-https://api.sunx.ai}"
SERVER_DESC="${SERVER_DESC:-生产环境}"

# Validate source
if [[ ! -d "$SOURCE_REPO/docs/openapi" ]]; then
  echo "ERROR: source openapi directory not found: $SOURCE_REPO/docs/openapi" >&2
  echo "Pass the new-api repo path as the first argument." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Sun API docs sync"
echo "  source : $SOURCE_REPO/docs/openapi"
echo "  dest   : $DEST_DIR"
echo "  server : $SERVER_URL ($SERVER_DESC)"
echo

for name in relay.json api.json; do
  src="$SOURCE_REPO/docs/openapi/$name"
  dst="$DEST_DIR/$name"

  if [[ ! -f "$src" ]]; then
    echo "WARN: $src not found, skipping" >&2
    continue
  fi

  cp "$src" "$dst"

  python3 - "$dst" "$SERVER_URL" "$SERVER_DESC" <<'PY'
import json
import sys

path, server_url, server_desc = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    spec = json.load(f)

# 1. Inject servers
spec["servers"] = [{"url": server_url, "description": server_desc}]

# 2. Strip malformed security schemes (Apifox bug: Combination* without openIdConnectUrl)
schemes = spec.setdefault("components", {}).setdefault("securitySchemes", {})
allowed_types = {"apiKey", "http", "oauth2", "openIdConnect", "mutualTLS"}
removed = []
for key in list(schemes.keys()):
    val = schemes[key] if isinstance(schemes[key], dict) else {}
    if val.get("type") not in allowed_types:
        del schemes[key]
        removed.append(key)

# Strip removed keys from operation-level + global security blocks
def filter_security(blocks):
    return [b for b in blocks if not any(k in b for k in removed)]

if "security" in spec:
    spec["security"] = filter_security(spec["security"])

for path_item in spec.get("paths", {}).values():
    if not isinstance(path_item, dict):
        continue
    for op in path_item.values():
        if isinstance(op, dict) and "security" in op:
            op["security"] = filter_security(op["security"])

with open(path, "w", encoding="utf-8") as f:
    json.dump(spec, f, ensure_ascii=False, indent=2)

base = path.rsplit("/", 1)[-1]
print(f"  {base}: kept {len(schemes)} schemes, removed {len(removed)}")
PY
done

echo
echo "Done. Next:"
echo "  git -C \"$DOCS_REPO\" diff --stat api-reference/"
echo "  git -C \"$DOCS_REPO\" add api-reference/ && git -C \"$DOCS_REPO\" commit -m 'docs: sync openapi'"
