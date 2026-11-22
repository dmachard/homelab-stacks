# Memos – Rename Tags

Petit script pour **renommer un tag Memos en masse**.

Le script récupère les mémos, remplace le tag demandé, puis réenregistre les mémos via l'API Memos.

## Prérequis

* Docker
* Memos en fonctionnement
* Un token API Memos dans `MEMOS_TOKEN`

```bash
export MEMOS_TOKEN="votre-token"
```

## Utilisation

```bash
./rename-tags.sh '#ancien-tag' '#nouveau-tag'
```

### Exemple

Renommer `#elec` en `#ELEC` :

```bash
./rename-tags.sh '#elec' '#ELEC'
```

Le script affiche les mémos modifiés :

```text
Tag : #elec → #ELEC
36 mémos trouvés
OK  memos/A83ZwcfDr6kWqpPvQEc8Ns
OK  memos/kYzAemuC4qZ9FBwbwSC6mf
...
```

## Fichiers

```text
.
├── README.md
├── rename-tags.py
└── rename-tags.sh
```

Le script utilise un conteneur Python temporaire et communique directement avec Memos via le réseau Docker `memos_memos`.

Aucune installation Python n'est nécessaire sur l'hôte.

