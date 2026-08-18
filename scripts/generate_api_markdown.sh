#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

output_dir="${1:-docs/api}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-mybatis-emmylua.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="$work_dir/source"
# Keep generated pages limited to the plugin entry point, user-facing
# integrations, important navigation/generation APIs, and public types.
# Every other Lua file is intentionally ignored by this generator.
api_sources=(
	"lua/nvim-mybatis/init.lua"
	"lua/nvim-mybatis/config.lua"
	"lua/nvim-mybatis/commands.lua"
	"lua/nvim-mybatis/navigator/init.lua"
	"lua/nvim-mybatis/actions/generator.lua"
	"lua/nvim-mybatis/completion/blink.lua"
	"lua/nvim-mybatis/types.lua"
)

if [[ "$output_dir" != "docs/api" ]]; then
	echo "The generated API directory must be docs/api" >&2
	exit 1
fi
command -v perl >/dev/null

for source in "${api_sources[@]}"; do
	destination="$source_root/$source"
	mkdir -p "$(dirname "$destination")"
	ln -s "$repo_root/$source" "$destination"
done

emmylua_doc_cli "$source_root" \
	--output-format markdown \
	--output "$work_dir"

rm -rf -- "$output_dir"
mkdir -p "$(dirname "$output_dir")"
mv "$work_dir/docs" "$output_dir"
LC_ALL=C find "$output_dir" -type f -name '*.md' -exec perl -0pi -e 's/\n+\z/\n/' {} +
cat >> "$output_dir/index.md" <<'EOF'

Generated from Lua annotations by [EmmyLua Analyzer Rust](https://github.com/emmyluals/emmylua-analyzer-rust).
EOF
