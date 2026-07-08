# Creative Writing Slash Commands

These custom slash commands provide explicit mode switching for the editorial
workspace's skills.

## Available Commands

### Brainstorming
- **`/bs`** - Brainstorm and explore story ideas

**Usage:**
```
/bs I'm thinking about a magic system where...
/bs What if the antagonist actually...
```

### Critique
- **`/critique`** - Get feedback on your writing (deep-dive or holistic editorial pass)

**Usage:**
```
/critique [file or paste text]
/critique Analyze the pacing in chapter 3
/critique Give me a full editorial pass on this chapter
```

### Knowledge Base
- **`/kb`** - Create or update kb reference pages

**Usage:**
```
/kb Create a character profile for my protagonist
/kb Update the magic system page with the new constraints
/kb Document the timeline for act 2
```

### Saving Progress
- **`/save`** - Save your progress (creates a versioned snapshot of the active project)

**Usage:**
```
/save
/save Added Ellora's character profile
```

### Project Setup
- **`/setup`** - One-time setup for a new writing project

**Usage:**
```
/setup Breaking the Beasts
```

## Why Use Slash Commands?

1. **Explicit invocation** - Clear signal about which skill you want
2. **Context shifting** - The command shifts Claude's focus to the skill
3. **Shorter syntax** - Easier than "use the prose-critique skill"
4. **Arguments** - Pass additional context directly

## Natural Language Still Works

You can still use natural language to invoke skills:
- "Help me brainstorm ideas for my antagonist"
- "Critique the pacing in chapter 3"
- "Save my progress"

The slash commands just provide an explicit alternative when you want guaranteed skill activation.
