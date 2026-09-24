---
name: "Multi-Agent Brainstorm"
description: "4-phase collaborative brainstorming: diverge, evaluate, synthesize, refine"
allowed-tools:
  - Read
  - Grep
preferred-model: "opus"
---

# Multi-Agent Brainstorm

Structured brainstorming framework with 4 phases for generating and refining ideas with diverse perspectives.

## Overview

The brainstorm process uses role-based agents to explore a problem from multiple angles:

1. **DIVERGE** - Generate many ideas without criticism
2. **EVALUATE** - Assess ideas against criteria
3. **SYNTHESIZE** - Combine best ideas into coherent solutions
4. **REFINE** - Polish and prepare for implementation

## Phase 1: DIVERGE (Generate Ideas)

**Role: Creative Ideator**
**Goal: Quantity and diversity of ideas**

For a given problem, generate 10+ ideas using:

### Creative Techniques

**Brainstorming Rules:**
- No judgment or criticism
- Encourage wild ideas
- Build on others' suggestions
- Aim for quantity first
- Cross-domain thinking

**Example: "Improve code review process"**

```
1. AI-powered code analysis with real-time suggestions
2. Pair programming sessions as alternative to reviews
3. Automated bot that catches 80% of issues
4. Rotating reviewer assignments to spread knowledge
5. Code review guild with rotating expertise areas
6. Time-boxed reviews (max 15 minutes per file)
7. Video walkthrough by author instead of static review
8. Gamification with points for thorough reviews
9. Pre-review linting and formatting automation
10. Review templates for different change types
11. Mandatory review time tracking and incentives
12. Split reviews by different expertise areas (security, performance, etc.)
```

### Divergence Techniques

**Reverse Brainstorm:** "How would we make code reviews WORSE?"
- No automated checks
- Reviewers without context
- No feedback
- Blocking all changes
- Generic comments
- *Reverse these* to find improvements

**Analogies:** "How do other industries review quality?"
- Manufacturing: statistical sampling, automated inspection
- Medicine: peer review, journal review process
- Food: taste testing, safety inspections
- *Apply to code review*

**Constraints:** "What if we had these limitations?"
- Only 5 minutes per review
- Only one reviewer
- No written comments
- *What solutions emerge?*

**Future Scenario:** "Code review in 2030"
- AI does all technical analysis
- Humans focus on design/architecture
- Real-time continuous reviews
- *What can we do now?*

## Phase 2: EVALUATE (Assess Ideas)

**Role: Critical Analyst**
**Goal: Identify strengths, weaknesses, feasibility**

### Evaluation Framework

For each idea, assess:

```
Idea: AI-powered code analysis with real-time suggestions

IMPACT (Scale: 1-10)
- How much would this improve code review?
  Score: 8/10
  Reason: Catches common issues, reduces reviewer workload

EFFORT (Scale: 1-10, 10 = hardest)
- How hard is this to implement?
  Score: 6/10
  Reason: Need to select/train model, integrate with workflow

FEASIBILITY (Scale: 1-10)
- Can we actually do this?
  Score: 8/10
  Reason: Off-the-shelf tools exist, we have budget

NOVELTY (Scale: 1-10)
- How new/different is this?
  Score: 3/10
  Reason: Already exists (GitHub Copilot, CodeRabbit)

ALIGNMENT
- Matches strategic goals? YES
- Solves user pain points? YES
- Fits technical constraints? YES

RISKS
- Tool might give bad suggestions (medium risk)
- Over-reliance on automation (medium risk)
- Integration complexity (low risk)

DEPENDENCIES
- Need LLM API access
- Need to curate training data
- Need reviewer training

---
Score: 7.5/10 (High priority)
Reasoning: High impact, moderate effort, proven by competitors, good ROI
```

### Evaluation Criteria

Create criteria specific to your context:

```
Category           Weight   Criteria
─────────────────────────────────────────────────
User Impact        30%      Solves real pain point?
Technical Effort   20%      Can we build it?
Alignment          20%      Matches goals?
Speed to Value     15%      Time to implementation?
Risk Level         15%      Can we handle risks?
```

## Phase 3: SYNTHESIZE (Combine Ideas)

**Role: Systems Thinker**
**Goal: Create coherent solutions from best ideas**

### Synthesis Process

1. **Cluster related ideas**
   ```
   Cluster A: Automation & Tools
   - AI-powered analysis
   - Pre-review linting
   - Automated bot

   Cluster B: Process Improvements
   - Time-boxing
   - Review templates
   - Rotating assignments

   Cluster C: Human Factors
   - Gamification
   - Pair programming
   - Knowledge sharing
   ```

2. **Identify complementary ideas**
   ```
   Strong pairing:
   AI analysis + Review templates
   → AI suggests template based on change type
   → Reviewer fills in details
   → Reduces effort, maintains quality

   Another pairing:
   Rotating assignments + Knowledge guild
   → Spread expertise across team
   → Build shared knowledge
   → Improve review quality
   ```

3. **Create integrated solutions**
   ```
   SOLUTION 1: AI-First Review
   - Component A: Pre-commit linting/formatting
   - Component B: AI analysis catches common issues
   - Component C: Human review focuses on design/business logic
   - Result: Faster, higher quality reviews

   SOLUTION 2: Process-First Review
   - Component A: Review templates for each change type
   - Component B: Time-boxed reviews (max 15 min)
   - Component C: Rotating expertise-based reviewers
   - Result: Efficient, spreads knowledge, consistent quality

   SOLUTION 3: Hybrid (Recommended)
   - Component A: Automated pre-checks (lint, format, static analysis)
   - Component B: AI analysis provides initial feedback + template
   - Component C: Human review with role-based template
   - Component D: Reviewer tracking and incentives
   - Result: Best of both worlds
   ```

4. **Describe integrated solution**
   ```
   NAME: Tiered Code Review System

   OVERVIEW: Combines automation, AI, and human judgment in layers

   LAYER 1 - Automated (pre-commit)
   - Syntax validation
   - Linting
   - Formatting
   - Test coverage

   LAYER 2 - AI Analysis
   - Security patterns
   - Performance issues
   - Common bugs
   - Complexity analysis
   - Generates review template

   LAYER 3 - Human Review
   - Design patterns
   - Business logic correctness
   - Architectural fit
   - Knowledge sharing
   - Final approval

   EXPECTED OUTCOMES
   - 40% faster reviews
   - 30% fewer bugs in production
   - Better knowledge distribution
   - Reviewer satisfaction +20%
   ```

## Phase 4: REFINE (Polish Solution)

**Role: Implementation Planner**
**Goal: Make solution ready for action**

### Refinement Questions

For the integrated solution, address:

```
WHAT
□ What exactly are we building?
  → Tiered review system with AI + human layers

□ What are the specific features?
  → Pre-commit checks, AI analysis, template-based review, metrics

□ What's out of scope?
  → Doesn't replace architecture review
  → Doesn't enforce specific coding styles beyond linting

WHO
□ Who will use this?
  → All developers, team leads, reviewers

□ Who will build this?
  → 1 senior engineer (8 weeks), 1 contractor (4 weeks)

□ Who are stakeholders?
  → Engineering team, QA, Product leads

WHEN
□ When do we start?
  → Sprint 15 (2 weeks)

□ What's the timeline?
  → Phase 1 (pre-commit): 4 weeks
  → Phase 2 (AI layer): 6 weeks
  → Phase 3 (human layer + metrics): 4 weeks

□ What are milestones?
  → Week 4: Pre-commit ready for testing
  → Week 10: AI analysis ready for closed alpha
  → Week 14: Full system launch

WHERE
□ Where does this live?
  → GitHub Actions, LLM service, metrics dashboard

□ Where do users interact?
  → GitHub PRs, dashboard, CLI tool

WHY
□ Why are we doing this?
  → Improve quality, reduce review time, scale knowledge

□ Why this approach?
  → Proven by industry, combines best practices, low risk

HOW
□ How does it work?
  → [Describe architecture and flow]

□ How do we measure success?
  → Review time: <15 min avg
  → Bug detection: +30%
  → Team satisfaction: +20%

□ How do we handle risks?
  → AI false positives: Manual override, human review
  → Tool failures: Fallback to manual review
  → Adoption resistance: Training, incentives

NEXT STEPS
1. Create detailed specification (1 week)
2. Design system architecture (1 week)
3. Set up development environment (3 days)
4. Build Phase 1 (4 weeks)
5. Alpha testing and feedback (2 weeks)
6. Phase 2 implementation (6 weeks)
7. Beta launch and rollout (4 weeks)
```

### Implementation Roadmap

```
┌─────────────────────────────────────────────────┐
│ Sprint 15-16: Foundation                        │
│ - Requirements finalization                     │
│ - Architecture design                           │
│ - Tool/LLM selection                            │
└─────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│ Sprint 17-18: Pre-commit Checks                 │
│ - Linting + formatting                          │
│ - Test coverage gates                           │
│ - GitHub Actions integration                    │
│ - Beta with volunteer team                      │
└─────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│ Sprint 19-24: AI Analysis Layer                 │
│ - LLM integration                               │
│ - Code analysis engine                          │
│ - Template generation                           │
│ - Closed alpha testing                          │
└─────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│ Sprint 25-26: Metrics & Human Layer             │
│ - Tracking and analytics                        │
│ - Incentive system                              │
│ - Review guidelines                             │
│ - Documentation and training                    │
└─────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│ Sprint 27-30: Rollout                           │
│ - Team training                                 │
│ - Phased adoption                               │
│ - Monitoring and tuning                         │
│ - Feedback collection                           │
└─────────────────────────────────────────────────┘
```

## Using This Framework

### For Your Brainstorm

1. **State the problem clearly**
   ```
   Problem: How do we improve code review efficiency
            while maintaining quality?
   Constraints: Limited reviewer time, growing codebase
   Success metrics: <15 min avg review, +30% bug detection
   ```

2. **Run through phases**
   - Diverge: 20-30 ideas
   - Evaluate: Score and rank top 10
   - Synthesize: Combine into 2-3 integrated solutions
   - Refine: Choose best, detail implementation

3. **Document decisions**
   - Capture why ideas were rejected
   - Note dependencies and risks
   - Create implementation plan

4. **Get alignment**
   - Share results with stakeholders
   - Incorporate feedback
   - Finalize specification

## Example Output

A complete brainstorm should produce:

```
PROJECT: Code Review System Improvement

PROBLEM STATEMENT
[Clear problem definition]

INITIAL IDEAS (30 ideas)
[List from divergence phase]

EVALUATED IDEAS
[Top 10 with scores and analysis]

SYNTHESIZED SOLUTIONS
1. [Solution A with components]
2. [Solution B with components]
3. [Recommended solution with full details]

IMPLEMENTATION PLAN
[Phases, timeline, owners, risks, success metrics]

NEXT STEPS
[Who does what by when]
```

## Tips for Success

- Keep divergence and evaluation separate (avoid killing ideas too early)
- Use concrete examples and scenarios
- Involve diverse perspectives (cross-functional team)
- Document reasoning, not just conclusions
- Revisit divergence if synthesis feels stuck
- Test assumptions with small experiments
- Get stakeholder buy-in before detailed planning
