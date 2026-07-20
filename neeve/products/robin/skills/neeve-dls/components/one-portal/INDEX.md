# Component Index

Look up the plain-language ask, get the component + layer + doc file. This index is
the fix for "the design team thinks everything comes from the DLS." Status legend:

- ✅ documented — doc file is filled in, safe to use as-is
- 🚧 stub — component exists, doc file not filled in yet, ask before building with it
- ❓ needs classification — not yet confirmed whether DLS / wrapper / page-local

## DLS components (`@neeve/dls`)

| Plain-language ask                  | Component                               | Doc                            | Status |
| ----------------------------------- | --------------------------------------- | ------------------------------ | ------ |
| avatar, profile picture             | `Avatar`                                | `dls/avatar.md`                | ✅     |
| alert, banner, inline message       | `AlertBanner`                           | `dls/alert-banner.md`          | ✅     |
| breadcrumb                          | `Breadcrumb`                            | `dls/breadcrumb.md`            | ✅     |
| badge, status pill                  | `Badge`                                 | `dls/badge.md`                 | ✅     |
| button                              | `Button`                                | `dls/button.md`                | ✅     |
| icon-only button                    | `iconOnlyButtonVariants` (via `Button`) | `dls/button.md`                | ✅     |
| card, tile                          | `Tile`                                  | `dls/tile.md`                  | ✅     |
| checkbox                            | `Checkbox`                              | `dls/checkbox.md`              | ✅     |
| combobox, searchable select         | `ComboBox`                              | `dls/combobox.md`              | ✅     |
| command palette, cmd+k menu         | `Command` (+ `CommandDialog` etc.)      | `dls/command.md`               | ✅     |
| dialog, modal                       | `Dialog` / `DialogRaw`                  | `dls/dialog.md`                | ✅     |
| drawer, side panel                  | `Drawer`                                | `dls/drawer.md`                | ✅     |
| empty state                         | `EmptyState`                            | `dls/empty-state.md`           | ✅     |
| text field, input                   | `TextInput`                             | `dls/text-input.md`            | ✅     |
| loading spinner                     | `Loader`                                | `dls/loader.md`                | ✅     |
| logo                                | `Logo`                                  | `dls/logo.md`                  | ✅     |
| dropdown menu, context menu         | `Menu`                                  | `dls/menu.md`                  | ✅     |
| menu bar (app-level)                | `Menubar` (+ subparts)                  | `dls/menubar.md`               | ✅     |
| multi-select                        | `MultiSelect`                           | `dls/multiselect.md`           | ✅     |
| popover                             | `Popover`                               | `dls/popover.md`               | ✅     |
| radio button                        | `Radio`                                 | `dls/radio.md`                 | ✅     |
| select, dropdown select             | `Select`                                | `dls/select.md`                | ✅     |
| divider, separator                  | `Separator`                             | `dls/separator.md`             | ✅     |
| summary panel                       | `Summary`                               | `dls/summary.md`               | ✅     |
| tabs                                | `Tabs`                                  | `dls/tabs.md`                  | ✅     |
| textarea                            | `TextArea`                              | `dls/textarea.md`              | ✅     |
| tooltip                             | `Tooltip`                               | `dls/tooltip.md`               | ✅     |
| grid layout container               | `LayoutGridContainer`                   | `dls/layout-grid-container.md` | ✅     |
| toolbar                             | `Toolbar`                               | `dls/toolbar.md`               | ✅     |
| search bar                          | `SearchBar`                             | `dls/search-bar.md`            | ✅     |
| toast notification                  | `Toast` / `ToastV1`                     | `dls/toast.md`                 | ✅     |
| title bar                           | `TitleBar`                              | `dls/title-bar.md`             | ✅     |
| prompt bar, AI input bar            | `PromptBar`                             | `dls/prompt-bar.md`            | ✅     |
| tag, chip                           | `Tag`, `Chip`                           | `dls/tag-and-chip.md`          | ✅     |
| bulk action bar                     | `BulkActionBar`                         | `dls/bulk-action-bar.md`       | ✅     |
| toggle, switch                      | `Toggle`                                | `dls/toggle.md`                | ✅     |
| table (any — static or interactive) | `TableV2` → see shared/components below | `wrappers/table-v2.md`         | ✅     |
| row card (list-style row)           | `RowCard`                               | `dls/row-card.md`              | ✅     |
| tree / hierarchical list            | `List`                                  | `dls/list.md`                  | ✅     |

## `shared/components` (one-portal repo)

This layer contains two distinct kinds of components. Status legend (same symbols as
DLS above):

- ✅ documented — doc file is filled in, safe to use as-is
- 🚧 stub — component exists, doc file not filled in yet, ask before building with it
- ❓ needs classification — not yet confirmed as wrapper / standalone

### Wrappers — extend a DLS primitive with product logic

| Plain-language ask                                                                                             | Component       | Wraps        | Doc                          | Status |
| -------------------------------------------------------------------------------------------------------------- | --------------- | ------------ | ---------------------------- | ------ |
| table (any), data table, static table, interactive table, reorder/resize/hide/freeze columns, filter, paginate | `TableV2`       | DLS `Table`  | `wrappers/table-v2.md`       | ✅     |
| submit/save button with loading state and dynamic label                                                        | `LoadingButton` | DLS `Button` | `wrappers/loading-button.md` | 🚧     |
| _(unknown — needs inventory)_                                                                                  | ?               | ?            | ?                            | ❓     |

### Standalones — not in the DLS for deliberate design or engineering reasons

These components were built for one-portal specifically. Do not assume a DLS equivalent
exists or will exist.

| Plain-language ask                   | Component        | Doc                              | Status |
| ------------------------------------ | ---------------- | -------------------------------- | ------ |
| step indicator, wizard progress tabs | `StepperTabs`    | `standalones/stepper-tabs.md`    | 🚧     |
| skeleton loading placeholder         | `SkeletonLoader` | `standalones/skeleton-loader.md` | ✅     |
| _(unknown — needs inventory)_        | ?                | ?                                | ❓     |

## Page-local (layout only, not a component to look up)

Grid/flex page composition. Not covered by this index — see
`references/one-portal-coding-standards.md` for one-portal's layout conventions once that's
filled in.

## Coverage gaps

✅ **All DLS components are now documented.** The skill can confidently recommend and provide examples for any DLS component when needed.
