#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

markdown_dir="${1:-docs/api}"
vimdoc_dir="${2:-doc}"

if [[ "$markdown_dir" != "docs/api" || "$vimdoc_dir" != "doc" ]]; then
	echo "The generated API paths must be docs/api and doc" >&2
	exit 1
fi

panvimdoc="${PANVIMDOC:-}"
if [[ -z "$panvimdoc" ]]; then
	panvimdoc="$(command -v panvimdoc.sh || true)"
fi
if [[ -z "$panvimdoc" || ! -x "$panvimdoc" ]]; then
	echo "panvimdoc.sh is required; set PANVIMDOC to its path" >&2
	exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

while IFS= read -r -d '' markdown_file; do
	relative_path="${markdown_file#"$markdown_dir"/}"
	stem="${relative_path%.md}"
	if [[ "$relative_path" == "index.md" ]]; then
		vimdoc_name="nvim-mybatis-api"
	else
		vimdoc_name="nvim-mybatis-api-${stem//\//-}"
	fi

	"$panvimdoc" \
		--description "$vimdoc_name" \
		--vim-version 'NVIM v0.8+' \
		--project-name "$vimdoc_name" \
		--input-file "$markdown_file"
done < <(find "$markdown_dir" -type f -name '*.md' -print0 | sort -z)
