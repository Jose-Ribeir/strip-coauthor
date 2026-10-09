# strip-coauthor

Git hooks that keep `Co-Authored-By:` trailers out of your history. A `commit-msg` hook strips them when a commit is made, so the commits you push are the commits you made (same SHAs). A `pre-push` hook catches any commit that got past it.

## Why

AI coding assistants (Claude Code, GitHub Copilot, etc.) append `Co-Authored-By:` lines to commits. That's fine for private repos, but you may not want AI attribution visible in public history. strip-coauthor removes the line before the commit exists, and as a fallback rewrites only the outgoing commits at push time.

Stripping at commit time matters because a commit's SHA covers its message: if the trailer is only removed at push, every affected commit gets a new SHA, and anything keyed on SHAs (code-review gates, CI caches, links you already shared) sees a brand-new set of commits.

## Requirements

| Tool | Required | Notes |
|------|----------|-------|
| bash | yes | any version; the Git for Windows bash works |
| Python ≥ 3.7 | yes | found as `python3`, `python` or `py` (the Windows Store `python3` stub is skipped) |
| git | yes | uses only plumbing commands (`rev-list`, `cat-file`, `hash-object`, `update-ref`) |

## Install

### One repo

From a clone of this repo, inside the target repository:

```bash
bash /path/to/strip-coauthor/install.sh
```

If the repo already has a `commit-msg` or `pre-push` hook, it is kept as `commit-msg.chained` / `pre-push.chained` and still runs after strip-coauthor.

### Global (all repos, recommended)

```bash
bash install.sh --global
```

This sets `core.hooksPath` to `~/.config/git/hooks` (unless it is already set somewhere else) and installs the hook there. Nothing is overwritten:

- the hooks are copied to `<hooks dir>/strip-coauthor-commit-msg` and `<hooks dir>/strip-coauthor` (pre-push);
- `<hooks dir>/commit-msg` and `<hooks dir>/pre-push` each become a small dispatcher that runs strip-coauthor first, then any hook of that name that was already there (moved to `<hook>.chained`). If there was none, it runs the repository's own `.git/hooks/<hook>` instead, which git would otherwise ignore once `core.hooksPath` is set; if there was one, whether the repo's hook runs stays up to that hook, as before (set `git config strip-coauthor.runRepoHook true` to run it anyway, or `false` to never run it);
- the first hook that fails stops the commit or push. Re-running the installer only refreshes strip-coauthor and the dispatchers.

### Quick one-liner (global)

```bash
curl -fsSL https://raw.githubusercontent.com/Jose-Ribeir/strip-coauthor/main/install.sh | bash -s -- --global
```

### Via npm / npx

```bash
npx strip-coauthor           # install into current repo
npx strip-coauthor --global  # install globally
```

## How it works

### At commit time (`commit-msg`)

Git hands the hook the message file just before it creates the commit. The hook deletes every line starting with `Co-Authored-By:` (any case) and the blank lines left trailing behind it. The commit is created from the cleaned message, so its SHA never needs to change. This runs for `git commit` (including `-m` and `--amend`) and `git merge`.

It does **not** run for `git commit --no-verify`, for commits replayed by `cherry-pick` / `rebase`, or for commits made before you installed it. Those are handled at push time.

### At push time (`pre-push`, fallback)

1. Git feeds the hook a list of `<local-ref> <local-sha> <remote-ref> <remote-sha>` lines on stdin before the push starts.
2. For each branch being pushed, the hook resolves every commit that is **new on this push** (not yet on the remote).
3. If any of those commits contain a `Co-Authored-By:` line, the hook re-creates them — and their descendants — with that line removed and trailing blank lines trimmed. It uses git plumbing only: trees, authors and dates are kept, nothing is checked out, and no rebase runs. Each affected local branch is moved to the rewritten history (recorded in its reflog), whether or not it is checked out.
4. Git has already picked which commits to send before a `pre-push` hook runs, so the hook **stops this push** and asks you to run it again:

   ```text
   [strip-coauthor] refs/heads/main: 2f88cebb93 -> f375f045f7
   [strip-coauthor] Removed Co-Authored-By from 1 commit(s).
   [strip-coauthor] Push stopped because git had already picked the original commits.
   [strip-coauthor] Run the same git push again to send the rewritten ones.
   error: failed to push some refs to 'origin'
   ```

   The second push finds nothing to strip and goes through.

With the `commit-msg` hook installed, this step normally finds nothing to do and the push goes through on the first try with your SHAs unchanged.

No commits that already exist on the remote are ever touched.

## Behaviour notes

- **Safe by default** — if any git command fails, the hook exits non-zero and the push is cancelled.
- **No extra dependencies** — uses only `bash`, Python 3, and `git`.
- **Multiple branches at once** — each branch in a multi-ref push is rewritten on its own ref, including branches that are not checked out.
- **Root commits and merges** — rewritten like any other commit.
- **Signed commits** — a rewritten commit loses its GPG/SSH signature, since the signature no longer matches.
- **Branch deletions and tags** — passed through untouched.

## Uninstall

In the hooks directory (`.git/hooks`, or your `core.hooksPath` for a global install):

```bash
rm strip-coauthor strip-coauthor-commit-msg pre-push commit-msg
# restore the hooks that were there before, if any:
mv pre-push.chained pre-push
mv commit-msg.chained commit-msg
```

For a global install, optionally unset `core.hooksPath` if it was set only for this hook: `git config --global --unset core.hooksPath`.

## Troubleshooting

**`[strip-coauthor] Python 3.7+ not found`**
Install Python 3.7 or newer and make sure `python3`, `python` or `py` is on the `PATH` git hooks run with.

**A push fails once and asks to be run again**
Some outgoing commits still carried a trailer (made with `--no-verify`, cherry-picked, rebased, or committed before installing) — see *At push time*. Run the push again. If it happens on every push, check that the `commit-msg` hook is installed in the hooks directory git is using (`git config core.hooksPath`).

**Stop the trailer at the source**
If the trailer comes from Claude Code, you can also turn it off there, in `~/.claude/settings.json`:

```json
{ "attribution": { "commit": "", "pr": "" } }
```

**`Both <hook> and <hook>.chained exist` during install**
A foreign hook was installed after strip-coauthor replaced the original. Merge the two by hand, then re-run the installer.

## License

MIT — see [LICENSE](LICENSE).
