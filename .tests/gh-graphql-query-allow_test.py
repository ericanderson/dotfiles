"""Tests for dot_claude/hooks/executable_gh-graphql-query-allow.py.

Run from anywhere: python3 -I .tests/gh-graphql-query-allow_test.py
Each case pipes a PermissionRequest event into the hook and checks whether it
answers "allow" (no prompt) or stays silent (the normal prompt shows). Exits 1
if any case fails.

This folder starts with a dot, so chezmoi never deploys it.
"""
import atexit, json, os, shutil, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = os.path.join(REPO, "dot_claude", "hooks", "executable_gh-graphql-query-allow.py")
d = tempfile.mkdtemp()
atexit.register(shutil.rmtree, d, ignore_errors=True)
open(os.path.join(d, "q.graphql"), "w").write('query { viewer { login } }')
open(os.path.join(d, "m.graphql"), "w").write('mutation { addStar(input:{starrableId:"x"}) { clientMutationId } }')
open(os.path.join(d, "commented.graphql"), "w").write('# a mutation would go here\n{ viewer { login } }')
open(os.path.join(d, "trick.graphql"), "w").write('# "\nmutation { addStar(input:{starrableId:"x"}) { clientMutationId } }\n"')
open(os.path.join(d, "in.json"), "w").write(json.dumps({"query": "{ viewer { login } }"}))
open(os.path.join(d, "in-m.json"), "w").write(json.dumps({"query": "mutation { x }"}))

cases = [
    # (expect_allow, command)
    (True,  "gh api graphql -F query=@q.graphql"),
    (True,  "gh api graphql -f query='query { viewer { login } }'"),
    (True,  "gh api graphql -f query='query($o:String!){ repository(owner:$o,name:\"x\"){ id } }' -f o=anthropics"),
    (True,  "gh api graphql --paginate -f query='{ viewer { login } }' --jq .data"),
    (True,  "gh api graphql --raw-field=query='{ viewer { login } }'"),
    (False, "gh api graphql -f query='{ a }' -iF query=@m.graphql"),
    (False, "gh api graphql -iFquery=@m.graphql"),
    (False, "gh api graphql -f=query=@m.graphql"),
    (False, "gh api graphql -f query='{ a }' -- -F query=@m.graphql"),
    (False, "gh api graphql -f query='{ a }' extra"),
    (False, "gh api graphql -f query='{ a }' --method=POST"),
    (False, "gh api graphql -f query='{ a }' --unknown"),
    (False, "gh api graphql -f query='{ a }' --jq"),
    (True,  "gh api graphql -i -H 'Accept: application/json' --hostname github.com -f query='{ a }' -q .data --jq=.data --silent"),
    (False, "gh api graphql -F query=@commented.graphql"),
    (False, "gh api graphql -F query=@trick.graphql"),
    (False, "gh api graphql -f query=$'\\x6dutation { addStar(input:{}) { clientMutationId } }'"),
    (False, "gh api graphql -f \"query=$Q\""),
    (False, "gh api graphql -f query=\\mutation"),
    (False, "gh api graphql -F query=@*.graphql"),
    (False, "gh api graphql -F query=@~/q.graphql"),
    (False, "gh api graphql -f query={viewer{login}}"),
    (False, "gh api graphql =gh -f query='{ a }'"),
    (False, "gh api graphql -F 'query[]=@m.graphql'"),
    (False, "gh api graphql -f query='{ a }' -f 'x[y]=1'"),
    (False, "gh api graphql -f query=\"{ viewer { login } }\" -f x=\"a\\\"b\""),
    (True,  "gh api graphql -f query=\"{ viewer { login } }\""),
    (True,  "gh api graphql -F query=@" + "QDIR/q.graphql"),
    (True,  "gh api graphql --input in.json"),
    (True,  "gh api graphql -f query='{ repository(owner:\"a\",name:\"b\"){ issue(number:1){ title } } }' -f note='mutation in a variable is fine'"),
    (False, "gh api graphql -F query=@m.graphql"),
    (False, "gh api graphql -f query='mutation { addStar(input:{}) { clientMutationId } }'"),
    (False, "gh api graphql -f query='subscription { x }'"),
    (False, "gh api graphql --input in-m.json"),
    (False, "gh api graphql --input -"),
    (False, "gh api graphql -F query=@missing.graphql"),
    (False, "gh api graphql -f query='{ viewer { login } }' -F secret=@/etc/hosts"),
    (False, "gh api graphql -f query='{ viewer { login } }' -Fsecret=@/etc/hosts"),
    (False, "gh api graphql -f query='{ viewer { login } }' ; rm -rf /tmp/x"),
    (False, "gh api graphql -f query='{ viewer { login } }' && echo hi"),
    (False, "gh api graphql -f query='{ viewer { login } }' | tee out"),
    (False, "gh api graphql -f query=\"$(cat m.graphql)\""),
    (False, "gh api graphql -f query='{ viewer { login } }' > out.json"),
    (False, "gh api graphql -X GET -f query='{ viewer { login } }'"),
    (False, "gh api repos/o/r/issues --jq graphql -f query=hi -f title=x"),
    (False, "gh api repos/o/r/issues -f title=x"),
    (False, "gh api graphql"),
    (False, "echo gh api graphql -f query='{ a }'"),
]

fails = 0
for expect, cmd in cases:
    cmd = cmd.replace("QDIR", d)
    ev ={"hook_event_name": "PermissionRequest", "tool_name": "Bash", "cwd": d,
          "tool_input": {"command": cmd}}
    r = subprocess.run([sys.executable, "-I", HOOK], input=json.dumps(ev), capture_output=True, text=True)
    got = bool(r.stdout.strip()) and json.loads(r.stdout)["hookSpecificOutput"]["decision"]["behavior"] == "allow"
    ok = got == expect and r.returncode == 0 and not r.stderr
    fails += not ok
    print(("PASS" if ok else "FAIL"), "allow" if got else "prompt", "|", cmd, ("| stderr: " + r.stderr.strip()) if r.stderr else "")

# Non-Bash and garbage input stay silent.
for raw in ['{"tool_name":"Edit","tool_input":{}}', "not json"]:
    r = subprocess.run([sys.executable, "-I", HOOK], input=raw, capture_output=True, text=True)
    ok = r.stdout == "" and r.returncode == 0
    fails += not ok
    print(("PASS" if ok else "FAIL"), "silent |", raw)

print("failures:", fails)
sys.exit(1 if fails else 0)
