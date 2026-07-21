# CountSection (Standalone component)

**Layer:** Wrapper component (`standalones/components`) — displays summary counts using DLS `Summary` primitive

Displays key metrics or count data in a structured summary layout. Used for dashboard summaries, statistics display, and overview panels.

## When to use

- Dashboard summary cards (user count, active connections, etc.)
- Statistics overview panels
- Quick metric display in headers or sidebars
- Hierarchical view summary statistics

## Props

| Prop        | Type                                               | Required | Notes                            |
| ----------- | -------------------------------------------------- | -------- | -------------------------------- |
| `isLoading` | `boolean`                                          | Yes      | Shows skeleton during data fetch |
| `counts`    | `Array<{ translationKey: string; value: number }>` | Yes      | Array of count items to display  |

## Capabilities

- Wraps DLS `Summary` component for consistent styling.
- Loading state automatically displays skeleton placeholders.
- Translatable labels via `translationKey` (i18n integration).
- Responsive multi-column layout (handled by DLS `Summary`).

## Known limitations

- Labels must exist in i18n translations (key must be in `messages/` files).
- No custom formatting (decimals, abbreviations)—values display as plain numbers.
- No click handlers or interactivity—purely display component.

## Ask before building if:

- Custom formatting is needed (e.g., "1.2K", "$1,234")—format values before passing to component.
- Counts should trigger actions or navigation—add wrapper component with click handlers.
- Trend indicators or sparklines needed—extend component or use custom layout.

## Accessibility floor

- Count labels are announced (from i18n keys).
- Values are numeric and announced as numbers.
- Loading state is clear (skeleton animation).

## Examples

### Basic count summary display

```tsx
import { CountSection } from "@/standalones/components";

export function HierarchyDashboard() {
  const [isLoading, setIsLoading] = useState(true);
  const [counts, setCounts] = useState([]);

  useEffect(() => {
    // Fetch counts
    async function fetchCounts() {
      const response = await api.getHierarchyCounts();
      setCounts([
        { translationKey: "dashboard.orgs", value: response.orgCount },
        {
          translationKey: "dashboard.portfolios",
          value: response.portfolioCount,
        },
        { translationKey: "dashboard.sites", value: response.siteCount },
      ]);
      setIsLoading(false);
    }
    fetchCounts();
  }, []);

  return <CountSection isLoading={isLoading} counts={counts} />;
}
```

### With Tanstack Query

```tsx
import { useQuery } from "@tanstack/react-query";
import { CountSection } from "@/standalones/components";

export function ConnectionStats() {
  const { data, isLoading } = useQuery({
    queryKey: ["connection-stats"],
    queryFn: async () => {
      const res = await fetch("/api/connections/stats");
      return res.json();
    },
  });

  const counts = [
    { translationKey: "stats.active", value: data?.active ?? 0 },
    { translationKey: "stats.idle", value: data?.idle ?? 0 },
    { translationKey: "stats.failed", value: data?.failed ?? 0 },
  ];

  return <CountSection isLoading={isLoading} counts={counts} />;
}
```

### Integration with page header

```tsx
import { TitleBar } from "@neeve/dls";
import { CountSection } from "@/standalones/components";

export function NodesPage() {
  const { data, isLoading } = useNodesOverview();

  return (
    <>
      <TitleBar title="Nodes" subtitle="Manage your infrastructure" />
      <CountSection isLoading={isLoading} counts={data?.counts ?? []} />
      {/* Rest of page */}
    </>
  );
}
```
