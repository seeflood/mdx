#!/usr/bin/env bash
# ---
# This file is automatically generated from mdsh.md - DO NOT EDIT
# ---

# MIT License
#
# Copyright (c) 2017 PJ Eby
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

set -euo pipefail  # Strict mode

# some pre-defined things
export project_path=$(pwd)
mdsh-compile-if.not.exit(){ printf "my_arr=($(echo %s | tr " " "\n")) ; if test ! -e \${my_arr[2]} ;then %s fi \n" "$2" "$1"; }
mdsh-compile-background() { printf 'nohup %s & \n sleep 2s \n' "$(echo $1)"; }
mdsh:file-header(){ printf 'set \-e \n';}

# belows are mdsh code
mdsh-parse() {
	local cmd=$1 lno=0 block_start lang mdsh_block ln indent fence close_fence indent_remove
	local mdsh_fence=$'^( {0,3})(~~~+|```+) *([^`]*)$'
	while mdsh-find-block; do
		indent=${BASH_REMATCH[1]} fence=${BASH_REMATCH[2]} lang=${BASH_REMATCH[3]} mdsh_block=
		block_start=$lno close_fence="^( {0,3})$fence+ *\$" indent_remove="^${indent// / ?}"
		while ((lno++)); IFS= read -r ln && ! [[ $ln =~ $close_fence ]]; do
			! [[ $ln =~ $indent_remove ]] || ln=${ln#${BASH_REMATCH[0]}}; mdsh_block+=$ln$'\n'
		done
		lang="${lang%"${lang##*[![:space:]]}"}"; "$cmd" fenced "$lang" "$mdsh_block"
	done
}
mdsh-find-block(){
	while ((lno++)); IFS= read -r ln; do if [[ $ln =~ $mdsh_fence ]]; then return; fi; done; false
}
mdsh-source() {
	local MDSH_FOOTER='' MDSH_SOURCE
	if [[ ${1:--} != '-' ]]; then
		MDSH_SOURCE="$1"
		mdsh-parse __COMPILE__ <"$1"
	else mdsh-parse __COMPILE__
	fi
	${MDSH_FOOTER:+ printf %s "$MDSH_FOOTER"}; MDSH_FOOTER=
}
mdsh-compile() (  # <-- force subshell to prevent escape of compile-time state
	mdsh-safe-subshell mdsh-source "$@"
)
__COMPILE__() {
	[[ $1 == fenced && $fence == $'```' && ! $indent ]] || return 0  # only unindented ``` code
	local mdsh_tag=$2 mdsh_lang tag_words
	mdsh-splitwords "$2" tag_words  # check for command blocks first
	case ${tag_words[1]-} in
	'') mdsh_lang=${tag_words[0]-} ;;  # fast exit for common case
	'@'*)
		mdsh_lang=${tag_words[1]#@} ;; # language alias: fall through to function lookup
	'!'*)
		mdsh_lang=${tag_words[0]}; set -- "$3" "$2" "$block_start"; eval "${2#*!}"; return
		;;
	'+'*)
		printf 'mdsh_lang=%q; %s %q\n' "${tag_words[0]}" "${2#"${tag_words[0]}"*+}" "$3"
		return
		;;
	'|'*)
		printf 'mdsh_lang=%q; ' "${tag_words[0]}"
		echo "${2#"${tag_words[0]}"*|} <<'\`\`\`'"; printf $'%s```\n' "$3"
		return
		;;
	*)  mdsh_lang=${2//[^_[:alnum:]]/_}  # convert entire line to safe variable name
	esac
	mdsh-emit-block
}
mdsh-block() {
	local mdsh_lang=${1-${mdsh_lang-}} mdsh_block=${2-${mdsh_block-}}
	local block_start=${3-${block_start-}} mdsh_tag=${4-${mdsh_lang-}} tag_words
	mdsh-splitwords "$mdsh_tag" tag_words; mdsh-emit-block
}
mdsh-emit-block() {
	if fn-exists "mdsh-lang-$mdsh_lang"; then
		mdsh-rewrite "mdsh-lang-$mdsh_lang" "{" "} <<'\`\`\`'"; printf $'%s```\n' "$mdsh_block"
	elif fn-exists "mdsh-compile-$mdsh_lang"; then
		"mdsh-compile-$mdsh_lang" "$mdsh_block" "$mdsh_tag" "$block_start"
	else
		mdsh-misc "$mdsh_tag" "$mdsh_block"
	fi
	if fn-exists "mdsh-after-$mdsh_lang"; then
		mdsh-rewrite "mdsh-after-$mdsh_lang"
	fi
}
# split words in $1 into the array named by $2 (REPLY by default), without wildcard expansion
# shellcheck disable=SC2206  # set -f is in effect
mdsh-splitwords() {
	local f=$-; set -f;  if [[ ${2-} ]]; then eval "$2"'=($1)'; else REPLY=($1); fi
	[[ $1 == *f* ]] || set +f
}
# fn-exists: succeed if argument is a function
fn-exists() { declare -F -- "$1"; } >/dev/null
# Output body of func $1, optionally replacing the opening/closing { and } with $2 and $3
mdsh-rewrite() {
	local b='}' r; r="$(declare -f -- "$1")"; r=${r#*{ }; r=${r%\}*}; echo "${2-{}$r${3-$b}"
}
mdsh-misc()          { mdsh-data "$@"; }    # Treat unknown languages as data
mdsh-compile-()      { :; }                 # Ignore language-less blocks

mdsh-compile-mdsh()  { eval "$1"; }         # Execute `mdsh` blocks in-line
mdsh-compile-mdsh_main() { ! @is-main || eval "$1"; }

mdsh-compile-shell() { printf '%s' "$1"; }  # Copy `shell` blocks to the output
mdsh-compile-shell_main() { ! @is-main || printf '%s' "$1"; }
mdsh-data() {
	printf 'mdsh_raw_%s+=(%q)\n' "${1//[^_[:alnum:]]/_}" "$2"
}
mdsh-compile-shell_mdsh() {
	indent='' fence=$'```' __COMPILE__ fenced mdsh "$1"
}
mdsh-compile-shell_mdsh_main() {
	indent='' fence=$'```' __COMPILE__ fenced "mdsh main" "$1"
}
# Main program: check for arguments and run markdown script
mdsh-main() {
	(($#)) || mdsh-error "Usage: %s [--out FILE] [ --compile | --eval ] markdownfile [args...]" "${0##*/}"
	case "$1" in
	--) mdsh-interpret "${@:2}" ;;
	--*|-?) fn-exists "mdsh.$1" || mdsh-error "%s: unrecognized option: %s" "${0##*/}" "$1"
		"mdsh.$1" "${@:2}"
		;;
	-??*) mdsh-main "${1::2}" "-${1:2}" "${@:2}" ;;  # split '-abc' into '-a -bc' and recurse
	*)  mdsh-interpret "$@" ;;
	esac
}
# Run markdown file as main program, with $0 == $BASH_SOURCE == "" and
# MDSH_ZERO pointing to the original $0.

function mdsh-interpret() {
	printf -v cmd $'eval "$(%q --compile %q)"' "$0" "$1"
	MDSH_ZERO="$1" exec bash -c "$cmd" "" "${@:2}"
}
mdsh.--compile() {
	(($#)) || mdsh-error "Usage: %s --compile FILENAME..." "${0##*/}"
	! fn-exists mdsh:file-header || mdsh:file-header
	for REPLY; do mdsh-compile "$REPLY"; done
	! fn-exists mdsh:file-footer || mdsh:file-footer
}

mdsh.-c() { mdsh.--compile "$@"; }
mdsh.--eval() {
	{ (($# == 1)) && [[ $1 != - ]]; } ||
		mdsh-error "Usage: %s --eval FILENAME" "${0##*/}"
	mdsh.--compile "$1"
	echo $'__status=$? eval \'return $__status || exit $__status\' 2>/dev/null'
}

mdsh.-E() { mdsh.--eval "$@"; }
mdsh.--out() {
	REPLY=("$(mdsh-safe-subshell mdsh-main "${@:2}")")
	mdsh-ok && exec echo "$REPLY" >"$1"   # handle self-compiling properly
}

mdsh.-o() { mdsh.--out "$@"; }
# mdsh-error: printf args to stderr and exit w/EX_USAGE (code 64)
# shellcheck disable=SC2059  # argument is a printf format string
mdsh-error() { exit 64 "$1" "${2-}" "${@:3}"; }
mdsh.--help() {
	printf 'Usage: %s [--out FILE] [ --compile | --eval ] markdownfile [args...]\n' "${0##*/}"
	echo $'
Run and/or compile code blocks from markdownfile(s) to bash.
Use a filename of `-` to run or compile from stdin.

Options:
  -h, --help                Show this help message and exit
  -c, --compile MDFILE...   Compile MDFILE(s) to bash and output on stdout.
  -E, --eval MDFILE         Compile one file w/a shelldown-support footer line\n'
}

mdsh.-h() { mdsh.--help "$@"; }
MDSH_LOADED_MODULES=
MDSH_MODULE=

@require() {
	flatname "$1"
	if ! [[ $MDSH_LOADED_MODULES == *"<$REPLY>"* ]]; then
		MDSH_LOADED_MODULES+="<$REPLY>"; local MDSH_MODULE=$1
		if (($#<2)); then
			REPLY="@provide-$1"
			fn-exists "$REPLY" || exit 70 \
				"No @provide defined for module $1 at line $(caller)"
			"$REPLY"
		else "${@:2}"
		fi
	fi
}
@provide() {
	if (($#<2)); then exit 64 \
		"No command given for @provide at line $(caller)"
	elif flatname "$1"; ! [[ $MDSH_LOADED_MODULES == *"<$REPLY>"* ]]; then
		printf -v REPLY "%q " "${@:2}"; eval "@provide-$1(){ $REPLY; }"
	else exit 70 \
		"Module $1 already loaded; attempted redefinition at line $(caller)"
	fi
}
@is-main() { ! [[ $MDSH_MODULE ]]; }
@module() {
	@is-main || return 0
	set -- "${1:-${MDSH_SOURCE-}}"
	echo "#!/usr/bin/env bash"
	echo "# ---"
	echo "# This file is automatically generated from ${1##*/} - DO NOT EDIT"
	echo "# ---"
	echo
}
@main() {
	@is-main || return 0
	MDSH_FOOTER=$'if [[ $0 == "${BASH_SOURCE-}" ]]; then '"$1"$' "$@"; exit; fi\n'
}
@comment() (  # subshell for cd
	! [[ "${MDSH_SOURCE-}" == */* ]] || cd "${MDSH_SOURCE%/*}"
	sed -e 's/^\(.\)/# \1/; s/^$/#/;' "$@"
	echo
)
# shellcheck disable=2059
exit() {
	set -- "${1-$?}" "${@:2}"
	case $# in 0|1) : ;; 2) printf '%s\n' "$2" ;; *) printf "$2\\n" "${@:3}" ;; esac >&2
	builtin exit "$1"
}
mdsh-safe-subshell() { set -E; trap exit ERR; "$@"; }
mdsh-ok(){ return $?;}
mdsh-embed() {
	local f=$1 base=${1##*/}; local boundary="# --- EOF $base ---" contents ctr=
	[[ $f == */* && -f $f ]] || f=$(command -v "$f") || {
		echo "Can't find module $1" >&2; return 69  # EX_UNAVAILABLE
	}
	contents=$'\n'$(<"$f")$'\n'
	while [[ $contents == *$'\n'"$boundary"$'\n'* ]]; do
		((ctr++)); boundary="# --- EOF $base.$ctr ---"
	done
	printf $'{ if [[ $OSTYPE != cygwin && $OSTYPE != msys && -e /dev/fd/0 ]]; then source /dev/fd/0; else source <(cat); fi; } <<\'%s\'%s%s\n' "$boundary" "$contents" "$boundary"
}
mdsh-make() {
	[[ -f "$1" && -f "$2" && ! "$1" -nt "$2" && ! "$1" -ot "$2" ]] || {
		( mdsh-safe-subshell "${@:3}" && mdsh-main --out "$2" --compile "$1" ); mdsh-ok && touch -r "$1" "$2"
	}
}
mdsh-cache() {
	[[ -d "$1" ]] || mkdir -p "$1"
	flatname "${3:-$2}"; REPLY="$1/$REPLY"; mdsh-make "$2" "$REPLY" "${@:4}"
}
flatname() {
	REPLY="${1//\%/%25}"; REPLY="${REPLY//\//%2F}"; REPLY="${REPLY/#./%2E}"
	REPLY="${REPLY//</%3C}"; REPLY="${REPLY//>/%3E}"
	REPLY="${REPLY//\\/%5C}"
}
MDSH_CACHE=
mdsh-use-cache() {
	if ! (($#)); then
		set -- "${XDG_CACHE_HOME:-${HOME:+$HOME/.cache}}"
		set -- "${1:+$1/mdsh}"
	fi
	MDSH_CACHE="$1"
}
mdsh-use-cache
mdsh-run() {
	if [[ ${MDSH_CACHE-} ]]; then
		mdsh-cache "$MDSH_CACHE" "$1" "${2-}"
		mdsh-ok && source "$REPLY" "${@:3}"
	else run-markdown "$1" "${@:3}"
	fi
}
# run-markdown file args...
# Compile `file` and source the result, passing along any positional arguments
run-markdown() {
	REPLY=("$(set -e; mdsh-source "${1--}")"); mdsh-ok || return
	if [[ $BASH_VERSINFO == 3 ]]; then # bash 3 can't source from proc
		# shellcheck disable=SC1091  # shellcheck shouldn't try to read stdin
		source /dev/fd/0 "${@:2}" <<<"$REPLY"
	else source <(echo "$REPLY") "${@:2}"
	fi
}
if [[ $0 == "${BASH_SOURCE-}" ]]; then mdsh-main "$@"; exit; fi
