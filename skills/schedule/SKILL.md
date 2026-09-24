---
name: schedule
description: Create scheduled tasks and reusable shortcuts for recurring or one-time automation. Set up cron jobs, scheduled commands, and task automation with proper timezone handling.
compatibility: Claude Code
---

# Schedule Skill

Use this skill to create scheduled tasks that run on a recurring basis or at specific times. Perfect for automating repeatable work, setting up monitoring tasks, or building persistent workflows that outlive individual conversations.

## How to Use

When you need to schedule a task:

1. **Analyze the session** for the core task to be scheduled. What needs to happen? When? How often?

2. **Draft a self-contained prompt** that doesn't reference the current session or conversation context. This prompt will execute independently later. Use imperative form: "Generate...", "Analyze...", "Create..." rather than "Please help me...".

3. **Choose a kebab-case taskName** that clearly identifies what the task does. Examples: `daily-report-generator`, `backup-database`, `check-system-health`.

4. **Determine scheduling**:
   - One-off: Use `schedule_type: "once"` with a future `run_at` timestamp
   - Recurring: Use `schedule_type: "cron"` with a cron expression

5. **Call create_scheduled_task** with:
   - `taskName`: kebab-case identifier
   - `prompt`: Complete, self-contained instruction
   - `schedule_type`: "once" or "cron"
   - `cron_expression` or `run_at`: Scheduling details
   - Optional `description`: Human-readable purpose

## Important Notes

- **Timezone handling**: Cron expressions use the system's local timezone, not UTC. Verify the target system's timezone when scheduling.

- **Local verification with Ollama**: Before deploying a scheduled task to production, use Ollama (with qwen3-coder or similar) to verify the scheduled task prompt will execute correctly. Run the self-contained prompt through Ollama to catch any missing context or invalid instructions.

## Example Workflow

```
Task: Create a daily report generator

1. Core task identified: "Generate daily metrics from previous 24 hours"

2. Self-contained prompt drafted:
   "Fetch metrics from the last 24 hours. Calculate averages, 
    identify anomalies. Format as HTML table with timestamp."

3. Task name chosen: daily-metrics-report

4. Scheduling: Recurring daily at 6 AM
   cron_expression: "0 6 * * *"

5. Call create_scheduled_task with all parameters

6. Verify with Ollama by testing the prompt independently
```

## Template

Use this template when calling create_scheduled_task:

```json
{
  "taskName": "your-kebab-case-name",
  "description": "Human-readable description of what this task does",
  "prompt": "Self-contained imperative prompt here. Include all context needed to execute independently.",
  "schedule_type": "cron",
  "cron_expression": "0 9 * * MON-FRI",
  "timezone": "America/New_York"
}
```

