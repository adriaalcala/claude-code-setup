# /workflow

Execute the complete multi-agent development pipeline with LOCAL-FIRST verification:

1. Read the workflow-agent instructions from agents/workflow-agent.md
2. Initialize .claude/knowledge/ if not present
3. Verify Ollama is available (ollama list)
4. Run: Planning → Check → Implementation → Check → Testing → Check → Documentation → Check → Knowledge Sync
5. Each check step uses Ollama first, cloud API for complex analysis
6. Save all results to $ARGUMENTS or ./workflow-output/

Arguments: $ARGUMENTS (description of the task to implement)
