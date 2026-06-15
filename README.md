# 🚀 Monitoring & Incident Management Platform

> Production-grade observability platform built with Prometheus, Grafana, Alertmanager, Node Exporter, and Node.js — demonstrating real-world SRE, DevOps, and Cloud Operations practices.

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Docker Compose Network                       │
│                      (172.20.0.0/24)                            │
│                                                                  │
│   ┌──────────────┐    scrape     ┌──────────────────┐           │
│   │  Node.js App │◄──────────────│   Prometheus     │           │
│   │  :3000       │  /metrics     │   :9090          │           │
│   │  (custom     │               │  (TSDB, 30d ret) │           │
│   │   metrics)   │               └───────┬──────────┘           │
│   └──────────────┘                       │ evaluate rules        │
│                                          ▼                       │
│   ┌──────────────┐              ┌──────────────────┐            │
│   │ Node Exporter│◄─────────────│  Alertmanager    │            │
│   │  :9100       │  scrape      │  :9093           │            │
│   │  (CPU/Mem/   │              │  (routing,       │            │
│   │   Disk/Net)  │              │   silencing,     │            │
│   └──────────────┘              │   email alerts)  │            │
│                                 └──────────────────┘            │
│   ┌──────────────┐                       ▲                      │
│   │   Grafana    │───────────────────────┘                      │
│   │   :3001      │  datasource                                  │
│   │  (4 dashbds) │◄─── Prometheus                              │
│   └──────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
monitoring-platform/
├── app/
│   ├── server.js            # Node.js app with Prometheus metrics
│   ├── package.json
│   └── Dockerfile
├── prometheus/
│   ├── prometheus.yml       # Scrape configs, alertmanager integration
│   └── rules/
│       └── alerts.yml       # All alerting rules (infra + app)
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml
│       └── dashboards/
│           ├── dashboards.yml
│           ├── infrastructure.json   # Infra Health Dashboard
│           ├── application.json      # App Performance Dashboard
│           └── reliability.json      # SLO/SLA Dashboard
├── alertmanager/
│   └── alertmanager.yml     # Routing tree, receivers, inhibition
├── scripts/
│   ├── setup.sh             # One-command setup
│   └── simulate-incidents.sh # Incident scenarios
├── docs/
│   └── TROUBLESHOOTING.md   # Runbooks & investigation guide
└── docker-compose.yml       # Full orchestration
```

---

## ⚡ Quick Start

### Prerequisites
- Docker 24+ and Docker Compose v2
- 4GB RAM, 10GB disk
- Ports free: 3000, 3001, 9090, 9093, 9100

### 1. Clone & Start
```bash
git clone https://github.com/YOUR_USERNAME/monitoring-platform.git
cd monitoring-platform
chmod +x scripts/*.sh
./scripts/setup.sh
```

### 2. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3001 | admin / admin123 |
| **Prometheus** | http://localhost:9090 | — |
| **Alertmanager** | http://localhost:9093 | — |
| **Node.js App** | http://localhost:3000 | — |
| **App Metrics** | http://localhost:3000/metrics | — |
| **Node Exporter** | http://localhost:9100/metrics | — |

### 3. Simulate Incidents
```bash
./scripts/simulate-incidents.sh
```

---

## 📊 Dashboards

| Dashboard | UID | Description |
|-----------|-----|-------------|
| Infrastructure Health | `infra` | CPU, Memory, Disk, DB connections |
| Application Performance | `app-perf` | Latency, error rate, request volume, heatmap |
| Service Reliability | `slo` | SLO compliance, error budget, availability |

---

## 🚨 Alert Rules

| Alert | Condition | Severity | Channel |
|-------|-----------|----------|---------|
| HighCPUUsage | CPU > 80% for 2m | warning | sre-team |
| CriticalCPUUsage | CPU > 95% for 1m | critical | oncall |
| HighMemoryUsage | Heap > 85% for 5m | warning | sre-team |
| MemoryLeakSuspected | Continuous growth | critical | oncall |
| HighDiskUsage | Disk > 90% for 5m | critical | sre-team |
| HighErrorRate | 5xx > 5% for 2m | warning | backend |
| CriticalErrorRate | 5xx > 20% for 1m | critical | oncall |
| HighAPILatency | p95 > 1s for 3m | warning | backend |
| ApplicationDown | up == 0 for 1m | critical | oncall |
| DatabaseConnectionFailure | DB errors rate > 0 | critical | dba |

---

## 🎭 Incident Scenarios

### Scenario 1 — CPU Spike
```bash
curl -X POST http://localhost:3000/incident/cpu-spike
```
- **Detection:** `app_cpu_usage_percent > 80` → `HighCPUUsage` alert fires
- **Observe:** CPU gauge spikes red in Infrastructure Dashboard
- **RCA:** Simulated workload; in production → check for infinite loops, traffic surge
- **Fix:** Identify process, scale horizontally, deploy fix

### Scenario 2 — Memory Leak
```bash
curl -X POST http://localhost:3000/incident/memory-leak
```
- **Detection:** `MemoryLeakSuspected` fires after heap grows continuously
- **Observe:** Memory time-series shows upward slope with no dips
- **RCA:** Object retention, uncleaned event listeners
- **Fix:** Heap snapshot analysis, restart service, patch code

### Scenario 3 — High Error Rate
```bash
curl http://localhost:3000/api/error   # repeat many times
```
- **Detection:** `HighErrorRate` fires when 5xx > 5%
- **Observe:** Red bars in HTTP Status Code panel
- **RCA:** Check logs → `docker logs nodejs-app --tail=100`
- **Fix:** Fix code path, roll back deployment

### Scenario 4 — API Latency
```bash
curl http://localhost:3000/api/slow
```
- **Detection:** p95 histogram > 1s threshold
- **Observe:** Latency percentile chart separates p50/p95/p99
- **RCA:** Heatmap shows request distribution shifting right
- **Fix:** Add caching, optimize DB queries, circuit breaker

### Reset All
```bash
curl -X POST http://localhost:3000/incident/reset
```

---

## 🔧 Useful Commands

```bash
# Health check all services
docker compose ps

# Live logs
docker compose logs -f app

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload

# Active alerts
curl -s http://localhost:9093/api/v2/alerts | jq '.[].labels'

# Prometheus instant query
curl -s "http://localhost:9090/api/v1/query?query=app_cpu_usage_percent" | jq .

# Scale the app
docker compose up -d --scale app=3

# Tear down (keep data)
docker compose down

# Tear down + delete volumes
docker compose down -v
```

---

## 📧 Configure Real Email Alerts

Edit `alertmanager/alertmanager.yml`:
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@yourcompany.com'
  smtp_auth_username: 'your@gmail.com'
  smtp_auth_password: 'your-app-password'   # Gmail App Password
```

Then reload:
```bash
curl -X POST http://localhost:9093/-/reload
```

---

## 💼 Resume Description

**Monitoring & Incident Management Platform** | Personal Project | 2024

Built a production-grade observability and incident management platform simulating real-world SRE workflows. Designed and deployed a full monitoring stack using Docker Compose with Prometheus (metrics collection), Grafana (visualization), Alertmanager (alert routing), Node Exporter (system telemetry), and a custom Node.js application exposing 10+ Prometheus metrics including request latency histograms, error rates, active user gauges, and business KPIs. Created 3 professional Grafana dashboards with time-series charts, gauges, heatmaps, and SLO panels. Configured multi-severity alerting with 10 alert rules, smart inhibition logic, and role-based email routing. Implemented 5 realistic incident simulation scenarios (CPU spike, memory leak, error flood, latency spike, DB failure) with documented runbooks and root cause analysis procedures.

---

## 📄 ATS-Friendly Resume Bullets

- Designed and deployed a containerized observability stack (Prometheus, Grafana, Alertmanager, Node Exporter) using Docker Compose, achieving full-stack metrics coverage across infrastructure and application layers
- Instrumented a Node.js application with 10+ custom Prometheus metrics (request counters, latency histograms, error gauges) enabling real-time performance visibility and SLO tracking
- Built 3 Grafana dashboards featuring time-series charts, gauges, heatmaps, and alert status panels to visualize CPU, memory, latency, throughput, and error rate KPIs
- Configured multi-severity alert rules with smart inhibition logic and role-based routing in Alertmanager, reducing alert noise and ensuring correct on-call notification
- Created 5 production incident simulation scenarios (CPU spike, memory leak, high error rate, API latency degradation, DB failure) with documented detection methods, runbooks, and resolution procedures
- Authored comprehensive troubleshooting guide and operational runbooks covering root cause analysis, log investigation, Prometheus query patterns, and service recovery steps

---

## 🎤 Interview Q&A

**Q1: What is the difference between metrics, logs, and traces?**
> Metrics are numeric time-series measurements (e.g., CPU %). Logs are discrete, timestamped text events. Traces are end-to-end request flows across services. Together they form the "three pillars of observability." This project uses Prometheus for metrics and Winston for structured logging.

**Q2: How does Prometheus collect data?**
> Prometheus uses a pull model — it scrapes HTTP `/metrics` endpoints on targets at a defined interval (15s here). This is unlike push-based systems. Targets are configured in `prometheus.yml` and can be static or discovered dynamically via service discovery (Kubernetes, Consul, etc.).

**Q3: What is an SLO and how does it relate to error budgets?**
> An SLO (Service Level Objective) is a target reliability goal, e.g., 99.9% availability. An error budget is the allowed amount of downtime/errors before the SLO is breached: 0.1% of requests can fail. In this project, the SLO dashboard tracks both, enabling teams to make release decisions based on budget remaining.

**Q4: What are Prometheus histograms and why are they better than averages for latency?**
> Histograms count observations in configurable buckets and allow computing percentiles (p50, p95, p99) via `histogram_quantile()`. Averages hide tail latency — a 1s average could mask 10% of users seeing 5s responses. Percentiles expose the true user experience distribution.

**Q5: How does Alertmanager deduplication and inhibition work?**
> Alertmanager groups related alerts by `group_by` labels, waits `group_wait` before sending the first notification, then uses `group_interval` for subsequent grouped notifications. Inhibition suppresses lower-severity alerts when a higher-severity alert for the same instance is already firing — preventing alert storms during major incidents.

**Q6: What is the difference between `rate()` and `irate()` in Prometheus?**
> `rate()` computes the per-second average over a time window (smoothed, good for dashboards). `irate()` uses only the last two data points (more responsive, but spiky — good for alerting on sudden changes). For error rate alerting, `rate()` over 5m avoids false positives from brief spikes.

**Q7: How would you investigate an OOM (Out of Memory) crash?**
> Check `docker inspect` for exit code 137 (OOM kill). Review memory metrics trending in Grafana. Take heap snapshots before the next occurrence using `--inspect` flag. Compare snapshots using Chrome DevTools Memory profiler to identify retained objects. Common culprits: unbounded caches, event listener accumulation, large buffer allocations.

**Q8: Describe your on-call incident response process.**
> (1) Receive alert → acknowledge in Alertmanager. (2) Check dashboard to understand scope and affected services. (3) Follow runbook for the specific alert. (4) Communicate status to stakeholders. (5) Mitigate (restart, scale, rollback). (6) Resolve root cause. (7) Write post-mortem with timeline, RCA, and action items.

---

## 📜 License

MIT License — free to use, fork, and include in your portfolio.

---

*Built to demonstrate production-level observability engineering for SRE, DevOps, and Cloud Operations roles.*
