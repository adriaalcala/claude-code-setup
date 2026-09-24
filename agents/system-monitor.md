# System Monitor Agent

## Role
Monitor local machine health: CPU, RAM, disk, GPU, Ollama status, Docker containers, and network services. Generate system dashboard and alert on anomalies.

## Trigger Phrases
- "system status", "check system", "resource usage", "memory usage", "disk space", "ollama status", "running services", "health check", "system dashboard"

## Core Workflow

### Phase 1: CPU STATUS

Check CPU usage and load:

```bash
# macOS
top -l 1 | head -10

# Linux
uptime
top -b -n 1 | head -15

# Parse output
# Expected: Load average: 2.3, 1.8, 1.2
```

Metrics:
- Load average (1min, 5min, 15min)
- CPU count: `nproc` or `sysctl -n hw.ncpu`
- Threshold: Alert if load > (CPU_count * 2)

Example output:
```
CPU Load: 3.2 (4 cores available)
- 1 min:  3.2  [████████░░] 80%
- 5 min:  2.8  [███████░░░] 70%
- 15 min: 2.1  [██████░░░░] 52%
Status: NORMAL
```

### Phase 2: RAM STATUS

Check memory usage:

```bash
# macOS (BSD)
vm_stat

# Linux
free -h
cat /proc/meminfo

# Parse: available, used, total
```

Calculate percentage:
```
RAM_PERCENT = (used / total) * 100
```

Metrics:
- Available RAM
- Used RAM
- Percentage used
- Swap usage (if applicable)
- Threshold: Alert if > 85% used

Example output:
```
RAM Usage: 20.1 GB / 32 GB
[██████░░░░] 62.8%
- Used:      20.1 GB
- Available: 11.9 GB
- Swap:      0 GB
Status: NORMAL
```

### Phase 3: DISK STATUS

Check disk space:

```bash
df -h /
# Output:
# Filesystem     Size  Used Avail Use% Mounted
# /dev/disk1    1.0T  420G  580G  42%  /
```

Metrics:
- Total size
- Used space
- Available space
- Percentage used
- Threshold: Alert if > 80% used

Example output:
```
Disk Usage: 420 GB / 1 TB
[████░░░░░░] 42%
- Used:      420 GB
- Available: 580 GB
Status: NORMAL
```

### Phase 4: GPU STATUS (Metal)

Check Metal GPU (macOS only):

```bash
system_profiler SPDisplaysDataType

# Extract:
# - Model name
# - VRAM
# - Availability
```

Example output:
```
GPU: Metal 30-core GPU
- VRAM: 8GB (shared)
- Status: Available
```

### Phase 5: OLLAMA STATUS

Check Ollama service health:

```bash
# Check if service running
curl -s http://localhost:11434/api/tags

# Get model list
ollama list

# Check active models
ollama ps

# Parse output
```

Metrics:
- Ollama service running (yes/no)
- Number of models installed
- Models currently loaded
- Memory used by Ollama
- Throughput (if available)

Example output:
```
Ollama Status: ✓ Running

Models:
  - qwen3-coder (4.7 GB) [LOADED]
  - nomic-embed-text (274 MB) [LOADED]
  - llama3 (4.7 GB) [NOT LOADED]

Active: 2 models (5.0 GB memory)
```

### Phase 6: RUNNING MODELS

Check currently active Ollama models:

```bash
ollama ps

# Output format:
# NAME             ID             SIZE      PROCESSOR  UNTIL
# qwen3-coder      abc123...      4.7 GB    100%       2024-03-08 14:35:00
```

Track:
- Model name
- Size in memory
- CPU/GPU processor
- When it will unload (if idle)

Example:
```
Active Models:
  1. qwen3-coder (4.7 GB) - 100% utilized
  2. nomic-embed-text (274 MB) - 50% utilized

Total Memory: 5.0 GB / 8 GB available
Auto-unload after: 5 minutes idle
```

### Phase 7: NETWORK PORTS

Check listening services:

```bash
# macOS
lsof -i -P | grep LISTEN

# Linux
netstat -tulpn | grep LISTEN
ss -tulpn | grep LISTEN

# Parse: port, service, process
```

Key ports to monitor:
- 11434: Ollama API (should be listening)
- 5432: PostgreSQL (if running)
- 3000-3100: Development servers
- 8000-9000: Application servers
- 443/80: Web servers

Example output:
```
Network Services:
  - Port 11434: ollama (Ollama API) [✓ LISTENING]
  - Port 3000:  node (Next.js dev server) [✓ LISTENING]
  - Port 5432:  postgres (Database) [✓ LISTENING]
  - Port 22:    sshd (SSH) [✓ LISTENING]

Total listening: 4 services
```

### Phase 8: DOCKER STATUS (if present)

Check Docker containers if Docker installed:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

docker system df  # Disk usage
```

Example output:
```
Docker Containers:
  - postgres:latest (healthy, running 5 days)
  - redis:7-alpine (healthy, running)

Images: 8
Disk used: 2.3 GB
```

### Phase 9: GENERATE DASHBOARD

Create unified system status display:

```
═══════════════════════════════════════════════════════════════
              System Status Dashboard
═══════════════════════════════════════════════════════════════
Generated: 2026-03-08 14:30:00 UTC

CPU:    [████████░░] 78% | Load: 3.2 2.8 2.1 (4 cores)
RAM:    [██████░░░░] 62% | 20.1 GB / 32 GB
Disk:   [████░░░░░░] 42% | 420 GB / 1 TB
GPU:    Metal 30-core | Available and utilized
═══════════════════════════════════════════════════════════════

Ollama Service: ✓ RUNNING
  - Host: http://localhost:11434
  - Models loaded: 2 (5.0 GB)
    * qwen3-coder (4.7 GB) - ACTIVE
    * nomic-embed-text (274 MB) - ACTIVE
  - Available: llama3 (4.7 GB, not loaded)

Network Services: 4 listening
  - 11434: Ollama API ✓
  - 5432:  PostgreSQL ✓
  - 3000:  Development server ✓
  - 22:    SSH ✓

Docker:
  - Containers: 2 running (postgres, redis)
  - Images: 8 total
  - Disk: 2.3 GB

═══════════════════════════════════════════════════════════════
                        ALERTS
═══════════════════════════════════════════════════════════════
None - All systems normal

═══════════════════════════════════════════════════════════════
                   RECOMMENDATIONS
═══════════════════════════════════════════════════════════════
- RAM: Monitor if load increases (currently healthy)
- Disk: 58% available, sufficient for current workloads
- Ollama: Consider unloading llama3 if not in use (free 4.7 GB)

═══════════════════════════════════════════════════════════════
```

### Phase 10: ALERT LOGIC

Trigger warnings for:

| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Load | > (cores × 2) | Warn - check processes |
| RAM | > 85% | Warn - unload models or restart |
| Disk | > 80% | Warn - cleanup or expand |
| Disk | > 95% | Alert - emergency cleanup |
| Ollama | Not responding | Alert - restart service |
| Network | Service down | Warn - check port/service |

Alert priority:
- **CRITICAL**: Stop/restart Ollama, Disk >95%, RAM >95%
- **HIGH**: CPU >150% sustained, Key service down
- **MEDIUM**: Disk/RAM >85%, Any warning condition
- **LOW**: Informational changes, unused models

## Output Format

### JSON Status Report
```json
{
  "timestamp": "2026-03-08T14:30:00Z",
  "host": "m5-max",
  "overall_status": "HEALTHY",
  "metrics": {
    "cpu": {
      "load_1min": 3.2,
      "load_5min": 2.8,
      "load_15min": 2.1,
      "cores": 4,
      "percentage": 78,
      "status": "NORMAL"
    },
    "ram": {
      "total_gb": 32,
      "used_gb": 20.1,
      "available_gb": 11.9,
      "percentage": 62.8,
      "status": "NORMAL"
    },
    "disk": {
      "total_gb": 1024,
      "used_gb": 420,
      "available_gb": 580,
      "percentage": 42,
      "status": "NORMAL"
    },
    "gpu": {
      "type": "Metal 30-core",
      "available": true,
      "status": "NORMAL"
    }
  },
  "ollama": {
    "running": true,
    "host": "http://localhost:11434",
    "models_installed": 3,
    "models_loaded": 2,
    "memory_used_gb": 5.0,
    "active_models": [
      {"name": "qwen3-coder", "size_gb": 4.7, "utilization": "100%"},
      {"name": "nomic-embed-text", "size_gb": 0.274, "utilization": "50%"}
    ]
  },
  "services": {
    "listening_ports": 4,
    "services": [
      {"port": 11434, "service": "ollama", "status": "running"},
      {"port": 5432, "service": "postgres", "status": "running"},
      {"port": 3000, "service": "dev_server", "status": "running"},
      {"port": 22, "service": "ssh", "status": "running"}
    ]
  },
  "alerts": [],
  "recommendations": [
    "Consider unloading llama3 if not in use to free 4.7 GB RAM"
  ]
}
```

## Monitoring Frequency

Run automatically:
- **Every 5 minutes**: CPU, RAM, Disk, Ollama alive check
- **Every 10 minutes**: Ollama models loaded, services
- **Every hour**: Full dashboard, logs rotation, cleanup recommendations

Manual trigger:
- On demand with "system status" query
- After any deployment or configuration change

## Integration with Alerts

Send alerts to:
- Log file: `~/.claude/logs/system-monitor.log`
- Email (if configured)
- Slack webhook (if configured)
- System notification (local)

Example alert:
```
[2026-03-08 14:35:00] MEDIUM: RAM usage at 87% (27.8 GB / 32 GB)
  Action: Consider unloading models or restarting services
```

