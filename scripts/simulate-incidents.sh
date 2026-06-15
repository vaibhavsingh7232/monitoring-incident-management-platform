#!/bin/bash
# ─────────────────────────────────────────────────────
# INCIDENT SIMULATION SCRIPT
# Triggers realistic production incidents for testing
# ─────────────────────────────────────────────────────

APP_URL="http://localhost:3000"
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

banner() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# ─────────────────────────────────────
# INCIDENT 1: CPU SPIKE
# ─────────────────────────────────────
simulate_cpu_spike() {
  banner "INCIDENT 1: CPU Spike Simulation"
  echo -e "${YELLOW}⚡ Triggering CPU spike...${NC}"
  
  RESPONSE=$(curl -s -X POST "$APP_URL/incident/cpu-spike")
  echo -e "${RED}🔥 CPU Spike STARTED: $RESPONSE${NC}"
  
  echo ""
  echo "Detection Method:"
  echo "  → Prometheus scrapes app_cpu_usage_percent every 15s"
  echo "  → Alert fires when CPU > 80% for 2 minutes"
  echo "  → Alertmanager routes to sre-team@yourcompany.com"
  echo ""
  echo "Dashboard: http://localhost:3001/d/infra"
  echo "Alert:     HighCPUUsage / CriticalCPUUsage"
  echo "Duration:  2 minutes"
  echo ""
  echo "Resolution Steps:"
  echo "  1. Check top processes: docker exec nodejs-app top"
  echo "  2. Review recent deployments"
  echo "  3. Check for infinite loops in application logs"
  echo "  4. Consider horizontal scaling or restarting pod"
}

# ─────────────────────────────────────
# INCIDENT 2: MEMORY LEAK
# ─────────────────────────────────────
simulate_memory_leak() {
  banner "INCIDENT 2: Memory Leak Simulation"
  echo -e "${YELLOW}💧 Triggering memory leak...${NC}"
  
  RESPONSE=$(curl -s -X POST "$APP_URL/incident/memory-leak")
  echo -e "${RED}🔥 Memory Leak STARTED: $RESPONSE${NC}"
  
  echo ""
  echo "Detection Method:"
  echo "  → app_memory_usage_bytes{type='heap'} increases continuously"
  echo "  → deriv() function detects upward trend over 10m"
  echo "  → Alert: MemoryLeakSuspected fires"
  echo ""
  echo "Root Cause Analysis:"
  echo "  1. Take heap snapshot: node --inspect server.js"
  echo "  2. Use Chrome DevTools → Memory → Take Snapshot"
  echo "  3. Compare snapshots to find growing objects"
  echo "  4. Look for event listeners not being cleaned up"
  echo ""
  echo "Resolution:"
  echo "  1. Identify the leaking object/closure"
  echo "  2. Add proper cleanup in component unmount / request end"
  echo "  3. Restart service temporarily while fix is deployed"
  echo "  4. Set --max-old-space-size as safety net"
}

# ─────────────────────────────────────
# INCIDENT 3: HIGH ERROR RATE
# ─────────────────────────────────────
simulate_high_errors() {
  banner "INCIDENT 3: High Error Rate Simulation"
  echo -e "${YELLOW}💥 Generating 5xx errors...${NC}"
  
  for i in $(seq 1 50); do
    curl -s "$APP_URL/api/error" > /dev/null
    curl -s "$APP_URL/api/nonexistent" > /dev/null
    sleep 0.2
  done
  
  echo -e "${RED}🔥 Error flood complete (50 errors generated)${NC}"
  echo ""
  echo "Detection:"
  echo "  → http_requests_total{status_code=~'5..'} rate increases"
  echo "  → Alert: HighErrorRate fires when >5% for 2 min"
  echo ""
  echo "Investigation Steps:"
  echo "  1. Check logs: docker logs nodejs-app --tail=100"
  echo "  2. Query Prometheus: rate(http_requests_total{status_code='500'}[5m])"
  echo "  3. Check which routes are failing by route label"
  echo "  4. Review recent code changes / deployments"
}

# ─────────────────────────────────────
# INCIDENT 4: API LATENCY SPIKE
# ─────────────────────────────────────
simulate_latency_spike() {
  banner "INCIDENT 4: High API Latency Simulation"
  echo -e "${YELLOW}🐢 Triggering slow API requests...${NC}"
  
  for i in $(seq 1 10); do
    curl -s "$APP_URL/api/slow" &
  done
  wait
  
  echo -e "${RED}🔥 Latency simulation complete (10 slow requests)${NC}"
  echo ""
  echo "Detection:"
  echo "  → histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1s"
  echo "  → Alert: HighAPILatency fires"
  echo ""
  echo "Root Cause:"
  echo "  → Check: N+1 DB queries, external API timeouts, missing indexes"
  echo "  → Use: Distributed tracing (Jaeger/Zipkin) to find bottleneck"
  echo "  → Prometheus: http_request_duration_seconds by route label"
}

# ─────────────────────────────────────
# INCIDENT 5: TRAFFIC LOAD TEST
# ─────────────────────────────────────
simulate_traffic() {
  banner "INCIDENT 5: Traffic Load Test"
  echo -e "${YELLOW}🚦 Generating realistic traffic...${NC}"
  
  for i in $(seq 1 200); do
    ENDPOINTS=("/health" "/api/users" "/api/orders" "/api/db-check" "/api/error" "/nonexistent")
    ENDPOINT=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
    curl -s "$APP_URL$ENDPOINT" > /dev/null &
    if [ $((i % 20)) -eq 0 ]; then
      wait
      echo "  Sent $i requests..."
    fi
  done
  wait
  
  echo -e "${GREEN}✅ Load test complete (200 requests)${NC}"
  echo "Check Grafana: http://localhost:3001/d/app-perf"
}

# ─────────────────────────────────────
# RESET ALL INCIDENTS
# ─────────────────────────────────────
reset_incidents() {
  banner "RESET: Restoring Normal Operations"
  RESPONSE=$(curl -s -X POST "$APP_URL/incident/reset")
  echo -e "${GREEN}✅ Reset complete: $RESPONSE${NC}"
}

# ─────────────────────────────────────
# MENU
# ─────────────────────────────────────
echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Monitoring Platform - Incident Simulator  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}\n"

echo "Select incident to simulate:"
echo "  1) CPU Spike"
echo "  2) Memory Leak"
echo "  3) High Error Rate"
echo "  4) API Latency Spike"
echo "  5) Traffic Load Test"
echo "  6) Reset All"
echo "  7) Run All (Demo Mode)"
echo ""

read -p "Enter choice [1-7]: " choice

case $choice in
  1) simulate_cpu_spike ;;
  2) simulate_memory_leak ;;
  3) simulate_high_errors ;;
  4) simulate_latency_spike ;;
  5) simulate_traffic ;;
  6) reset_incidents ;;
  7)
    simulate_traffic
    simulate_high_errors
    simulate_latency_spike
    simulate_cpu_spike
    simulate_memory_leak
    echo -e "\n${GREEN}✅ Full demo complete! Check Grafana at http://localhost:3001${NC}"
    ;;
  *) echo "Invalid choice" ;;
esac
