# Troubleshooting Guide
## Monitoring & Incident Management Platform

---

## 1. HOW TO INVESTIGATE ALERTS

### Step 1 — Acknowledge the Alert
- Go to **Alertmanager**: http://localhost:9093
- Identify alert name, severity, and affected instance
- Silence if maintenance is planned

### Step 2 — Open the Dashboard
| Alert | Dashboard |
|-------|-----------|
| HighCPUUsage | http://localhost:3001/d/infra |
| HighMemoryUsage | http://localhost:3001/d/infra |
| HighErrorRate | http://localhost:3001/d/app-perf |
| HighAPILatency | http://localhost:3001/d/app-perf |
| ApplicationDown | http://localhost:3001/d/slo |

### Step 3 — Check Prometheus directly
```
# Is the target up?
up{job="nodejs-app"}

# What is the current error rate?
sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# p95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

---

## 2. INCIDENT RUNBOOKS

### 🔥 INCIDENT: High CPU Usage

**Detection:** `app_cpu_usage_percent > 80` for 2 minutes

**Immediate triage:**
```bash
# Check container CPU
docker stats nodejs-app --no-stream

# Check running processes inside container
docker exec nodejs-app top -bn1

# Check recent logs for loops or errors
docker logs nodejs-app --tail=200 --since=10m
```

**Common root causes:**
- Infinite loop in code
- CPU-intensive computation without limits
- DDoS or traffic spike
- Runaway cron job

**Resolution:**
1. If traffic spike → scale horizontally: `docker compose up --scale app=3`
2. If code bug → redeploy previous version
3. If DDoS → rate-limit at nginx layer
4. Temporary: `docker restart nodejs-app`

---

### 💧 INCIDENT: Memory Leak

**Detection:** `deriv(app_memory_usage_bytes[10m]) > 0` sustained + high absolute usage

**Immediate triage:**
```bash
# Check memory
docker stats nodejs-app --no-stream --format "{{.MemUsage}}"

# Node.js heap stats
docker exec nodejs-app node -e "console.log(process.memoryUsage())"

# Application logs for OOM warnings
docker logs nodejs-app 2>&1 | grep -i "memory\|heap\|oom"
```

**Root cause analysis:**
```bash
# Attach Node.js inspector
docker exec nodejs-app node --inspect=0.0.0.0:9229 server.js
# Then: chrome://inspect in Chrome browser
# Take heap snapshots at t=0, t+5min, t+10min
# Compare retained objects between snapshots
```

**Common causes:**
- Event listeners not removed
- Closures holding references to large objects
- Global arrays/maps growing unbounded
- Caching without TTL or size limits

**Resolution:**
1. Restart immediately to restore service: `docker restart nodejs-app`
2. Set memory limit in docker-compose: `mem_limit: 512m`
3. Deploy fix after identifying leak source
4. Add `--max-old-space-size=400` to Node.js flags as guard

---

### 💥 INCIDENT: High Error Rate

**Detection:** HTTP 5xx rate > 5% for 2 minutes

**Immediate triage:**
```bash
# Real-time error logs
docker logs nodejs-app -f 2>&1 | grep -E "ERROR|error|500"

# Which routes are failing?
# Prometheus query:
# sum(rate(http_requests_total{status_code="500"}[5m])) by (route)

# Check dependencies
curl -s http://localhost:3000/api/db-check
curl -s http://localhost:3000/health
```

**Resolution:**
1. Identify failing route from Prometheus/Grafana
2. Check logs for stack traces
3. Test dependency connectivity (DB, external APIs)
4. Roll back recent deployment if correlated
5. Apply hotfix or feature flag to disable broken feature

---

### 🐢 INCIDENT: High API Latency

**Detection:** p95 latency > 1s for 3 minutes

**Immediate triage:**
```bash
# Which endpoint is slow?
# Prometheus: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) by (route)

# Check for upstream slowness
curl -w "@curl-format.txt" -s http://localhost:3000/api/orders

# Check DB query times
docker logs nodejs-app --since=5m | grep "latency\|slow\|timeout"
```

**Common causes:**
- N+1 database queries
- Missing database index
- External API timeout (no circuit breaker)
- Large payload serialization

**Resolution:**
1. Identify slow route from Grafana heatmap
2. Add DB query explain analyze
3. Add caching layer (Redis) for repeated queries
4. Implement circuit breaker for external calls
5. Add DB index if missing

---

### 🛑 INCIDENT: Application Down

**Detection:** `up{job="nodejs-app"} == 0` for 1 minute

**Immediate triage:**
```bash
# Is the container running?
docker ps | grep nodejs-app

# Container exit code and reason
docker inspect nodejs-app --format='{{.State.Status}} {{.State.ExitCode}}'

# Last 50 lines before crash
docker logs nodejs-app --tail=50

# Restart the service
docker compose restart app
```

**Resolution:**
1. Check exit code: 137 = OOM killed, 1 = crash, 0 = clean exit
2. Review logs for fatal error
3. Check disk space: `df -h`
4. Check for port conflict: `lsof -i :3000`
5. Restart: `docker compose up -d app`
6. Post-mortem after restoration

---

## 3. ROOT CAUSE ANALYSIS FRAMEWORK (5 Whys)

**Example: Application crash**
1. Why did the service go down? → Container OOM killed
2. Why was memory exhausted? → Memory leak in request handler
3. Why was there a memory leak? → Event listener added but never removed
4. Why wasn't it caught? → No memory trending alert existed
5. Why was the alert missing? → Monitoring gaps in sprint backlog

**Actions:** Fix listener cleanup + add MemoryLeakSuspected alert + add alert coverage to DoD

---

## 4. USEFUL COMMANDS CHEATSHEET

```bash
# View all services
docker compose ps

# Live logs (all services)
docker compose logs -f

# App logs only
docker logs nodejs-app -f

# Restart one service
docker compose restart app

# Reload Prometheus config (no restart)
curl -X POST http://localhost:9090/-/reload

# Check active alerts
curl -s http://localhost:9093/api/v2/alerts | jq '.[].labels.alertname'

# Prometheus query
curl -s "http://localhost:9090/api/v1/query?query=up" | jq '.data.result'

# Scale app
docker compose up -d --scale app=3

# Full teardown (preserve volumes)
docker compose down

# Full teardown (delete data)
docker compose down -v
```
