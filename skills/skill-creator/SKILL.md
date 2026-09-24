---
name: skill-creator
description: Design, build, and iterate on Claude OS skills using a structured evaluation framework. Create production-ready skills that combine metadata, logic, and test coverage.
compatibility: Claude Code
---

# Skill Creator Skill

This skill guides you through the complete lifecycle of creating or improving a Claude OS skill. It combines structured design thinking, iterative testing, and continuous improvement patterns.

## 1. Capture Intent

Before writing code or prompts, establish what the skill must accomplish:

- **Core purpose**: What single capability does this skill provide?
- **Triggers**: When should this skill activate? What phrases or patterns invoke it?
- **Expected output**: What format, quality, and structure should results have?
- **Test cases**: Generate 2-3 realistic use cases that exercise the skill:
  - Best-case scenario
  - Edge case or constraint
  - Potentially ambiguous input

Document these as concrete prompts you'll use later for evaluation.

## 2. Interview and Research

Thoroughly explore the problem space:

- **Edge cases**: What inputs might break the skill? What constraints exist?
- **Input/output formats**: How will the skill receive data? What formats must outputs support?
- **Dependencies**: What external tools, APIs, or resources does the skill require? Does Ollama suffice for local verification?
- **Compatibility constraints**: Which Claude OS versions support this? Any hardware requirements?

## 3. Write SKILL.md

The SKILL.md file is the manifest and interface for your skill. Structure it with:

- **YAML frontmatter**:
  - `name`: kebab-case identifier
  - `description`: Make it slightly "pushy" to combat under-triggering. Use action verbs, clarify value. Example: "Instantly convert between formats" rather than "Can help with format conversion"
  - `compatibility`: Which Claude OS versions

- **Body sections**:
  - **How to Use**: Step-by-step instructions with examples
  - **Important Notes**: Edge cases, gotchas, timezone/precision issues
  - **Example Workflow**: Concrete before/after scenario
  - **Template**: Copy-paste ready JSON/markdown the user can adapt

## 4. Skill Anatomy

```
my-skill/
├── SKILL.md              # Required. Metadata + instructions
├── scripts/              # Optional. Supporting executables
│   └── helper.py
├── references/           # Optional. Documentation, specs
│   └── api-reference.md
└── assets/               # Optional. Data files, templates
    └── template.json
```

**Progressive disclosure**: 
- SKILL.md metadata always loads (name, description, compatibility)
- Full SKILL.md content loads when the skill triggers
- scripts/, references/, assets/ load on-demand when referenced in SKILL.md

Keep SKILL.md under 500 lines. Use hierarchical structure to keep it scannable:
- H1 for skill title
- H2 for major sections
- H3 for subsections
- Bullet points for steps and guidance

## 5. Writing Patterns

**Imperative form**: Use commands, not questions.
- Good: "Extract all email addresses from the text"
- Bad: "Can you extract email addresses?"

**Examples pattern**: Show, don't just tell.
- Include 2-3 complete examples with input → output
- Label what's happening at each step

**Explain WHY, not just MUST**:
- Good: "Include the full timestamp because downstream systems depend on ISO-8601 format for parsing"
- Bad: "Always include full timestamp"

## 6. Test Cases

Create 2-3 realistic test prompts that exercise your skill:

```
Test 1 (Best case): Standard, straightforward use
"Create a weekly standup meeting schedule for Q2"

Test 2 (Edge case): Constraints, unusual inputs
"Create a meeting schedule that respects no-meeting hours 
 on Fridays, recurring across 6 timezones, with buffer time"

Test 3 (Ambiguity): Underspecified or conflicting requirements
"Schedule this for next Tuesday. Wait, maybe next month? 
 Make it recurring anyway."
```

**Evaluation process**:
1. Run prompt WITHOUT the skill active
2. Run prompt WITH the skill active
3. Compare outputs side-by-side
4. Score on: clarity, completeness, correctness, usability

Use the comparator agent (see `.claude/agents/comparator.md`) for blind evaluation.

## 7. Improvement Loop

After testing:

1. **Generalize from feedback**: If a test case revealed a gap, did it expose a fundamental skill limitation or just unclear wording?

2. **Keep prompts lean**: Remove redundant instructions. Every line must earn its place.

3. **Explain the why**: Users learn faster when they understand reasoning, not just rules.

4. **Look for repeated work**: Across your test cases, what patterns repeat? Extract them into reusable sections.

5. **Run iteratively**:
   - Fix skill
   - Re-test with same 3 prompts
   - Score improvements
   - Adjust again if needed

## 8. LOCAL-FIRST Verification

Before relying on cloud APIs for evaluation:

- **Use Ollama** with qwen3-coder or similar for local evaluation of skill outputs
- Test the skill's generated prompts directly in Ollama
- Verify the output format and logic correctness before cloud deployment
- This reduces API costs and feedback latency

## 9. Reference Other Agents

Your skill may benefit from collaboration with Claude OS agents:

- **grader.md** (`.claude/agents/grader.md`): Evaluate skill outputs against explicit expectations. Use for formal test grading.
- **comparator.md** (`.claude/agents/comparator.md`): Blind comparison of two skill variants. Use for A/B testing iterations.
- **analyzer.md** (`.claude/agents/analyzer.md`): Post-hoc analysis of why one skill outperformed another. Use to extract improvement insights.

## Summary Checklist

- [ ] Intent captured: purpose, triggers, outputs, test cases defined
- [ ] Research complete: edge cases, dependencies, constraints identified
- [ ] SKILL.md written: metadata, sections, examples, template included
- [ ] Anatomy organized: scripts/, references/, assets/ structured (if needed)
- [ ] Writing patterns applied: imperative, examples, explanations throughout
- [ ] Test cases created: 2-3 realistic scenarios drafted
- [ ] Local verification done: Ollama tested the generated prompts
- [ ] Iteration complete: grader/comparator/analyzer feedback incorporated
- [ ] Documentation finished: README, edge case notes, troubleshooting guide complete

