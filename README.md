# Microsoft Tech Day — Innovate with Azure AI Optimized Databases

This repository contains everything you need to deliver the **"Innovate with Azure AI Optimized Databases"** session, including a progressive **L100 → L200 → L300 demo progression** that maps directly to the deck narrative.

---

## 🎯 Demo Strategy

The demos follow the **"Modern Data, Modern Apps"** story arc:

| Level | Theme | Audience | Time |
|---|---|---|---|
| 🟢 L100 | AI inside SQL — no app rewrite | Everyone | 5–7 min |
| 🟡 L200 | From SQL to API to App in minutes | Developers & Architects | 7–10 min |
| 🔵 L300 | End-to-end RAG app inside the database | Architects & Senior Devs | 10–12 min |

> **If you only have time for 2 demos**, do **L100 + L300**.  
> That gives you immediate accessibility + strong differentiation.

---

## 📁 Repository Structure

```
demos/
├── L100-Vector-Search/         🟢 Semantic search on SQL data
│   ├── 01-setup.sql            Create table, credential, sample data
│   ├── 02-generate-embeddings.sql   Vectorise data via Azure OpenAI
│   ├── 03-demo.sql             Live demo: LIKE vs vector search
│   └── README.md               Step-by-step guide + talk track
│
├── L200-Data-API-Builder/      🟡 SQL → REST/GraphQL API
│   ├── 01-setup.sql            Products table + stored procedure
│   ├── dab-config.json         Data API Builder configuration
│   ├── 02-demo-commands.sh     CLI commands for live demo
│   ├── 03-bonus-sql-queries.sql   JSON column queries
│   └── README.md               Step-by-step guide + talk track
│
└── L300-RAG-In-SQL/            🔵 Full RAG pipeline inside SQL
    ├── 01-setup.sql            Knowledge base + chat history tables
    ├── 02-generate-embeddings.sql   Vectorise documents
    ├── 03-rag-demo.sql         RAG stored procedure + demo queries
    ├── architecture.md         ASCII architecture diagram
    └── README.md               Step-by-step guide + talk track
```

---

## 🟢 L100 — AI Inside SQL: No App Rewrite

**Goal**: Show that existing SQL skills + existing data can immediately participate in AI scenarios.

```sql
-- Traditional search ❌ — misses synonyms
SELECT * FROM SupportTickets WHERE TicketText LIKE '%slow%';

-- Semantic search ✅ — understands meaning
SELECT TOP 5 TicketId, TicketText,
    ROUND(1 - VECTOR_DISTANCE('cosine', Embedding, @query_vector), 4) AS Score
FROM SupportTickets
ORDER BY VECTOR_DISTANCE('cosine', Embedding, @query_vector);
```

**Talk track**: *"This is not an AI app. This is a SQL query — but now it understands meaning, not just keywords."*

📂 [L100 Demo Guide →](demos/L100-Vector-Search/README.md)

---

## 🟡 L200 — From SQL to API to App in Minutes

**Goal**: Show how modern apps are built on top of modern databases — fast, without writing backend code.

```bash
# Start REST + GraphQL APIs from one config file
dab start --config dab-config.json

# Instant API — no backend code written
curl http://localhost:5000/api/Product
curl "http://localhost:5000/api/Product?\$filter=category eq 'Laptop'"
```

**Talk track**: *"We didn't replace SQL with a service — we turned SQL into a service."*

📂 [L200 Demo Guide →](demos/L200-Data-API-Builder/README.md)

---

## 🔵 L300 — End-to-End RAG App: SQL Orchestrates the AI

**Goal**: Show a real AI architecture — without bolting systems together.

```sql
-- One stored procedure call = full RAG pipeline
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'My application is slow after login. What should I do?';
-- Returns: grounded answer + source documents with relevance scores
```

Inside `usp_RAGQuery`, SQL:
1. Embeds the question (calls Azure OpenAI)
2. Runs vector search against the knowledge base
3. Builds context from top-K documents
4. Calls the LLM with grounded context
5. Writes to the audit/chat history table
6. Returns the answer + source evidence

**Talk track**: *"This is not a chatbot querying SQL. This is SQL orchestrating the AI."*

📂 [L300 Demo Guide →](demos/L300-RAG-In-SQL/README.md)  
📐 [Architecture Diagram →](demos/L300-RAG-In-SQL/architecture.md)

---

## 🧩 Deck Alignment

| Deck Section | Demo |
|---|---|
| AI Built-in / Vector Search (slides 13–16) | L100 |
| Built for Developers (slide 21) | L200 |
| Agentic RAG / AI Apps (slides 15–18) | L300 |

---

## ⚡ Quick Setup

### Prerequisites

- Azure SQL Database (General Purpose or higher)
- Azure OpenAI resource with:
  - An embedding model deployed (e.g. `text-embedding-ada-002`)
  - A chat model deployed (e.g. `gpt-4o`) — for L300 only
- [Data API Builder CLI](https://learn.microsoft.com/azure/data-api-builder/get-started/get-started-azure-sql) — for L200 only

### Setup order

```
1. Create TechDayDemo database in Azure SQL
2. Run L100/01-setup.sql        (creates SupportTickets + credential)
3. Run L100/02-generate-embeddings.sql
4. Run L200/01-setup.sql        (creates Products table)
5. Run L300/01-setup.sql        (creates KnowledgeBase + ChatHistory)
6. Run L300/02-generate-embeddings.sql
```

All demos share the same `TechDayDemo` database.

---

## 🔗 Key Resources

| Resource | Link |
|---|---|
| Azure SQL Vector Search | [docs.microsoft.com](https://learn.microsoft.com/azure/azure-sql/database/ai-artificial-intelligence-intelligent-applications) |
| VECTOR data type | [learn.microsoft.com](https://learn.microsoft.com/sql/t-sql/data-types/vector-data-type) |
| VECTOR_DISTANCE function | [learn.microsoft.com](https://learn.microsoft.com/sql/t-sql/functions/vector-distance-transact-sql) |
| sp_invoke_external_rest_endpoint | [learn.microsoft.com](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql) |
| Data API Builder | [learn.microsoft.com](https://learn.microsoft.com/azure/data-api-builder/overview) |
| Row Level Security | [learn.microsoft.com](https://learn.microsoft.com/sql/relational-databases/security/row-level-security) |
| SQL Ledger | [learn.microsoft.com](https://learn.microsoft.com/sql/relational-databases/security/ledger/ledger-overview) |
