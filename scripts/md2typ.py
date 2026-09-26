#!/usr/bin/env python3
"""bookforge: deterministic Markdown(subset) -> Typst fragment converter.

Contract (chapter md):
  - first `# H1` = chapter title (opener rendered via bf-chapter; summary from outline.json)
  - `##`/`###` -> == / ===
  - paragraphs, **bold**, *em*, `code`, fenced code, > quote, lists, GFM tables, links
  - images: ![caption](path "출처: X") -> bf-fig
  - callouts (line-based, nesting depth 1):
      ::: tip 제목텍스트
      body md
      :::
    kinds: info|tip|warn|quote|example|stat  (stat: first line = value, second = label)
"""
import json, re, sys
from pathlib import Path
from markdown_it import MarkdownIt

MD = MarkdownIt("commonmark").enable("table").enable("strikethrough")

# CommonMark 강조 규칙은 닫는 `**` 앞이 문장부호이고 뒤가 글자면 닫지 못한다.
# 한국어는 조사가 바로 붙으므로 `**[누구]**가`·`**보였는가?**를`·`**"직원"**이라고`
# 가 굵게가 안 되고 `**` 가 인쇄면에 그대로 찍힌다(G15-PRINT 가 잡은 실사례).
# `*` 구분자에 한해 앞뒤 한중일 글자를 문장부호처럼 취급해 조사 결합을 허용한다
# (markdown-cjk-friendly 와 같은 방향). `_`·`~` 는 영문 식별자 오판을 막으려 그대로 둔다.
from markdown_it.rules_inline.state_inline import StateInline, Scanned
from markdown_it.common.utils import isWhiteSpace, isPunctChar, isMdAsciiPunct

_CJK_RE = re.compile(r"[ᄀ-ᇿ぀-ヿ㄰-㆏㐀-䶿一-鿿가-힣豈-﫿]")
_orig_scan = StateInline.scanDelims


def _cjk_scan(self, start, canSplitWord):
    if self.src[start] != "*":
        return _orig_scan(self, start, canSplitWord)
    pos, maximum = start, self.posMax
    last = self.src[start - 1] if start > 0 else " "
    while pos < maximum and self.src[pos] == "*":
        pos += 1
    nxt = self.src[pos] if pos < maximum else " "
    lp = isMdAsciiPunct(ord(last)) or isPunctChar(last) or bool(_CJK_RE.match(last))
    np_ = isMdAsciiPunct(ord(nxt)) or isPunctChar(nxt) or bool(_CJK_RE.match(nxt))
    lw, nw = isWhiteSpace(ord(last)), isWhiteSpace(ord(nxt))
    left = not (nw or (np_ and not (lw or lp)))
    right = not (lw or (lp and not (nw or np_)))
    return Scanned(left and (canSplitWord or not right or lp),
                   right and (canSplitWord or not left or np_), pos - start)


StateInline.scanDelims = _cjk_scan

ESC = "\\`#$&_*@<>[]~^"

def esc(text: str) -> str:
    out = []
    for ch in text:
        if ch in ESC:
            out.append("\\" + ch)
        elif ch == "/":
            out.append("\\/")  # avoid `//` comment
        else:
            out.append(ch)
    return "".join(out)

def inline(tokens) -> str:
    """Render markdown-it inline children to typst markup."""
    out = []
    for t in tokens:
        ty = t.type
        if ty == "text":
            out.append(esc(t.content))
        elif ty == "code_inline":
            content = t.content.replace("`", "\\`")
            out.append(f"#raw(\"{content_escape(t.content)}\")")
        elif ty == "strong_open":
            out.append("#strong[")
        elif ty == "strong_close":
            out.append("];")  # ';' terminates the code expr so a following '(' or '[' is not parsed as call args
        elif ty == "em_open":
            out.append("#emph[")
        elif ty == "em_close":
            out.append("];")
        elif ty == "s_open":
            out.append("#strike[")
        elif ty == "s_close":
            out.append("];")
        elif ty == "link_open":
            href = dict(t.attrs).get("href", "")
            out.append(f'#link("{content_escape(href)}")[')
        elif ty == "link_close":
            out.append("];")
        elif ty == "softbreak":
            out.append(" ")
        elif ty == "hardbreak":
            out.append(" \\\n")
        elif ty == "image":
            # inline images are promoted to block figures by block pass; ignore here
            pass
        else:
            if t.content:
                out.append(esc(t.content))
    return "".join(out)

def content_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')

def fig_width_mm(src: str, ctx) -> float | None:
    """도해 사이드카 `bf.width` → `#bf-fig(..., width: Nmm)`에 실을 mm 수치.

    구 구현은 width를 **아예 넘기지 않았다**. 그래서 base.typ:123 `bookfig(..., width: 100%)`
    기본값이 그대로 걸리고 `bf.width: twothirds` 선언이 조판에 도달하지 못했다 — 사이드카는
    render_diagrams.mjs의 pt 환산 기준으로만 쓰이고 지면 폭은 전폭 그대로였다는 뜻이라,
    도해 글자 하한은 2/3폭 기준(예: essay 52mm)으로 재면서 실제로는 88mm로 그렸다.
    HTML 트랙이 2단계에서 없앤 것과 같은 형태의 '제2의 진리원'이며, 여기서는 그 두 번째
    값이 아예 무시되는 쪽으로 나타났다.

    `full`도 수치로 발행한다. 4종 실측에서 `100%`가 판면폭과 정확히 같아 결과는 불변이지만
    (practical 121.000 / academic 106.000 / essay 88.000 / business 132.500mm — 프로브
    PDF 벡터 실측), 그렇게 두면 판면폭이 유일 진리원이고 tokens는 그것을 **추정**하는
    제2의 값으로 남는다. 수치로 발행하면 tokens 하나가 조판과 게이트를 동시에 정하고,
    둘이 갈라지는 순간 지면에서 눈에 보인다(G16-SYNC widths 축이 정적으로도 잡는다).

    사이드카가 없는 이미지(표지 아트 등)는 `None` — 종전대로 `width: 100%`로 떨어진다.
    """
    widths, dg = ctx.get("fig_widths"), ctx.get("diagrams_dir")
    if not isinstance(widths, dict) or dg is None:
        return None
    sidecar = Path(dg) / (Path(src).stem + ".json")
    if not sidecar.exists():
        return None
    try:
        bf = json.loads(sidecar.read_text(encoding="utf-8")).get("bf") or {}
    except (ValueError, OSError):
        return None                       # 사이드카 파손은 render_diagrams가 이미 죽인다
    v = widths.get(bf.get("width") or "full")
    if isinstance(v, bool) or not isinstance(v, (int, float)) or v <= 0:
        return None                       # 값 부재/비수치는 G16-SYNC widths ①이 렌더 전에 막는다
    # W7 배치 높이 상한 — render_diagrams(figFitReport)가 metrics.fit에 내린 축소 폭이
    # 있으면 그 값을 전사한다(HTML 트랙 build_html.fig의 인라인 width와 같은 소비 계약).
    # 진리원은 tokens.diagram.maxHeightMm 하나이고 여기는 결정의 배치 전사일 뿐이다.
    metrics_p = Path(dg).parent / "assets" / (Path(src).stem + ".metrics.json")
    if metrics_p.exists():
        try:
            fit = json.loads(metrics_p.read_text(encoding="utf-8")).get("fit") or {}
        except (ValueError, OSError):
            fit = {}
        fw = fit.get("widthMm")
        if (fit.get("verdict") == "shrunk"
                and isinstance(fw, (int, float)) and not isinstance(fw, bool) and fw > 0):
            return float(fw)
    return float(v)

def render_tokens(tokens, ctx) -> str:
    out, i = [], 0
    while i < len(tokens):
        t = tokens[i]
        ty = t.type
        if ty == "heading_open":
            level = int(t.tag[1])
            content = inline(tokens[i + 1].children or [])
            i += 3
            if level == 1:
                if not ctx["chapter_emitted"]:
                    summary = ctx.get("summary")
                    s = f", summary: [{esc(summary)}]" if summary else ""
                    out.append(f'#bf-chapter("{content_escape(ctx["title_raw"])}"{s})\n')
                    ctx["chapter_emitted"] = True
                # extra H1s demoted
                else:
                    out.append(f"== {content}\n")
            else:
                out.append("=" * min(level, 4) + " " + content + "\n")
            continue
        if ty == "paragraph_open":
            raw_line = (tokens[i + 1].content or "").strip()
            capm = re.match(r"^\[표\]\s*(.+?)(?:\s*\|\s*자료\s*[:：]\s*(.+))?$", raw_line)
            if capm:
                ctx["pending_tbl"] = (capm.group(1).strip(), (capm.group(2) or "").strip() or None)
                i += 3
                continue
            children = tokens[i + 1].children or []
            imgs = [c for c in children if c.type == "image"]
            if imgs and all(c.type in ("image", "softbreak", "text") and (c.type != "text" or not c.content.strip()) for c in children):
                for im in imgs:
                    attrs = dict(im.attrs)
                    src = attrs.get("src", "")
                    title = attrs.get("title", "") or ""
                    cap = inline(im.children or []) or None
                    source = None
                    m = re.match(r"출처\s*[:：]\s*(.+)", title)
                    if m:
                        source = m.group(1).strip()
                    args = [f'"{content_escape(ctx["img_prefix"] + src)}"']
                    if cap:
                        args.append(f"caption: [{cap}]")
                    if source:
                        args.append(f"source: [{esc(source)}]")
                    w = fig_width_mm(src, ctx)
                    if w is not None:
                        args.append(f"width: {w:g}mm")
                    out.append(f'#bf-fig({", ".join(args)})\n')
            else:
                out.append(inline(children) + "\n")
            i += 3
            continue
        if ty == "fence":
            lang = (t.info or "").strip().split()[0] if (t.info or "").strip() else ""
            body = t.content.rstrip("\n")
            fence = "`" * max(3, max((len(m) for m in re.findall(r"`+", body)), default=0) + 1)
            out.append(f"{fence}{lang}\n{body}\n{fence}\n")
            i += 1
            continue
        if ty == "blockquote_open":
            j, depth = i + 1, 1
            while j < len(tokens) and depth:
                if tokens[j].type == "blockquote_open":
                    depth += 1
                elif tokens[j].type == "blockquote_close":
                    depth -= 1
                j += 1
            inner = render_tokens(tokens[i + 1:j - 1], ctx)
            out.append(f"#quote(block: true)[{inner.strip()}]\n")
            i = j
            continue
        if ty in ("bullet_list_open", "ordered_list_open"):
            j, depth = i + 1, 1
            opener = ty
            closer = opener.replace("open", "close")
            while j < len(tokens) and depth:
                if tokens[j].type == opener:
                    depth += 1
                elif tokens[j].type == closer:
                    depth -= 1
                j += 1
            out.append(render_list(tokens[i:j], ctx))
            i = j
            continue
        if ty == "table_open":
            j = i
            while tokens[j].type != "table_close":
                j += 1
            cap = ctx.pop("pending_tbl", None)
            out.append(render_table(tokens[i:j + 1], ctx, cap=cap))
            i = j + 1
            continue
        if ty == "hr":
            out.append("#v(0.6em)#line(length: 30%, stroke: 0.5pt + luma(170))#v(0.6em)\n")
            i += 1
            continue
        i += 1
    return "\n".join(out)

# GFM 작업목록(`- [ ] 항목`)은 markdown-it 기본 설정에서 일반 리스트로 들어오고
# 대괄호가 본문에 그대로 인쇄된다. 인쇄물의 체크리스트는 네모 칸이어야 하므로
# 항목 머리의 대괄호 표기를 걷어내고 그 목록만 마커를 네모로 바꾼다.
# 네모는 글꼴 글리프가 아니라 조판으로 그려 글꼴 지원 여부와 무관하게 나온다.
CHECKBOX_MARKER = (
    "box(width: 3.1pt, height: 3.1pt, stroke: 0.55pt + luma(90), baseline: -0.2pt)"
)
CHECKBOX_DONE_MARKER = (
    "box(width: 3.1pt, height: 3.1pt, stroke: 0.55pt + luma(90), baseline: -0.2pt, "
    "align(center + horizon, text(size: 2.6pt, [X])))"
)
_CB_RE = re.compile(r"^\\\[([ xX])\\\][ \t]+")


def _strip_checkbox(inner):
    """항목 머리의 작업목록 표기를 떼고 (본문, 체크여부)를 돌려준다."""
    m = _CB_RE.match(inner)
    if not m:
        return inner, None
    return inner[m.end():], m.group(1) in ("x", "X")


def render_list(tokens, ctx) -> str:
    ordered = tokens[0].type == "ordered_list_open"
    marker = "+" if ordered else "-"
    items, checks, i = [], [], 1
    while i < len(tokens) - 1:
        if tokens[i].type == "list_item_open":
            j, depth = i + 1, 1
            while depth:
                if tokens[j].type == "list_item_open":
                    depth += 1
                elif tokens[j].type == "list_item_close":
                    depth -= 1
                j += 1
            inner = render_tokens(tokens[i + 1:j - 1], ctx).strip()
            body, checked = _strip_checkbox(inner)
            body = body.replace("\n", "\n  ")
            items.append(f"{marker} {body}")
            checks.append(checked)
            i = j
        else:
            i += 1

    out = "\n".join(items) + "\n"
    if not ordered and items and all(c is not None for c in checks):
        mk = CHECKBOX_DONE_MARKER if all(checks) else CHECKBOX_MARKER
        return "#[\n#set list(marker: " + mk + ")\n" + out + "]\n"
    return out

# 표 열 폭: 균등 분할(1fr)은 좁은 열에서 낱말을 중간에서 끊고 넓은 열은 자리를 남긴다.
# 각 열의 가장 긴 셀을 글자 폭으로 재서 그 비율대로 fr 을 배분한다.
# 표 전체 폭은 그대로 판면 100%를 채운다(auto 를 쓰면 우측이 빈다).
_TYP_MARKUP = re.compile(r"\\(.)|#\w+\([^)]*\)|[*_`\[\]#]")


def _disp_width(text: str) -> int:
    """조판에 실리는 글자 폭의 근사값. 한글·한자·전각은 두 칸으로 센다."""
    plain = _TYP_MARKUP.sub(lambda m: m.group(1) or "", text)
    w = 0
    for ch in plain:
        o = ord(ch)
        w += 2 if (0x1100 <= o <= 0x115F or 0x2E80 <= o <= 0xA4CF
                   or 0xAC00 <= o <= 0xD7A3 or 0xF900 <= o <= 0xFAFF
                   or 0xFE30 <= o <= 0xFE6F or 0xFF00 <= o <= 0xFF60
                   or 0xFFE0 <= o <= 0xFFE6) else 1
    return w


def column_weights(rows, ncol: int) -> str:
    """열별 최장 셀 폭에 비례한 fr 목록을 돌려준다."""
    # 한 열이 표를 독식하지 않도록 상·하한을 둔다. 하한은 머리글 두 글자가
    # 한 줄에 들어갈 최소치, 상한은 한 열이 절반을 넘지 않게 하는 값이다.
    LO, HI = 6, 34
    widths = []
    for c in range(ncol):
        longest = 0
        for r in rows:
            if c < len(r):
                longest = max(longest, _disp_width(r[c]))
        widths.append(min(HI, max(LO, longest)))
    # 차이를 그대로 쓰면 긴 열이 과하게 커진다. 제곱근으로 눌러 균형을 맞춘다.
    damped = [w ** 0.5 for w in widths]
    # 그래도 짧은 열은 균등 몫보다 좁아져 낱말이 중간에서 끊긴다.
    # 어떤 열도 균등 몫의 85% 아래로 내려가지 않게 바닥을 둔다.
    floor = (sum(damped) / len(damped)) * 0.85
    damped = [round(max(w, floor) * 10) / 10 for w in damped]
    return "(" + ", ".join(f"{w}fr" for w in damped) + ")"

def render_table(tokens, ctx, cap=None) -> str:
    rows, cur = [], None
    for t in tokens:
        if t.type == "tr_open":
            cur = []
        elif t.type == "tr_close":
            rows.append(cur)
        elif t.type == "inline" and cur is not None:
            cur.append(inline(t.children or []))
    if not rows:
        return ""
    ncol = max(len(r) for r in rows)
    cells = []
    for r in rows:
        r = r + [""] * (ncol - len(r))
        cells.extend(f"[{c}]" for c in r)
    tbl = f"table(columns: {column_weights(rows, ncol)}, " + ", ".join(cells) + ")"
    if cap:
        title, source = cap
        args = [f"caption: [{esc(title)}]"]
        if source:
            args.append(f"source: [{esc(source)}]")
        return f"#bf-tbl({', '.join(args)}, {tbl})\n"
    return f"#bf-tbl({tbl})\n"

# statrow는 stat보다 먼저 — 대안 순서가 뒤면 "::: statrow"가 stat(title="row")로 오탐된다
CALLOUT_RE = re.compile(r"^:::\s*(info|tip|warn|quote|example|statrow|stat|pull|lead|cols|pagebreak)\s*(.*)$")

def split_callouts(md: str):
    """Yield ('md', text) and ('callout', kind, title, body) segments."""
    lines = md.split("\n")
    buf, i = [], 0
    while i < len(lines):
        m = CALLOUT_RE.match(lines[i].strip())
        if m:
            if buf:
                yield ("md", "\n".join(buf))
                buf = []
            kind, title = m.group(1), m.group(2).strip() or None
            body, i = [], i + 1
            while i < len(lines) and lines[i].strip() != ":::":
                body.append(lines[i])
                i += 1
            i += 1
            yield ("callout", kind, title, "\n".join(body))
        else:
            buf.append(lines[i])
            i += 1
    if buf:
        yield ("md", "\n".join(buf))

def convert_chapter(md_path: Path, out_path: Path, title: str, summary: str | None,
                    img_prefix: str = "../../assets/",
                    diagrams_dir: Path | None = None, fig_widths: dict | None = None) -> None:
    """`diagrams_dir`+`fig_widths`(= tokens.diagram.widths)가 주어지면 도해 사이드카의
    `bf.width`를 `#bf-fig(..., width: Nmm)`로 발행한다. 둘 중 하나라도 없으면 종전대로
    width 인자를 생략해 base.typ 기본 `100%`로 떨어진다(단독 CLI 실행 경로)."""
    md = md_path.read_text(encoding="utf-8")
    ctx = {"chapter_emitted": False, "title_raw": title, "summary": summary,
           "img_prefix": img_prefix, "diagrams_dir": diagrams_dir, "fig_widths": fig_widths}
    parts = ['#import "../_style/theme.typ": *\n']
    for seg in split_callouts(md):
        if seg[0] == "md":
            parts.append(render_tokens(MD.parse(seg[1]), ctx))
        else:
            _, kind, title_c, body = seg
            if kind == "pagebreak":
                parts.append("#pagebreak(weak: true)\n")
            elif kind == "stat":
                ls = [l.strip() for l in body.strip().split("\n") if l.strip()]
                value = ls[0] if ls else ""
                label = ls[1] if len(ls) > 1 else ""
                parts.append(f'#bf-stat("{content_escape(value)}", "{content_escape(label)}")\n')
            elif kind == "statrow":
                # 각 행 = "값 | 라벨" — T1 하단 키 스탯 스트립 (business 팩 전용)
                cells = []
                for l in body.strip().split("\n"):
                    if not l.strip():
                        continue
                    value, _, label = l.partition("|")
                    cells.append(f'("{content_escape(value.strip())}", "{content_escape(label.strip())}")')
                parts.append(f'#bf-statrow({", ".join(cells)})\n')
            elif kind in ("lead", "cols"):
                inner = render_tokens(MD.parse(body), ctx).strip()
                parts.append(f'#bf-{kind}[{inner}]\n')
            else:
                if kind == "pull":  # 풀퀘트는 HTML 전용 — Typst 트랙에선 인용으로 강등
                    kind = "quote"
                inner = render_tokens(MD.parse(body), ctx).strip()
                targ = f"title: [{esc(title_c)}], " if title_c else ""
                parts.append(f'#bf-callout(kind: "{kind}", {targ})[{inner}]\n'.replace(", )", ")"))
    if not ctx["chapter_emitted"]:
        s = f", summary: [{esc(summary)}]" if summary else ""
        parts.insert(1, f'#bf-chapter("{content_escape(title)}"{s})\n')
    out_path.write_text("\n".join(parts), encoding="utf-8")

if __name__ == "__main__":
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    title = sys.argv[3] if len(sys.argv) > 3 else src.stem
    summary = sys.argv[4] if len(sys.argv) > 4 else None
    convert_chapter(src, dst, title, summary)
    print(f"OK {dst}")
