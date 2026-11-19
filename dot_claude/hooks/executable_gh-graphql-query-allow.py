#!/usr/bin/env python3
"""PermissionRequest hook: approve read-only `gh api graphql` queries.

The ask rules in settings.json prompt for every `gh api graphql` call and for
any `gh api` call with -f/-F/--input, because those can write. This hook runs
only when Claude Code is about to show that prompt. It answers "allow" when the
call is a single `gh api graphql` command whose query text never contains the
word `mutation` or `subscription`. In every other case it prints nothing, and
the normal prompt appears.

It fails closed: anything it cannot read exactly the way the shell will is
left to the prompt. So it stays silent when:
- the command uses any shell syntax beyond plain words, 'single quotes' and
  "double quotes" without $, backtick or backslash inside (no operators, expansions, globs,
  ~, escapes or newlines);
- the one exception, a single `> file` or `>> file` at the very end, names a
  file that is not an absolute path inside /tmp/claude-<uid>/ (where Claude
  Code keeps session scratchpads) once symlinks are followed;
- the query cannot be found or read, or comes from stdin;
- `mutation` or `subscription` appears anywhere in the query text, even in a
  comment or string (a false alarm only costs a prompt);
- a field other than `query` reads a file (`-F name=@path`), which would send
  that file's contents to GitHub;
- a field name is not a plain identifier (`a[b]=`, `query[]=`);
- any flag outside a fixed list of `gh api` flags appears (so -X/--method,
  short-flag clusters such as `-iF`, attached values such as `-Fx=@f`, `--`),
  or a bare argument follows `graphql`;
- `graphql` is not the first argument after `gh api`.
"""
import json
import os
import re
import sys

FIELD_FLAGS = {"-f", "--raw-field", "-F", "--field"}
# Every other `gh api` flag the hook accepts, spelled exactly. Anything else
# starting with "-" (short-flag clusters such as -iF, --, unknown flags) and
# any bare argument after `graphql` leaves the call to the prompt.
VALUE_FLAGS = {"-H", "--header", "--hostname", "-q", "--jq", "-t", "--template",
               "--cache", "-p", "--preview"}
BOOL_FLAGS = {"-i", "--include", "--paginate", "--silent", "--slurp", "--verbose"}
# Characters allowed outside quotes. Excludes everything the shell treats
# specially: operators, $, `, \, globs, braces, ~, quotes, #, !, and = at the
# start of a word (zsh expands =cmd).
PLAIN = re.compile(r"[A-Za-z0-9_./:@,+%=-]")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
WRITE_OPS = re.compile(r"\b(mutation|subscription)\b")


def silent():
    sys.exit(0)


def approve():
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": {"behavior": "allow"},
        }
    }))
    sys.exit(0)


def split_words(command):
    """Split a command into words the way bash and zsh would.

    Returns (words, redirect_target), where redirect_target is the file named
    by one trailing `> file` or `>> file`, or None if there is none. Returns
    None if the command uses any syntax this function does not model."""
    words, cur, in_word, i, n = [], [], False, 0, len(command)
    redirect_at = None
    while i < n:
        c = command[i]
        if c == ">":
            # Only a standalone `>` or `>>` (so not `2>`, `x>`, `>|`, `>&`,
            # `>(`), and only once. The characters after it go through the
            # normal rules, which reject |, & and (.
            if in_word or redirect_at is not None:
                return None
            redirect_at = len(words)
            i += 2 if command.startswith(">>", i) else 1
        elif c in " \t":
            if in_word:
                words.append("".join(cur))
                cur, in_word = [], False
            i += 1
        elif c == "'":
            end = command.find("'", i + 1)
            if end < 0:
                return None
            cur.append(command[i + 1:end])
            in_word, i = True, end + 1
        elif c == '"':
            end = command.find('"', i + 1)
            if end < 0:
                return None
            body = command[i + 1:end]
            if any(ch in body for ch in "$`\\"):
                return None
            cur.append(body)
            in_word, i = True, end + 1
        elif PLAIN.fullmatch(c):
            if c == "=" and not in_word:
                return None
            cur.append(c)
            in_word, i = True, i + 1
        else:
            return None
    if in_word:
        words.append("".join(cur))
    if redirect_at is None:
        return words, None
    # The redirect must name exactly one file and end the command.
    if len(words) != redirect_at + 1:
        return None
    return words[:-1], words[-1]


def scratch_target(path):
    """True if path is an absolute file path whose real location (symlinks
    followed) is inside /tmp/claude-<uid>/, the parent of Claude Code's
    session scratchpads, and that directory belongs to this user."""
    if not os.path.isabs(path):
        return False
    root = os.path.realpath("/tmp/claude-%d" % os.getuid())
    try:
        if os.stat(root).st_uid != os.getuid():
            return False
    except OSError:
        return False
    return os.path.realpath(path).startswith(root + os.sep)


def read_file(path, cwd):
    if path == "-":
        return None  # stdin: cannot inspect
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except (OSError, UnicodeDecodeError):
        return None


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        silent()
    if event.get("tool_name") != "Bash":
        silent()
    command = (event.get("tool_input") or {}).get("command", "")
    cwd = event.get("cwd") or os.getcwd()

    split = split_words(command)
    if split is None:
        silent()
    tokens, target = split
    if target is not None and not scratch_target(target):
        silent()
    # The endpoint must come first, so a later "graphql" token (a --jq value,
    # say) cannot make a REST call look like a query.
    if tokens[:3] != ["gh", "api", "graphql"]:
        silent()

    queries = []
    i = 3
    while i < len(tokens):
        tok = tokens[i]
        flag, _, inline = tok.partition("=") if tok.startswith("--") else (tok, "", "")
        if flag in BOOL_FLAGS and not inline:
            pass
        elif flag in VALUE_FLAGS:
            if not inline:
                i += 1
                if i >= len(tokens):
                    silent()
        elif flag in FIELD_FLAGS or flag == "--input":
            if inline:
                value = inline
            elif i + 1 < len(tokens):
                i += 1
                value = tokens[i]
            else:
                silent()
            if flag == "--input":
                body = read_file(value, cwd)
                try:
                    q = json.loads(body).get("query") if body else None
                except (ValueError, AttributeError):
                    q = None
                if not isinstance(q, str):
                    silent()
                queries.append(q)
            else:
                name, sep, val = value.partition("=")
                if not sep or not IDENT.fullmatch(name):
                    silent()
                reads_file = flag in ("-F", "--field") and val.startswith("@")
                if name == "query":
                    q = read_file(val[1:], cwd) if reads_file else val
                    if q is None:
                        silent()
                    queries.append(q)
                elif reads_file:
                    silent()
        else:
            silent()
        i += 1

    if queries and not any(WRITE_OPS.search(q) for q in queries):
        approve()
    silent()


if __name__ == "__main__":
    main()
