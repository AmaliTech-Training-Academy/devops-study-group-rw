# Week II: CI/CD with GitHub Actions (Intermediate–Advanced)

<p align="center">
  <img alt="Week 2" src="https://img.shields.io/badge/Week-2-7C4DFF?style=for-the-badge"/>
  <img alt="Focus" src="https://img.shields.io/badge/Focus-CI%2FCD-0A7EA4?style=for-the-badge"/>
  <img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=fff&style=for-the-badge"/>
  <img alt="Automation" src="https://img.shields.io/badge/Automation-YAML-555?style=for-the-badge"/>
  <img alt="Security" src="https://img.shields.io/badge/Security-OIDC-6f42c1?style=for-the-badge"/>
</p>

> **⚠️ Scope note:** This week is about CI/CD using GitHub Actions: workflows, runners, caching, artifacts, secrets, security, and gated deployments.
>
> **📋 Prerequisites:** Git/GitHub basics, GitHub CLI (`gh`) installed and authenticated, a demo repo to run workflows, basic YAML comfort.
>
> **What you’ll build:** End-to-end workflows that lint, test, build, cache, publish artifacts, and deploy with approvals and OIDC-based cloud auth.

---

## 🚀 GitHub Actions Fundamentals

### Topics
- Workflow triggers: `push`, `pull_request`, `workflow_dispatch`, `schedule`.
- Jobs & runners: hosted vs. self-hosted, `runs-on`, `container` jobs.
- Steps: actions vs. shell, using the GitHub token, `permissions` hardening.
- Artifacts & caching: `actions/upload-artifact`, `actions/cache` (keys/paths/restore-keys).
- Matrices & strategy: build/test across versions and OSes; `fail-fast`, `max-parallel`.
- Concurrency & conditions: `concurrency`, `if:` guards, `needs` for dependencies.
- Secrets & environments: `secrets`, `env`, environments with approvals, protection rules.
- OIDC to clouds: short-lived credentials to AWS/Azure/GCP; avoiding long-lived secrets.
- Reusable & composite workflows: `workflow_call`, `inputs/secrets`, local composite actions.
- Security: pin actions by commit SHA, least-privileged permissions, dependency review/code scanning hooks.

### 5-minute exercises
1. Create a `ci.yml` that runs on `push` and `pull_request` to `main`, executes lint + tests, and uploads a test report artifact.
2. Add a matrix for Node or Python versions (e.g., `node: [18, 20]` or `python: [3.10, 3.11]`) and fail-fast off.
3. Add build caching (e.g., npm/pnpm/pip cache) with a sensible key and restore-keys.
4. Add an environment `staging` requiring approval; gate a deploy job with `environment: staging`.
5. Add OIDC-based AWS auth using a role ARN and deploy a static site to S3 (no long-lived secrets).
6. Add `concurrency` to prevent overlapping deploys for the same branch/ref.

#### Handy snippets

Minimal CI (lint + test + artifact):
```yaml
name: ci
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --json --outputFile=reports/tests.json
      - uses: actions/upload-artifact@v4
        with:
          name: test-report
          path: reports/tests.json
```

Matrix + cache + concurrency:
```yaml
name: matrix-ci
on: [push]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        node: [18, 20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm test
```

Environment-gated deploy with OIDC (AWS example):
```yaml
name: deploy
on:
  workflow_dispatch:
    inputs:
      env:
        description: "Environment"
        required: true
        default: staging

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.env }}
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/gha-oidc-role
          aws-region: eu-west-1
      - run: |
          aws s3 sync dist/ s3://my-site-${{ inputs.env }}/ --delete
```

---

## 🛠️ GitHub Actions CLI & Tooling
- Run and inspect workflows: `gh workflow run`, `gh run list`, `gh run view --log`.
- Generate starter workflows: `gh workflow list`, `gh workflow view`.
- Local authoring aids: `actionlint` (YAML/static checks), `npm exec --yes @actions/toolkit` for local action dev helpers.

### 5-minute exercises
1. Trigger a workflow manually with `gh workflow run ci.yml` and inspect logs with `gh run view --log`.
2. Add `permissions` to the workflow to least-privilege (e.g., `contents: read`, `pull-requests: write` if needed).
3. Add `actionlint` to CI to lint workflow files on every PR.

---

## 🚧 Project 1: Full CI Pipeline
- Lint, test, and build a sample app (Node or Python) on `push`/`pull_request`.
- Matrix across two runtimes (Node 18/20 or Python 3.10/3.11).
- Cache dependencies; upload test and coverage artifacts.
- Enforce `fail-fast: false` and `concurrency` to avoid overlapping runs.
- Require status checks in branch protection (set in repo settings).

## ☁️ Project 2: Staged Deploy with Approvals
- Jobs: `build` -> `deploy_staging` (environment `staging` with approval) -> `deploy_prod` (environment `production` with approval).
- Use artifacts to pass build outputs between jobs.
- Use OIDC to assume a cloud role (AWS example) without long-lived secrets.
- Add `if: github.ref == 'refs/heads/main'` guard for production deploy.
- Add notifications step (e.g., Slack or Teams) on success/failure.

---

## 🎯 Summary
This week you’ll build practical CI/CD workflows with GitHub Actions: automated lint/test/build, caching, artifacts, environment-gated deploys, OIDC auth, and safe concurrency controls.

---

## Resources
- Official docs: [GitHub Actions](https://docs.github.com/actions) • [Workflow syntax](https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions) • [Reusable workflows](https://docs.github.com/actions/using-workflows/reusing-workflows) • [Caching](https://docs.github.com/actions/using-workflows/caching-dependencies) • [OIDC security hardening](https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- Tooling: [actionlint](https://github.com/rhysd/actionlint) (lint workflow YAML)
- Examples: [actions/checkout](https://github.com/actions/checkout) • [actions/setup-node](https://github.com/actions/setup-node) • [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
- YouTube — CI/CD explained: [Video](https://www.youtube.com/watch?v=AknbizcLq4w)
- YouTube — Fundamentals of GitHub Actions: [Video](https://www.youtube.com/watch?v=R8_veQiYBjI)
- YouTube — Advanced GitHub Actions with Kubernetes: [Video](https://www.youtube.com/watch?v=Xwpi0ITkL3U)
