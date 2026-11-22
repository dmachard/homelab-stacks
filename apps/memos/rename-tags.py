import os
import re
import sys

import requests


BASE_URL = os.environ.get("MEMOS_URL", "http://memos:5230")
TOKEN = os.environ["MEMOS_TOKEN"]

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <ancien-tag> <nouveau-tag>")
    print(f"Exemple: {sys.argv[0]} '#elec' '#ELEC'")
    sys.exit(1)

OLD_TAG = sys.argv[1]
NEW_TAG = sys.argv[2]

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
}

# Le tag doit être délimité : #elec ne doit pas matcher #electricien
pattern = re.compile(
    rf"(?<!\w){re.escape(OLD_TAG)}(?!\w)"
)

# Récupération des mémos
response = requests.get(
    f"{BASE_URL}/api/v1/memos",
    headers=headers,
    params={"page_size": 1000},
)
response.raise_for_status()

all_memos = response.json()["memos"]

memos = [
    memo
    for memo in all_memos
    if pattern.search(memo.get("content", ""))
]

print(f"Tag : {OLD_TAG} → {NEW_TAG}")
print(f"{len(memos)} mémos trouvés")

if not memos:
    sys.exit(0)

for memo in memos:
    name = memo["name"]
    content = memo["content"]

    new_content = pattern.sub(NEW_TAG, content)

    response = requests.patch(
        f"{BASE_URL}/api/v1/{name}",
        headers=headers,
        params={"update_mask": "content"},
        json={
            "name": name,
            "content": new_content,
        },
    )

    if response.ok:
        print(f"OK  {name}")
    else:
        print(f"ERR {name}: {response.status_code} {response.text}")
