# Monitoring & Incident Management Platform

A production-style observability and incident management platform built using Prometheus, Grafana, Alertmanager, Node Exporter, Docker, and Node.js.

The platform enables real-time monitoring of infrastructure and application health, proactive incident detection, SLA-focused alerting, and root cause analysis through automated observability workflows.

---

## Overview

Modern applications require continuous monitoring and rapid incident response to maintain reliability and performance. This project demonstrates how a complete monitoring and alerting stack can be deployed to observe system behavior, detect failures, and support operational troubleshooting.

The platform collects infrastructure and application metrics, visualizes them through Grafana dashboards, and generates alerts when predefined thresholds are breached.

---

## Key Features

* Real-time monitoring of infrastructure and application health
* CPU, memory, latency, and error-rate tracking
* Custom Prometheus metrics using a Node.js application
* SLA-focused alerting and incident detection
* Multi-severity alert classification
* Root cause analysis and troubleshooting workflows
* Grafana dashboards for operational visibility
* Containerized deployment using Docker
* Incident response runbooks for common production failures

---

## Technology Stack

### Monitoring & Observability

* Prometheus
* Grafana
* Alertmanager
* Node Exporter

### Backend

* Node.js
* Express.js

### Infrastructure

* Docker
* Docker Compose

### Alerting & Incident Management

* Prometheus Alert Rules
* Alertmanager Routing
* Incident Runbooks

---

## Architecture

```text
                 +----------------+
                 |   Node Exporter|
                 +--------+-------+
                          |
                          |
+------------+     +------+------+
| Node.js API|---->| Prometheus  |
+------------+     +------+------+
                          |
                          |
                 +--------+-------+
                 | Alertmanager   |
                 +--------+-------+
                          |
                          |
                 +--------+-------+
                 |   Grafana      |
                 +----------------+
```

---

## Metrics Collected

### Infrastructure Metrics

* CPU Utilization
* Memory Consumption
* Disk Usage
* System Load
* Host Availability

### Application Metrics

* Request Count
* Request Latency
* Error Rate
* Response Status Distribution
* Application Availability

---

## Alerting Strategy

The platform implements a multi-severity alerting model:

### Critical Alerts

* Service Down
* High Error Rate
* Extreme CPU Utilization

### Warning Alerts

* Elevated Memory Usage
* Increased Response Latency
* Resource Saturation

### Informational Alerts

* Operational Health Notifications
* Service Status Updates

Alert routing and inhibition policies are configured through Alertmanager to reduce alert fatigue and improve incident prioritization.

---

## Incident Management

The platform supports structured incident response through documented runbooks covering:

* CPU Spikes
* Memory Leaks
* API Latency Issues
* Service Downtime
* Infrastructure Resource Exhaustion

Each runbook includes:

1. Detection
2. Diagnosis
3. Root Cause Analysis
4. Resolution Steps
5. Validation Procedures

---

## Dashboard Capabilities

Grafana dashboards provide:

* Infrastructure Health Monitoring
* Application Performance Monitoring
* SLO Tracking
* Alert Status Visualization
* Resource Utilization Trends
* Operational KPI Monitoring

---

## Project Highlights

* Designed and deployed a containerized observability stack using Prometheus, Grafana, Alertmanager, and Node Exporter.
* Implemented 10+ custom Prometheus metrics for application monitoring.
* Created multiple Grafana dashboards for performance analysis and operational visibility.
* Configured 13 alert rules with severity-based escalation workflows.
* Developed incident response runbooks supporting troubleshooting and root cause analysis.
* Enabled SLA-focused monitoring and proactive issue detection.

---

## Getting Started

### Clone Repository

```bash
git clone https://github.com/vaibhavsingh7232/monitoring-incident-management-platform.git
cd monitoring-incident-management-platform
```

### Start Services

```bash
docker-compose up -d
```

### Access Components

| Component    | URL                   |
| ------------ | --------------------- |
| Grafana      | http://localhost:3000 |
| Prometheus   | http://localhost:9090 |
| Alertmanager | http://localhost:9093 |

---

## Future Enhancements

* Kubernetes Deployment
* Distributed Tracing with Jaeger
* Log Aggregation using Loki
* Automated Incident Ticket Creation
* Advanced SLO and Error Budget Tracking
* Cloud Deployment on AWS

---

## Author

**Vaibhav Singh**

Computer Science Undergraduate | Backend Engineering | Observability & Monitoring | Incident Management

GitHub: https://github.com/vaibhavsingh7232
