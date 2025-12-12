# Week I: Bash Scripting (Intermediate–Advanced), Git & GitHub (Advanced)

<p align="center">
  <img alt="Week 1" src="https://img.shields.io/badge/Week-1-7C4DFF?style=for-the-badge"/>
  <img alt="Level" src="https://img.shields.io/badge/Level-Intermediate%E2%80%93Advanced-1E90FF?style=for-the-badge"/>
  <img alt="Bash" src="https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff&style=for-the-badge"/>
  <img alt="Git" src="https://img.shields.io/badge/Git-F05032?logo=git&logoColor=fff&style=for-the-badge"/>
  <img alt="GitHub" src="https://img.shields.io/badge/GitHub-181717?logo=github&logoColor=fff&style=for-the-badge"/>
  <img alt="GitHub CLI" src="https://img.shields.io/badge/GitHub_CLI-181717?logo=github&logoColor=fff&style=for-the-badge"/>
  <img alt="AWS CLI" src="https://img.shields.io/badge/AWS_CLI-232F3E?logo=amazonaws&logoColor=fff&style=for-the-badge"/>
  <img alt="No Actions" src="https://img.shields.io/badge/GitHub%20Actions-Next%20Week-orange?style=for-the-badge"/>
</p>

> **⚠️ Scope note:** This week is about Bash, Git, and GitHub administration. GitHub Actions intentionally not covered — that's for next week.

> **📋 Prerequisites:** Have Git, GitHub CLI (`gh`), and AWS CLI installed and authenticated. On Windows, use WSL or Git Bash for Bash exercises.
>
> **Docs:** [Git](https://git-scm.com/downloads) • [GitHub CLI](https://cli.github.com/) • [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

---

## 🔧 Bash Scripting — Intermediate → Advanced

### Topics

- Safer scripts with `set -euo pipefail`, quoting, and exit codes.
- Functions, parameters, return codes; `getopts` for flags.
- Arrays and associative arrays; subshells vs grouping; heredocs/herestrings.
- Jobs, traps, and cleanup with `trap '...' EXIT`.
- Process control and pipelines; `xargs` vs loops; command substitution.
- Integrations: calling `gh` and `aws`, parsing JSON output (`--json` flags; optional `jq`).

<!-- Resources moved to bottom -->

### 5‑minute exercises

1. Create `backup.sh` that takes `-s <src>` and `-d <dst>` via `getopts`, uses `set -euo pipefail`, copies only `*.conf` files, and prints how many files were copied.
2. Write `wait_for_port.sh` that loops until `localhost:5432` is open, with a 10s timeout using `SECONDS` and `nc` or `bash` `/dev/tcp`.
3. Integrate CLI: list your open PRs with `gh pr list --state open --json number,title --jq '.[] | "#\(.number) \(.title)"'` and save to `prs.txt`.
4. Integrate AWS: print all S3 bucket names with `aws s3api list-buckets --query 'Buckets[].Name' --output text`; for each, show object count using `aws s3 ls s3://BUCKET --recursive | wc -l`.

---

## 🔀 Git & GitHub — Advanced

### Essential Git Operations

- **Branching & Merging:** Create branches (`git branch`, `git checkout -b`), merge branches (`git merge`), delete branches (`git branch -d`).
- **Commit Management:** Amend last commit (`git commit --amend`), reset commits (`git reset --soft/--mixed/--hard`), view history (`git log`, `git log --oneline --graph`).
- **Remote Operations:** Fetch updates (`git fetch`), pull changes (`git pull`), push commits (`git push`, `git push -u origin branch`), manage remotes (`git remote -v`).
- **Stashing:** Save work temporarily (`git stash`), list stashes (`git stash list`), apply stash (`git stash pop`, `git stash apply`).
- **Conflict Resolution:** Identify conflicts, resolve manually, stage resolved files (`git add`), complete merge (`git commit`).
- **Viewing Changes:** Check status (`git status`), view diffs (`git diff`, `git diff --staged`), show commits (`git show`).

#### Examples

```bash
# Branching & merging
git checkout -b feature/login
git merge feature/login
git branch -d feature/login

# Commit management
git commit --amend --no-edit
git reset --soft HEAD~1   # keep changes staged
git reset --hard HEAD~1   # discard last commit and changes

# Remote operations
git fetch origin
git pull
git push -u origin feature/login

# Stashing
git stash
git stash list
git stash pop

# Conflict resolution (typical flow)
git merge feature/other
# resolve files, then
git add .
git commit

# Viewing changes
git status
git diff --staged
git log --oneline --graph --decorate --all
```

### GitHub Administration

- **Branch protection rules:** required reviews, required status checks, linear history, dismissal on new commits.
- **Pull Requests:** templates, draft PRs, auto-merge settings, merge methods (rebase, squash).
- **Issues:** labels, assignees, milestones, saved replies, forms YAML (issue forms).
- **Security tab:** Dependabot alerts, secret scanning, code scanning overview, advisories.
- **Ownership:** `CODEOWNERS` for review routing (e.g., `docs/* @docs-team`).
- **Tags/Releases:** create/delete tags and annotated releases via CLI and Web UI.

<!-- Resources moved to bottom -->

### 5‑minute exercises

1. Create a new branch (`git checkout -b feature/new-feature`), make 2 commits, push to remote (`git push -u origin feature/new-feature`), then merge into main.
2. Trigger and resolve a merge conflict: create two branches, edit the same line differently, merge one branch, then resolve conflicts when merging the second.
3. Practice stashing: make changes without committing, stash them (`git stash`), switch branches, then return and apply the stash (`git stash pop`).
4. Amend a commit: make a commit, realize you forgot something, add the changes and use `git commit --amend` to update the last commit.
5. Create a PR with `gh pr create`, request a review from a teammate, merge it using `gh pr merge`.
6. Add a `CODEOWNERS` file with `* @your-team` and test by opening a PR (owners should be requested automatically).

---

## 🛠️ CLI Focus: GitHub CLI and AWS CLI

### GitHub CLI (`gh`)

- **Authenticate:** `gh auth login`; set default repo with `gh repo set-default`.
- **PRs:** `gh pr list`, `gh pr view`, `gh pr create`, `gh pr merge --squash`.
- **Issues/Projects:** `gh issue create`, `gh issue list`.
- **Admin via API:** use `gh api` to manage branch protection rules programmatically.
- **Tags/Releases:** create, list, delete tags and draft releases: `git tag` + `gh release create`, `gh release delete`.

<!-- Docs moved to bottom -->

### AWS CLI

- **Profiles and regions:** `aws configure --profile dev` (set default region to `eu-west-1`), `--output json`.
- **Common services:** `s3`, `ec2`, `iam` with `--query` (JMESPath) filters.
- **Safety:** least-privileged IAM creds, tag filtering.

<!-- Docs moved to bottom -->

### 5‑minute exercises

1. List PRs assigned to you as JSON and pretty-print titles: `gh pr list --search "assignee:@me state:open" --json title --jq '.[].title'`.
2. Create an issue with a label and body: `gh issue create -t "Bug: login" -b "Steps to reproduce..." -l bug`.
3. List EC2 instances showing name and state: `aws ec2 describe-instances --query 'Reservations[].Instances[].{Name: Tags[?Key==\`Name\`]|[0].Value, State: State.Name, Id: InstanceId}' --output table`.
4. Sync a local folder to S3 (test bucket): `aws s3 sync ./public s3://YOUR-BUCKET/public --delete` (use a non-critical bucket).
5. Create a draft release from a tag: `gh release create v0.2.0 -t "v0.2.0" -n "Changelog..." --draft`. Delete with `gh release delete v0.2.0` (confirm prompt).


> **⚠️ Next week:** GitHub Actions (workflows, runners, environments, secrets) — not part of this guide.

---

## 🚀 Project 1: GitHub Automation (`gh` CLI)

### Goal

- Create 7 repositories named `capstone-proj-repo-1` through `capstone-proj-repo-7` using a Bash script that leverages GitHub CLI (`gh`).
- For each repo, create branches: `development`, `staging`, `production`.
- Apply branch protections and `CODEOWNERS`:
  - `development`: code owner _rodrigue_, require 2 reviews, owners must approve.
  - `staging`: code owner _viateur_, require 1 review, owner must approve.
  - `production`: code owner _valence_, require 1 review, owner must approve.

### Inputs

- **Interactive:** prompt for names; or
- **File list:** read repo names from `repos.txt`.
- **Default names:** if no names are provided, create `capstone-proj-repo-1` to `capstone-proj-repo-7`.
- **Flags:** `-o <org>`, `-f <file>`, `-n <name1,name2,...>`, `--private/--public`.

## ☁️ Project 2: AWS CLI Infrastructure

### Goal
 
- Provision an EC2 Auto Scaling Group with user-specified min, desired, and max.
- Create an Application Load Balancer routing to those instances.
- Provide commands to create, destroy, and list status.
- Keep the Application Load Balancer in a single Availability Zone for simplicity.

### Usage

**Arguments:** `create`, `destroy`, or `list`

**Flags for `create`:**
- `--stack-name` (required)
- `--min`, `--desired`, `--max` (required)

**Flags for `destroy`:**
- `--stack-name` (required)
- Confirmation prompt is required

**Flags for `list`:**
- No flags

#### Notes

- Uses your AWS CLI default profile and region. If no default region is configured, the script will use `eu-west-1`.
- The load balancer is intentionally created in a single Availability Zone to reduce complexity.

#### Examples

```bash
# Create a stack (uses default region eu-west-1)
./stack.sh create --stack-name web-stack --min 2 --desired 3 --max 5

# List current stacks/resources (defaults to eu-west-1)
./stack.sh list

# Destroy a stack (confirmation prompted; default region eu-west-1)
./stack.sh destroy --stack-name web-stack
```

## 🎯 Summary

This week focuses on mastering Bash scripting and Git/GitHub workflows. Practice the exercises, build the projects, and ensure you understand every command before moving forward. Next week we'll dive into GitHub Actions!

---

## Resources

- Official docs: [GNU Bash Manual](https://www.gnu.org/software/bash/manual/bash.html) • [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) • [GitHub CLI Manual](https://cli.github.com/manual)
- YouTube — Linux scripting courses: [Video](https://www.youtube.com/watch?v=PNhq_4d-5ek) • [Playlist](https://www.youtube.com/watch?v=2733cRPudvI&list=PLT98CRl2KxKGj-VKtApD8-zCqSaN2mD4w)
- YouTube — GitHub CLI: [Video](https://www.youtube.com/watch?v=j5zUoyPaQqc)
- YouTube — AWS CLI: [Video](https://www.youtube.com/watch?v=PWAnY-w1SGQ)
- Interactive — Linux command game: [cmdchallenge.com](https://cmdchallenge.com)
- LLM assistants (use responsibly to learn/iterate): ChatGPT, Claude, Gemini
