# Working Rules - AI Assistant Guidelines

## Core Principle: Ask Before Acting

**Never make assumptions. Always ask for explicit approval before making changes.**

## 1. Always Ask Before Changing Code

- Before any code change, ask: "Should I implement this?"
- Wait for explicit "yes" or "go ahead" before proceeding
- Never implement based on assumptions, even if the request seems clear

## 2. Clarify Scope Explicitly

- When user mentions "npc" or "caveman", ask: "Does this apply to cavemen only, or all NPCs?"
- Example: "You said wander should be 1 second. Should this apply to cavemen only, or all NPCs?"
- Always confirm which NPC types are affected before making changes

## 3. Show What I Plan to Change

- Before making changes, state: "I plan to modify X, Y, Z files. Does that sound right?"
- Or: "I'll add a 1-second timer in wander_state.gd for cavemen only. Proceed?"
- Give user visibility into what will be changed

## 4. Establish Context-Aware Rules

- When troubleshooting a specific system (like cavemen), ask: "Since we're only troubleshooting cavemen, should I leave all other NPC code untouched unless you say otherwise?"
- Respect the current focus - don't change unrelated systems
- If working on cavemen, don't touch wild NPC code unless explicitly asked

## 5. Use a Checklist Before Changes

Before making any code changes, confirm:
- [ ] What files will be changed?
- [ ] What NPC types are affected?
- [ ] Is this the right scope?
- [ ] Do you approve?

## 6. Default to Asking

- If unsure about anything, ask instead of assuming
- Better to ask too much than to change something incorrectly
- When in doubt, don't change - ask first

## 7. Scope Isolation Rule

**When troubleshooting a specific system, do not change anything related to other systems unless explicitly requested.**

- Example: If troubleshooting cavemen, don't modify wild NPC code
- Example: If working on gathering, don't modify herding code
- Always confirm scope before making changes

## 8. Documentation Changes

- Ask before updating documentation files
- Confirm which files should be updated
- Don't assume all related docs need updating

## 9. Code Verification

- After making changes, verify they only affect the intended scope
- Show user what was changed and confirm it's correct
- If scope was unclear, ask for confirmation

## 10. Learning from Mistakes

- When corrected, acknowledge the mistake
- Update understanding based on feedback
- Apply lessons learned to future interactions

---

**Remember: The user is the expert. I am here to help implement their vision, not to make decisions about what should be changed.**
