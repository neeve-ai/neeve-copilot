# Design Tokens

Source of truth: `dls-neeve/src/index.css` (also mirrored for reference in this skill's
`assets/one-portal-index.css` — but always prefer the live repo file if available, since
this file changes). Never hardcode a hex value, an arbitrary `px`/`rem` spacing value, or
a raw font stack anywhere in one-portal code, including page-local layout code.

## Typography

Use the `dls-*` utility classes, never raw `font-size`/`font-family`/`line-height`:

| Class                                      | Use for                                          |
| ------------------------------------------ | ------------------------------------------------ |
| `dls-page-title`                           | Top-level page title                             |
| `dls-page-heading`                         | Page-section heading, one level below page title |
| `dls-section-heading`                      | Sub-section heading within a page                |
| `dls-callout-strong` / `dls-callout`       | Emphasized standalone statements, empty states   |
| `dls-body-strong` / `dls-body`             | Default body copy                                |
| `dls-body-small-strong` / `dls-body-small` | Secondary/dense body copy (tables, lists)        |
| `dls-caption-strong` / `dls-caption`       | Helper text, timestamps, metadata                |
| `dls-eyebrow`                              | Uppercase label above a heading                  |
| `dls-code-strong` / `dls-code`             | Inline code / monospace values                   |

These classes are already responsive (desktop sizes differ from mobile via the `lg`
breakpoint internally) — don't add manual font-size overrides at breakpoints.

## Color

Two tiers exist. **Prefer semantic tokens over raw palette tokens** — semantic tokens
carry intent and survive a re-theme; raw palette tokens (`--gray500`, `--red600`, etc.)
are the implementation detail behind them.

Semantic tokens to reach for first:

- Text: `--text-primary`, `--text-secondary`, `--text-tertiary`, `--text-contrast`
- Surface: `--background-primary/secondary/tertiary`
- Borders: `--border-primary`, `--border-secondary`
- Neutral scale: `--neutral-primary` … `--neutral-contrast`
- Brand: `--brand-primary` … `--brand-contrast`
- Status: `--success-*`, `--warning-*`, `--danger-*` (each has primary/secondary/
  tertiary/quarternary — quarternary is the lightest, primary the strongest)
- Disabled/inactive: `--inactive-*`
- Tenant/theme variants: `--neeve-*`, `--sara-*`, `--custom-*` — only use these when the
  request is explicitly about tenant-branded surfaces, not general UI

Only drop to raw palette tokens (`--gray*`, `--green*`, `--red*`, `--blue*`, etc.) when
building something inside the DLS itself, or when a component file explicitly says a
raw token is correct for that spot. If you find yourself reaching for a raw palette
token inside one-portal product code, that's usually a sign the right semantic token
just hasn't been identified yet — ask rather than default to raw.

Note there's also a legacy/default block in `index.css` marked "DONOT USE Default
Colors" — never use `--primary`, `--secondary`, `--muted`, `--accent`,
`--destructive`, etc. from that block. Those exist for shadcn/ui internals and are
explicitly not part of the DLS token contract.

## Spacing

The DLS uses a **custom Tailwind spacing scale** defined in `dls-neeve/tailwind.config.js`
under `theme.extend.spacing`. The `dls-` prefix is applied globally by Tailwind's
`prefix` setting, so the resulting utility classes are `dls-p-100`, `dls-m-200`, etc.

| Suffix | rem     | px  |
| ------ | ------- | --- |
| `0`    | 0       | 0   |
| `100`  | 0.25rem | 4   |
| `200`  | 0.5rem  | 8   |
| `300`  | 0.75rem | 12  |
| `400`  | 1rem    | 16  |
| `500`  | 1.5rem  | 24  |
| `600`  | 2rem    | 32  |
| `700`  | 3rem    | 48  |
| `800`  | 4rem    | 64  |
| `900`  | 6rem    | 96  |
| `1000` | 10rem   | 160 |

Applies to all spacing utilities: `dls-p-*`, `dls-m-*`, `dls-gap-*`, `dls-w-*`,
`dls-h-*`, `dls-px-*`, `dls-py-*`, `dls-mx-*`, `dls-my-*`, etc.

### Icon sizes

Use the dedicated icon-size utilities rather than raw spacing classes for icon elements:

| Class         | Applied classes             | Rendered size |
| ------------- | --------------------------- | ------------- |
| `dls-icon-xs` | `dls-h-3 dls-w-3 dls-p-0.5` | 12px box      |
| `dls-icon-sm` | `dls-h-4 dls-w-4 dls-p-1`   | 16px box      |
| `dls-icon-md` | `dls-h-8 dls-w-8 dls-p-2`   | 32px box      |
| `dls-icon-lg` | `dls-h-16 dls-w-16 dls-p-4` | 64px box      |

Note: `dls-icon-*` classes use standard Tailwind numeric suffixes (h-3, h-4, h-8,
h-16), **not** the custom 100–1000 scale above.

## Breakpoints

Defined in `dls-neeve/tailwind.config.js` under `theme.screens`:

| Token | Min-width | Primary use                          |
| ----- | --------- | ------------------------------------ |
| `xs`  | 0px       | Mobile baseline                      |
| `sm`  | 361px     | Small phones                         |
| `md`  | 641px     | Tablet                               |
| `lg`  | 769px     | Desktop — where typography scales up |
| `xl`  | 1441px    | Wide desktop                         |

The `lg` breakpoint (769px) is the main threshold used inside the DLS typography
classes. Whether one-portal inherits these breakpoints from the DLS Tailwind preset
or redeclares them in its own `tailwind.config.js` should be confirmed before adding
any `lg:`-prefixed responsive overrides in page-local code.
