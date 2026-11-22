# Homelab Stacks

Self-hosted Docker Compose infrastructure organized into three modular stacks (`network`, `observe`, `apps`).

Each stack follows the same convention:
- A single root `.env` file (ignored by Git) centralizing versions, hostnames, paths, and secrets.
- A root `docker-compose.yml` using Docker Compose's native `include:` directive to orchestrate each service subfolder.
- All persistent runtime data stored outside the repository under `${DATA_DIR}` (default `/data`).

---

## Architecture

```text
.
├── network/   # Core infrastructure (DNS, VPN, Dynamic DNS, Reverse Proxy)
├── observe/   # Observability (Metrics, Logs, Dashboards & Exporters)
└── apps/      # User-facing self-hosted applications
```

### `network/` — Core Infrastructure
| Service | Role |
| --- | --- |
| **Traefik** | HTTPS reverse proxy with automatic Let's Encrypt TLS (OVH DNS-01) |
| **dnsdist** | Front-end DNS router/filter (Do53, split-horizon, CDB blocklist) |
| **PowerDNS Recursor** | Upstream recursive DNS resolver (`:5301`) |
| **DNS-collector** | `dnstap` collector, query logger, and Prometheus metrics exporter |
| **WireGuard** | VPN server for remote access to homelab subnets and internal DNS |
| **PublicAddr** | OVHcloud Dynamic DNS updater |

### `observe/` — Observability
| Service | Role |
| --- | --- |
| **Prometheus** | Time-series metrics scraping and storage (`:9091`) |
| **Grafana** | Metrics/logs dashboards and exploration (`:3000`) |
| **Loki** | Log aggregation and LogQL querying (`:3100`) |
| **Linky TIC Exporter** | Electricity consumption metrics from USB Linky TIC serial adapter (`:9100`) |
| **Tempus Exporter** | Calendar, ephemeris, public holidays, trash & birthday metrics (`:9101`) |

### `apps/` — Applications
| Service | Role |
| --- | --- |
| **Calibre-Web** | eBook library browser and reader |
| **CDN** | Lightweight Nginx static file server |
| **Dufs** | Web file server with per-user access control |
| **FamilyTimeline** | Self-hosted family timeline web app |
| **FreshRSS** | RSS/Atom feed aggregator |
| **Gonic & Airsonic-Refix** | Subsonic-compatible music streaming server & web player |
| **Immich** | Photo and video management with local ML |
| **Jellyfin** | Media server with AMD VAAPI/ROCm hardware transcoding |
| **LazyDocs** | Document organizer with local LLM classification (Kev) |
| **LinkTower** | Automated media download manager |
| **Mealie** | Recipe manager and meal planner |
| **Memos** | Lightweight note-taking service |
| **MeTube** | Web GUI for `yt-dlp` |
| **SCI-Compta** | Real-estate accounting web app (FastAPI + PostgreSQL) |
| **Thingport** | 3D model library manager |
| **Vaultwarden** | Bitwarden-compatible password manager |

---

## Prerequisites

- Docker Engine & Docker Compose **v2.20+** (required for `include:`)
- Shared external reverse-proxy network:
  ```bash
  docker network create traefik_proxy
  ```
- Host sysctl for Immich Valkey/Redis stability:
  ```bash
  sudo sysctl -w vm.overcommit_memory=1
  ```
- Configure each stack's `.env` file (`network/.env`, `observe/.env`, `apps/.env`) and ensure `${DATA_DIR}` (default `/data`) exists with appropriate ownership.

---

## Deployment

Start the stacks in order (`network` → `observe` → `apps`):

```bash
# 1. Core networking & reverse proxy
cd network && docker compose up -d

# 2. Observability stack
cd ../observe && docker compose up -d

# 3. Applications (build custom Jellyfin image on first run)
cd ../apps && docker compose up -d --build
```

### Common Operations

```bash
# Start or restart a single service inside a stack
cd apps && docker compose up -d vaultwarden

# Pull updated images and recreate changed containers
docker compose pull && docker compose up -d

# Check status across a stack
docker compose ps

# Validate merged Compose config
docker compose config --quiet
```

---

## Storage Notes

Persistent application data lives under `/data` (separated from this Git repository).

For USB external media disks mounted under `/data/medias/external_disks/`, you can use `udev` + `systemd` automount units:

```bash
# 1. Identify the disk UUID
sudo blkid

# 2. Trigger systemd mount unit on USB plug-in (/etc/udev/rules.d/99-custom-mount.rules)
ACTION=="add", KERNEL=="sd[a-z][0-9]*", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="<DISK_UUID>", ENV{SYSTEMD_WANTS}="data-medias-external_disks-dock_disk1.mount"

# 3. Define mount unit (/etc/systemd/system/data-medias-external_disks-dock_disk1.mount)
[Unit]
Description=Mount external USB disk

[Mount]
What=/dev/disk/by-uuid/<DISK_UUID>
Where=/data/medias/external_disks/dock_disk1
Type=auto
Options=noauto,nofail,uid=1000,gid=1000
```
