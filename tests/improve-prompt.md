You are improving a Claude Code skill file called GEB (SKILL.md).

Your goal: make ONE targeted change to improve the skill's test scores, while minimizing regressions on other scenarios (up to 2 minor regressions are acceptable if overall improvement is significant).

## Current SKILL.md

```
{{skill_md}}
```

## Current Test Scores

```
{{scores}}
```

## Previous Attempts This Session

{{changelog}}

## User Feedback (from real usage)

{{feedback}}

## Rules

1. **ONE change per iteration.** Small, specific edits. Do not rewrite the entire file.
2. **Target the weakest area.** Look at the lowest-scoring category or specific failing scenarios.
3. **If a previous attempt on the same area was reverted, try a DIFFERENT approach.** Don't repeat failed strategies. Study WHY it caused regressions (see changelog) and avoid the same side effects.
4. **Do not remove content associated with passing tests.** If a section has passing scenarios, leave it alone.
5. **Prefer concrete over abstract:**
   - Add a 2-3 line example over a paragraph of description
   - Tighten existing language over adding new sections
   - Remove ineffective instructions over rewording them
6. **Keep total SKILL.md length under 200 lines.** If adding content, remove something less effective.
7. **Minimize blast radius.** When modifying a section, consider what OTHER scenarios it affects. Scope your change narrowly — add a conditional or qualifier rather than changing a general rule. For example, instead of "always provide implementation", write "for well-known patterns (pagination, CRUD, auth), provide implementation directly."
8. **Common improvement patterns:**
   - Fast scenarios failing? → The skill may need stronger "just do it" signals or fewer caveats
   - Silent rule failing? → Look for language that invites meta-commentary
   - Slow scenarios failing? → The thinking flow may need more concrete prompts for when to ask questions, while SIMULTANEOUSLY providing initial analysis (don't just ask and stop)
   - Medium scenarios failing? → The one-sentence confirmation pattern may need an example
   - Upgrade/downgrade failing? → Dynamic routing instructions may be too vague, add concrete trigger examples
   - Regressions on fast/simple tasks? → Your change probably made a rule too broad — add scope limits

## Output Format

Output ONLY the following, nothing else:

```
CHANGE_SUMMARY: <one line: what you changed and why>
TARGET_CATEGORY: <which category this targets: fast|medium|slow|silent|upgrade|downgrade|conflict|discipline>

---SKILL_MD_START---
<the complete modified SKILL.md>
---SKILL_MD_END---
```
