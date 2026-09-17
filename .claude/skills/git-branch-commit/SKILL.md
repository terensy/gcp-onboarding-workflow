---
name: git-branch-commit
description: This repo's standing git workflow for landing any change — always branch, never commit straight to main. Use this whenever the user asks to commit, ship, save, land, or push a change in this repository (e.g. "commit this", "commit and push", "ship it", "commit and merge", "can you push that up"), even if they don't spell out the branch/merge/push steps explicitly — those steps are implied by this repo's convention, not optional extras the user has to ask for separately. Also use it to recover if a change ever ends up committed directly on main by mistake.
---

# Git branch → commit → no-ff merge → push

## Why this exists

The maintainer of this repo wants every change traceable through a feature branch and a merge commit — never a direct commit on `main`. Look at `git log --oneline --merges` and you'll see the whole history is built this way (`Merge branch 'feature/sme-quickstart'`, `Merge branch 'feature/ai-onboarding'`, ...). A direct push to `main` breaks that trail, and it's happened before in this repo's history by mistake — twice in one session, which is why this workflow is written down instead of re-explained each time. Follow it by default; only skip a step if the user explicitly says so for that specific request.

## The workflow

**0. Look before you branch.** Run `git status` and `git branch --show-current` first — don't assume the working tree is clean or that you're on `main`. If there are unrelated pre-existing changes in the working tree that the current task didn't produce, don't sweep them into this commit; ask or leave them alone.

**1. Branch off main before touching the index.** If you're on `main`, create the branch *before* staging or committing anything — never commit-then-branch:

```bash
git checkout -b <type>/<short-kebab-description>
```

Use `feature/...` for new work, `fix/...` for a correction — both patterns already exist in this repo's branch history (`git branch -a` / `git log --oneline --merges` to check naming precedent before inventing a new one).

**2. Stage by name, and look at what you staged.** Never `git add -A` or `git add .` — list the files explicitly so nothing unrelated rides along:

```bash
git add path/to/file1 path/to/file2
git status --short   # confirm the staged set is exactly what you intend
```

**3. Commit with a real message.** Match this repo's existing tone (`git log` for recent examples) — lead with *why*, not just *what*; a multi-paragraph body for anything non-trivial, a one-liner only for genuinely small changes. Whatever attribution trailer the current session's instructions specify goes at the end (check the system reminder governing commit attribution in this session — don't assume it's frozen; as of this writing it's `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`, but that value can change over time and the live instruction wins over this note).

**4. Merge into main with `--no-ff`, always:**

```bash
git checkout main
git merge --no-ff <branch> -m "Merge branch '<branch>'"
```

Never let this fast-forward — the explicit merge commit is the point. The `-m` message matches the plain `Merge branch '<branch>'` phrasing already used throughout this repo's history; don't embellish it.

**5. Push everything that changed, in one go:**

```bash
git push origin main <branch>
```

"Push all branches" means the feature/fix branch included — don't leave it sitting local-only on the remote-tracking side while only `main` goes up.

**6. Never force-push, never rewrite history that's already on origin, and never take a shortcut back to step 4 by committing straight on `main`.** If a step fails partway, fix forward with a new commit rather than reaching for `reset --hard` or `push --force`.

## Recovery: something already landed directly on main

If a change somehow already got committed and pushed straight to `main` (skipping the branch), don't force-push or reset to undo it — that rewrites published history. Instead, do it the safe, additive way:

```bash
# 1. Undo it on main with a revert commit (forward-only, safe to push)
git checkout main
git revert --no-edit <bad-commit-sha>
git push origin main

# 2. Redo the same change properly, on a branch
git checkout -b fix/<short-kebab-description>
git cherry-pick <bad-commit-sha>

# 3. Merge it back in the normal way
git checkout main
git merge --no-ff fix/<short-kebab-description> -m "Merge branch 'fix/<short-kebab-description>'"
git push origin main fix/<short-kebab-description>
```

End state: `main` has the same content it would have had if the branch flow had been followed from the start, reached through a revert + a proper branch + merge instead of one direct commit — no force-push, no lost history, nothing destroyed.
