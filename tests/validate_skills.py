#!/usr/bin/env python3
"""wise-vibe 스킬·매니페스트 정적 검증 (Agent Skills 사양 + 저장소 규칙). 표준 라이브러리 + PyYAML(있으면)."""
import glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, "plugins", "wise-vibe")
errors, checks = [], 0


def check(cond, msg):
    global checks
    checks += 1
    if not cond:
        errors.append(msg)


def frontmatter(path):
    text = open(path, encoding="utf8").read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return (m.group(1) if m else None), text


try:
    import yaml
except ImportError:
    yaml = None

# 1. SKILL.md — agentskills.io 사양
for skill_md in sorted(glob.glob(os.path.join(P, "skills", "*", "SKILL.md"))):
    d = os.path.basename(os.path.dirname(skill_md))
    fm, text = frontmatter(skill_md)
    check(fm is not None, f"{d}: frontmatter 없음")
    if fm is None:
        continue
    meta = yaml.safe_load(fm) if yaml else {}
    name = meta.get("name") if yaml else re.search(r"^name:\s*(\S+)", fm, re.M).group(1)
    check(name == d, f"{d}: name({name}) != 디렉터리명")
    check(re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or "") is not None and len(name) <= 64, f"{d}: name 형식 위반")
    if yaml:
        desc = " ".join(str(meta.get("description", "")).split())
        check(1 <= len(desc) <= 1024, f"{d}: description 길이 {len(desc)} (1~1024)")
        check(len(str(meta.get("compatibility", ""))) <= 500, f"{d}: compatibility > 500")
        check(isinstance(meta.get("metadata", {}), dict), f"{d}: metadata 는 맵")
    check(text.count("\n") < 500, f"{d}: SKILL.md {text.count(chr(10))}줄 (< 500 권장)")
    check("CLAUDE_PLUGIN_ROOT" not in text, f"{d}: CLAUDE_PLUGIN_ROOT 사용 (타 도구 비호환)")
    for ref in re.findall(r"`(?:SKILL_DIR/)?((?:references|scripts|assets)/[A-Za-z0-9_./-]+)`", text):
        if "<" in ref or "*" in ref:
            continue
        check(os.path.exists(os.path.join(P, "skills", d, ref)), f"{d}: 참조 파일 없음 {ref}")

# 2. 금지 패턴 (local/prod · compose 전용)
for f in glob.glob(os.path.join(P, "skills", "wds-scaffold", "assets", "**", "*"), recursive=True):
    base = os.path.basename(f)
    check(base not in ("Procfile.dev", "ecosystem.config.cjs", ".env.dev", ".env.staging", "Staging.xcconfig"),
          f"금지 파일: {os.path.relpath(f, ROOT)}")
for f in glob.glob(os.path.join(P, "skills", "wds-scaffold", "assets", "scaffold", "*", "**", "*"), recursive=True):
    if os.path.isfile(f) and not f.endswith((".md",)):
        t = open(f, encoding="utf8", errors="ignore").read()
        check(not re.search(r"\b(honcho|goreman|overmind|pm2)\b", t), f"프로세스 매니저 잔존: {os.path.relpath(f, ROOT)}")

# 3. 레지스트리 ↔ 템플릿 ↔ 프로파일 YAML
reg = [l.rstrip("\n").split("\t") for l in open(os.path.join(P, "skills", "wds-scaffold", "assets", "profiles.tsv"), encoding="utf8") if not l.startswith("#")]
for r in reg:
    check(len(r) == 9, f"profiles.tsv 열 수 오류: {r[0]}")
    check(os.path.isdir(os.path.join(P, "skills", "wds-scaffold", "assets", "scaffold", r[2])), f"{r[0]}: 템플릿 없음")
    y = os.path.join(P, "skills", "wds-recommend", "references", "profiles", r[0] + ".yaml")
    check(os.path.isfile(y), f"{r[0]}: 프로파일 YAML 없음")
    if yaml and os.path.isfile(y):
        env = yaml.safe_load(open(y, encoding="utf8")).get("environments", {})
        check(set(env) == {"local", "prod"}, f"{r[0]}: environments 키 {sorted(env)} != [local, prod]")
    if r[1] == "service":
        t = os.path.join(P, "skills", "wds-scaffold", "assets", "scaffold", r[2])
        for need in ("Dockerfile", "docker-compose.yml", "docker-compose.local.yml", "docker-compose.prod.yml", "wds.mk"):
            check(os.path.isfile(os.path.join(t, need)), f"{r[0]}: {need} 없음")
        df = open(os.path.join(t, "Dockerfile"), encoding="utf8").read()
        check(re.search(r"AS dev\b", df) is not None, f"{r[0]}: Dockerfile dev 스테이지 없음")
        check(re.search(r"AS runtime", df) is not None, f"{r[0]}: Dockerfile runtime 스테이지 없음")
if yaml:
    for y in glob.glob(os.path.join(P, "skills", "wds-recommend", "references", "**", "*.yaml"), recursive=True):
        try:
            yaml.safe_load(open(y, encoding="utf8"))
            check(True, "")
        except Exception as e:  # noqa: BLE001
            check(False, f"YAML 오류 {os.path.relpath(y, ROOT)}: {e}")

# 4. JSON 매니페스트 + 버전 일치
versions = {}
for jf in [os.path.join(ROOT, ".claude-plugin", "marketplace.json"), os.path.join(P, ".claude-plugin", "plugin.json"),
           os.path.join(P, ".cursor-plugin", "plugin.json"), os.path.join(P, "plugin.json"), os.path.join(P, "hooks", "hooks.json")]:
    try:
        data = json.load(open(jf, encoding="utf8"))
        check(True, "")
        if "version" in data:
            versions[os.path.relpath(jf, ROOT)] = data["version"]
    except FileNotFoundError:
        check(False, f"매니페스트 없음: {os.path.relpath(jf, ROOT)}")
    except json.JSONDecodeError as e:
        check(False, f"JSON 오류 {os.path.relpath(jf, ROOT)}: {e}")
mk = json.load(open(os.path.join(ROOT, ".claude-plugin", "marketplace.json"), encoding="utf8"))
for pl in mk.get("plugins", []):
    if "version" in pl:
        versions["marketplace.plugins[" + pl["name"] + "]"] = pl["version"]
check(len(set(versions.values())) == 1, f"버전 불일치: {versions}")

print(f"checks={checks} errors={len(errors)}")
for e in errors:
    print("  FAIL", e)
sys.exit(1 if errors else 0)
