#!/usr/bin/env bash
FILE="$1"
BN="$(basename "$FILE")"
docker run --rm -v /Users/tusharadhatrao/work/github_repo/orms/efcore/bench:/app -w /app mcr.microsoft.com/dotnet/sdk:8.0-alpine dotnet build /app/test/deliberate-mistakes/MistakeRunner.csproj "/p:MistakeFile=/app/test/deliberate-mistakes/$BN" -v:q --nologo
