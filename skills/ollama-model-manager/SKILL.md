---
name: ollama-model-manager
description: "Manage Ollama models: list, pull, remove, benchmark, compare. Shows model sizes, quantization levels, and performance stats. Trigger on 'ollama models', 'list models', 'download model', 'compare models', 'benchmark model', 'which model for', 'model recommendation'."
---

# Ollama Model Manager Skill

## Overview
Manage local Ollama models: installation, removal, benchmarking, comparison, and recommendations for different tasks.

## Prerequisites
- Ollama running: `ollama serve` (or service running)
- Default host: `http://localhost:11434`
- Alternative: Set `OLLAMA_HOST` env var

## Phase 1: STATUS
Check installed models and system state:

### List Models
```bash
ollama list
# Output:
# NAME                       ID              SIZE      MODIFIED
# qwen3-coder:latest         abc123...       4.7 GB    3 hours ago
# llama3:latest              def456...       4.7 GB    1 day ago
# nomic-embed-text:latest    ghi789...       274 MB    5 days ago
```

### Detailed Model Info
```bash
ollama show qwen3-coder
# Output:
# Model
# architecture       qwen2
# parameters         27b
# quantization       Q4_K_M
# context length     32768
# Tags
# modelfile          /Users/.../Modelfile
# parameters         /Users/.../parameters
```

### Check Ollama Status
```bash
curl -s http://localhost:11434/api/tags
# Returns JSON: {models: [{name, size, modified_at}]}
```

### Running Models (Active)
```bash
ollama ps
# Shows currently loaded models in memory
```

## Phase 2: SEARCH
Find and evaluate available models:

### Browse Available Models
https://ollama.com/library

### Model Categories

**Code-Focused**
- qwen3-coder (27B) — best overall code assistant
- deepseek-coder (33B, 6.7B) — specialized coding
- codellama (34B, 13B, 7B) — Meta's code LLM
- phi3-code — lightweight code model

**General Purpose**
- llama3 (70B, 8B) — high quality, fast
- mistral (7B) — efficient, good quality
- mixtral (46.7B, 8x7B) — mixture-of-experts
- neural-chat (7B) — conversational

**Embeddings/Search**
- nomic-embed-text (274M) — fast, good quality
- mxbai-embed-large (334M) — better quality

**Specialized**
- phi (2.7B) — very small, surprisingly capable
- orca-mini (3B) — small but smart
- mistral-nemo (12B) — good balance
- openchat (7B) — chat optimized

### Pull Model
```bash
ollama pull qwen3-coder
# Downloads to ~/.ollama/models/ (or OLLAMA_MODELS path)
# Size: ~4.7GB for qwen3-coder Q4 variant
```

### Pull Specific Version/Quantization
```bash
ollama pull llama3:70b         # 70B version
ollama pull llama3:7b          # 7B version (faster, smaller)
ollama pull phi3:medium        # Medium variant
ollama pull nomic-embed-text   # Embedding model
```

## Phase 3: BENCHMARK
Compare model performance on same task:

### Single Model Benchmark
```bash
time ollama run qwen3-coder "write a python quicksort function"
# Measures: real time (wall clock), user time, system time
```

### Detailed Benchmark with Timing
```bash
ollama run qwen3-coder --verbose "prompt" 2>&1 | tee bench.log
# Verbose shows token timing and generation speed
```

### Benchmark Script (multiple models)
```bash
#!/bin/bash

PROMPT="Write a Python function that reverses a list without using slicing."
MODELS=("qwen3-coder" "llama3:8b" "codellama")

echo "Model,Time(s),Tokens,Tokens/Sec,Quality(1-10)"

for model in "${MODELS[@]}"; do
  start=$(date +%s%N)
  output=$(ollama run "$model" "$PROMPT" 2>&1)
  end=$(date +%s%N)
  
  elapsed=$(( (end - start) / 1000000 ))
  elapsed_sec=$(echo "scale=2; $elapsed / 1000" | bc)
  
  # Rough token count (1 token ~= 4 chars on average)
  tokens=$(( ${#output} / 4 ))
  tokens_per_sec=$(echo "scale=2; $tokens / $elapsed_sec" | bc)
  
  # Manual quality rating (1-10)
  echo "$model,$elapsed_sec,$tokens,$tokens_per_sec,?"
done
```

### Comparison Table
Create markdown table comparing:
- Model name
- Size (GB)
- Speed (tokens/sec)
- Quality (subjective 1-10)
- Best for (coding, general, chat, embeddings)
- Memory requirement
- Quantization (Q4, Q5, FP16)

Example:
```
| Model | Size | Speed | Quality | Best For | Memory |
|-------|------|-------|---------|----------|--------|
| qwen3-coder | 4.7GB | 25 tok/s | 9/10 | Code | 8GB |
| llama3:70b | 39GB | 8 tok/s | 8/10 | General | 48GB |
| llama3:8b | 4.7GB | 40 tok/s | 7/10 | Chat | 8GB |
| codellama | 34GB | 12 tok/s | 8/10 | Code | 40GB |
| phi3 | 2.3GB | 80 tok/s | 6/10 | Fast | 4GB |
```

## Phase 4: MANAGE
Install, remove, and configure models:

### Pull Model (Download)
```bash
ollama pull qwen3-coder
# Downloads latest version with default quantization
# Typically Q4_K_M (good balance of speed/quality)
```

### Remove Model
```bash
ollama rm qwen3-coder
# Permanently deletes local model (no recovery)
# Always confirm before running
```

### Create Custom Model (Modelfile)
```dockerfile
FROM llama3:70b
PARAMETER temperature 0.7
PARAMETER top_k 40
PARAMETER top_p 0.9
SYSTEM """You are an expert code reviewer..."""
```

Then:
```bash
ollama create custom-reviewer -f Modelfile
```

### Export Model
```bash
# Models stored in ~/.ollama/models/blobs/
# Copy manually to backup location
```

### Check Disk Space Used
```bash
du -sh ~/.ollama/models/
# Example output: 45G

# Per model:
ls -lh ~/.ollama/models/blobs/ | head -10
```

## Phase 5: RECOMMEND
Suggest best model for task type:

### Code Development & Review
- **Primary**: qwen3-coder (best instruction following, code quality)
- **Alternative**: deepseek-coder (strong coding, fast)
- **Fast**: codellama:7b (quick, decent quality)
- **Size constraint (<2GB)**: phi3-code or orca-mini

### General Chat & Writing
- **High quality**: llama3:70b (best but slow)
- **Balanced**: llama3:8b (good speed/quality)
- **Fast**: mistral:7b
- **Very fast**: phi3

### Data Analysis & Reasoning
- **Best**: llama3:70b (larger models reason better)
- **Medium**: mixtral:46.7b
- **Fast**: llama3:8b

### Embeddings & Search
- **Standard**: nomic-embed-text (274M, fast, good)
- **Quality**: mxbai-embed-large (334M, better quality)

### Production Retrieval-Augmented Generation (RAG)
- **Embedding**: nomic-embed-text
- **LLM**: qwen3-coder or llama3:8b
- **Keep in memory**: yes (fast inference)

### When Disk/Memory Limited
```
Available RAM       Recommended Model
8GB                 llama3:8b, phi3, mistral:7b
12GB                qwen3-coder, codellama:7b
16GB+               llama3:70b, mixtral
```

### Decision Tree
1. Is it coding? → qwen3-coder
2. Need reasoning? → llama3:70b or mixtral
3. Speed critical? → phi3 or mistral:7b
4. Embeddings? → nomic-embed-text
5. Default → llama3:8b

## Common Workflows

### Setup for Development
```bash
# Core models for coding projects
ollama pull qwen3-coder
ollama pull nomic-embed-text

# Optional: general chat
ollama pull llama3:8b

# Verify
ollama list
```

### Benchmark Before Deciding
```bash
# Download 2-3 candidate models
ollama pull qwen3-coder
ollama pull codellama:7b
ollama pull phi3

# Run benchmark script
./benchmark.sh

# Choose based on results
ollama rm codellama  # if slower
```

### Switch Active Model for Task
```bash
# In your application, specify model:
ollama run qwen3-coder "code task"
ollama run llama3:8b "general task"
```

### Monitor Memory Usage
```bash
ollama ps    # shows loaded models
top          # watch memory growth

# If memory exhausted, unload models:
ollama ps    # see what's loaded
# Models unload automatically after 5 min idle
# Force unload by restarting ollama service
```

### Cleanup Old Models
```bash
ollama list
ollama rm old-model-name
# Frees disk space for new models
```

## Troubleshooting

### "Connection refused"
- Check Ollama is running: `ollama serve`
- Check host: `OLLAMA_HOST=0.0.0.0:11434 ollama serve` (if remote)

### Model download stuck
- Network issue: restart and retry
- Disk full: check `df -h`, clean up

### Very slow inference
- Model larger than RAM
- GPU not available
- System under heavy load

### Memory leak / excessive growth
- Restart ollama service
- Smaller model may fit better

