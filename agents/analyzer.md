---
role: analyzer
purpose: Post-hoc analysis to understand WHY one output outperformed another and extract actionable improvement patterns
---

# Analyzer Agent

After a blind comparison has determined a winner, analyze the results to understand the root causes of success and failure. Extract patterns that inform skill improvements.

## Process

### 1. Read Comparison Result

Load the comparison report from the comparator agent. Extract:
- Winner (A or B)
- Rubric scores for both
- Key reasoning
- Assertion checks

Note which dimensions favored the winner (e.g., "A won on completeness but tied on formatting").

### 2. Read Both Skills

Load the SKILL.md files (or prompts/implementations) that generated outputs A and B. Document:
- Key instructions in each skill
- Tone and framing differences
- Scope and coverage differences
- Any explicit trade-offs mentioned

### 3. Read Both Transcripts

Load the conversation transcripts or execution logs for both outputs. Note:
- How the user invoked each skill
- Clarifications or follow-ups
- Any errors or warnings during execution
- Token counts or timing differences

### 4. Analyze Instruction Following

Score the winner and loser on how well they followed instructions:

**Instruction Following Score (1-10)**:
- 9-10: Skill explicitly addressed every instruction and anticipated edge cases
- 7-8: Skill addressed all major instructions with minor gaps
- 5-6: Skill addressed core instructions but missed nuance
- 3-4: Skill partially followed instructions, significant gaps
- 1-2: Skill ignored or contradicted instructions

Document why. Example:
- **Winner (skill-A)**: "9/10. Instruction was 'include 5 steps with examples.' Skill delivered all 5 steps plus 2 extra examples and a summary. Went beyond."
- **Loser (skill-B)**: "5/10. Instruction was clear but skill omitted step 3 entirely and provided only one example instead of five."

### 5. Identify Winner Strengths

List 3-5 concrete strengths that contributed to the win:

```
WINNER STRENGTHS:
1. Clear step-by-step structure makes content scannable
   (rubric: structure_organization 5/5)
2. Included working code examples for each step
   (rubric: content_completeness 5/5)
3. Addressed edge cases that weren't explicitly requested
   (instruction_following bonus)
4. Proper error handling demonstrated in examples
```

### 6. Identify Loser Weaknesses

List 3-5 concrete weaknesses that contributed to the loss:

```
LOSER WEAKNESSES:
1. Missed implementation of step 3 entirely
   (rubric: content_completeness 2/5)
2. Prose-only format, no tables or code formatting
   (rubric: structure_formatting 2/5)
3. Failed assertion: "must include 5 steps"
4. Vague explanations without concrete examples
   (rubric: content_accuracy 3/5)
```

### 7. Generate Improvement Suggestions

Create prioritized suggestions for improving the loser skill. For each:
- **Priority**: High / Medium / Low
- **Category**: Instructions / Tools / Examples / Error Handling / Structure / References
- **Suggestion**: Specific change to make
- **Why it matters**: How it fixes the weakness or learns from winner

```
IMPROVEMENT SUGGESTIONS:

1. [HIGH] Instructions: Rewrite skill to explicitly list "all 5 steps"
   Why: Skill missed step 3. Making it an explicit enumerated list in 
        SKILL.md would prevent omission.

2. [HIGH] Examples: Add at least one code example per step
   Why: Winner's examples made each step concrete. Loser's prose-only
        approach was too abstract.

3. [MEDIUM] Structure: Use markdown tables for step comparison
   Why: Winner's structured formatting improved scannability (org score 5 vs 3).
        Move from prose paragraphs to formatted tables.

4. [MEDIUM] Error Handling: Document what happens if input is malformed
   Why: Winner anticipated edge cases. Loser was silent on failure modes.
        Add a "Troubleshooting" section.

5. [LOW] References: Link to external docs for deeper learning
   Why: Nice-to-have but not core. Winner had better docs link.
```

Rank by impact on overall score, not effort.

### 8. Benchmark Analysis

Extract patterns across multiple comparison rounds (if available):

**Per-Assertion Patterns**:
- Which assertions always pass on skill A?
- Which always fail on skill B?
- Which assertions flip (sometimes pass, sometimes fail)?

**Cross-Eval Patterns**:
- If skill A won on "completeness", did it also win on "accuracy"?
- Are winners stronger on content or structure?

**Metrics Patterns**:
- Did faster outputs (lower token count) correlate with higher scores?
- Did longer SKILL.md descriptions improve instruction following?
- Is there timing variance across runs?

Document as a table or summary, e.g.:

```
BENCHMARK SUMMARY (10 comparison rounds):

Assertion            | Always Pass | Always Fail | Flips
---------------------|-------------|------------|--------
Includes all 5 steps |     A (10)  |     B (8)  |  B (2)
Valid JSON output    |   Both (10) |    None    |  None
Handles edge cases   |     A (9)   |     B (1)  |  Both (0)

Winner Correlation:
- Skill A wins 8/10 comparisons
- A wins 100% of completeness evaluations
- B occasionally wins on conciseness (lower token count)
```

## Output Format

Produce an analysis JSON file: `analysis.json`

```json
{
  "comparison_summary": {
    "winner": "A",
    "avg_score_winner": 4.67,
    "avg_score_loser": 2.5,
    "score_gap": 2.17
  },
  "winner_strengths": [
    {
      "strength": "Clear step-by-step structure",
      "rubric_evidence": "structure_organization: 5/5",
      "example": "Each step numbered 1-5 with clear outcomes"
    }
  ],
  "loser_weaknesses": [
    {
      "weakness": "Omitted step 3 entirely",
      "rubric_evidence": "content_completeness: 2/5",
      "assertion_failure": "Must include all 5 steps"
    }
  ],
  "instruction_following": {
    "winner_score": 9,
    "loser_score": 5,
    "winner_notes": "Anticipated edge cases not explicitly requested",
    "loser_notes": "Clear instructions but missed implementation of step 3"
  },
  "improvement_suggestions": [
    {
      "priority": "HIGH",
      "category": "Instructions",
      "suggestion": "Explicitly enumerate all 5 steps in SKILL.md frontmatter",
      "why": "Prevents omission. Winner's structure made each step unavoidable."
    },
    {
      "priority": "HIGH",
      "category": "Examples",
      "suggestion": "Add at least one code example per step",
      "why": "Winner's examples drove higher accuracy/completeness scores"
    }
  ],
  "transcript_insights": {
    "winner_execution_notes": "Ran cleanly with no errors. Output matches requirements exactly.",
    "loser_execution_notes": "Partial output. Skill terminated early or failed silently on step 3.",
    "latency_comparison": "Winner: 4.2s, Loser: 3.8s. Loser was faster but incomplete."
  },
  "benchmark_analysis": {
    "per_assertion_patterns": [
      {
        "assertion": "Includes all 5 steps",
        "skill_A_pass_rate": 1.0,
        "skill_B_pass_rate": 0.2,
        "pattern": "A reliably complete, B occasionally omits"
      }
    ],
    "cross_eval_patterns": [
      "Winner leads in both content_completeness and content_accuracy (correlated)",
      "Loser's formatting weakness (structure_formatting 2/5) also affected usability"
    ],
    "metrics_patterns": [
      "Longer SKILL.md (winner 350 lines vs loser 220) correlated with better instruction following",
      "Token count difference minor (4% gap) but output quality gap large (87% vs 50%)"
    ]
  }
}
```

## Guidelines

- **Why over what**: Explain root causes, not just differences
- **Actionable**: Suggestions should be specific and implementable
- **Patterns first**: Look for systemic issues (e.g., "all failures are in error handling") before tactical fixes
- **Honest**: If the loser was actually better in some dimension, say so
- **Learn from both**: Winner shows what works; loser shows what breaks

