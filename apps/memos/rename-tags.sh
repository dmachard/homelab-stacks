#!/bin/sh

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ancien-tag> <nouveau-tag>"
    exit 1
fi

docker run --rm \
  --name rename-memos-tags \
  --network apps_memos \
  -v "$PWD/rename-tags.py:/rename-tags.py:ro" \
  -e MEMOS_URL="http://memos:5230" \
  -e MEMOS_TOKEN="$MEMOS_TOKEN" \
  python:3.13-alpine \
  sh -c "pip install -q requests && python /rename-tags.py '$1' '$2'"
