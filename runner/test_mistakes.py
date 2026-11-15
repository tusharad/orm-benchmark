#!/usr/bin/env python3
"""
Automated Test Runner for the Deliberate Mistake Suite
Compiles deliberate failure cases E01..E10 for an ORM,
measures error line count, tests for internal type leakage,
and returns structured scorecard metrics.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

LEAKAGE_KEYWORDS_HASKELL = [
    "Unpackspec", "Default", "QGenExpr", "QExpr", "SqlVal",
    "Rel8able", "TableSchema", "PersistEntity", "PersistField",
    "BackendKey", "SqlBackend", "SqlType", "ToSql", "FromSql",
    "TableField", "Col", "Rel8.Expr", "BeamSqlBackend", "HasSqlValueSyntax"
]

LEAKAGE_KEYWORDS_TYPESCRIPT = [
    "PgColumn", "SelectedFields", "BuildQueryResult", "TableRelationalConfig",
    "InferModel", "DrizzleTypeError", "ExtractTablesWithRelations"
]

LEAKAGE_KEYWORDS_RUST = [
    "diesel::expression::Expression", "diesel::query_builder::QueryFragment",
    "sea_orm::entity::ColumnDef", "FromQueryResult"
]

LEAKAGE_KEYWORDS_ELIXIR = [
    "Ecto.Query.Builder", "Ecto.Queryable.impl_for", "Ecto.Schema.Metadata"
]

LEAKAGE_KEYWORDS_CSHARP = [
    "Microsoft.EntityFrameworkCore.Query.Internal", "IQueryCompiler",
    "QueryCompilationContext", "ShapedQueryCompilingExpressionVisitor"
]

LEAKAGE_KEYWORDS_GO = [
    "gorm.Statement", "schema.Schema", "callbacks.processor", "clause.Expression"
]

LEAKAGE_KEYWORDS_JAVA = [
    "org.hibernate.query.sqm.tree", "org.hibernate.query.spi",
    "org.hibernate.internal", "org.hibernate.metamodel.mapping"
]

LEAKAGE_KEYWORDS_RUBY = [
    "Arel::Nodes", "ActiveRecord::ConnectionAdapters", "ActiveRecord::Relation"
]

LEAKAGE_KEYWORDS_PYTHON = [
    "sqlalchemy.sql.elements", "sqlalchemy.orm.attributes",
    "sqlalchemy.sql.selectable", "ClauseElement", "InstrumentedAttribute"
]

def analyze_diagnostic(diagnostic_text: str, language: str = "haskell"):
    # Strip empty lines
    lines = [l for l in diagnostic_text.splitlines() if l.strip()]
    line_count = len(lines)
    
    keywords = LEAKAGE_KEYWORDS_HASKELL
    if language.lower() in ["ts", "typescript"]:
        keywords = LEAKAGE_KEYWORDS_TYPESCRIPT
    elif language.lower() in ["rust"]:
        keywords = LEAKAGE_KEYWORDS_RUST
    elif language.lower() in ["elixir", "ex"]:
        keywords = LEAKAGE_KEYWORDS_ELIXIR
    elif language.lower() in ["csharp", "cs", "dotnet"]:
        keywords = LEAKAGE_KEYWORDS_CSHARP
    elif language.lower() in ["go", "golang"]:
        keywords = LEAKAGE_KEYWORDS_GO
    elif language.lower() in ["java"]:
        keywords = LEAKAGE_KEYWORDS_JAVA
    elif language.lower() in ["ruby", "rb", "rails"]:
        keywords = LEAKAGE_KEYWORDS_RUBY
    elif language.lower() in ["python", "py", "sqlalchemy"]:
        keywords = LEAKAGE_KEYWORDS_PYTHON
        
    leaked_terms = []
    for kw in keywords:
        if re.search(r'\b' + re.escape(kw) + r'\b', diagnostic_text):
            leaked_terms.append(kw)
            
    zero_leakage = (len(leaked_terms) == 0)
    return {
        "line_count": line_count,
        "zero_leakage": zero_leakage,
        "leaked_terms": leaked_terms,
        "preview": "\n".join(lines[:10])
    }

def main():
    parser = argparse.ArgumentParser(description="Test Deliberate Mistakes Suite")
    parser.add_argument("--dir", type=Path, required=True, help="Directory containing E01..E10 mistake files")
    parser.add_argument("--cmd", type=str, required=True, help="Compile command (e.g., 'ghc -fno-code {file}' or 'tsc --noEmit')")
    parser.add_argument("--language", type=str, default="haskell", help="Target language (haskell, typescript, rust)")
    
    args = parser.parse_args()
    mistake_files = sorted(list(args.dir.glob("E*.*")))
    
    if not mistake_files:
        print(f"No E01..E10 files found in {args.dir}", file=sys.stderr)
        sys.exit(1)
        
    print(f"Testing {len(mistake_files)} Deliberate Mistakes in {args.dir}...")
    for mf in mistake_files:
        cmd_str = args.cmd.replace("{file}", str(mf))
        proc = subprocess.run(cmd_str, shell=True, capture_output=True, text=True)
        diag = proc.stderr if proc.stderr else proc.stdout
        result = analyze_diagnostic(diag, args.language)
        
        status = "PASS (Zero Leakage)" if result["zero_leakage"] else f"FAIL (Leaked: {', '.join(result['leaked_terms'])})"
        print(f"[{mf.stem}] {result['line_count']} lines | {status}")

if __name__ == "__main__":
    main()
