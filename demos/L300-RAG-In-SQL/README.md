# 🔵 L300 Demo — End-to-End RAG App: SQL Orchestrates the AI

> **Level**: L300 — Architects & Senior Developers  
> **Time**: 10–12 minutes  
> **Risk**: Medium (have screenshots as backup)  
> **Impact**: Massive

## 🎯 Goal

Show a **real AI architecture** — without bolting external systems together.  
Demonstrate that Azure SQL can *orchestrate* AI, not just store data for it.

## 🗣️ Talk Track

> "This is not a chatbot querying SQL.  
> This is SQL **orchestrating** the AI."

## 📋 Prerequisites

| Requirement | Notes |
|---|---|
| Azure SQL Database | General Purpose or higher with `sp_invoke_external_rest_endpoint` enabled |
| Azure OpenAI resource | Deploy an embedding model **and** a chat model (e.g. `gpt-4o`) |
| Database scoped credential | Created in L100 setup |
| SSMS / Azure Data Studio | Any recent version |

## 🚀 Demo Steps

### Step 0 — Open architecture diagram (1 minute)

Open `architecture.md` (or paste it into a Markdown renderer). Walk through the diagram:

- Every RAG step runs **inside** a single stored procedure call
- No Python orchestrator, no separate vector database, no custom middleware
- The client makes **one database call** — SQL does everything else

### Step 1 — Setup (run once, before the session)

Run `01-setup.sql` — creates:
- `dbo.KnowledgeBase` — documents with `VECTOR(1536)` column
- `dbo.ChatHistory` — tamper-evident audit trail

### Step 2 — Generate embeddings (run once, before the session)

Run `02-generate-embeddings.sql` — vectorises each document via Azure OpenAI.

Same pattern as L100 but against the knowledge base.

### Step 3 — Live demo: walk through the stored procedure (5 minutes)

Open `03-rag-demo.sql`. Scroll to the `CREATE PROCEDURE usp_RAGQuery` block.

Walk through each step **slowly**, pointing to the SQL:

| Step | SQL | Talk track |
|---|---|---|
| ① Embed question | `sp_invoke_external_rest_endpoint` → embedding model | "SQL calls Azure OpenAI — no Python" |
| ② Vector search | `VECTOR_DISTANCE('cosine', Embedding, @question_vector)` | "Similarity search in the same engine that holds the data" |
| ③ Build context | `SELECT TOP (@TopK) ... ORDER BY Distance` | "The database retrieves exactly the right documents" |
| ④ Call LLM | `sp_invoke_external_rest_endpoint` → chat model | "SQL calls the LLM — still no Python" |
| ⑤ Audit | `INSERT INTO dbo.ChatHistory` | "Every interaction is logged with source documents" |
| ⑥ Return | `SELECT @answer; SELECT source rows` | "The app gets a grounded answer *and* the evidence" |

### Step 4 — Run the demo queries (3 minutes)

Execute the three demo queries one at a time:

```sql
-- Performance question → should cite "Slow Application Performance" doc
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'My application is really slow after I log in. What should I do?';

-- Billing question → should cite "Refund and Billing Policy" doc
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'I was charged twice this month. How do I get a refund?';

-- Out-of-scope → should gracefully decline
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'What is the weather forecast for Seattle tomorrow?';
```

Point out:
- The answer **cites the source document**
- The second result set shows **which documents were used** with relevance scores
- The out-of-scope question is gracefully rejected — no hallucination

### Step 5 — Show the audit trail (1 minute)

```sql
SELECT ConversationId, Role, LEFT(Content, 120), SourceDocIds, CreatedAt
FROM dbo.ChatHistory
ORDER BY MessageId DESC;
```

**Say**: "Every AI conversation is in SQL. Queryable, auditable, reportable — with Power BI or any BI tool."

### Step 6 — Optional advanced flex (if time allows)

Scroll to the commented RLS section at the bottom of `03-rag-demo.sql`. Walk through the concept:

> "With three lines of SQL, the RAG search is automatically scoped to the user's  
> department. Finance users get Finance docs. IT users get IT docs.  
> No application change required."

## 💬 Key Points to Highlight

| Point | What it means |
|---|---|
| One stored procedure call | Zero orchestration middleware |
| VECTOR_DISTANCE in T-SQL | No separate vector database |
| sp_invoke_external_rest_endpoint | SQL calls the LLM directly |
| dbo.ChatHistory | Built-in audit trail |
| Row Level Security on KnowledgeBase | Automatic context scoping |
| Switch @chat_endpoint variable | Model portability — local or cloud |

## 🗺️ Slide Alignment

| Demo step | Deck slide |
|---|---|
| Architecture overview | Slides 15–18: RAG, Vector Search, T-SQL + AI |
| usp_RAGQuery walkthrough | Slide 16: AI orchestration inside the database |
| RLS on RAG context | Slide 19: Security is built-in, not bolted on |
| ChatHistory audit trail | Slide 20: Compliance and auditability |

## 📸 Backup Screenshots

If live execution is not possible, prepare screenshots of:
1. The stored procedure body in SSMS
2. The query result showing `Answer` + `RelevanceScore` columns
3. The `ChatHistory` table with populated `SourceDocIds`

## 🔗 Resources

- [Azure SQL Vector Search (docs)](https://learn.microsoft.com/azure/azure-sql/database/ai-artificial-intelligence-intelligent-applications)
- [sp_invoke_external_rest_endpoint](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql)
- [Row Level Security](https://learn.microsoft.com/sql/relational-databases/security/row-level-security)
- [SQL Ledger](https://learn.microsoft.com/sql/relational-databases/security/ledger/ledger-overview)
- [Azure OpenAI models](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)
