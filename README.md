# strip-coauthor

A git `pre-push` hook that automatically removes `Co-Authored-By:` trailers from every commit before it reaches the remote — silently and without touching your local history until the moment you push.

## Why

AI coding assistants (Claude Code, GitHub Copilot, etc.) append `Co-Authored-By:` lines to commits. That's fine for private repos, but you may not want AI attribution visible in public history. This hook intercepts the push, rewrites only the outgoing commits, and pushes the clean versions — nothing else changes.

## Requirements

| Tool | Required | Notes |
|------|----------|-------|
| bash ≥ 4 | yes | macOS ships bash 3; install via Homebrew (`brew install bash`) |
| python3 | yes | used for the sequence-editor script |
| git ≥ 2.13 | yes | for `GIT_SEQUENCE_EDITOR` support |

## Install

### One repo

```bash
cp pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

Or, if you have cloned this repo:

```bash
bash install.sh
```

### Global (all repos, recommended)

```bash
bash install.sh --global
```

This sets `core.hooksPath` to `~/.config/git/hooks` (unless it is already set somewhere else) and copies the hook there. All existing hooks in that directory are left untouched.

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

1. Git feeds the hook a list of `<local-ref> <local-sha> <remote-ref> <remote-sha>` lines on stdin before the push starts.
2. The hook resolves every commit that is **new on this push** (not yet on the remote).
3. If any of those commits contain a `Co-Authored-By:` line, it runs a non-interactive rebase (`GIT_SEQUENCE_EDITOR` + `GIT_EDITOR`) that rewrites only those commits, removing the trailer and trimming the trailing blank lines.
4. The push then proceeds with the rewritten commits.

No commits that already exist on the remote are ever touched.

## Behaviour notes

- **Safe by default** — if the rebase fails for any reason the hook aborts, restores the original HEAD, and exits non-zero so the push is cancelled.
- **No extra dependencies** — uses only `bash`, `python3`, and `git` builtins.
- **Multiple branches at once** — handles multi-ref pushes correctly.
- **Root commits** — correctly handles the case where the oldest commit to rewrite has no parent.
- **Tag-only pushes** — exits immediately with no-op.

## Uninstall

### One repo

```bash
rm .git/hooks/pre-push
```

### Global

```bash
rm ~/.config/git/hooks/pre-push
# optionally un-set core.hooksPath if you set it only for this hook:
# git config --global --unset core.hooksPath
```

## Troubleshooting

**`/usr/bin/env: 'python3': No such file or directory`**
Install Python 3 or symlink it: `ln -s $(which python) /usr/local/bin/python3`

**Rebase conflicts during push**
The hook rewrites commit messages only — it should never cause conflicts. If it does, open an issue with `git log --oneline -10` output.

**macOS bash 3 `declare -A` error**
Upgrade bash: `brew install bash`. The system bash at `/bin/bash` is version 3 and lacks associative arrays.

## License

MIT — see [LICENSE](LICENSE).
