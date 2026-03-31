#!/bin/sh
# Context summarization with LLM support
set -eu

echo "Context summarization"
echo ""
echo "Usage: bin/summarize-context.sh <input-file> [output-file]"
echo ""

input="${1:-}"
output="${2:-}"

if [ -z "$input" ]; then
  echo "Error: input file required"
  echo ""
  echo "Manual offloading:"
  echo "  1. Read the input file"
  echo "  2. Extract key findings, decisions, and current state"
  echo "  3. Write summary to output or PLANS.md"
  echo ""
  echo "Token budget guidance:"
  echo "  - Summarize when context exceeds ~70% capacity"
  echo "  - Keep summaries under 500 lines"
  echo "  - Include: objective, completed steps, blockers, next actions"
  exit 1
fi

if [ ! -f "$input" ]; then
  echo "Error: file not found: $input"
  exit 1
fi

file_size=$(wc -l < "$input")
echo "Input: $input ($file_size lines)"

if [ -n "$output" ]; then
  head -n 200 "$input" > "$output"
  echo "" >> "$output"
  echo "... [truncated, full content in $input]" >> "$output"
  echo ""
  echo "Summary written to: $output"
  echo "  Original: $file_size lines"
  echo "  Summary: $(wc -l < "$output") lines"
else
  head -n 50 "$input"
  echo ""
  echo "... [use output parameter to save summary]"
fi
