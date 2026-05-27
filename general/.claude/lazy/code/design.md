# Design

**Load this when:** planning a code implementation, designing architecture, choosing file or module layout, deciding where logic should live, or modifying / reading / updating / deleting code that crosses multiple files. Precedents for separation of responsibilities and where work belongs.

## Priority order: works → understandable → optimized

Get it working. Make it readable. Then think about optimization. Reverse this order and you build something fast and broken, or clever and unmaintainable. Readability is the multiplier; the rest is downstream.

## Simple beats smart

Code should be pleasant to read, easy to understand, and easy to follow. SOLID, DRY, KISS are guidelines, not commandments: apply them when they make the next reader's life easier, skip them when they don't.

A "smart" abstraction that future readers (including you in three months) have to mentally decompress is worse than the obvious version that just works. When you catch yourself reaching for an elegant pattern, ask whether the obvious version would have been faster to read.

## File length

A file pushing several hundred lines is a smell. Thousands is a problem. Split by responsibility before the file becomes a navigation tax.

The first split is usually the cleanest: lead file plus a sibling `helpers.go` (or topical file). Subsequent splits go topical (`orders.go` → `orders.go` + `orders_repository.go` + `orders_renderer.go`). If you find yourself scrolling to locate functions inside the same file, the file is too long.

## Push "fetch everything" loops down into the data layer

A higher-layer function (a service, a controller, a report generator) should describe its own work, not the mechanics of draining a paginated API. Push the loop into the client / repository / data layer where the API contract lives.

**Don't (in `report.go`):**

```go
func GenerateMonthlyReport(api *Client) (Report, error) {
    var orders []Order
    page := 1
    for {
        batch, next, err := api.ListOrders(page)
        if err != nil { return Report{}, err }
        orders = append(orders, batch...)
        if next == 0 { break }
        page = next
    }
    return summarize(orders), nil
}
```

**Do (in `client/orders.go`):**

```go
func (c *Client) AllOrders() ([]Order, error) {
    var orders []Order
    page := 1
    for {
        batch, next, err := c.ListOrders(page)
        if err != nil { return nil, err }
        orders = append(orders, batch...)
        if next == 0 { break }
        page = next
    }
    return orders, nil
}
```

`report.go` becomes `orders, err := api.AllOrders(); return summarize(orders), err`. The loop is in the layer that owns the API contract; the report file describes the report.

## URL/endpoint constants live in their own file

Put all URL and endpoint constants in a dedicated `urls.go` (or `endpoints.go`) file in the package that owns the HTTP calls. Each constant gets a one-line comment above it with the link to the vendor docs for that endpoint — this is a justified comment exception (the link is the non-obvious WHY, not a restatement of the code):

```go
// https://developer.example.com/api/users
const usersEndpoint = "https://api.example.com/v1/users"
```

This file is the first place to look when auditing what a client calls or finding the spec for a given call.

## No re-export aliases

Don't define `type Foo = subpkg.Foo` in a wrapper package just so callers avoid importing the sub-package. Have callers import the sub-package directly — unless the alias significantly improves readability or structure.

## Keep responsibilities separate

If a function does two things ("fetch + decide"), split it. A resource/feature file shouldn't define its own client function; a config file shouldn't carry business logic; a UI component shouldn't talk directly to the database. Push API loops into the client layer, push small helpers into a sibling `helpers.go` (or topical file), and keep the lead file thin.

## Feature files stay just the framework surface

Small support functions (format a header, build a struct, cache an intermediate value) live in a sibling `helpers.go` (or a topical file), not in the feature file. The lead file should read as just the framework contract.

**Don't (in `orders.go`):**

```go
type OrderHandler struct { ... }

func (h *OrderHandler) List(w http.ResponseWriter, r *http.Request)   { ... }
func (h *OrderHandler) Create(w http.ResponseWriter, r *http.Request) { ... }

func formatOrderHeader(o Order) string {
    return fmt.Sprintf("Order #%d - %s", o.ID, o.PlacedAt.Format(time.DateOnly))
}
```

**Do:**

`orders.go` keeps only the handler and its `List` / `Create` methods. `formatOrderHeader` moves into `helpers.go` (or `formatters.go`). Every feature file ends up the same shape; helpers cluster where future contributors will look for them.
