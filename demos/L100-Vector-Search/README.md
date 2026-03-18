# 🟢 L100 Demo — AI Inside SQL: No App Rewrite Required

> **Level**: L100 — Everyone  
> **Time**: 5–7 minutes  
> **Risk**: Very Low  
> **Impact**: High

## 🎯 Goal

Show that **existing SQL skills + existing data** can immediately participate in AI scenarios — without touching application code, without external vector databases, and without leaving T-SQL.

## 🗣️ Talk Track

> "This is not an AI app.  
> This is a SQL query — but now it understands *meaning*, not just keywords."

## 📋 Prerequisites

| Requirement | Notes |
|---|---|
| Azure SQL Database | General Purpose tier or higher; or SQL Server 2022 CU9+ with vector preview |
| Azure OpenAI resource | Deploy `text-embedding-ada-002` or `text-embedding-3-small` |
| SSMS / Azure Data Studio | Any recent version |
| Database master key | Required for scoped credentials |

## 🚀 Demo Steps

### Step 1 — Setup (run once, before the session)

Open `01-setup.sql` in SSMS or Azure Data Studio and execute it.

```
Edit these placeholders first:
  <AOAI_KEY>       → your Azure OpenAI API key
  <AOAI_ENDPOINT>  → e.g. myoai
```

This will:
- Create the `SupportTickets` table with a `VECTOR(1536)` column
- Insert 10 realistic support tickets
- Create a database scoped credential for Azure OpenAI

### Step 2 — Generate embeddings (run once, before the session)

Open `02-generate-embeddings.sql` and execute it.

```
Edit these placeholders first:
  <AOAI_ENDPOINT>    → e.g. myoai
  <DEPLOYMENT_NAME>  → e.g. text-embedding-ada-002
```

This calls Azure OpenAI for each ticket and stores the embedding vector in SQL.

### Step 3 — Live demo

Open `03-demo.sql`. Walk through both sections live:

#### Part A — Traditional LIKE search ❌

Run the `LIKE` query. Point out:
- It finds tickets with the exact words "slow", "performance", "login"
- It **misses** tickets that say "grinds to a halt" or "unresponsive"

#### Part B — Semantic vector search ✅

Run the vector search. Point out:
- **"grinds to a halt"** is ranked highly — same *meaning*, different *words*
- **"lags badly"** surfaces too — the model understands context
- Still plain T-SQL — no Python, no vector DB, no app rewrite needed

## 💬 Key Points to Highlight

1. ✅ No Python required
2. ✅ No external vector database
3. ✅ Still T-SQL — any DBA can read and maintain it
4. ✅ Security, permissions, and auditing work exactly as before
5. ✅ Existing indexes and tooling unchanged

## 🗺️ Slide Alignment

| Demo step | Deck slide |
|---|---|
| LIKE vs. vector search | Slides 13–16: AI Built-in, RAG, Vector Search |
| sp_invoke_external_rest_endpoint | Slide 17: T-SQL + AI integration |

## 🔗 Resources

- [Azure SQL — Vector Search (docs)](https://learn.microsoft.com/azure/azure-sql/database/ai-artificial-intelligence-intelligent-applications?view=azuresql)
- [VECTOR data type](https://learn.microsoft.com/sql/t-sql/data-types/vector-data-type)
- [VECTOR_DISTANCE function](https://learn.microsoft.com/sql/t-sql/functions/vector-distance-transact-sql)
- [sp_invoke_external_rest_endpoint](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql)
