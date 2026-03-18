# 🟡 L200 Demo — From SQL to API to App in Minutes

> **Level**: L200 — Developers & Architects  
> **Time**: 7–10 minutes  
> **Risk**: Low  
> **Impact**: Very High for developers

## 🎯 Goal

Show how **modern apps** are built *on top of* modern databases — in minutes, without writing backend code.

## 🗣️ Talk Track

> "We didn't replace SQL with a service —  
> we **turned SQL into a service**."

## 📋 Prerequisites

| Requirement | Notes |
|---|---|
| Azure SQL Database | Same `TechDayDemo` DB from L100 |
| Data API Builder CLI | `npm install -g @azure/data-api-builder` or `dotnet tool install -g Microsoft.DataApiBuilder` |
| curl / Postman / browser | For calling the API |
| SSMS / Azure Data Studio | For the bonus SQL section |

## 🔑 One-time environment variable

```bash
export DATABASE_CONNECTION_STRING="Server=<server>.database.windows.net;Database=TechDayDemo;Authentication=Active Directory Default;"
```

## 🚀 Demo Steps

### Step 1 — Setup (run once, before the session)

Run `01-setup.sql` against your `TechDayDemo` database. This creates:
- `dbo.Products` table with a JSON `Attributes` column
- `dbo.usp_GetProductsByCategory` stored procedure

### Step 2 — Walk through `dab-config.json` (2 minutes)

Open `dab-config.json` in VS Code. Point out:
- One JSON file replaces an entire backend service
- **Entities** map directly to tables and stored procedures
- **Permissions** are declarative (`anonymous:read`, `authenticated:create`)
- Both REST (`/api`) and GraphQL (`/graphql`) are enabled simultaneously

### Step 3 — Start DAB (30 seconds)

```bash
dab start --config dab-config.json
```

Watch the terminal — both endpoints appear immediately.

### Step 4 — Call the REST API (2 minutes)

Open a browser or Postman:

```
# All products
GET http://localhost:5000/api/Product

# Filter: only Laptops
GET http://localhost:5000/api/Product?$filter=category eq 'Laptop'

# Stored procedure as a REST action
GET http://localhost:5000/api/ProductsByCategory?Category=Console
```

**Say**: "No backend code. No ORM. Security still SQL-based."

### Step 5 — GraphQL query (2 minutes)

Open the GraphQL playground at `http://localhost:5000/graphql` and run:

```graphql
{
  products {
    items {
      id
      name
      category
      price
      inStock
    }
  }
}
```

**Say**: "The same config. REST *and* GraphQL. Production-ready out of the box."

### Step 6 — Bonus: JSON in SQL (optional, 2 minutes)

Switch to SSMS and run `03-bonus-sql-queries.sql`.

Show `JSON_VALUE` extracting typed properties from the `Attributes` column.

**Say**: "The database understands the document structure — not just the column."

## 💬 Key "Aha" Moments

| Moment | What to say |
|---|---|
| Config → API in 30s | "No backend code" |
| REST *and* GraphQL | "One config, two protocols" |
| Stored proc as REST action | "No ORM" |
| JSON_VALUE in filter | "SQL understands documents" |
| Permissions section | "Security still SQL-based. This is production-ready." |

## 🗺️ Slide Alignment

| Demo step | Deck slide |
|---|---|
| DAB init → API | Slide 21: Built for Developers |
| JSON column + JSON_VALUE | Slide 22: Flexible data models |
| REST + GraphQL | Slide 23: Modern API patterns |

## 🔗 Resources

- [Data API Builder documentation](https://learn.microsoft.com/azure/data-api-builder/overview)
- [DAB CLI reference](https://learn.microsoft.com/azure/data-api-builder/reference-command-line-interface)
- [JSON in SQL Server](https://learn.microsoft.com/sql/relational-databases/json/json-data-sql-server)
- [DAB on GitHub](https://github.com/Azure/data-api-builder)
