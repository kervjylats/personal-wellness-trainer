#!/usr/bin/env python3
"""
Universal Project Scanner v2.3
Run: python project_scanner.py   (from your project root)

v2.3 fixes vs v2.2:
  - Tech Debt markers (BUG, XXX, TODO etc.) now only flagged inside COMMENT
    lines (lines whose first non-space chars are // # or *).
    Previously "BUG" matched inside "debugShowCheckedModeBanner" and
    AppLogger.debug() calls; "XXX" matched inside "AppSpacing.xxxl".
    Both were false positives producing ~30 phantom INFO entries.
  - All markers now require word boundaries (\b) to avoid partial matches.
  - WORKAROUND added as a recognised marker.
"""

import os, sys, re, json, argparse, datetime
from pathlib import Path
from collections import Counter
from difflib import SequenceMatcher

# ── Config ────────────────────────────────────────────────────────────────────

EXCLUDED_DIRS = {
    "build", ".dart_tool", ".gradle", "dist", "out", "__pycache__",
    ".next", ".nuxt", "node_modules", ".expo", "DerivedData",
    ".idea", ".vscode", ".vs", ".fleet",
    ".git", ".svn", ".hg",
    ".cache", ".tmp", "tmp", "temp", ".pytest_cache", ".mypy_cache",
    "coverage", ".tox", "Pods", ".pub-cache",
    "android", "ios", "linux", "macos", "windows",
    "ephemeral", "Runner.xcworkspace", "GeneratedPluginRegistrant",
    "docs",
}

SOURCE_EXTENSIONS = {
    ".dart", ".js", ".ts", ".jsx", ".tsx", ".html", ".css", ".scss",
    ".py", ".yaml", ".yml", ".json", ".toml", ".env", ".ini", ".cfg",
    ".sh", ".bash", ".zsh", ".ps1", ".bat", ".md", ".txt", ".rst",
    ".go", ".rs", ".rb", ".php", ".lua",
}

ALWAYS_INCLUDE_NAMES = {
    "pubspec.yaml", "package.json", "Cargo.toml", "go.mod",
    "requirements.txt", "pyproject.toml", "Makefile", "Dockerfile",
    "docker-compose.yml", ".env.example", "analysis_options.yaml",
    "l10n.yaml", "firebase.json", ".gitignore", "README.md", "CHANGELOG.md",
}

SKIP_EXTENSIONS = {
    ".png",".jpg",".jpeg",".gif",".ico",".svg",".webp",".bmp",
    ".ttf",".otf",".woff",".woff2",".eot",".pdf",".doc",".docx",
    ".zip",".tar",".gz",".rar",".7z",".exe",".dll",".so",".dylib",
    ".class",".jar",".apk",".ipa",".mp3",".mp4",".wav",".mov",
    ".db",".sqlite",".lock",".pbxproj",".xcscheme",".storyboard",
    ".xib",".plist",".entitlements",".iml",".xcconfig",".cmake",
    ".rc",".manifest",".props",".h",".cc",".cpp",".m",
}

SKIP_FILENAME_PATTERNS = [
    r'^project_scan_.+\.md$',
    r'^project_scanner\.py$',
    r'^pubspec\.lock$',
    r'^\.flutter-plugins',
    r'^\.metadata$',
    r'^GeneratedPluginRegistrant\.',
]

SKIP_IF_ANCESTOR = {
    "android","ios","linux","macos","windows","ephemeral","docs",
}

MAX_FILE_SIZE_KB = 300
MAX_LINE_LENGTH  = 300
MAX_FUNC_LINES   = 80
MIN_DUPE_LINES   = 6
DUPE_SIMILARITY  = 0.90

# Markers that indicate tech debt — only matched in comment lines
# Using word boundaries to avoid partial matches (BUG in debug, XXX in xxxl)
TECH_DEBT_MARKERS = ["TODO", "FIXME", "HACK", "BUG", "XXX", "TEMP", "WORKAROUND"]

def _is_comment_line(stripped: str) -> bool:
    """True if this line is primarily a comment, not executable code."""
    return (stripped.startswith("//") or stripped.startswith("#")
            or stripped.startswith("*") or stripped.startswith("/*"))

# ── Project type ──────────────────────────────────────────────────────────────

def detect_project_type(root):
    dart=js=py=rust=go=False
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS and not d.startswith('.')]
        for f in filenames:
            if f=="pubspec.yaml": dart=True
            if f=="package.json": js=True
            if f in ("requirements.txt","pyproject.toml"): py=True
            if f=="Cargo.toml": rust=True
            if f=="go.mod": go=True
    types=[]
    if dart:  types.append("Flutter/Dart")
    if js:    types.append("Node.js/JS")
    if py:    types.append("Python")
    if rust:  types.append("Rust")
    if go:    types.append("Go")
    return ", ".join(types) if types else "Unknown"

# ── Issue ─────────────────────────────────────────────────────────────────────

class Issue:
    def __init__(self,level,category,file,line,message,snippet=""):
        self.level=level; self.category=category; self.file=file
        self.line=line; self.message=message; self.snippet=snippet.strip()

# ── Analyzer ──────────────────────────────────────────────────────────────────

class Analyzer:
    def __init__(self,root,project_type):
        self.root=root; self.project_type=project_type
        self.issues=[]; self._func_bodies=[]; self._tech_debt={}

    def add(self,level,category,file,line,message,snippet=""):
        rel=os.path.relpath(file,self.root)
        self.issues.append(Issue(level,category,rel,line,message,snippet))

    def add_td(self,file,line,marker,snippet):
        rel=os.path.relpath(file,self.root)
        self._tech_debt.setdefault(rel,[]).append((line,marker,snippet))

    def flush_tech_debt(self):
        for rel,entries in self._tech_debt.items():
            counts=Counter(e[1] for e in entries)
            summary=", ".join(f"{v}× {k}" for k,v in sorted(counts.items()))
            lines=sorted(set(e[0] for e in entries))
            ll=", ".join(str(l) for l in lines[:8])
            if len(lines)>8: ll+=f" …+{len(lines)-8} more"
            self.issues.append(Issue("🔵 INFO","Tech Debt",rel,0,
                f"{len(entries)} developer note(s): {summary}. Lines: {ll}"))

    def analyze_file(self,path,lines):
        rel=str(path)
        is_md=path.suffix.lower()=='.md'

        for i,raw in enumerate(lines,1):
            line=raw.rstrip("\n"); stripped=line.strip()

            if len(line)>MAX_LINE_LENGTH:
                self.add("🟡 NOTICE","Code Style",rel,i,
                    f"Line is {len(line)} chars (>{MAX_LINE_LENGTH}).",line[:120]+"…")

            # FIX v2.3: Tech Debt only flagged in comment lines with word boundaries.
            # Prevents "BUG" matching inside "debug"/"debugShowCheckedModeBanner"
            # and "XXX" matching inside "xxxl"/"AppSpacing.xxxl".
            if _is_comment_line(stripped):
                for marker in TECH_DEBT_MARKERS:
                    if re.search(rf'\b{marker}\b', stripped, re.IGNORECASE):
                        self.add_td(rel, i, marker, stripped[:80])
                        break

            # Secrets
            m=re.search(r'(?i)\b(password|passwd|secret|api_?key|access_?token|auth_?token|private_?key)\s*[=:]\s*["\']([^"\']{8,})["\']',line)
            if m:
                val=m.group(2)
                if not re.match(r'^[/\w\-]+$',val) and not val.startswith('http'):
                    self.add("🔴 CRITICAL","Security",rel,i,
                        "Possible hardcoded secret. Move to env vars.",
                        re.sub(r'(["\'])[^"\']{4}[^"\']*(["\'])',r'\1****\2',stripped[:100]))

            if re.search(r'(?i)(sk-|pk_live_|rk_live_|AIza)[A-Za-z0-9_\-]{20,}',line):
                self.add("🔴 CRITICAL","Security",rel,i,"Possible hardcoded API key.",stripped[:100])

            # Debug prints — not in comments, not in .md
            if not is_md and not _is_comment_line(stripped):
                for pat in [r'\bprint\s*\(',r'\bconsole\.log\s*\(',r'\bdebugPrint\s*\(']:
                    if re.search(pat,stripped):
                        self.add("🟠 WARNING","Debug Leftover",rel,i,
                            "Debug/print statement found. Remove before production.",stripped[:100])
                        break

            # Empty catch — peek 4 lines ahead
            if re.search(r'\bcatch\s*(\([^)]*\))?\s*\{?\s*$',stripped):
                ahead=[lines[j].strip() for j in range(i,min(i+4,len(lines)))]
                body=[l for l in ahead if l and l not in ('{','}','{}')]
                if not body:
                    self.add("🟠 WARNING","Error Handling",rel,i,
                        "Empty catch block — errors silently swallowed.",stripped[:100])

        # Duplicate imports (not in .md)
        if not is_md:
            imps=[l.strip() for l in lines if l.strip().startswith(("import ","from "))]
            for imp,cnt in Counter(imps).items():
                if cnt>1:
                    self.add("🟠 WARNING","Duplicate Import",rel,0,f"Duplicate import {cnt}x: `{imp}`")

        # Large files
        if len(lines)>600 and path.suffix not in {'.lock','.json','.md'}:
            self.add("🟠 WARNING","Maintainability",rel,0,f"File has {len(lines)} lines. Consider splitting.")

    def analyze_dart(self,path,lines,content):
        rel=str(path)

        # setState directly in initState
        in_init=False; depth=0
        for i,line in enumerate(lines,1):
            s=line.strip()
            if "void initState()" in s: in_init=True; depth=0
            if in_init:
                depth+=s.count("{")-s.count("}")
                if re.search(r'(?<!Listener\()(?<!listener\()\bsetState\s*\(',s):
                    self.add("🔴 CRITICAL","Flutter Bug",rel,i,
                        "`setState()` called directly inside `initState()`. Use addPostFrameCallback.",s[:100])
                if depth<=0 and i>1: in_init=False

        # BuildContext after await (10-line lookahead, check for context. dot-access not just context:)
        for i,line in enumerate(lines,1):
            if re.search(r'\bawait\b',line) and i<len(lines):
                ahead="\n".join(lines[i:i+10])
                # Only flag if context is accessed (context.) not just passed as named param (context:)
                if re.search(r'context\.',ahead) and not re.search(r'mounted',ahead):
                    self.add("🟠 WARNING","Flutter Async",rel,i,
                        "BuildContext accessed after `await` without `mounted` check.",line.strip()[:100])
                    break

        # `new` keyword
        nw=re.findall(r'\bnew\s+[A-Z]\w+\s*\(',content)
        if nw:
            self.add("🟡 NOTICE","Flutter Performance",rel,0,
                f"`new` keyword used {len(nw)}x — remove it.",nw[0][:80])

        # Missing dispose (StatefulWidget only)
        if "State<" in content and "void dispose()" not in content:
            found=[c for c in ["TextEditingController","AnimationController","ScrollController",
                               "PageController","FocusNode","StreamController","StreamSubscription"]
                   if c in content]
            if found:
                self.add("🟠 WARNING","Memory Leak",rel,0,
                    f"Controller(s) without dispose(): {', '.join(found)}")

        # Controllers in void methods (not State)
        if re.search(r'void \w+\([^)]*\)[^{]*\{[^}]*TextEditingController\(\)',content):
            self.add("🟠 WARNING","Memory Leak",rel,0,
                "TextEditingController created inside a void method — never disposed. "
                "Extract to a StatefulWidget dialog.")

        # Hardcoded colors
        hc=re.findall(r'Color\(0x[0-9A-Fa-f]+\)|Colors\.\w+(?!\.shade)',content)
        if len(hc)>5:
            self.add("🟡 NOTICE","Flutter Design",rel,0,
                f"{len(hc)} hardcoded colors. Consider Theme.of(context).colorScheme.")

        # Long build()
        bm=re.search(r'Widget build\s*\(BuildContext context\)\s*\{',content)
        if bm:
            start=content[:bm.end()].count("\n"); depth=1; ln=start
            for ch in content[bm.end():]:
                ln+=(ch=="\n"); depth+=(ch=="{"); depth-=(ch=="}")
                if depth==0: break
            if ln-start>MAX_FUNC_LINES:
                self.add("🟠 WARNING","Maintainability",rel,start+1,
                    f"`build()` is ~{ln-start} lines. Extract sub-widgets.")

        # Navigator.push overuse
        pc=len(re.findall(r'Navigator\.push\s*\(',content))
        if pc>5:
            self.add("🟡 NOTICE","Flutter Architecture",rel,0,
                f"`Navigator.push()` used {pc}x. Consider go_router named routes.")

        self._extract_dart_functions(path,lines)

    def _extract_dart_functions(self,path,lines):
        body=[]; depth=0; start=0; in_fn=False
        for i,line in enumerate(lines,1):
            s=line.strip()
            if not in_fn:
                if re.search(r'\)\s*(?:async\s*)?\{',s) or re.search(r'=>\s*\{',s):
                    in_fn=True; start=i; body=[s]; depth=s.count("{")-s.count("}")
            else:
                body.append(s); depth+=s.count("{")-s.count("}")
                if depth<=0:
                    if len(body)>=MIN_DUPE_LINES: self._func_bodies.append((str(path),start,body))
                    body=[]; in_fn=False; depth=0

    def analyze_pubspec(self,path,content):
        rel=str(path)
        pins=re.findall(r':\s+(\d+\.\d+\.\d+)\s*$',content,re.MULTILINE)
        if pins:
            self.add("🟡 NOTICE","Dependencies",rel,0,
                f"{len(pins)} exact-pinned version(s). Use ^ for compatible updates.")
        if "flutter_test" in content and "dev_dependencies:" in content:
            if "flutter_test" in content.split("dev_dependencies:")[0]:
                self.add("🟠 WARNING","Dependencies",rel,0,
                    "`flutter_test` should be under `dev_dependencies`.")
        skip_keys={'sdk','flutter','path','git','hosted','version','ref','url'}
        pkgs=re.findall(r'^\s{2,4}(\w[\w_]+):',content,re.MULTILINE)
        dup=[p for p,c in Counter(pkgs).items() if c>1 and p not in skip_keys]
        if dup:
            self.add("🔴 CRITICAL","Dependencies",rel,0,f"Duplicate package entries: {', '.join(dup)}")

    def analyze_json(self,path,content):
        rel=str(path)
        try: json.loads(content)
        except json.JSONDecodeError as e:
            self.add("🔴 CRITICAL","Syntax Error",rel,0,f"Invalid JSON: {e}")

    def find_duplicates(self):
        reported=set()
        for i,(fa,la,ba) in enumerate(self._func_bodies):
            for fb,lb,bb in self._func_bodies[i+1:]:
                if fa==fb and abs(la-lb)<len(ba): continue
                key=(min(fa,fb),max(fa,fb))
                if key in reported: continue
                ratio=SequenceMatcher(None,"\n".join(ba),"\n".join(bb)).ratio()
                if ratio>=DUPE_SIMILARITY:
                    reported.add(key)
                    ra=os.path.relpath(fa,self.root); rb=os.path.relpath(fb,self.root)
                    self.issues.append(Issue("🟠 WARNING","Code Duplication",f"{ra}:{la}",0,
                        f"~{int(ratio*100)}% similar block in `{rb}:{lb}` ({len(ba)} lines). Extract to shared utility.",
                        "\n".join(ba[:4])+"\n…"))

    def run(self,files):
        for path,content,lines in files:
            self.analyze_file(path,lines)
            ext=path.suffix.lower(); name=path.name.lower()
            if ext==".dart": self.analyze_dart(path,lines,content)
            elif name=="pubspec.yaml": self.analyze_pubspec(path,content)
            elif ext==".json" and len(content)<100_000: self.analyze_json(path,content)
        self.flush_tech_debt()
        self.find_duplicates()
        order={"🔴 CRITICAL":4,"🟠 WARNING":3,"🟡 NOTICE":2,"🔵 INFO":1}
        self.issues.sort(key=lambda x:order.get(x.level,0),reverse=True)

# ── File walker ───────────────────────────────────────────────────────────────

def _is_under_platform(path,root):
    try:
        parts=path.relative_to(root).parts
        return bool(parts and parts[0] in SKIP_IF_ANCESTOR)
    except ValueError: return False

def _skip_by_name(name):
    return any(re.match(p,name,re.IGNORECASE) for p in SKIP_FILENAME_PATTERNS)

def should_include(path,root):
    if _is_under_platform(path,root): return False
    if _skip_by_name(path.name): return False
    if path.suffix.lower() in SKIP_EXTENSIONS: return False
    if path.name in ALWAYS_INCLUDE_NAMES: return True
    if path.suffix.lower() in SOURCE_EXTENSIONS: return True
    if path.stat().st_size<50*1024:
        try: path.read_text(encoding="utf-8",errors="strict"); return True
        except: return False
    return False

def walk_project(root):
    results=[]
    for dirpath,dirnames,filenames in os.walk(root):
        dirnames[:]= sorted([d for d in dirnames if d not in EXCLUDED_DIRS and not d.startswith(".")])
        for fname in sorted(filenames):
            fpath=Path(dirpath)/fname
            if fpath.stat().st_size>MAX_FILE_SIZE_KB*1024: continue
            if not should_include(fpath,root): continue
            try:
                content=fpath.read_text(encoding="utf-8",errors="replace")
                results.append((fpath,content,content.splitlines()))
            except: continue
    return results

def build_tree(root):
    lines=[f"📁 {root.name}/"]
    def recurse(path,prefix,depth):
        if depth>10: return
        entries=sorted(path.iterdir(),key=lambda p:(p.is_file(),p.name.lower()))
        entries=[e for e in entries if not (e.is_dir() and (e.name in EXCLUDED_DIRS or e.name.startswith(".")))]
        for idx,entry in enumerate(entries):
            conn="└── " if idx==len(entries)-1 else "├── "
            icon="📁 " if entry.is_dir() else "📄 "
            lines.append(f"{prefix}{conn}{icon}{entry.name}")
            if entry.is_dir():
                recurse(entry,prefix+("    " if idx==len(entries)-1 else "│   "),depth+1)
    recurse(root,"",0); return "\n".join(lines)

# ── Report ────────────────────────────────────────────────────────────────────

def build_report(root,files,issues,project_type):
    now=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    total=sum(len(ls) for _,_,ls in files)
    ec=Counter(p.suffix.lower() for p,_,_ in files)
    lc=Counter(i.level for i in issues)
    cat=Counter(i.category for i in issues)
    ext_table="\n".join(f"| `{e or '(none)'}` | {c} |" for e,c in sorted(ec.items(),key=lambda x:-x[1]))
    cat_table="\n".join(f"| {k} | {v} |" for k,v in sorted(cat.items(),key=lambda x:-x[1]))
    lang_map={"dart":"dart","py":"python","js":"javascript","ts":"typescript",
              "yaml":"yaml","yml":"yaml","json":"json","md":"markdown",
              "sh":"bash","go":"go","rs":"rust","toml":"toml","xml":"xml"}

    out=[f"""# 🔍 Project Scan Report
**Generated:** {now}  **Root:** `{root}`  **Type:** {project_type}  **Scanner:** v2.3

## 📊 Overview
| Metric | Value |
|--------|-------|
| Files scanned | {len(files)} |
| Total lines | {total:,} |
| 🔴 Critical | {lc.get('🔴 CRITICAL',0)} |
| 🟠 Warnings | {lc.get('🟠 WARNING',0)} |
| 🟡 Notices | {lc.get('🟡 NOTICE',0)} |
| 🔵 Info (developer notes) | {lc.get('🔵 INFO',0)} |

> 🔵 Info = your own TODO/FIXME notes in comments. Not bugs. Grouped one entry per file.
> Most are Phase 10 reminders ("replace MockXSource with SupabaseXSource") — keep them until Phase 10.

### Files by Extension
| Extension | Count |
|-----------|-------|
{ext_table}

## 🗂 Directory Structure
```
{build_tree(root)}
```

## ⚠️ Issues ({len(issues)} total)
### By Category
| Category | Count |
|----------|-------|
{cat_table}

---
"""]

    for issue in issues:
        snip=f"\n  ```\n  {issue.snippet}\n  ```" if issue.snippet else ""
        out.append(
            f"### {issue.level} — {issue.category}\n"
            f"**Location:** `{issue.file}`"
            f"{(' line '+str(issue.line)) if issue.line else ''}\n\n"
            f"{issue.message}{snip}\n"
        )

    out.append("## 📄 Full Source Files\n")
    for path,content,lines in sorted(files,key=lambda x:str(x[0])):
        rel=os.path.relpath(path,root)
        fi=[i for i in issues if i.file.startswith(rel) or i.file==rel]
        note=f" ⚠️ {len(fi)} issue(s)" if fi else ""
        lang=lang_map.get(path.suffix.lstrip("."), "")
        out.append(f"### `{rel}`{note}\n*{len(lines)} lines*\n\n```{lang}\n{content}\n```\n")

    return "\n".join(out)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--dir","-d",default=".")
    p.add_argument("--out","-o",default="")
    args=p.parse_args()

    root=Path(args.dir).resolve()
    if not root.is_dir(): print(f"❌ Not found: {root}"); sys.exit(1)

    print(f"\n🔍 Scanning: {root}\n"+"─"*60)
    ptype=detect_project_type(root)
    print(f"📦 Project type detected: {ptype}")
    print("📂 Collecting files…",end=" ",flush=True)
    files=walk_project(root)
    print(f"{len(files)} files found")
    print("🧠 Analysing code…",end=" ",flush=True)
    az=Analyzer(root,ptype)
    az.run(files)
    issues=az.issues
    print(f"{len(issues)} issues found")
    print("📝 Building report…",end=" ",flush=True)
    report=build_report(root,files,issues,ptype)
    print("done")

    ts=datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    out=Path(args.out or f"project_scan_{root.name}_{ts}.md")
    out.write_text(report,encoding="utf-8")
    kb=out.stat().st_size/1024
    print(f"\n✅ Report saved: {out}  ({kb:.1f} KB)\n"+"─"*60)
    c=Counter(i.level for i in issues)
    print(f"  🔴 Critical : {c.get('🔴 CRITICAL',0)}")
    print(f"  🟠 Warnings : {c.get('🟠 WARNING',0)}")
    print(f"  🟡 Notices  : {c.get('🟡 NOTICE',0)}")
    print(f"  🔵 Info     : {c.get('🔵 INFO',0)}  ← Phase 10 reminders in comments, not bugs")
    print(f"\n📤 Upload the report to Claude for review.\n")

if __name__=="__main__":
    main()
