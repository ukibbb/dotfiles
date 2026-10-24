# Global Claude Instructions

These instructions apply to all projects.

## Preferences

- Be concise and direct
- Prefer simple solutions over complex ones

## Communication

- Lead with the answer or the result. Context only if it changes what I do.
- Say each thing once. No recap of what you just did, no restating my question, no closing summary that repeats the body.
- No filler: no "Great question", "Let me…", "I hope this helps", no hedging stacks ("might possibly").
- Short by default: a quick question gets 1–3 sentences; use lists/headers only when there are 3+ parallel items.
- Status updates while working: one line, what you're doing now. Not what you did before.
- Separate facts from guesses: say what you verified (code, test, error, docs) and mark the rest as an assumption.
- Ask only questions whose answer changes what you'll do; for the rest pick a sensible default and name it in one line.
- When reporting work: what changed, what was tested and the result, what wasn't checked. Skip the play-by-play.
- If you made a mistake or were too verbose, fix it in one sentence — no long apology.

## Working style

- Before changing code, find the responsible code and trace how data flows through it; base the diagnosis on evidence, not on the first idea.
- When there are several real options, compare them briefly on the same example and recommend one with the reason. Don't invent fake options or new layers/libraries without need.
- If you discover something that breaks the plan or grows the scope, stop and say what you found, what's already done, and the options.
- Match the amount of discussion to the task: small fix — short note; big change — agree the plan first.

## Git

- Never add a `Co-Authored-By: Claude ...` trailer or any other Claude/AI attribution to commit messages or PR descriptions (no "Generated with Claude Code" line either).
- Branch names: `feature/<short-name>` for new work, `release/<version>` for releases, `hotfix/<version>` for urgent fixes.
- Write commit messages in Conventional Commits format: `<type>(<optional scope>): <description>`.
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Description in imperative mood, lowercase, no trailing period, ~72 chars max.
  - Breaking changes: add `!` after the type/scope and a `BREAKING CHANGE: <details>` footer.

## Coordination with other Claude sessions

Several sessions may work in the same checkout at once (shared dev server, no worktrees).

- Coordinate only with peers working in the same repository: a peer counts only if its working directory (shown by `ListAgents` / `/peers`) is inside the same git repo as yours. Ignore sessions in other projects — don't message them about scope, and don't announce your scope to them.
- At the start of a task that edits files, call `ListAgents`. If a same-repo peer exists, send it a `SendMessage` with the files/directories you plan to change, and ask for its scope.
- Stay within your announced scope. Before editing a file outside it, message the same-repo session that owns that area and wait for a reply before editing.
- When a same-repo session messages you, reply briefly with your current scope and any files you are mid-edit on. If a session from another project asks, reply in one line that you work in a different repo.
- Don't run destructive git commands (`reset --hard`, `checkout .`, `stash`, `clean`) while a peer works in the same checkout — they wipe its uncommitted changes.

## Writing code

Separate real responsibilities, not individual steps. Don't add abstractions for hypothetical future changes. Pick the simplest complete solution that meets the requirements and keeps correctness and security. Judge simplicity across the whole solution, not by line count in one file.

Run a separate readability review before proposing code and after writing it: names, types, split of responsibilities, data flow. Pick the simplest clear form that keeps the required behavior. Do this before presenting a plan, not after I point it out.

Before the first code proposal:
- Trace the existing code and check what the technology already provides.
- Compare the draft with a simpler one: what can be removed, done directly, or left to a library or the database?
- Remove unnecessary operations and intermediate state before extracting helpers. Moving code is not simplifying it.
- Simplicity is not "no classes, no layers, few lines". Fit structure to real responsibilities, data flow and state ownership. Functions are for operations; consider an object when several operations need a shared state owner with a defined lifetime.

While writing:
- Make the main flow visible: input → check → operation → result. When a function coordinates several distinct operations, separate their details from the coordination. Don't split a single responsibility just to shorten a function.
- Let names, types and data flow tell the story. Describe fixed-shape data with named models with readable fields, not generic containers. Keep dynamic maps and collections as collections. No wrappers without a concrete benefit.
- Prefer explicit calls and composition over building a structure and then patching its internals.
- Prefer operations that do the job directly and return the needed result. Avoid unnecessary reads, preparation steps and filling in state later.
- Keep one responsibility in one place. Don't scatter the same rule or data handling across modules.
- Extract a function when its name explains a concrete operation, removes meaningful duplication, or separates responsibilities — not just to make functions shorter.
- Names reveal significant side effects. Keep the main path flat: handle path-ending cases early with return/raise/continue, no needless else. Keep else for clear, mutually exclusive variants. Don't flatten at the cost of correctness, duplicated logic, logic hidden in arbitrary helpers, or skipped resource cleanup.
- No generic mechanisms for hypothetical uses; handle current requirements.
- No config, flags or behavior-switching parameters when clear separate operations are enough.
- Don't remove validation, transactions, locks or error handling to shorten code. Explain which concrete problem they prevent.

Before handing off:
- Evaluate the simplicity of the change together with its direct dependencies: duplication, split of responsibilities, data flow, state ownership. Justify the verdict briefly with a concrete from the code — passing tests or no new layers don't prove good structure. Report problems outside the agreed scope; don't fix them without consent.
- Distinguish removing complexity from moving it to another file.
- Verify with tests that a simplification keeps required behavior, including on errors and concurrent operations.
- If a complex part stays, say briefly why a simpler version would be incorrect or harder to maintain.
- Don't present the first working version as done before checking whether a simpler way reaches the same result.
