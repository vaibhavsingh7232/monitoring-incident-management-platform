#!/bin/bash
# ─────────────────────────────────────────────────────
# SETUP SCRIPT — Monitoring & Incident Management Platform
# ─────────────────────────────────────────────────────

set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

echo -e "\n${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Monitoring & Incident Management Platform   ║${NC}"
echo -e "${BLUE}║  Setup Script v1.0                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}\n"

# Check prerequisites
info "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { err "Docker not installed. Install from https://docs.docker.com/get-docker/"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || command -v "docker compose" >/dev/null 2>&1 || { err "Docker Compose not found"; exit 1; }
command -v curl >/dev/null 2>&1 || { warn "curl not installed — health checks will be skipped"; }
log "Prerequisites satisfied"

# Create runtime directories
info "Creating runtime directories..."
mkdir -p prometheus/rules
mkdir -p grafana/provisioning/{datasources,dashboards}
mkdir -p logs
chmod +x scripts/*.sh 2>/dev/null || true
log "Directories ready"

# Build and start
info "Building and starting all services..."
docker compose up -d --build

# Wait for services
info "Waiting for services to start (60s)..."
sleep 20

wait_for_service() {
  local name=$1
  local url=$2
  local max=30
  for i in $(seq 1 $max); do
    if curl -sf "$url" >/dev/null 2>&1; then
      log "$name is ready"
      return 0
    fi
    echo -n "."
    sleep 2
  done
  warn "$name may not be ready yet — check 'docker compose logs $name'"
}

wait_for_service "Node.js App"    "http://localhost:3000/health"
wait_for_service "Prometheus"     "http://localhost:9090/-/healthy"
wait_for_service "Grafana"        "http://localhost:3001/api/health"
wait_for_service "Alertmanager"   "http://localhost:9093/-/healthy"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Platform is UP and RUNNING!               ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  📊 Grafana:        ${BLUE}http://localhost:3001${NC}  (admin/admin123)"
echo -e "  📈 Prometheus:     ${BLUE}http://localhost:9090${NC}"
echo -e "  🔔 Alertmanager:   ${BLUE}http://localhost:9093${NC}"
echo -e "  🚀 App:            ${BLUE}http://localhost:3000${NC}"
echo -e "  📉 App Metrics:    ${BLUE}http://localhost:3000/metrics${NC}"
echo -e "  🖥️  Node Exporter:  ${BLUE}http://localhost:9100/metrics${NC}"
echo ""
echo -e "  Run incidents:     ${YELLOW}./scripts/simulate-incidents.sh${NC}"
echo -e "  View logs:         ${YELLOW}docker compose logs -f${NC}"
echo -e "  Stop platform:     ${YELLOW}docker compose down${NC}"
echo ""
