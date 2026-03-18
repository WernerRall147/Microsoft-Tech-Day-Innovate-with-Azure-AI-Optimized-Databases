# RAG in Azure SQL — Architecture

## Overview

This diagram shows how all RAG components are **unified inside Azure SQL**,
eliminating the need for a separate orchestration layer, vector database, or
custom middleware.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          CLIENT / APPLICATION                            │
│                  (Web app, chatbot, API, Power App…)                     │
└──────────────────────────┬───────────────────────────────────────────────┘
                           │  Single stored-procedure call
                           │  EXEC usp_RAGQuery @UserQuestion = '...'
                           ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         AZURE SQL DATABASE                               │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  usp_RAGQuery (T-SQL stored procedure)                          │    │
│  │                                                                  │    │
│  │  ① Embed question   ──► sp_invoke_external_rest_endpoint        │    │
│  │       │                      │                                   │    │
│  │       │                      ▼                                   │    │
│  │       │             ┌────────────────┐                          │    │
│  │       │             │  Azure OpenAI  │                          │    │
│  │       │             │  Embedding API │                          │    │
│  │       │             └───────┬────────┘                          │    │
│  │       ▼                     │ VECTOR(1536)                      │    │
│  │  ② Vector search  ◄─────────┘                                   │    │
│  │       │  VECTOR_DISTANCE('cosine', …)                           │    │
│  │       │  against dbo.KnowledgeBase                              │    │
│  │       ▼                                                          │    │
│  │  ③ Build context string (Top-K documents)                       │    │
│  │       │                                                          │    │
│  │       ▼                                                          │    │
│  │  ④ Call LLM         ──► sp_invoke_external_rest_endpoint        │    │
│  │       │                      │                                   │    │
│  │       │                      ▼                                   │    │
│  │       │             ┌────────────────┐                          │    │
│  │       │             │  Azure OpenAI  │                          │    │
│  │       │             │  Chat API      │                          │    │
│  │       │             └───────┬────────┘                          │    │
│  │       ▼                     │ Grounded answer                   │    │
│  │  ⑤ Write to ChatHistory ◄───┘                                   │    │
│  │  ⑥ Return answer + source rows                                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │  KnowledgeBase   │  │   ChatHistory     │  │  SupportTickets  │      │
│  │  VECTOR(1536)    │  │  (audit trail)    │  │  VECTOR(1536)    │      │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘      │
│                                                                          │
│  Optional security layers:                                               │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │  Row Level Security (dept-scoped RAG context)                │       │
│  │  SQL Ledger (tamper-evident chat history)                    │       │
│  │  Always Encrypted (encrypt knowledge base at rest)           │       │
│  └──────────────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────┘
```

## Why "SQL orchestrates the AI" matters

| Traditional approach | This approach |
|---|---|
| Python / LangChain orchestrator | T-SQL stored procedure |
| Separate vector database (Pinecone, Qdrant…) | `VECTOR` column in Azure SQL |
| Custom embedding pipeline | `sp_invoke_external_rest_endpoint` |
| External audit log | `dbo.ChatHistory` table |
| Separate RLS service | Native SQL Row Level Security |
| Multiple network hops | One database call |

## Security layers available at no extra cost

1. **Row Level Security** — automatically scopes which documents each user
   can use as RAG context.  A Finance user cannot receive context from IT
   documents, and vice-versa.

2. **SQL Ledger** — makes the `ChatHistory` table tamper-evident.  Every AI
   interaction is cryptographically verifiable.

3. **Always Encrypted / TDE** — knowledge base content is encrypted at rest
   and in transit.

4. **Microsoft Entra ID Authentication** — the application never holds a
   username or password; it uses managed identity.

## Switching models (local vs Azure)

The `@chat_endpoint` and `@embed_endpoint` variables are just URL strings.
To switch from Azure OpenAI to:

- **Ollama (local)** — point to `http://localhost:11434/v1/...`
- **GitHub Models** — point to `https://models.inference.ai.azure.com/...`
- **Another Azure region** — change the host name only

No application code changes required — the SQL procedure stays identical.
