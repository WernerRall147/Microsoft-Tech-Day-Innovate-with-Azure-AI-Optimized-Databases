#!/usr/bin/env bash
# =============================================================================
# L200 Demo: Data API Builder — CLI commands for live demo
# =============================================================================
# Prerequisites:
#   npm install -g @azure/data-api-builder   (or use the .NET tool)
#   dotnet tool install -g Microsoft.DataApiBuilder
#
# Set your connection string once:
#   export DATABASE_CONNECTION_STRING="Server=<your-server>.database.windows.net;Database=TechDayDemo;Authentication=Active Directory Default;"
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# STEP 1 — Show DAB version (proves it is a standard CLI tool)
# ---------------------------------------------------------------------------
echo "=== DAB version ==="
dab --version

# ---------------------------------------------------------------------------
# STEP 2 — (Optional) Regenerate config from scratch to show the init flow
#          Skip in demos where time is tight — use the pre-built dab-config.json
# ---------------------------------------------------------------------------
# dab init \
#     --database-type "mssql" \
#     --connection-string "@env('DATABASE_CONNECTION_STRING')" \
#     --host-mode Development \
#     --output dab-config-generated.json
#
# dab add Product \
#     --source "dbo.Products" \
#     --permissions "anonymous:read" \
#     --config dab-config-generated.json
#
# dab add SupportTicket \
#     --source "dbo.SupportTickets" \
#     --permissions "anonymous:read" \
#     --config dab-config-generated.json

# ---------------------------------------------------------------------------
# STEP 3 — Start the API using the pre-built config
# ---------------------------------------------------------------------------
echo ""
echo "=== Starting Data API Builder ==="
echo "  REST  →  http://localhost:5000/api/Product"
echo "  GraphQL → http://localhost:5000/graphql"
echo ""

dab start --config dab-config.json

# ---------------------------------------------------------------------------
# Example API calls (open a new terminal after dab start):
#
#   # REST — list all products
#   curl http://localhost:5000/api/Product
#
#   # REST — filter by category
#   curl "http://localhost:5000/api/Product?\$filter=category eq 'Laptop'"
#
#   # REST — stored procedure (products by category)
#   curl "http://localhost:5000/api/ProductsByCategory?Category=Laptop"
#
#   # GraphQL — query with field selection
#   curl -X POST http://localhost:5000/graphql \
#     -H "Content-Type: application/json" \
#     -d '{"query":"{ products { items { id name price inStock } } }"}'
# ---------------------------------------------------------------------------
