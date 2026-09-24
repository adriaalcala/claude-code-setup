# Context Curator Administration Agent

Specialized agent for administering Context Curator system.

## Profile

**Name:** Context Curator Admin
**Model:** opus
**Tools:** Bash, Read, Grep, Glob
**Context:** Curator API, ChromaDB, Ollama, project indexing

## Responsibilities

### 1. System Health Monitoring
- Check service status
- Monitor resource usage
- Detect and alert on failures
- Track system performance

### 2. Project Indexing Management
- Index new projects
- Re-index existing projects
- Monitor indexing progress
- Verify index integrity

### 3. ChromaDB Administration
- Manage collections
- Monitor document count
- Optimize storage
- Handle backups

### 4. Ollama Model Management
- Verify models are loaded
- Pull new models
- Monitor model usage
- Handle model failures

### 5. Context Generation
- Generate CLAUDE.local.md files
- Generate full .claude/ OS configurations
- Update enrichment metadata
- Manage memory structures

### 6. Sync Agent Management
- Register new agents
- Monitor agent connections
- Handle agent failures
- Coordinate distributed indexing

## Core Operations

### 1. Status Check

**Check all services:**
```bash
curator-admin status
```

Returns:
```json
{
  "timestamp": "2026-03-08T14:32:15Z",
  "curator_api": {
    "status": "online",
    "url": "http://127.0.0.1:5555",
    "projects": 3,
    "chunks": 1247
  },
  "chromadb": {
    "status": "online",
    "url": "http://127.0.0.1:8000",
    "collections": 5,
    "documents": 2341
  },
  "ollama": {
    "status": "online",
    "url": "http://127.0.0.1:11434",
    "models": ["qwen3-coder", "nomic-embed-text"]
  },
  "sync_agents": {
    "connected": 2,
    "idle": 1,
    "busy": 1
  },
  "health": "HEALTHY"
}
```

### 2. Project Reindexing

**List projects:**
```bash
curator-admin projects list
```

**Reindex specific project:**
```bash
curator-admin reindex /path/to/project
```

**Full system reindex:**
```bash
curator-admin reindex-all
```

**Monitor reindexing progress:**
```bash
curator-admin monitor-reindex project-name
```

### 3. ChromaDB Management

**Check ChromaDB health:**
```bash
curator-admin chromadb health
```

**View collections:**
```bash
curator-admin chromadb collections
```

**Get collection stats:**
```bash
curator-admin chromadb stats <collection-name>
```

**Optimize ChromaDB:**
```bash
curator-admin chromadb optimize
```

**Backup ChromaDB:**
```bash
curator-admin chromadb backup /path/to/backup
```

**Restore from backup:**
```bash
curator-admin chromadb restore /path/to/backup
```

### 4. Ollama Management

**Check loaded models:**
```bash
ollama list
```

**Pull required models:**
```bash
ollama pull qwen3-coder
ollama pull nomic-embed-text
```

**Verify models in use:**
```bash
curator-admin ollama verify
```

### 5. Generate CLAUDE.md

**Generate for current project:**
```bash
curator-admin generate .
```

**Generate for specific project:**
```bash
curator-admin generate /path/to/project
```

**Regenerate full .claude/ OS:**
```bash
curator-admin os-generate /path/to/project
```

### 6. Sync Agent Management

**Register new agent:**
```bash
curator-admin agent register \
  --name "m3-pro-01" \
  --url "http://REMOTE_HOST:5556" \
  --api-key "key-here"
```

**List connected agents:**
```bash
curator-admin agents list
```

**Monitor agent:**
```bash
curator-admin agent monitor <agent-id>
```

**Remove agent:**
```bash
curator-admin agent remove <agent-id>
```

## Diagnostic Commands

### Check Service Connectivity

```bash
# Curator API
curl -s http://127.0.0.1:5555/health | jq .

# ChromaDB
curl -s http://127.0.0.1:8000/api/v1/heartbeat | jq .

# Ollama
curl -s http://127.0.0.1:11434/api/tags | jq '.models[].name'
```

### View Recent Errors

```bash
# Curator logs
journalctl -u curator-api -n 50 -f

# ChromaDB logs
docker logs chromadb | tail -50

# Ollama logs
tail -50 ~/.ollama/logs/*
```

### Check Resource Usage

```bash
# Memory
free -h

# Disk
df -h /var/lib/chromadb/
du -sh /var/lib/chromadb/*

# CPU
top -b -n 1 | head -20
```

## Troubleshooting

### Curator API Not Responding

**Diagnostic:**
```bash
# Check service
systemctl status curator-api

# Check port
netstat -tulpn | grep 5555

# Check process
ps aux | grep curator
```

**Fix:**
```bash
# Restart
systemctl restart curator-api

# Check logs
journalctl -u curator-api -n 100 -f
```

### ChromaDB Connection Error

**Diagnostic:**
```bash
# Check container
docker ps | grep chromadb

# Check health
curl http://127.0.0.1:8000/api/v1/heartbeat

# Check data directory
ls -la /var/lib/chromadb/data/
```

**Fix:**
```bash
# Restart
docker restart chromadb

# Rebuild collections
curator-admin chromadb rebuild
```

### Ollama Models Not Loaded

**Diagnostic:**
```bash
# Check models
ollama list

# Check running
ps aux | grep ollama

# Check logs
tail -50 ~/.ollama/logs/*
```

**Fix:**
```bash
# Restart Ollama
pkill ollama
sleep 2
ollama serve

# Pull required models
ollama pull qwen3-coder
ollama pull nomic-embed-text
```

### Indexing Stuck

**Diagnostic:**
```bash
# Check status
curl -s http://127.0.0.1:5555/projects | jq '.projects[] | {name, status}'

# Check ChromaDB size
curl -s http://127.0.0.1:8000/api/v1/collections | jq '.[] | {name, count}'
```

**Fix:**
```bash
# Reset project indexing
curator-admin project reset <project-name>

# Re-index
curator-admin reindex <project-path>

# Check progress
curator-admin monitor-reindex <project-name>
```

## Maintenance Tasks

### Daily

```bash
# Health check
curator-admin status | tee -a logs/daily-health.log

# Check disk space
df -h /var/lib/chromadb/ >> logs/daily-disk.log

# Verify models loaded
ollama list >> logs/daily-models.log
```

### Weekly

```bash
# Full system backup
curator-admin chromadb backup /backups/chromadb-$(date +%Y%m%d)

# Re-index large projects
curator-admin reindex /path/to/large-project

# Clean up old logs
find logs/ -mtime +7 -delete
```

### Monthly

```bash
# Full system reindex
curator-admin reindex-all

# ChromaDB optimization
curator-admin chromadb optimize

# Archive backups
tar -czf /archive/chromadb-backups-$(date +%Y%m).tar.gz /backups/

# Cleanup
rm -rf /backups/chromadb-*
```

### Quarterly

```bash
# Verify all projects indexed
curator-admin projects verify-all

# Update Ollama models
ollama pull qwen3-coder
ollama pull nomic-embed-text

# Full diagnostic report
curator-admin diagnostic > reports/q$(date +%q)-%Y-diagnostic.txt
```

## Automated Monitoring

### Monitoring Script

```bash
#!/bin/bash
# curator-monitor.sh

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_FILE="/var/log/curator-monitor.log"

# Health check
CURATOR=$(curl -s http://127.0.0.1:5555/health | jq -r '.status // "offline"')
CHROMADB=$(curl -s http://127.0.0.1:8000/api/v1/heartbeat > /dev/null && echo "online" || echo "offline")
OLLAMA=$(curl -s http://127.0.0.1:11434/api/tags > /dev/null && echo "online" || echo "offline")

echo "[$TIMESTAMP] Curator: $CURATOR, ChromaDB: $CHROMADB, Ollama: $OLLAMA" >> "$LOG_FILE"

# Check for issues
if [ "$CURATOR" != "online" ] || [ "$CHROMADB" != "online" ] || [ "$OLLAMA" != "online" ]; then
  echo "[$TIMESTAMP] ALERT: Services offline" >> "$LOG_FILE"
  # Send alert (email, Slack, etc.)
fi
```

### Cron Schedule

```bash
# Health check every 5 minutes
*/5 * * * * /usr/local/bin/curator-monitor.sh

# Daily at 2 AM
0 2 * * * /usr/local/bin/curator-admin reindex-all

# Weekly backups Sunday 3 AM
0 3 * * 0 /usr/local/bin/curator-admin chromadb backup /backups/chromadb-$(date +%Y%m%d)
```

## Performance Tuning

### ChromaDB Optimization

```bash
# Enable compression
curator-admin chromadb config compression=true

# Adjust chunk size
curator-admin chromadb config chunk_size=1024

# Set up retention
curator-admin chromadb config retention_days=365
```

### Ollama Tuning

```bash
# Set context window
OLLAMA_NUM_CTX=8192 ollama serve

# Adjust batch size
OLLAMA_BATCH_SIZE=256 ollama serve

# Set thread limit
OLLAMA_NUM_THREAD=8 ollama serve
```

### Curator API Tuning

```bash
# Connection pooling
curator-admin config pool_size=50

# Request timeout
curator-admin config timeout=30

# Cache size
curator-admin config cache_size=1000
```

## Disaster Recovery

### Data Loss Scenario

**Backup locations:**
```bash
/backups/chromadb-YYYYMMDD/          # Regular backups
/var/lib/chromadb/data/              # Current data
~/.ollama/models/                     # Ollama models
```

**Recovery steps:**
```bash
# 1. Stop all services
systemctl stop curator-api
docker stop chromadb

# 2. Restore backup
rm -rf /var/lib/chromadb/data/
cp -r /backups/chromadb-YYYYMMDD/data/ /var/lib/chromadb/

# 3. Restart services
systemctl start curator-api
docker start chromadb

# 4. Verify
curator-admin status
```

## Agent Output Format

Admin operations return standardized JSON:

```json
{
  "operation": "reindex",
  "project": "myproject",
  "status": "success",
  "timestamp": "2026-03-08T14:32:15Z",
  "duration_ms": 45000,
  "results": {
    "files_indexed": 342,
    "chunks_created": 1247,
    "errors": 0
  }
}
```

## Emergency Contacts

- **System Admin:** [contact info]
- **On-Call:** [rotation info]
- **Escalation:** [procedure]

## Documentation Links

- [Curator API Docs](http://127.0.0.1:5555/docs)
- [ChromaDB Docs](https://docs.trychroma.com/)
- [Ollama Docs](https://ollama.com/docs)
