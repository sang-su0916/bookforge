// bookforge style: business — 비즈니스·컨설팅 리포트.
// LBiz branded profile follows the supplied ivory A5 editorial template.
#import "base.typ": default-tokens, keep-words, numpad, chapter-state, full-bleed
#import "base.typ" as base
#let code-font = ((name: "DejaVu Sans Mono", covers: regex("[A-Za-z0-9]")), "Pretendard")

#let meta = json("meta.json")

#let brand-editorial = meta.at("layout_profile", default: "") == "lbiz-editorial-branded"
#let light-editorial = meta.at("layout_profile", default: "") == "lbiz-editorial-light"

#let navy-900 = if brand-editorial {
  rgb(meta.at("editorial_navy_900", default: "#17233A"))
} else { rgb(meta.at("navy_900", default: "#111A2D")) }
#let navy-700 = if brand-editorial {
  rgb(meta.at("editorial_navy_700", default: "#24466B"))
} else { rgb(meta.at("brand", default: "#1B2A4A")) }
#let navy-300 = if brand-editorial {
  rgb(meta.at("editorial_navy_300", default: "#8EA8BC"))
} else { rgb("#7FB2D9") }
#let navy-500 = if brand-editorial {
  rgb(meta.at("editorial_navy_500", default: "#5D7892"))
} else { rgb(meta.at("navy_500", default: "#2D4373")) }
#let navy-100 = if brand-editorial {
  rgb(meta.at("editorial_navy_100", default: "#E3E8EA"))
} else { rgb(meta.at("brand_light", default: "#E8D5B7")) }
#let teal-600 = rgb("#0E6E62")
#let accent   = if brand-editorial {
  rgb(meta.at("editorial_accent", default: "#8B650F"))
} else { rgb(meta.at("accent", default: "#C8A96E")) }
#let alert-c  = rgb("#B3261E")
#let ink      = if brand-editorial {
  rgb(meta.at("editorial_ink", default: "#1D2738"))
} else { rgb(meta.at("ink", default: "#141A26")) }
#let ink-60   = if brand-editorial {
  rgb(meta.at("editorial_ink_muted", default: "#5D6775"))
} else { rgb(meta.at("ink_muted", default: "#626A76")) }
#let ink-30   = if brand-editorial { rgb("#A5A9A5") } else { rgb("#9AA5B1") }
#let rule-c   = if brand-editorial { rgb("#D9D0C1") } else { rgb("#D5D9DE") }
#let ivory    = if brand-editorial { rgb(meta.at("editorial_paper", default: "#FAF5EB")) } else { white }
#let paper-alt = if brand-editorial {
  rgb(meta.at("editorial_paper_alt", default: "#F3EEE4"))
} else { rgb(meta.at("paper", default: "#F6F1E6")) }

// content → 평문 (목차 Executive Summary 판별용)
#let plain-text(c) = {
  if type(c) == str { c }
  else if type(c) != content { "" }
  else if c.func() == text { c.text }
  else if c.has("children") { c.children.map(plain-text).join("") }
  else if c.has("body") { plain-text(c.body) }
  else if c.func() == smartquote { "'" }
  else { " " }
}

#let theme-tokens = default-tokens + (
  trim: if brand-editorial { (w: 148mm, h: 210mm) } else { (w: 200mm, h: 280mm) },
  margin: if brand-editorial {
    (top: 17mm, bottom: 18mm, left: 14mm, right: 14mm)
  } else {
    // 본문 5컬럼 132.5mm + 바깥 마진 컬럼 22.5mm(+거터 5mm) 확보
    (top: 28mm, bottom: 30mm, left: 20mm, right: 47.5mm)
  },
  brand: navy-700, brand-light: navy-100,
  ink: ink, muted: ink-60, paper: if brand-editorial { ivory } else { white },
  body-font: ("Pretendard",), sans-font: ("Pretendard",),
  display-font: ("Pretendard",),
  // 공식 TTF판의 내부 패밀리명은 "Gmarket Sans TTF" (OTF판 "Gmarket Sans"와 다름)
  stat-font: ("Gmarket Sans TTF", "Gmarket Sans"),
  quote-font: ("Noto Serif KR",),
  body-size: if brand-editorial { 9.2pt } else { 10.5pt },
  body-leading: if brand-editorial { 0.73em } else { 0.62em },
)

#let TT = theme-tokens

// ---- cover: navy + vector data-mesh pattern (상단 40%) -----------------------
#let cover-pattern(w, h) = {
  // 결정론적 데이터 메시: 사선 + 노드
  for i in range(12) {
    let x = w * i / 11
    place(top + left, dx: x, dy: 0mm,
      line(end: (w * 0.35, h), stroke: 0.4pt + navy-500.transparentize(72%)))
  }
  for i in range(9) {
    let x = w * (i + 1) / 10
    let y = h * calc.rem(i * 37, 83) / 83
    place(top + left, dx: x, dy: y, circle(radius: 1.1mm, fill: navy-300.transparentize(55%)))
  }
}

#let make-cover(meta) = {
  if brand-editorial {
    page(margin: 0mm, header: none, footer: none, fill: ivory, {
      set par(justify: false, first-line-indent: 0em)
      // Supplied LBiz branded template: ivory field, left-aligned identity,
      // generous title block, and contact/imprint footer.
      place(top + left, dx: 14mm, dy: 14mm, {
        grid(columns: (10mm, 1fr), column-gutter: 2mm,
          if meta.at("_brand_logo", default: none) != none {
            image(meta.at("_brand_logo"), width: 8mm)
          } else {
            h(8mm)
          },
          text(font: TT.sans-font, size: 10pt, weight: "bold", fill: navy-900,
            meta.at("publisher", default: "엘비즈파트너스")))
      })
      place(top + left, dx: 14mm, dy: 53mm, {
        text(font: TT.sans-font, size: 8pt, weight: "bold", fill: accent,
          meta.at("publisher", default: "엘비즈파트너스"))
        v(6mm)
        text(font: TT.display-font, size: 27pt, weight: "extrabold", tracking: -0.035em,
          fill: navy-900, keep-words(meta.title))
        if meta.at("subtitle", default: none) != none {
          v(5mm)
          text(font: TT.sans-font, size: 11.5pt, fill: ink-60, keep-words(meta.subtitle))
        }
      })
      place(bottom + left, dx: 14mm, dy: -17mm, {
        let im = meta.at("imprint", default: (:))
        block(width: 120mm, {
          line(length: 100%, stroke: 0.5pt + accent)
          v(4mm)
          text(font: TT.sans-font, size: 11pt, weight: "bold", fill: navy-900,
            im.at("name", default: meta.at("author", default: "이상수")))
          v(1mm)
          text(font: TT.sans-font, size: 8.5pt, fill: navy-900,
            im.at("role", default: meta.at("publisher", default: "엘비즈파트너스") + " 대표"))
          if im.at("phone", default: none) != none {
            v(1.5mm)
            text(font: TT.sans-font, size: 8.2pt, fill: ink-60, "전화 " + im.phone)
          }
          if im.at("email", default: none) != none {
            linebreak()
            text(font: TT.sans-font, size: 8.2pt, fill: ink-60, "메일 " + im.email)
          }
          if im.at("site", default: none) != none {
            linebreak()
            text(font: TT.sans-font, size: 8.2pt, fill: ink-60, "홈페이지 " + im.site)
          }
          v(2mm)
          text(font: TT.sans-font, size: 6.2pt, fill: navy-700,
            "본 자료는 저작권법의 보호를 받습니다. " +
            meta.at("publisher", default: "엘비즈파트너스") +
            "의 사전 서면 동의 없이 무단 복제·배포·전송·게시·공유하는 행위를 금하며, 위반 시 관련 법령에 따라 민·형사상 책임을 질 수 있습니다.")
        })
      })
    })
  } else if light-editorial {
    page(margin: 0mm, header: none, footer: none, fill: white, {
      set par(justify: false, first-line-indent: 0em)
      // Updated LBiz personal-brand cover: white field, centered identity,
      // restrained gold rule, and a short promise card.  Text remains a
      // Typst layer so the cover stays searchable and editable.
      place(top + center, dy: 19mm, block(width: 160mm, {
        align(center, {
          if meta.at("_brand_logo", default: none) != none {
            image(meta.at("_brand_logo"), width: 18mm)
            v(5mm)
          }
          text(font: TT.sans-font, size: 8pt, weight: "bold", tracking: 0.08em,
            fill: navy-700, "LBIZ PARTNERS  ·  PRACTICAL WHITEPAPER")
          v(9mm)
          text(font: TT.display-font, size: 38pt, weight: "extrabold", tracking: -0.03em,
            fill: navy-900, keep-words(meta.title))
          if meta.at("subtitle", default: none) != none {
            v(6mm)
            text(font: TT.sans-font, size: 14pt, fill: ink-60, keep-words(meta.subtitle))
          }
          v(8mm)
          line(length: 42mm, stroke: 1.5pt + accent)
          v(6mm)
          text(font: TT.sans-font, size: 11pt, weight: "semibold", fill: navy-700,
            meta.at("slogan", default: "법인전환, 감이 아니라 숫자로 판단합니다."))
          v(7mm)
          text(font: TT.sans-font, size: 10pt, weight: "medium", fill: navy-700,
            meta.at("author", default: "이상수") + "  |  " + meta.at("publisher_en", default: "L.Biz Partners"))
          v(2mm)
          text(font: TT.sans-font, size: 8.5pt, fill: ink-60,
            meta.at("basis_date", default: meta.at("date", default: "")))
        })
      }))
      place(bottom + center, dy: -27mm, block(width: 160mm,
        fill: paper-alt, stroke: (left: 2pt + accent), inset: (x: 6mm, y: 5mm), {
          text(font: TT.sans-font, size: 8pt, weight: "bold", tracking: 0.04em,
            fill: navy-700, "이 책의 약속")
          v(2mm)
          text(font: TT.sans-font, size: 10pt, fill: ink,
            meta.at("cover_statement", default: "가족이라서 생략하는 회사가 아니라, 가족이라서 설명 가능한 회사로"))
        }))
      place(bottom + left, dx: 20mm, dy: -12mm,
        text(font: TT.sans-font, size: 8pt, fill: ink-60,
          meta.at("author", default: "이상수") + "  ·  " + meta.at("publisher", default: "엘비즈파트너스") +
          "  ·  " + meta.at("date", default: "") + "  ·  " + meta.at("series_no", default: "PRACTICAL WHITEPAPER 01")))
    })
  } else {
  page(margin: 0mm, header: none, footer: none, fill: navy-900, {
    set par(justify: false, first-line-indent: 0em)
    block(width: 100%, height: 40%, clip: true, cover-pattern(200mm, 112mm))
    place(top + left, dx: 20mm, dy: 20mm, rect(width: 24mm, height: 4mm, fill: accent))
    if meta.at("_brand_logo", default: none) != none {
      place(top + right, dx: -20mm, dy: 16mm,
        image(meta.at("_brand_logo"), width: 24mm))
    }
    // 시리즈 라벨: 제목 블록 위 6mm
    place(top + left, dx: 20mm, dy: 114mm,
      text(fill: navy-300, font: TT.display-font, size: 8pt, tracking: 0.06em,
        upper(meta.at("series", default: "LBIZ PARTNERS"))))
    // 제목 블록 상단 = 판면 상단(28mm) + 96mm = 페이지 상단 124mm 고정 (STYLE 표지 문법)
    place(top + left, dx: 20mm, dy: 124mm, block(width: 160mm, {
      set text(fill: white, font: TT.display-font)
      context {
        // 48pt ExtraBold 기본, 3행(3×52pt) 초과 시에만 하향
        let title-at(sz) = text(size: sz, weight: "extrabold", tracking: -0.025em,
          keep-words(meta.title))
        let sz = 48pt
        while sz > 30pt and measure(block(width: 160mm, title-at(sz))).height > 3 * 52pt {
          sz = sz - 4pt
        }
        title-at(sz)
      }
      if meta.at("subtitle", default: none) != none {
        v(6mm)
        text(size: 16pt, weight: "regular", fill: navy-100, keep-words(meta.subtitle))
      }
      if meta.at("slogan", default: none) != none {
        v(4mm)
        text(size: 10pt, weight: "medium", fill: accent, meta.slogan)
      }
      v(12mm)
      line(length: 100%, stroke: 0.6pt + navy-500.transparentize(40%))
    }))
    place(bottom + left, dx: 20mm, dy: -18mm, {
      set text(size: 8pt, fill: navy-100, font: TT.sans-font)
      [#meta.at("author", default: "이상수") · #meta.at("publisher", default: "LBiz Partners") · #meta.at("date", default: "") · #meta.at("series_no", default: "")]
    })
  })
  }
}

// ---- LBiz supplied branded opener: chapter label + illustration + summary ---
#let opener-image(n) = {
  let k = calc.rem(n - 1, 7) + 1
  if k == 1 { "../../assets/three-doors.png" }
  else if k == 2 { "../../assets/threshold-desk.png" }
  else if k == 3 { "../../assets/audit-calendar.png" }
  else if k == 4 { "../../assets/evidence-chain.png" }
  else if k == 5 { "../../assets/three-layers.png" }
  else if k == 6 { "../../assets/audit-report.png" }
  else { "../../assets/roadmap-faq.png" }
}

#let branded-opener(n, title, summary, t) = {
  full-bleed(t, block(fill: ivory, width: 100%, height: 100%, inset: (x: 14mm, y: 17mm), {
    set text(fill: navy-900, font: t.display-font)
    set par(justify: false, first-line-indent: 0em)
    v(1mm)
    text(font: t.sans-font, size: 8pt, weight: "bold", tracking: 0.08em, fill: accent,
      "CHAPTER " + numpad(n))
    v(4mm)
    text(size: 23pt, weight: "extrabold", tracking: -0.025em, keep-words(title))
    v(4mm)
    line(length: 100%, stroke: 0.7pt + accent)
    if summary != none {
      v(4mm)
      set text(size: 9.5pt, weight: "regular", fill: ink-60)
      set par(leading: 0.72em, justify: false)
      block(width: 100%, summary)
    }
    v(5mm)
    block(width: 100%, fill: white, stroke: 0.5pt + rule-c, inset: 2mm, radius: 3pt,
      image(opener-image(n), width: 100%))
    place(bottom + left, dx: 0mm, dy: -5mm,
      text(font: t.sans-font, size: 7pt, fill: ink-60,
        meta.at("publisher", default: "엘비즈파트너스") + " · " +
        meta.at("date", default: "2026-09")))
  }))
}

// ---- 도비라: navy 풀블리드 + 96pt 장번호 + accent 룰 + 하단 절 목록 ----------
#let biz-opener(n, title, summary, t) = {
  full-bleed(t, block(fill: navy-900, width: 100%, height: 100%, inset: (x: 20mm, y: 28mm), {
    set text(fill: white, font: t.display-font)
    set par(justify: false, first-line-indent: 0em)
    // 표지 계통 벡터 패턴: 우측 하단 60% 영역, 30% 불투명도 (STYLE 도비라 문법)
    place(bottom + right, dx: 20mm, dy: 28mm,
      block(width: 120mm, height: 168mm, clip: true, cover-pattern(120mm, 168mm)))
    v(6mm)
    text(size: 96pt, weight: "extrabold", tracking: -0.03em, fill: navy-300, numpad(n))
    v(6mm)
    text(size: 30pt, weight: "extrabold", tracking: -0.02em, keep-words(title))
    v(12mm)
    rect(width: 40mm, height: 3pt, fill: accent)
    if summary != none {
      v(6mm)
      set text(size: 11pt, weight: "regular", fill: navy-100)
      set par(leading: 0.7em, justify: false)
      block(width: 82%, summary)
    }
    // 하단 좌측: 해당 장 수록 절 목록 8pt/+6% navy-300
    context {
      let h1s = query(heading.where(level: 1).after(here()))
      let secs = query(heading.where(level: 2).after(here()))
      if h1s.len() > 0 {
        let lim = h1s.first().location().page()
        secs = secs.filter(h => h.location().page() < lim)
      }
      if secs.len() > 0 {
        place(bottom + left, {
          set text(font: t.sans-font, size: 8pt, tracking: 0.06em, fill: navy-300)
          set par(leading: 0.5em, spacing: 0.5em)
          stack(dir: ttb, spacing: 2.8mm, ..secs.map(h => h.body))
        })
      }
    }
  }))
}

// LBiz editorial-light chapter divider: keeps the same numbering and
// hierarchy as the report template while moving the visual weight to a
// readable white field for the updated personal-brand system.
#let light-opener(n, title, summary, t) = {
  full-bleed(t, block(fill: white, width: 100%, height: 100%, inset: (x: 20mm, y: 28mm), {
    set text(font: t.display-font)
    set par(justify: false, first-line-indent: 0em)
    place(top + right, dx: 20mm, dy: 16mm,
      block(width: 96mm, height: 168mm, clip: true, cover-pattern(96mm, 168mm)))
    text(font: t.sans-font, size: 8pt, weight: "bold", tracking: 0.08em,
      fill: navy-700, "LBIZ PARTNERS  ·  FAMILY CORPORATION")
    v(7mm)
    text(size: 82pt, weight: "extrabold", tracking: -0.04em, fill: navy-500, numpad(n))
    v(12mm)
    text(size: 28pt, weight: "extrabold", tracking: -0.02em, fill: navy-900, keep-words(title))
    v(9mm)
    rect(width: 38mm, height: 3pt, fill: accent)
    if summary != none {
      v(6mm)
      set text(size: 11pt, weight: "regular", fill: ink-60)
      set par(leading: 0.7em, justify: false)
      block(width: 78%, summary)
    }
    place(bottom + left, dy: -4mm,
      text(font: t.sans-font, size: 8pt, fill: ink-60,
        meta.at("series", default: "이상수의 법인전환 판단실") + "  ·  " + meta.at("slogan", default: "")))
  }))
}

#let biz-tbl = counter("biz-tbl")
#let biz-fig = counter("biz-fig")

// T1 — Executive Summary: 도비라 없이 라벨 + 결론 액션 타이틀(22pt)로 여는 지면.
// 장 카운터(chapter-state)를 건드리지 않아 본장 번호·표/그림 채번이 밀리지 않는다.
#let bf-exec-open(title, summary) = {
  pagebreak(weak: true)
  hide(block(height: 0pt, heading(level: 1, outlined: true, bookmarked: true, title)))
  v(-1.2em)
  block({
    set par(justify: false, first-line-indent: 0em)
    // 라벨색은 토큰만 사용 — accent(#C2662E)는 흰 바탕 4.01로 4.5:1 미달(G14-C).
    // W4 7단계 전에는 10.5pt Bold로 올려 구(舊) 완화 하한의 "대형 3:1" 대역에 넣어
    // 통과시켰으나, 하한이 WCAG(≥18pt 또는 ≥14pt Bold)로 교정되면서 그 회피가 무효화됐다.
    // 급수를 14pt Bold로 더 올리는 길은 STYLE.md 타입 스케일에 없다(라벨은 8/12/+6이
    // 유일한 급수이고, 14pt는 리드문 13pt·항 15pt 사이라 라벨이 액션 타이틀과 경합한다).
    // 그래서 색을 바꾼다 — CONTENTS 라벨(아래 toc-head)이 같은 이유로 이미 택한
    // navy-700(11.60:1)을 그대로 쓰고, 급수는 STYLE.md T1 규정값 8pt/+6%로 되돌린다.
    text(font: TT.sans-font, size: 8pt, tracking: 0.06em, weight: "bold", fill: navy-700, title)
    if summary != none {
      v(4mm)
      text(font: TT.display-font, size: 22pt, weight: "bold", tracking: -0.015em,
        fill: navy-900, keep-words(summary))
    }
    v(3mm)
    line(length: 100%, stroke: 0.8pt + navy-700)
  })
  v(4mm)
}

#let bf-chapter(title, summary: none) = {
  if lower(title).contains("executive summary") {
    bf-exec-open(title, summary)
  } else {
    biz-tbl.update(0)
    biz-fig.update(0)
    base.chapter(title, summary: summary, t: TT,
      opener: if brand-editorial { branded-opener }
        else if light-editorial { light-opener }
        else { biz-opener })
  }
}

// ---- 키 스탯: accent 상단 룰 + Gmarket 숫자 40pt (STYLE 타입 스케일) ----------
// 주의: 본문 par spacing(1em)은 급수에 비례해 커진다 — 40pt 문단이 그대로 상속하면
// 룰과 숫자 사이 20mm대 공기가 생긴다(실측). 블록 내부는 스페이싱을 0으로 재설정.
#let bf-stat-cell(value, label, width: 100%) = {
  set par(spacing: 0em, leading: 0.35em, justify: false, first-line-indent: 0em)
  set block(spacing: 0em)
  rect(width: width, height: 2pt, fill: accent)
  v(2.5mm)
  block(text(font: TT.stat-font, weight: "bold", size: 40pt, tracking: -0.03em,
    fill: navy-900, top-edge: "cap-height", bottom-edge: "baseline", value))
  v(2.5mm)
  block(width: width, text(font: TT.sans-font, size: 9pt, fill: ink-60, label))
}

#let bf-stat(value, label) = {
  block(breakable: false, width: 50mm, above: 5mm, below: 5mm,
    bf-stat-cell(value, label))
}

// ---- Exec Summary 리드문 13/21pt ---------------------------------------------
#let bf-lead(body) = block(width: 100%, above: 4mm, below: 5mm, {
  set text(size: 13pt, fill: ink)
  set par(leading: 0.62em, spacing: 1.0em, justify: true, first-line-indent: 0em)
  body
})

// ---- 2단(3+3 컬럼) 배치 — Exec Summary 키 메시지용 (2단 본문 9.5/15.5) -------
// columns()는 무한 플로우에서 남은 지면 전체를 차지한다(실측 — 뒤따르는 스탯
// 스트립이 다음 면으로 밀림). 단일 컬럼 실측 높이의 절반 + 여유로 높이를 고정.
#let bf-cols(body) = {
  let styled = {
    set text(size: 9.5pt)
    set par(leading: 0.63em, spacing: 0.9em)
    body
  }
  block(width: 100%, above: 4mm, below: 4mm, layout(size => context {
    let col-w = (size.width - 5mm) / 2
    let h-full = measure(block(width: col-w, styled)).height
    let h = h-full / 2 + 30pt  // 헤딩 keep 경계의 불균형 분할 여유
    block(width: 100%, height: h, columns(2, gutter: 5mm, styled))
  }))
}

// ---- 키 스탯 3연 스트립 (T1 하단, paper-alt 바탕) ----------------------------
// items: "값 | 라벨" 행들의 배열
// T1 하단 고정 스트립 — 흐름이 아니라 지면 하단에 앉힌다 (STYLE T1 "하단 고정 스트립")
#let bf-statrow(..items) = place(bottom + left,
  block(breakable: false, width: 100%, fill: paper-alt, inset: 6mm,
    // align: top — place(bottom)의 정렬 컨텍스트가 셀에 상속되면 설명이 2행인 셀만
    // 숫자가 위로 밀려 3연 숫자 기준선이 어긋난다(실측 9.5pt). 셀 상단 정렬로
    // 룰·숫자 기준선을 통일하고, 행 수 차이는 라벨 아래쪽으로만 흡수한다.
    grid(columns: (1fr,) * items.pos().len(), column-gutter: 6mm, align: top,
      ..items.pos().map(it => bf-stat-cell(it.at(0), it.at(1))))))

// ---- 콜아웃: 인사이트 박스 / 인용 박스 / alert ------------------------------
#let bf-callout(kind: "info", title: none, body) = {
  if kind == "quote" {
    block(breakable: false, inset: (left: 6mm),
      stroke: (left: 3pt + navy-500), {
        set text(font: TT.quote-font, size: 13pt, fill: navy-900)
        set par(leading: 0.62em, first-line-indent: 0em)
        body
      })
  } else {
    let label = if title != none { title } else if kind == "warn" { "유의" } else { "시사점" }
    let lc = if kind == "warn" { alert-c } else { navy-700 }
    block(
      width: 100%, breakable: false,
      fill: if kind == "example" { white } else { paper-alt },
      stroke: 0.5pt + navy-100, inset: 6mm,
      {
        text(font: TT.sans-font, size: 8pt, tracking: 0.06em, weight: "bold", fill: lc, upper(label))
        v(2.5mm)
        set text(size: 9.5pt, fill: if kind == "example" { navy-700 } else { ink })
        set par(leading: 0.6em, spacing: 0.8em)
        body
      })
  }
}

// 그림: 표와 동일한 장-순번 채번 — [그림 2-1] 9pt Bold navy-700 + 제목 11pt SemiBold
#let bf-fig(path, caption: none, source: none, width: 100%) = {
  block(breakable: false, {
    if caption != none {
      context {
        biz-fig.step()
        let n = chapter-state.get().num
        let m = biz-fig.get().first() + 1
        text(font: TT.sans-font, size: 9pt, weight: "bold", fill: navy-700,
          "[그림 " + str(n) + "-" + str(m) + "]")
        h(0.5em)
        text(font: TT.sans-font, size: 11pt, weight: "semibold", fill: ink, caption)
      }
      v(2.5mm)
    }
    image(path, width: width)
    if source != none {
      v(3mm)
      text(font: TT.sans-font, size: 7.5pt, fill: ink-60, [자료: #source])
    }
  })
}

// 표: 콘텐츠 [표] 캡션 계약 — 캡션이 실재할 때만 <표 n-m> 라벨, 출처는 콘텐츠가 준 것만
#let bf-tbl(caption: none, source: none, body) = block(breakable: false, above: 6mm, below: 6mm, width: 100%, {
  if caption != none {
    context {
      biz-tbl.step()
      let n = chapter-state.get().num
      let m = biz-tbl.get().first() + 1
      text(font: TT.sans-font, size: 9pt, weight: "bold", fill: navy-700,
        "<표 " + str(n) + "-" + str(m) + ">")
      h(0.5em)
      text(font: TT.sans-font, size: 9.5pt, weight: "semibold", fill: ink, caption)
    }
    v(2mm)
  }
  body
  if source != none {
    v(2mm)
    text(font: TT.sans-font, size: 7.5pt, fill: ink-60, [자료: #source])
  }
})

// 판권면. meta.imprint(사전)가 있으면 발행처 프로필 블록을 함께 싣는다.
//   imprint: (name, role, tagline, credentials[], books[], stats[(num,label)],
//             phone, email, site, note)
// 전부 선택 항목이며, 없으면 종전과 같이 한 줄 판권 표기만 남는다.
#let colophon(meta, t) = {
  pagebreak(weak: true)
  page(header: none, footer: none, background: none, {
    set par(first-line-indent: 0em, leading: 0.62em)
    v(1fr)

    let im = meta.at("imprint", default: none)
    if im != none {
      block(width: 100%, inset: (x: 8mm, y: 7mm), radius: 3pt, fill: paper-alt, {
        // 발행처 라벨
        text(font: TT.sans-font, size: 8pt, weight: "bold", tracking: 0.06em,
          fill: navy-700, upper(im.at("label", default: "PUBLISHED BY")))
        v(3mm)
        // 이름 · 직함
        text(font: TT.sans-font, size: 15pt, weight: "extrabold",
          tracking: -0.02em, fill: navy-900, im.at("name", default: ""))
        if im.at("role", default: none) != none {
          h(2mm)
          text(font: TT.sans-font, size: 9.5pt, fill: ink-60, im.role)
        }
        if im.at("tagline", default: none) != none {
          v(2mm)
          text(font: TT.sans-font, size: 9pt, fill: ink, im.tagline)
        }

        // 지표 가로 배치
        let st = im.at("stats", default: ())
        if st.len() > 0 {
          v(4mm)
          grid(columns: st.len(), column-gutter: 6mm, ..st.map(it => {
            text(font: TT.sans-font, size: 12pt, weight: "bold",
              fill: navy-700, it.at(0))
            linebreak()
            text(font: TT.sans-font, size: 7.5pt, fill: ink-60, it.at(1))
          }))
        }

        // 자격 · 저서
        let cr = im.at("credentials", default: ())
        if cr.len() > 0 {
          v(4mm)
          text(font: TT.sans-font, size: 8pt, fill: ink-60, cr.join(" · "))
        }
        let bk = im.at("books", default: ())
        if bk.len() > 0 {
          v(1.5mm)
          text(font: TT.sans-font, size: 8pt, fill: ink-60,
            "저서 " + bk.map(x => "「" + x + "」").join(" · "))
        }

        // 연락처
        v(4mm)
        line(length: 100%, stroke: 0.4pt + rule-c)
        v(3mm)
        let rows = ()
        if im.at("phone", default: none) != none { rows.push(("전화", im.phone)) }
        if im.at("email", default: none) != none { rows.push(("이메일", im.email)) }
        if im.at("site", default: none) != none { rows.push(("홈페이지", im.site)) }
        if rows.len() > 0 {
          grid(columns: rows.len(), column-gutter: 8mm, ..rows.map(r => {
            text(font: TT.sans-font, size: 7.5pt, tracking: 0.06em, fill: ink-60, r.at(0))
            linebreak()
            text(font: TT.sans-font, size: 9.5pt, weight: "semibold", fill: navy-900, r.at(1))
          }))
        }
        if im.at("note", default: none) != none {
          v(3mm)
          text(font: TT.sans-font, size: 7.5pt, fill: ink-60, im.note)
        }
      })
      v(5mm)
    }

    set text(size: 8pt, fill: ink-60)
    // 면책: meta.disclaimer 가 있으면 판권 위에 싣는다(장 본문에서 뺄 수 있게)
    let dc = meta.at("disclaimer", default: none)
    if dc != none {
      block(width: 100%, inset: (x: 8mm, y: 5mm), radius: 3pt,
        stroke: 0.5pt + navy-100, {
        text(font: TT.sans-font, size: 8pt, weight: "bold", tracking: 0.06em,
          fill: navy-700, "면책")
        v(2mm)
        set par(justify: true, leading: 0.6em)
        text(font: TT.sans-font, size: 8pt, fill: ink-60, dc)
      })
      v(5mm)
    }
    line(length: 40%, stroke: 0.4pt + rule-c)
    v(4pt)
    [#meta.title · #meta.at("author", default: "") · #meta.at("date", default: "") 발행]
    linebreak()
    [본 보고서의 수치·인용은 본문 표기 출처를 따르며, 무단 전재를 금합니다.]
  })
}

// ---- LBiz branded closing page: source / recheck list ----------------------
#let source-list(meta, t) = {
  let product-guide = meta.at("source_list_mode", default: "") == "product-guide"
  let investment-association = meta.at("source_list_mode", default: "") == "investment-association"
  let medical-mso = meta.at("source_list_mode", default: "") == "medical-mso"
  let notice = meta.at("disclaimer", default:
    if investment-association {
      "본 자료는 개인투자조합의 등록·운영·청산을 이해하기 위한 일반 안내입니다. 실제 접수·투자·분배·세무 신고 전에는 최신 공식 서식과 조합별 사실관계를 변호사·세무사·회계사 및 접수기관과 확인하십시오."
    } else if medical-mso {
      "본 자료는 의료기관 경영지원 구조를 이해하기 위한 교육·실무 보조 자료입니다. 실제 설립·계약·세무·노무·개인정보·의료광고 판단 전에는 최신 원문과 기관별 사실관계를 자격사와 확인하십시오."
    } else {
      "본 자료는 일반 안내이며 개별 자문을 대신하지 않습니다. 실제 적용 전에는 최신 원문과 회사별 사실관계를 전문가와 확인하십시오."
    })
  pagebreak(weak: true)
  page(header: none, footer: none, background: none, fill: ivory, {
    set text(font: t.body-font, size: 8.8pt, fill: ink, lang: "ko", region: "KR")
    set par(justify: false, first-line-indent: 0em, leading: 0.62em, spacing: 0.72em)
    text(font: t.display-font, size: 18pt, weight: "bold", fill: navy-900,
      "출처·확인 필요 목록 (독자용)")
    v(2mm)
    line(length: 42mm, stroke: 1pt + accent)
    v(5mm)
    text(font: t.sans-font, size: 8.7pt, fill: ink,
      if product-guide {
        "아래는 본문에서 참조한 Claude 공식 문서와 실제 앱 화면, 그리고 독자가 마지막으로 확인할 항목입니다. 제품명·요금·기능·화면은 계정·운영체제·출시 시점에 따라 달라질 수 있습니다."
      } else if investment-association {
        "아래는 본문에서 참조한 개인투자조합 법·시행령·시행규칙·고시·행정 안내와 독자가 조합별로 마지막에 확인할 항목입니다. 법령·서식·접수창구는 신청일에 국가법령정보센터와 담당기관에서 다시 확인하십시오."
      } else if medical-mso {
        "아래는 본문에서 참조한 의료·세무·노무·개인정보·의료광고 관련 법령과 정부 안내, 그리고 MSO 운영자가 마지막에 확인할 항목입니다. 실제 적용 전에는 국가법령정보센터와 관계기관의 최신 원문을 다시 확인하십시오."
      } else {
        "아래는 본문에서 참조한 법·제도와 대표님이 마지막으로 확인할 항목입니다. 법령 원문은 국가법령정보센터(law.go.kr)에서 법령명과 조문으로 다시 확인할 수 있습니다."
      })
    v(3mm)
    block(width: 100%, fill: white, stroke: 0.5pt + rule-c, inset: (x: 5mm, y: 4mm), {
      text(font: t.sans-font, size: 8pt, weight: "bold", fill: navy-700,
        if product-guide { "본문의 핵심 근거" } else { "본문의 핵심 근거" })
      v(2mm)
      if product-guide {
        text(size: 8.2pt, fill: ink,
          "· Claude Code 데스크톱 시작·참조 문서(code.claude.com)")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· Claude Cowork 시작·컴퓨터 사용·예약 작업 지원 문서(support.claude.com)")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 권한 모드·메모리·MCP·기능 개요 공식 문서")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 실제 Claude 데스크톱 설정 화면 관찰·주석 캡처(2026-09-12)")
      } else if investment-association {
        text(size: 8.2pt, fill: ink,
          "· 벤처투자 촉진에 관한 법률 제12조·제13조·제18조·제19조·제22조 현행 원문")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 같은 법 시행령 제6조·제7조·제8조·제10조 및 시행규칙 제5조·제9조·별지 서식")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 개인투자조합 등록 및 투자확인서 발급규정과 정부24 민원 안내")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 조세특례제한법 제16조와 국세법령정보시스템의 사실관계별 세무 검토 창구")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 2026-09-15 집필팀이 확인한 공식 출처 목록과 법령 재확인 기록")
      } else if medical-mso {
        text(size: 8.2pt, fill: ink,
          [· 의료법 제33·56·57조: #link("https://law.go.kr/LSW/lsLinkCommonInfo.do?lsJoLnkSeq=1032064215")[국가법령정보센터 제57조 원문]에서 광고 기준 확인])
        linebreak()
        text(size: 8.2pt, fill: ink,
          [· 개인정보 보호법 제23·26·34조, 시행령 제39·39의2·40조: #link("https://law.go.kr/lsLinkCommonInfo.do?chrClsCd=010202&lsJoLnkSeq=1020399009")[제26조 원문]에서 법령명·조문 검색])
        linebreak()
        text(size: 8.2pt, fill: ink,
          [· 법인세법 제52·116조, 부가가치세법 제8·32조: #link("https://www.law.go.kr/법령/법인세법/제52조")[법인세법 제52조]·#link("https://www.law.go.kr/법령/부가가치세법/제32조")[부가가치세법 제32조]와 국세청 안내 대조])
        linebreak()
        text(size: 8.2pt, fill: ink,
          [· 근로기준법 제17조·파견근로자 보호 관련 법령: #link("https://www.law.go.kr/법령/근로기준법/제17조")[근로기준법 제17조]와 고용노동부 안내 대조])
        linebreak()
        text(size: 8.2pt, fill: ink,
          [· 집필 확인일 2026-09-15: 의료법·개인정보 보호법 2026-09-11 시행본과 #link("https://pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS074&mCode=C020010000&nttId=12459")[개인정보보호위원회 개정 안내]를 대조; 실제 적용일 다시 확인])
      } else {
        text(size: 8.2pt, fill: ink,
          "· 상법·법인세법·소득세법·상속세 및 증여세법의 현행 원문과 시행령·시행규칙")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 근로기준법·최저임금법·국민연금·국민건강보험·고용보험·산재보험 관계 법령")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 국세청·홈택스·국세법령정보시스템·기획재정부·고용노동부·4대보험 기관 안내")
        linebreak()
        text(size: 8.2pt, fill: ink,
          "· 2026-09-10 korean-law 원문 조회 및 법령 사실 대장(research/fact-ledger.md)")
      }
    })
    v(4mm)
    text(font: t.sans-font, size: 8pt, weight: "bold", fill: navy-700,
      if product-guide { "독자가 작업별로 다시 확인할 항목" } else if investment-association { "조합별로 다시 확인할 항목" } else if medical-mso { "MSO 운영자가 다시 확인할 항목" } else { "대표님이 회사별로 다시 확인할 항목" })
    v(2mm)
    if product-guide {
      text(size: 8.2pt, fill: ink,
        "· 현재 계정·플랜·운영체제에서 같은 메뉴와 권한이 보이는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· Local·Remote·Cloud·SSH 중 실제 실행 위치가 어디인가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 폴더·프로젝트·커넥터·MCP의 읽기·쓰기·공유 범위가 맞는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 공식 문서의 최신 변경과 실제 화면의 차이를 확인했는가")
    } else if investment-association {
      text(size: 8.2pt, fill: ink,
        "· GP·LP·조합원 수·출자좌수·존속기간·GP 출자비율이 현행 요건과 맞는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 결성총회 의사록·규약·명부·출자이행·잔액증명과 최신 공식 첨부목록을 대조했는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 등록 후 투자의무·관계인 거래·보고·변경등록·청산 일정과 증거 보관 위치를 정했는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 투자확인서·소득공제·분배·보수·원천징수의 조합별 세무 쟁점을 전문가에게 전달했는가")
    } else if medical-mso {
      text(size: 8.2pt, fill: ink,
        "· 의료기관과 MSO의 소유·자금·진료·인사·광고 책임이 실제 행동에서도 분리되는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 서비스계약·가격 산정·요청·승인·검수·세금계산서·이체가 거래별로 이어지는가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 직원의 고용주·지휘자·급여 책임과 환자·직원정보 접근권한이 명확한가")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 의료광고·환자 유입·사고 대응에 필요한 최신 기준과 자격사 검토를 확인했는가")
    } else {
      text(size: 8.2pt, fill: ink,
        "· 법인 형태·결산월·주주명부·임원등기와 실제 의사결정 권한")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 가족 구성원별 실제 업무·근무시간·지휘감독·보수·지급일과 신고 흔적")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 회사 카드·대여·임대차·용역 등 가족 간 거래의 목적·시가·계약·이행")
      linebreak()
      text(size: 8.2pt, fill: ink,
        "· 승계·증여·상속의 적용일, 신고·납부일, 경영·고용·자산 사후관리 조건")
    }
    v(4mm)
    block(width: 100%, fill: paper-alt, inset: (x: 5mm, y: 4mm), {
      text(font: t.sans-font, size: 8pt, weight: "bold", fill: alert-c, "주의")
      v(2mm)
      text(size: 8.2pt, fill: ink,
        notice)
    })
    v(1fr)
    block(width: 100%, {
      line(length: 100%, stroke: 0.4pt + rule-c)
      v(2mm)
      text(font: t.sans-font, size: 6.2pt, fill: navy-700,
        "본 자료는 저작권법의 보호를 받습니다. " +
        meta.at("publisher", default: "엘비즈파트너스") +
        "의 사전 서면 동의 없이 무단 복제·배포·전송·게시·공유하는 행위를 금합니다.")
      v(1mm)
      text(font: t.sans-font, size: 7pt, fill: ink-60,
        "상담·강의 보조")
      h(1fr)
      text(font: t.sans-font, size: 7pt, fill: ink-60,
        meta.at("title", default: "가족법인 실무백서") + " · 출처·확인 필요 목록")
    })
  })
}

// ---- 마스터 래퍼 -------------------------------------------------------------
#let book(meta: (:), tokens: (:), cover: none, toc: true, toc-title: "차례", body) = {
  let t = TT
  set document(title: meta.at("title", default: "무제"), author: meta.at("author", default: "이상수"))
  set page(
    width: t.trim.w, height: t.trim.h,
    margin: (top: t.margin.top, bottom: t.margin.bottom, left: t.margin.left, right: t.margin.right),
    fill: if brand-editorial { ivory } else { white },
    // 러닝헤드 하단(헤어라인) = 판면 상단 위 6mm → 텍스트 베이스라인 ≈ 8mm (STYLE 러닝 시스템)
    header-ascent: 6mm,
    header: context {
      let prev = query(heading.where(level: 1).before(here()))
      if prev.len() > 0 {
        set text(font: t.sans-font,
          size: if brand-editorial { 7.2pt } else { 8pt },
          tracking: if brand-editorial { 0.04em } else { 0.06em }, fill: ink-60)
        let n = chapter-state.get().num
        if n > 0 {
          text(weight: "bold", fill: if brand-editorial { accent } else { ink-60 }, numpad(n))
          h(0.6em)
        }
        text(weight: "medium", fill: ink-60, prev.last().body)
        h(1fr)
        text(weight: "bold", fill: navy-700, meta.at("title", default: ""))
        v(1.2mm)  // 베이스라인과 헤어라인 사이 여백
        line(length: 100%, stroke: 0.4pt + rule-c)
      }
    },
    footer: context {
      let pg = here().page()
      let h1-here = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
      if h1-here.len() == 0 {
        if brand-editorial {
          set text(font: t.sans-font, size: 7.2pt, fill: ink-60)
          text(weight: "medium", meta.at("publisher", default: "엘비즈파트너스") + " · " +
            meta.at("date", default: "2026-09"))
          h(1fr)
          text(weight: "bold", fill: navy-700, str(counter(page).get().first()))
        } else {
          align(right, text(font: t.sans-font, size: 9pt, weight: "medium", fill: navy-700,
            str(counter(page).get().first())))
        }
      }
    },
    background: context {
      if not brand-editorial {
        // 섹션 탭: 재단선 안쪽 8mm, 도비라·ES 면에는 그리지 않는다.
        let n = chapter-state.get().num
        let pg = here().page()
        let h1-here = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
        if n > 0 and h1-here.len() == 0 {
          place(top + right, dx: -8mm, dy: 28mm + (n - 1) * 26mm,
            rect(width: if light-editorial { 3mm } else { 6mm },
              height: if light-editorial { 18mm } else { 24mm },
              fill: if light-editorial { accent } else { navy-500 }, {
              align(center + horizon, text(font: t.sans-font,
                size: if light-editorial { 6.5pt } else { 8pt }, weight: "bold",
                fill: if light-editorial { navy-900 } else { white }, numpad(n)))
            }))
        }
      }
    },
  )
  set text(font: t.body-font, size: t.body-size, fill: ink, lang: "ko", region: "KR")
  set text(costs: (orphan: 100%, widow: 100%, runt: 200%))
  set par(justify: true, leading: t.body-leading, spacing: 1.0em, first-line-indent: 0em)

  // 절/항: 액션 타이틀 문법 — 강제 개면 금지(흐름 배치), 개면은 H1만
  show heading.where(level: 2): it => {
    v(1.8em, weak: true)
    block(sticky: true, {
      text(font: t.sans-font, size: if brand-editorial { 14pt } else { 16pt },
        weight: "bold", tracking: -0.01em, fill: navy-900, it.body)
      v(2.2mm)
      line(length: 100%, stroke: 0.8pt + navy-700)
    })
    v(1.1em, weak: true)
  }
  show heading.where(level: 3): it => {
    v(1.5em, weak: true)
    block(sticky: true, text(font: t.sans-font,
      size: if brand-editorial { 10.5pt } else { 12pt },
      weight: "semibold", fill: navy-700, it.body))
    v(0.6em, weak: true)
  }
  set heading(numbering: none)

  show quote.where(block: true): it => bf-callout(kind: "quote")[#it.body]
  set list(marker: ([•], [–]), indent: 5mm, spacing: 0.7em, body-indent: 3mm)
  set enum(indent: 5mm, spacing: 0.7em, body-indent: 3mm)
  show list: set block(above: 1em, below: 1em)
  show enum: set block(above: 1em, below: 1em)
  set text(number-type: "lining", number-width: "tabular")
  show raw.where(block: true): it => block(
    width: 100%, fill: paper-alt, inset: 5mm, stroke: 0.5pt + navy-100,
    text(font: code-font, size: 8.5pt, it))

  // 표: 세로 괘선·얼룩말 금지, navy 상하 굵은 룰
  set table(stroke: none, inset: (x: 3mm, y: 2.6mm), fill: none)
  show table: it => {
    set text(size: if brand-editorial { 8.5pt } else { 9pt }, font: t.sans-font)
    block(breakable: false, {
      it
    })
  }
  set table(stroke: (x, y) => (
    top: if y == 0 { 1.2pt + navy-900 } else if y == 1 { 0.6pt + navy-700 } else { 0.4pt + rule-c },
    bottom: 1.2pt + navy-900,
  ))
  show table.cell.where(y: 0): it => text(weight: "semibold", fill: navy-900, it)
  show table.cell: set align(left + horizon)
  show link: it => text(fill: if brand-editorial { navy-700 } else { navy-500 }, it)
  show figure.caption: it => text(font: t.sans-font, size: 8pt, fill: ink-60, it)

  if cover != none { cover }
  // 리포트형: 속표지 생략, 목차 1면 완결 (STYLE.md「목차 문법」)
  //  - 좌측 22.5mm 컬럼 장번호 / 우측 5컬럼 장제목 + 절제목 리스트
  //  - 점선 리더 금지, 쪽번호 우측 정렬 tabular, 위계는 장·절 2단계까지
  //  - 최상단 Executive Summary는 장번호 없이 별도 행
  if toc {
    // 한 행 = 제목(1fr) + 쪽번호(우측 정렬). 리더 없음.
    let toc-row(body, pnum, t-size, p-size, t-fill, p-fill, t-weight, t-font) = grid(
      columns: (1fr, 11mm), column-gutter: 3mm,
      align: (left + top, right + top),
      text(font: t-font, size: t-size, weight: t-weight, tracking: -0.01em, fill: t-fill, body),
      {
        // 쪽번호를 제목 베이스라인에 맞춰 내림(급수 차 보정)
        v((t-size - p-size) * 0.88)
        text(font: t.sans-font, size: p-size, weight: "medium", fill: p-fill, str(pnum))
      },
    )

    // 항목 전체 렌더 — 간격/급수는 tier로 주입(1면 완결을 위한 적응 축소)
    let toc-body(entries, ch-gap, sec-gap, ch-size, sec-size, num-size) = {
      // 간격은 오직 v()로만 — 블록 자동 간격 제거(1면 예산 계산의 전제)
      set par(justify: false, first-line-indent: 0em, leading: 0.42em, spacing: 0em)
      set block(spacing: 0em)
      for (i, e) in entries.enumerate() {
        if i > 0 { v(ch-gap) }
        block(breakable: false, width: 100%, grid(
          columns: (22.5mm, 1fr),
          {
            // 장번호 01 / ES는 번호 없이 accent 마커
            if e.num == none {
              v(ch-size * 0.5)
              rect(width: 12mm, height: 2pt, fill: accent)
            } else {
              text(font: t.display-font, size: num-size, weight: "extrabold",
                tracking: -0.02em, fill: navy-500, numpad(e.num))
            }
          },
          {
            link(e.loc, toc-row(e.title, e.page, ch-size, ch-size * 0.7,
              navy-900, navy-700, "semibold", t.sans-font))
            if e.secs.len() > 0 {
              v(sec-gap * 0.9)
              for (j, s) in e.secs.enumerate() {
                if j > 0 { v(sec-gap) }
                link(s.loc, toc-row(s.title, s.page, sec-size, sec-size,
                  ink-60, ink-60, "regular", t.body-font))
              }
            }
          },
        ))
        // ES 블록은 본장과 헤어라인으로 분리
        if e.num == none {
          v(ch-gap * 0.6)
          line(length: 100%, stroke: 0.4pt + rule-c)
        }
      }
    }

    let toc-head = {
      set par(spacing: 0em)
      set block(spacing: 0em)
      // 라벨색은 토큰만 사용 — accent(#C2662E)는 8pt에서 배경 대비 4.5:1 미달(G14-C)이라
      // 그림/표 라벨과 같은 navy-700을 쓴다 (임의 중간색 #AF5C2A 제거)
      text(font: t.sans-font, size: 8pt, tracking: 0.06em, weight: "bold", fill: navy-700, "CONTENTS")
      v(3mm)
      text(font: t.display-font, size: 20pt, weight: "extrabold", tracking: -0.02em,
        fill: navy-900, toc-title)
      v(4mm)
      line(length: 100%, stroke: 1.2pt + navy-900)
      v(8mm)
    }

    // 넉넉한 사양치부터 시도해 1면에 들어가는 첫 tier 채택
    let tiers = (
      (ch: 12mm,  sec: 6mm,   chs: 15pt,   secs: 10.5pt, num: 24pt),
      (ch: 10mm,  sec: 5mm,   chs: 14.5pt, secs: 10pt,   num: 22pt),
      (ch: 8mm,   sec: 4.2mm, chs: 14pt,   secs: 9.5pt,  num: 21pt),
      (ch: 6.5mm, sec: 3.4mm, chs: 13pt,   secs: 9pt,    num: 19pt),
      (ch: 6.0mm, sec: 3.1mm, chs: 12.5pt, secs: 8.8pt,  num: 18pt),
      (ch: 5.2mm, sec: 2.8mm, chs: 12pt,   secs: 8.5pt,  num: 17pt),
      (ch: 4.2mm, sec: 2.2mm, chs: 11.5pt, secs: 8.2pt,  num: 16pt),
      (ch: 3.4mm, sec: 1.7mm, chs: 11pt,   secs: 8pt,    num: 15pt),
      (ch: 2.8mm, sec: 1.2mm, chs: 10.5pt, secs: 7.6pt,  num: 14pt),
    )

    // 목차 면은 6컬럼 전폭(160mm)을 쓴다 — 바깥 마진 컬럼 해제
    page(
      margin: (top: t.margin.top, bottom: t.margin.bottom,
        left: t.margin.left, right: t.margin.left),
      header: none, footer: none, background: none,
      context {
        let w = t.trim.w - t.margin.left * 2
        let avail = t.trim.h - t.margin.top - t.margin.bottom

        // 장·절 수집 (2단계까지, 항 제외)
        let toc-levels = meta.at("toc_levels", default: 2)
        let hs = query(heading).filter(h => h.level <= toc-levels and h.outlined)
        let entries = ()
        for h in hs {
          let p = counter(page).at(h.location()).first()
          if h.level == 1 {
            entries.push((
              num: entries.len() + 1, title: h.body,
              page: p, loc: h.location(), secs: (),
            ))
          } else if entries.len() > 0 {
            let last = entries.pop()
            last.secs.push((title: h.body, page: p, loc: h.location()))
            entries.push(last)
          }
        }
        // 1장이 Executive Summary면 번호 없는 별도 행으로 — 뒤 장들은 01부터 다시 채번
        // (본문 도비라·표/그림 번호는 chapter-state 기준이라 ES를 세지 않는다)
        if entries.len() > 0 {
          let head-title = lower(plain-text(entries.first().title))
          if head-title.contains("executive summary") or head-title.contains("요약") {
            let first = entries.first()
            first.num = none
            entries.at(0) = first
            for i in range(1, entries.len()) {
              let e = entries.at(i)
              e.num = e.num - 1
              entries.at(i) = e
            }
          }
        }

        let hh = measure(block(width: w, toc-head)).height
        let budget = avail - hh - 4mm
        let fits(tier) = measure(block(width: w,
          toc-body(entries, tier.ch, tier.sec, tier.chs, tier.secs, tier.num))).height
        let pick = tiers.last()
        for tier in tiers {
          if fits(tier) <= budget { pick = tier; break }
        }
        // 남은 여백은 장 사이 간격으로 되돌린다(사양치 12mm 상한)
        let slack = budget - fits(pick)
        let gaps = calc.max(entries.len() - 1, 1)
        let ch-gap = calc.min(pick.ch + slack / gaps, 12mm)

        toc-head
        toc-body(entries, ch-gap, pick.sec, pick.chs, pick.secs, pick.num)
      },
    )
  }
  counter(page).update(1)
  body
}
