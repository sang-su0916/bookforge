#!/usr/bin/env python3
"""bookforge build: render a book project to draft/book.pdf.

Usage: python3 build.py <book_dir>
Reads  <book_dir>/book.json + outline.json + chapters/*.md
Route  style -> engine (typst | html) from styles/<style>/tokens.json ("engine").
Output <book_dir>/draft/book.pdf   (never writes final/ — that is qc_gate's job)
"""
import json, os, re, shutil, subprocess, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import g16_tokens  # noqa: E402

SKILL = Path(__file__).resolve().parent.parent
FONTS = SKILL / "assets" / "fonts"
BRAND_PROFILE_RE = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
DEFAULT_BRAND_PROFILE = "lbiz-partners"
DEFAULT_LAYOUT_PROFILE = "lbiz-editorial-branded"
EDITORIAL_ASSETS = (
    "three-doors.png",
    "threshold-desk.png",
    "audit-calendar.png",
    "evidence-chain.png",
    "three-layers.png",
    "audit-report.png",
    "roadmap-faq.png",
)

def die(msg: str):
    print(f"BUILD FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

def run_g16(style: str, style_dir: Path, tokens: dict, book: dict, warn_only: bool):
    """G16-TOKENS(렌더 전). 여기가 유일한 중단 지점이다.

    qc_gate.py의 G10·G0도 이름은 "렌더 전"이지만 실행 순서가 build -> qc_gate라
    실제로는 렌더 후에 돈다. 토큰 계약 위반은 typst/Chromium 렌더 비용을 지불하기
    전에 잡아야 존재 이유가 성립하므로 load() 직후·render_diagrams 앞에 둔다.
    """
    css = style_dir / "theme.css"
    res = g16_tokens.run(style, tokens, css.read_text(encoding="utf-8") if css.exists() else None,
                         book.get("brand"), style_dir)
    fails = []
    for axis, findings in res.items():
        for f in findings:
            if f["level"] == "FAIL":
                fails.append(f"{axis}: {f['msg']}")
            else:
                print(f"WARN {axis}: {f['msg']}")
    if not fails:
        return
    if warn_only:
        # 긴급 탈출구 — 전역 강등은 6스타일이 한꺼번에 풀리므로 수렴에 쓸 수 없다.
        # 축별 승격은 스타일별 데이터 스위치(contrast_contract.enforce)가 담당한다.
        # 탈출구를 썼다는 사실 자체가 표준출력에 남아야 로그만 보는 사람도 안다.
        print(f"!! G16-TOKENS 탈출구 사용: --g16-warn-only로 HARD FAIL {len(fails)}건을 "
              f"강등하고 빌드를 계속한다 (gate-report.json의 gates.G16-*/warns에도 실린다)")
        for m in fails:
            print(f"WARN(강등) {m}")
        return
    die("G16-TOKENS:\n  " + "\n  ".join(fails) + "\n  (긴급 시 --g16-warn-only)")

def _merge_dicts(base: dict, override: dict) -> dict:
    merged = dict(base)
    for key, value in override.items():
        if isinstance(merged.get(key), dict) and isinstance(value, dict):
            merged[key] = _merge_dicts(merged[key], value)
        else:
            merged[key] = value
    return merged


def resolve_brand_profile(book: dict) -> dict:
    profile_name = book.get("brand_profile")
    if profile_name is None:
        return book
    if not isinstance(profile_name, str) or not BRAND_PROFILE_RE.fullmatch(profile_name):
        die("book.json: brand_profile은 소문자·숫자·하이픈·밑줄만 사용할 수 있음")
    profile_path = SKILL / "brands" / f"{profile_name}.json"
    if not profile_path.is_file():
        die(f"brand profile missing: {profile_path}")
    try:
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die(f"brand profile JSON invalid: {profile_path}: {exc}")
    if not isinstance(profile, dict):
        die(f"brand profile must be an object: {profile_path}")
    return _merge_dicts(profile, book)


def resolve_book_profile(raw_book: dict) -> dict:
    book = dict(raw_book)
    if "style" not in book:
        book["style"] = "business"
    if book.get("style") == "business" and "brand_profile" not in book:
        book["brand_profile"] = DEFAULT_BRAND_PROFILE
    book = resolve_brand_profile(book)
    if (book.get("style") == "business"
            and "layout_profile" not in raw_book
            and "layout_profile" not in book):
        book["layout_profile"] = DEFAULT_LAYOUT_PROFILE
    return book


def resolve_layout_profile(tokens: dict, book: dict) -> dict:
    profile_name = book.get("layout_profile")
    profiles = tokens.get("layout_profiles")
    if not isinstance(profile_name, str) or not isinstance(profiles, dict):
        return tokens
    override = profiles.get(profile_name)
    if not isinstance(override, dict):
        return tokens
    return _merge_dicts(tokens, override)


def output_slug(book: dict, book_dir: Path) -> str:
    slug = book.get("output_slug") or book_dir.name
    if not isinstance(slug, str) or not re.fullmatch(r"^[A-Za-z0-9][A-Za-z0-9._-]*$", slug):
        die("book.json: output_slug은 영문·숫자·점·밑줄·하이픈으로만 지정해야 함")
    return slug


def prepare_brand_logo(book_dir: Path, meta: dict):
    logo = meta.get("logo")
    if not logo:
        return
    logo_path = Path(str(logo))
    candidates = [logo_path] if logo_path.is_absolute() else [book_dir / logo_path, SKILL / logo_path]
    source = next((candidate for candidate in candidates if candidate.is_file()), None)
    if source is None:
        die(f"brand logo missing: {logo}")
    asset_dir = book_dir / "assets"
    asset_dir.mkdir(parents=True, exist_ok=True)
    target = asset_dir / source.name
    if source.resolve() != target.resolve():
        if target.exists():
            if source.read_bytes() != target.read_bytes():
                die(f"brand logo target exists with different bytes: {target}")
        else:
            shutil.copyfile(source, target)
    meta["_brand_logo"] = f"../../assets/{target.name}"


def prepare_editorial_assets(book_dir: Path, meta: dict):
    if (meta.get("style") != "business"
            or meta.get("layout_profile") != "lbiz-editorial-branded"):
        return
    asset_dir = book_dir / "assets"
    asset_dir.mkdir(parents=True, exist_ok=True)
    for name in EDITORIAL_ASSETS:
        source = asset_dir / name
        bundled = SKILL / "brand-assets" / name
        if not source.is_file():
            if not bundled.is_file():
                die(f"branded editorial asset missing: {name}")
            shutil.copyfile(bundled, source)


def load(book_dir: Path):
    raw_book = json.loads((book_dir / "book.json").read_text(encoding="utf-8"))
    if not isinstance(raw_book, dict):
        die("book.json must be an object")
    book = resolve_book_profile(raw_book)
    outline = json.loads((book_dir / "outline.json").read_text(encoding="utf-8"))
    style = book.get("style") or die("book.json: style missing")
    style_dir = SKILL / "styles" / style
    if not style_dir.exists():
        die(f"unknown style: {style}")
    tokens = json.loads((style_dir / "tokens.json").read_text(encoding="utf-8"))
    tokens = resolve_layout_profile(tokens, book)
    return book, outline, style_dir, tokens

def render_diagrams(book_dir: Path, book: dict, tokens: dict | None = None):
    """P1.5 도해 프리렌더: diagrams/fig-*.json -> assets/fig-*.svg (+labels.json).

    images 정책(book.json)은 여기서 살아 있는 스위치가 된다 —
    "none"이면 도해 존재 자체가 계약 위반, "vector"(기본)면 프리렌더 실행.
    """
    dg = book_dir / "diagrams"
    if not dg.exists() or not sorted(dg.glob("fig-*.json")):
        return
    if book.get("images") == "none":
        die('book.json images="none"인데 diagrams/에 도해 사이드카가 있음')
    env = dict(os.environ)
    env["NODE_PATH"] = subprocess.run(["npm", "root", "-g"], capture_output=True,
                                      text=True).stdout.strip()
    diagram_style_dir = None
    if tokens is not None:
        diagram_style_dir = book_dir / "typeset" / "_diagram_style"
        diagram_style_dir.mkdir(parents=True, exist_ok=True)
        (diagram_style_dir / "tokens.json").write_text(
            json.dumps(tokens, ensure_ascii=False), encoding="utf-8")
    command = ["node", str(SKILL / "scripts" / "render_diagrams.mjs"),
               str(book_dir), "--style", book["style"]]
    if diagram_style_dir is not None:
        command.extend(["--style-dir", str(diagram_style_dir)])
    r = subprocess.run(command,
                       capture_output=True, text=True, env=env)
    if r.stdout.strip():
        print(r.stdout.strip())
    if r.returncode != 0:
        die("diagram prerender:\n" + (r.stderr or r.stdout))

def build_typst(book_dir: Path, book: dict, outline: dict, style_dir: Path, tokens: dict):
    sys.path.insert(0, str(SKILL / "scripts"))
    from md2typ import convert_chapter

    ts = book_dir / "typeset"
    style_snap = ts / "_style"
    chap_out = ts / "chapters"
    for d in (style_snap, chap_out, book_dir / "draft"):
        d.mkdir(parents=True, exist_ok=True)

    shutil.copy(SKILL / "templates" / "base.typ", style_snap / "base.typ")
    shutil.copy(style_dir / "theme.typ", style_snap / "theme.typ")
    meta = dict(book)
    prepare_brand_logo(book_dir, meta)
    prepare_editorial_assets(book_dir, meta)
    for name in ("cover-art.png", "cover.png", "cover.jpg"):
        if (book_dir / "assets" / name).exists():
            meta["_cover_art"] = f"../../assets/{name}"
            break
    (style_snap / "meta.json").write_text(json.dumps(meta, ensure_ascii=False), encoding="utf-8")

    # refit-params.json: 장별 자간 미세조정(pagination.md §5 L2, refit.py가 산출)
    refit = {}
    rp = book_dir / "refit-params.json"
    if rp.exists():
        refit = json.loads(rp.read_text(encoding="utf-8"))

    includes = []
    for ch in outline["chapters"]:
        src = book_dir / "chapters" / ch["file"]
        if not src.exists():
            die(f"chapter file missing: {src}")
        dst = chap_out / (src.stem + ".typ")
        # tokens.diagram.widths를 그대로 넘긴다 — Typst 트랙의 도해 폭 단일 진리원.
        # HTML 트랙이 theme.css $fig_*_mm 치환으로 받는 것과 같은 계약을 md2typ가
        # `#bf-fig(..., width: Nmm)`로 받는다. 넘기지 않던 구 구현에서는 base.typ 기본
        # `width: 100%`가 걸려 `bf.width: twothirds`가 조판에 도달하지 못했다.
        convert_chapter(src, dst, ch["title"], ch.get("summary"),
                        diagrams_dir=book_dir / "diagrams",
                        fig_widths=(tokens.get("diagram") or {}).get("widths"))
        prm = refit.get(src.stem, {})
        if prm.get("tracking_em"):
            head, _, rest = dst.read_text(encoding="utf-8").partition("\n")
            dst.write_text(f"{head}\n#set text(tracking: {prm['tracking_em']}em)\n{rest}",
                           encoding="utf-8")
        includes.append(f'#include "chapters/{dst.name}"')

    main = "\n".join([
        '#import "_style/theme.typ": *',
        "#show: book.with(meta: meta, tokens: theme-tokens, cover: make-cover(meta), toc: true)",
        *includes,
        ("#source-list(meta, TT)" if (book.get("style") == "business"
                                      and book.get("layout_profile") == "lbiz-editorial-branded")
         else "#colophon(meta, TT)"),
    ])
    (ts / "main.typ").write_text(main, encoding="utf-8")

    out = book_dir / "draft" / "book.pdf"
    cmd = ["typst", "compile", "--root", str(book_dir),
           "--font-path", str(FONTS), "--ignore-system-fonts",
           str(ts / "main.typ"), str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        die("typst compile:\n" + r.stderr)
    print(f"OK draft: {out}")

def build_html(book_dir: Path, book: dict, outline: dict, style_dir: Path):
    from build_html import build as html_build  # scripts/build_html.py
    html_build(book_dir, book, outline, style_dir, SKILL)

def main():
    # 인자 파싱이 없는 파일이라 플래그를 먼저 걸러낸다 — 위치 인자(book_dir) 취득이
    # 플래그 위치에 흔들리면 안 된다. --strict-pages(qc_gate.py:358)와 같은 raw sys.argv 관례.
    argv = [a for a in sys.argv[1:] if a != "--g16-warn-only"]
    warn_only = "--g16-warn-only" in sys.argv[1:]
    if not argv:
        sys.exit("usage: python3 scripts/build.py <book_dir> [--g16-warn-only]")
    book_dir = Path(argv[0]).resolve()
    book, outline, style_dir, tokens = load(book_dir)
    run_g16(book["style"], style_dir, tokens, book, warn_only)
    # 재빌드 시작 = 이전 final/ 무효화. final/은 이번 산출물이 게이트를 통과한
    # 뒤에만 다시 생긴다 (qc_gate FAIL 경로의 제거와 이중 방어).
    stale = book_dir / "final" / f"{output_slug(book, book_dir)}.pdf"
    if stale.exists():
        stale.unlink()
        print(f"재빌드: 이전 final 무효화 -> {stale}")
    render_diagrams(book_dir, book, tokens)
    engine = tokens.get("engine", "typst")
    if engine == "typst":
        build_typst(book_dir, book, outline, style_dir, tokens)
    elif engine == "html":
        sys.path.insert(0, str(SKILL / "scripts"))
        build_html(book_dir, book, outline, style_dir)
    else:
        die(f"unknown engine: {engine}")

if __name__ == "__main__":
    main()
