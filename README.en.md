# wise-vibe — unified dev-standard plugin for vibe coding

Give it a PRD, or several planning documents (PDF, Markdown, DOCX). It recommends a stack and database, generates a docker compose project, implements and tests it, then reviews the result. One set of Agent Skills is shipped to **Claude Code, Cursor, Google Antigravity, GitHub Copilot and Codex**.

- 한국어: [README.md](README.md)
- Based on [pub-wise-dev-std](https://github.com/WisemanLim/pub-wise-dev-std) v1.2.0 (commit 4be11b9).
- Design rationale: whitepaper TR-2026-10, roadmap in chapter 7 and verdicts in chapter 5. What was applied is listed in [docs/MIGRATION.md](docs/MIGRATION.md).

## 1. What changed (wise-dev-std → wise-vibe)

| Area | wise-dev-std 1.2 | wise-vibe 2.0 |
|------|------------------|---------------|
| Format | 11 commands + 9 skills | **10 skills (`wds-*`)**, open Agent Skills spec only |
| Distribution | Claude plugin + 7 copied IDE rule files | `install.sh --tool claude\|cursor\|antigravity\|copilot\|codex\|all` → each tool's official skill path |
| PRD input | survey | survey + **multiple documents** (`a.pdf a-ui-design.pdf …`) with role inference and source citations |
| Environments | local/dev/staging/prod, separate env-init | **local / prod only**; env-init merged into scaffold |
| Run | host process managers (PM2, honcho, goreman, overmind) + compose | **docker compose only**, with `dev` and `runtime` image stages |
| Database | SQLite locally, PostgreSQL elsewhere | SQLite for local by default (`--local-db` exception); prod `--db postgres` (default), `mysql`, `mariadb` or `sqlite` |
| Multiple services | — | **integration repo (`workspace`)** + sub repos (`--workspace`): release.sh, deploy tests, DEPLOY-PROD-GUIDE, READMEs (2.1) |
| Review, test, UI, implement loop | all custom | delegated to official features where they exist; only the unique parts are kept |

## 2. Skills (whitepaper section 5.4 verdicts)

| Skill | Verdict | Role | Delegated to / replaced by |
|-------|---------|------|----------------------------|
| `wds-prd` | keep | documents + survey → `PRD.md` | doc-coauthoring, docx/pdf (optional) |
| `wds-recommend` | keep | PRD × KSIC industry → language, package manager, framework, prod DB | — |
| `wds-scaffold` | keep (absorbs env-init) | deterministic compose scaffold | — |
| `wds-living-doc` | keep (absorbs req-update) | propagates requirement changes to docs | — |
| `wds-reverse-prd` | keep | source code → PRD | — |
| `stack-architect` agent | keep | runs the whole flow | — |
| `wds-test` | delegate | `test/dev-env`, `test/impl/<Nth>` conventions | webapp-testing, /verify, browser agents |
| `wds-implement` | delegate | epic plan, test rounds, BLOCKED handling | ralph-loop, /loop, feature-dev, Antigravity /goal |
| `wds-review` | delegate + replace | reader-level line review, license / ISO 5230 audit | /code-review, /security-review, pr-review-toolkit, Bugbot; **pdf/docx skills replace the old converter** |
| `wds-ui-design` | delegate | Korean references, KWCAG, per-platform design delta | frontend-design, theme-factory |
| `wds-standardize` | redesigned | AGENTS.md managed block + skill install | — |
| packaging & hooks | added | Claude, Cursor and Agent Plugins manifests; SessionStart hook | — |

## 3. Install

**Claude Code plugin** (recommended for teams):
```
/plugin marketplace add WisemanLim/wise-vibe-plugin
/plugin install wise-vibe@wise-vibe
```

**One-line install** (2.1):
```bash
curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash                          # detect installed tools → user scope
curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash -s -- --tool claude,codex  # explicit tools (project scope: current dir)
curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash -s -- --list               # detection and skill list only
```
- For a private repo `raw.githubusercontent.com` returns 404; use `gh api -H "Accept: application/vnd.github.raw" repos/WisemanLim/wise-vibe-plugin/contents/install.sh | bash -s -- [options]` (the body is fetched with `gh api` too).
- Without `--tool` the installer detects tools (`~/.claude`, `~/.cursor`, `~/.gemini`, `~/.copilot`, `~/.codex` or their executables) and uses `--scope user`; with `--tool` the scope defaults to project, as before.
- `--ref <tag>` pins a version, `--source <checkout>` uses a local copy, `--plugin` prints the Claude Code marketplace commands. A truncated download never runs (the whole script is one `{ … }` group).

**Any tool**, from a checkout, by passing the tool to the install script:
```bash
/path/to/wise-vibe-plugin/install.sh --tool cursor
/path/to/wise-vibe-plugin/install.sh --tool copilot,codex
/path/to/wise-vibe-plugin/install.sh --tool all --hooks
/path/to/wise-vibe-plugin/install.sh --tool all --scope user
/path/to/wise-vibe-plugin/install.sh --tool all --uninstall
```

| `--tool` | project path | user path | agents | hooks (`--hooks`) |
|----------|--------------|-----------|--------|-------------------|
| claude | `.claude/skills` | `~/.claude/skills` | `.claude/agents` | `.claude/settings.json` |
| cursor | `.cursor/skills` | `~/.cursor/skills` | `.cursor/agents` | `.cursor/hooks.json` |
| antigravity | `.agents/skills` | `~/.gemini/config/skills` | `.agents/agents` | none (AGENTS.md instruction) |
| copilot | `.github/skills` | `~/.copilot/skills` | — | — |
| codex | `.agents/skills` | `~/.agents/skills` | — | — |
| all | `.agents/skills` + relative links in `.claude/skills` | all of the above | both | Claude + Cursor |

**What the installer also does**
- Writes a managed block into `AGENTS.md`.
- Adds `@AGENTS.md` to an existing `CLAUDE.md`. When a `CLAUDE.md` exists, Claude Code ignores `AGENTS.md`.

**Plugin manifests**

| Manifest | Read by |
|----------|---------|
| `.claude-plugin/` | Claude Code (Copilot CLI also reads this marketplace) |
| `.cursor-plugin/` | Cursor 2.5+ |
| `plugins/wise-vibe/plugin.json` (Agent Plugins 1.1) | Codex, Copilot, Cursor, Antigravity |

Install commands:
- Antigravity: `agy plugin install plugins/wise-vibe`
- Copilot CLI: `copilot plugin install WisemanLim/wise-vibe-plugin:plugins/wise-vibe`

## 4. Flow

```
wds-prd → wds-recommend → wds-scaffold → wds-implement   (optional: wds-test, wds-review, wds-living-doc, wds-standardize)
```

How you invoke a skill depends on the tool:
- Claude Code plugin: `/wise-vibe:wds-<name>`
- Claude Code (installed by script), Cursor, Antigravity, Copilot: `/wds-<name>`
- Codex: `$wds-<name>`

**PRD from several documents**

```
/wds-prd spec.pdf spec-ui-design.pdf api-spec.docx --domain commerce
```

1. Text is extracted to `.wds/prd-sources/`. If no extractor is available, or the PDF is a scan, the agent reads the original file.
2. The filename sets each document's role:
   - `*ui*` / `*design*`: design requirements
   - `*api*` / `*spec*`: integrations
   - `*nfr*` / `*security*`: non-functional requirements
   - anything else: main body
3. Each PRD item cites its source. Conflicts between documents are listed as open questions.
4. Only the gaps are asked about in the survey.

**Scaffold:** for example `/wds-scaffold python-fastapi --db mysql --extras redis`.

| Mode | Compose files | Env file | Database | Image stage |
|------|---------------|----------|----------|-------------|
| local | `docker-compose.yml` + `docker-compose.local.yml` | `.env.local` | SQLite (same RDBMS as prod with `--local-db <db>`, via `compose/db.yml`) | `dev` |
| prod | `docker-compose.yml` + `docker-compose.prod.yml` | `.env.prod` (CHANGE_ME placeholders) | `--db` | `runtime` |

Make targets:
- `make <local|prod>-{all,build,logs,stop,restart,ps}`
- `make test`
- `make db-{ping,shell,migrate,seed,reset,fresh} [ENV=]`
- `make preflight`, `make deploy`

Profiles also include `react-spa` (Vite + nginx static SPA, no database).

**Several services: integration repo + sub repos** (2.1)
```bash
S=plugins/wise-vibe/skills/wds-scaffold/scripts/scaffold.sh
bash $S workspace --name app --services app-api:api:8280:db,app-web:web:8290 --target .     # root, never tracks sub repos
bash $S go-gin --db postgres --local-db postgres --workspace app --name app-api --target app-api
bash $S react-spa --workspace app --name app-web --target app-web
make test && release/release.sh up --env dev --yes                                          # deploy regression, then local rehearsal
```
The root gets `Makefile`, `README.md`/`README.en.md`, `DEPLOY-PROD-GUIDE.md`, `release/{release.sh,services.tsv,deploy.env.example}`,
`scripts/{prod-secrets,secret-scan}.sh`, `test/deploy/` (deployment tests only), `docs/TEST-OWNERSHIP.md`, CI (gitleaks + make test) and a `.gitignore` that excludes the sub repos.
`release.sh` covers `doctor`, `build` (multi-arch tar.gz + sha256), `up`, `deploy` (ssh, image streaming, releases/<V> + current + shared secrets), `status`, `down` and `rollback`, with exit codes 0/2/4/5/8.

## 5. Validate

```bash
make validate   # skill spec, YAML, JSON, version consistency, claude plugin validate
make test       # scaffold matrix (profiles × DBs, compose config), installer, document extraction
```

Docker end-to-end results are in [docs/MIGRATION.md §5](docs/MIGRATION.md#5-검증-결과).

## 6. Limitations

- The Cursor and Antigravity manifests follow the official docs as of 2026-10-01. Publishing to their marketplaces was not tested.
- There is no Codex marketplace file. Use `install.sh --tool codex` instead.
- `/health` runs a real database query only in the Python and Java templates. For every profile, `make db-ping ENV=prod` checks the DB container's health.
- Mobile templates need their platform SDKs, so they are checked structurally only.
- `workspace` `deploy --host`, `rollback`, `--install-deps` and multi-arch `build` need a target server and are outside the automated tests (`up`/`status`/`down` are covered by a local rehearsal).
