---
name: prompt-engineer
description: "Create and optimize LLM prompts for specific tasks. Covers prompt patterns, few-shot learning, chain-of-thought, output formatting. Test prompts locally with Ollama before cloud APIs. Trigger on 'prompt', 'improve prompt', 'optimize prompt', 'write prompt', 'prompt engineering'."
---

# Prompt Engineer Skill

## Overview
Design, test, and optimize prompts for language models. Includes patterns for classification, generation, reasoning, and code tasks.

## Phase 1: UNDERSTAND

### Task Type
Identify what you need the model to do:
- **Classification**: Categorize input into predefined classes
- **Extraction**: Pull specific information from text
- **Summarization**: Condense longer text
- **Generation**: Create new content (code, text, ideas)
- **Translation**: Convert between languages
- **Reasoning**: Multi-step logical thinking (math, planning)
- **Code**: Generate, debug, or explain code
- **Chat**: Conversation/dialogue

### Model Characteristics
- **Model name**: Which LLM (GPT-4, Claude, qwen3-coder, llama3)?
- **Context size**: How much input can fit?
- **Speed requirement**: Real-time vs batch processing?
- **Cost**: API cost per token?
- **Capability level**: Is model strong enough for task?

### Input/Output Specification
- **Input format**: Structured data, free text, code, images?
- **Input size**: Typical length?
- **Output format**: JSON, markdown, plain text?
- **Output length**: Short (sentence), medium (paragraph), long (multi-page)?
- **Quality criteria**: Accuracy, creativity, speed?

### Success Criteria
Define how you'll measure success:
- Accuracy: Must match expected answer X% of the time
- Relevance: Output must address the question
- Format: Must be JSON/markdown/code
- Tone: Professional, casual, technical?
- Length: Exactly N words, under N tokens?

## Phase 2: CRAFT

### Prompt Structure

```
[ROLE] (optional)
You are an [expert/assistant/etc] who [core responsibility].

[CONTEXT]
[Background information needed for task]
[Constraints and requirements]

[TASK]
[Specific instruction]
[What to do with input]

[FORMAT]
Respond in [format]: [example or template]

[EXAMPLE] (optional but recommended)
Input: [example input]
Output: [example output]

[INPUT]
[The actual user input/data]
```

### Best Practices

**Be Specific**
- Bad: "Write code"
- Good: "Write a Python function that validates email addresses. Use regex and return True/False"

**Use Role/Persona**
- Gives model context and bias toward that perspective
- "You are a security expert auditing code for vulnerabilities"
- "You are a technical writer explaining concepts simply"

**Provide Context**
- Explain why task matters
- Give domain knowledge if specialized
- "Context: We're building a real-time chat system. Message latency <100ms is critical."

**Give Examples**
- Few-shot learning: 1-3 examples help enormously
- Format: Input → Output pairs
- Shows both content AND format expectations

**Specify Format Explicitly**
- "Return as JSON with keys: title, summary, tags"
- "Return as a valid Python function"
- "Return as markdown with ## headings"

**Use Delimiters**
- Separate sections with clear markers: `===`, `---`, or triple backticks
- Helps model understand structure

**Constraint Specification**
- "Do not exceed 100 words"
- "Return only the code, no explanation"
- "Ignore previous examples, use only this context"

**Chain of Thought**
- For reasoning tasks, ask model to explain thinking
- "Let's think step by step:"
- "First, [step 1]. Then, [step 2]. Finally, [step 3]."

### Common Prompt Patterns

**Classification**
```
You are a content moderation assistant. Classify the following message.

Categories:
- SPAM: Advertising, promotional content
- OFFENSIVE: Hateful, discriminatory language
- NORMAL: Regular conversation
- QUESTION: User asking for help

Message: "{input}"

Respond only with the category name.
```

**Extraction**
```
Extract the following information from the text below:
- Names (people, companies)
- Dates
- Financial amounts
- Action items

Text:
"{input}"

Return as JSON:
{
  "names": [],
  "dates": [],
  "amounts": [],
  "actions": []
}
```

**Summarization**
```
Summarize the following article in 2-3 sentences, focusing on key findings.

Article:
"{input}"

Summary:
```

**Code Generation**
```
Generate a Python function with the following requirements:
- Name: calculate_fibonacci
- Input: integer n (0 <= n <= 100)
- Output: nth Fibonacci number
- Should use memoization for performance

Include docstring and type hints.
```

**Reasoning (Chain of Thought)**
```
Solve this math problem step by step.

Problem: A train leaves Station A at 10 AM going 60 mph.
Another train leaves Station B (50 miles away) at 10:30 AM going 75 mph toward A.
When do they meet?

Let's think step by step:
1. [Define variables]
2. [Set up equation]
3. [Solve]

Answer:
```

**Code Review**
```
You are a senior code reviewer. Review the following code for:
- Logic errors
- Performance issues
- Security vulnerabilities
- Code style problems

Code:
{code}

For each issue, provide:
1. Line number
2. Severity (HIGH/MEDIUM/LOW)
3. Description
4. Suggested fix
```

## Phase 3: TEST

### Local Testing with Ollama

Test before sending to cloud APIs:

```bash
# Test with qwen3-coder (good for code/reasoning)
ollama run qwen3-coder << 'EOF'
[YOUR FULL PROMPT HERE]
EOF

# Or with llama3 for general tasks
ollama run llama3 << 'EOF'
[YOUR FULL PROMPT HERE]
EOF
```

### Test Dataset
Create 5-10 representative test cases:
```
Test Case 1:
  Input: [example input]
  Expected: [what good output looks like]
  Actual: [model output]
  Pass: ✓/✗

Test Case 2:
  ...
```

### Evaluation Criteria
For each test case, check:
- ✓ Format correct? (JSON valid? Markdown? Code syntactically correct?)
- ✓ Content accurate? (Does answer match expectation?)
- ✓ Complete? (No truncation, all required fields?)
- ✓ Relevant? (Addresses the question?)
- ✓ Length appropriate? (Not too long/short?)
- ✓ Tone right? (Professional/casual/technical as needed?)

### Success Rate
- < 70%: Major revision needed
- 70-85%: Fine-tune details
- 85%+: Ready to deploy

## Phase 4: OPTIMIZE

### If Success Rate Too Low

**Unclear task?**
- Add more context/examples
- Be more specific about expectations
- Add constraints ("exactly 3 items", "under 50 words")

**Wrong format?**
- Show explicit output format/template
- Add example with exact formatting

**Missing information?**
- Add more context to prompt
- Provide background knowledge
- Link to reference materials

**Model capability gap?**
- Try stronger model (qwen3-coder, llama3:70b)
- Break task into simpler sub-tasks
- Use different approach (e.g., few-shot instead of zero-shot)

### Iterative Refinement

1. Test initial prompt → 60% success
2. Add examples → 75% success
3. Clarify format → 85% success
4. Add constraints → 92% success
5. Deploy with confidence

### Prompt Optimization Techniques

**Few-Shot Learning**
- Add 2-3 examples showing input/output
- Better than zero-shot by 10-30% typically

**Negative Examples**
- Show what NOT to do
- "Do NOT include: [these things]"

**Explicit Instructions**
- "Return ONLY [x], no explanation"
- "Must be valid [format]"
- "Use [specific terminology]"

**Temperature Tuning** (if supported)
- Lower temp (0.1-0.3): More deterministic, focused
- Higher temp (0.7-1.0): More creative, varied

**Token Limit**
- Constraining output length forces conciseness
- "Response must be under 150 tokens"

## Phase 5: Document & Deploy

### Document Prompt
```markdown
## Task: [Task Name]
**Purpose**: [Why this prompt needed]
**Model**: qwen3-coder (local) or GPT-4 (cloud)
**Success Rate**: 92% on test set

**Prompt**:
[Full prompt]

**Test Cases**: [Link to test results]
**Version**: 1.0
**Last Updated**: 2026-03-08
```

### Version Control
- Keep prompts in git (prompts/ directory)
- Track changes: version numbers, improvement notes
- Test results per version

### Monitoring
- Track success rate in production
- Log inputs that fail
- Iterate based on real-world usage

## Example Workflows

### Code Generation Prompt

```bash
ollama run qwen3-coder << 'EOF'
You are an expert Python developer.

Generate a Python function that:
- Parses a CSV file
- Filters rows where "age" > 18
- Returns a list of dictionaries

Requirements:
- Use type hints
- Include docstring with example
- Handle errors gracefully

Example usage:
```python
data = load_csv("people.csv")
adults = filter_adults(data, age_threshold=18)
print(adults)  # [{name: "Alice", age: 25}, ...]
```

Your implementation:
```

Note: Test output locally, refine if needed, then use in production.

## Common Mistakes to Avoid

- **Vague prompts**: "Write code" → Specify language, requirements
- **Too many tasks**: One prompt per task (chain them if needed)
- **No examples**: Always include 1-2 examples for clarity
- **Unclear format**: Specify output format explicitly
- **Missing context**: Provide domain knowledge upfront
- **Assuming knowledge**: Define terms, don't assume background
- **Inflexible constraints**: Allow some flexibility unless strict requirement

## Testing Locally Before Cloud

Always test with Ollama first:
- qwen3-coder: code, reasoning, technical
- llama3:8b: general, chat, balanced
- nomic-embed-text: embeddings/search

This saves API costs and keeps data local during development.

