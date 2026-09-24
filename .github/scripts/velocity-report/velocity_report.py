#!/usr/bin/env python3
"""
Team velocity / productivity report for a git repository hosted on GitHub.

It combines two sources:
  * the local git history of *every* remote branch (integration branches such as
    develop/master, but also feature branches with or without a pull request);
  * the GitHub REST API (pull requests, reviews, author association) when a
    token is available.

Contributors are split into internal / external / bot / AI categories and the
output is a JSON dataset plus a self-contained HTML report.

Only the Python standard library is required.

Example:
    GITHUB_TOKEN=... python3 velocity_report.py --repo-path . \\
        --github-repo centreon/centreon-plugins --since 2025-09-01 --out-dir /tmp/velocity
"""

import argparse
import concurrent.futures
import datetime as dt
import fnmatch
import json
import os
import re
import statistics
import subprocess
import sys
import unicodedata
import urllib.error
import urllib.request
from collections import Counter, defaultdict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

DEFAULT_CONFIG = {
    # Email domains that identify internal contributors.
    "internal_domains": ["centreon.com"],
    # GitHub author_association values that identify internal contributors.
    "internal_associations": ["OWNER", "MEMBER", "COLLABORATOR"],
    # Force the category of an identity (login, email or name).
    "internal": [],
    "external": [],
    "bots": ["dependabot[bot]", "github-actions[bot]", "technique-ci", "renovate[bot]"],
    "bot_patterns": [r"\[bot\]", r"^technique-ci$", r"github-actions"],
    # Identities that are AI agents committing on their own.
    "ai_patterns": [r"noreply@anthropic\.com", r"^claude$", r"^copilot$", r"copilot-swe-agent"],
    # Commit message / PR body markers of AI-assisted work.
    "ai_markers": [
        r"co-authored-by:.*(anthropic|claude|copilot|cursor|codex|openai|gemini)",
        r"generated with \[?claude",
        r"claude\.ai/code",
        r"copilot",
    ],
    # Author names / email local parts shared by many people, never used to link identities.
    "generic_names": ["root", "unknown", "admin", "administrator", "user", "ubuntu", "centos", "yourname",
                      "git", "jenkins", "build", "test", "noreply", "noreply", "github"],
    # Merge several identities into one person: [["login:foo", "email:foo@bar.com"], ...]
    "aliases": [],
    # Optional team mapping: {"Team A": ["login", "email", "name", ...]}
    "teams": {},
    # Paths never counted (generated / vendored / lockfiles). fnmatch globs, '*' spans '/'.
    "exclude_paths": [
        "build/*", "*.lock", "*-lock.yaml", "*-lock.json", "*.min.js", "vendor/*", "*/vendor/*",
    ],
    # Ordered area rules: first match wins.
    "areas": [
        ["Fixtures de test", ["*.snmpwalk", "*mockoon*.json", "tests/*.json", "tests/*.txt", "tests/*/kubectl"]],
        ["Tests", ["tests/*", "*.t", "*.robot"]],
        ["Plugins Perl", ["src/*"]],
        ["Plugins Rust", ["rust-plugins/*"]],
        ["CI / packaging", [".github/*", "packaging/*", ".githooks/*", "selinux/*", "dependencies/*", ".version*"]],
        ["Documentation", ["doc/*", "*.md", "changelog"]],
        ["Connecteurs / autres", ["*"]],
    ],
    # Areas that are not counted as "code" in the headline KPIs.
    "non_code_areas": ["Fixtures de test"],
    # A branch without activity since this many days is considered dormant.
    "stale_days": 30,
}

PR_REF_RE = re.compile(r"\(#(\d+)\)\s*$")
MERGE_PR_RE = re.compile(r"^Merge pull request #(\d+)")
NOREPLY_RE = re.compile(r"^(?:\d+\+)?([^@]+)@users\.noreply\.github\.com$", re.I)
RENAME_BRACE_RE = re.compile(r"\{[^{}]* => ([^{}]*)\}")
COAUTHOR_RE = re.compile(r"^co-authored-by:\s*(.*?)\s*<([^>]+)>", re.I | re.M)
PR_MENTION_RE = re.compile(r"(?:#|/pull/)(\d+)\b")
PLUGIN_TOKEN_RE = re.compile(r"[a-z0-9_]+(?:::[a-z0-9_]+)+")
WORD_RE = re.compile(r"[a-z0-9]{3,}")


# --------------------------------------------------------------------------- utils

def log(msg):
    print(msg, file=sys.stderr, flush=True)


def git(repo, *args):
    return subprocess.run(
        ["git", "-C", repo, *args], check=True, capture_output=True, text=True, errors="replace"
    ).stdout


def parse_date(s):
    if s is None:
        return None
    return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))


def week_start(d):
    d = d.astimezone(dt.timezone.utc).date()
    return (d - dt.timedelta(days=d.weekday())).isoformat()


def month_of(d):
    return d.astimezone(dt.timezone.utc).strftime("%Y-%m")


def hours_between(a, b):
    return (b - a).total_seconds() / 3600.0


def median(values):
    values = [v for v in values if v is not None]
    return round(statistics.median(values), 1) if values else None


def percentile(values, p):
    values = sorted(v for v in values if v is not None)
    if not values:
        return None
    k = (len(values) - 1) * p
    f, c = int(k), min(int(k) + 1, len(values) - 1)
    return round(values[f] + (values[c] - values[f]) * (k - f), 1)


def norm_name(name):
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", name.lower())


def numstat_path(path):
    if " => " not in path:
        return path
    if "{" in path:
        return RENAME_BRACE_RE.sub(r"\1", path).replace("//", "/")
    return path.split(" => ", 1)[1]


def load_config(path):
    cfg = json.loads(json.dumps(DEFAULT_CONFIG))
    if path:
        with open(path, encoding="utf-8") as fh:
            user = json.load(fh)
        for key, value in user.items():
            cfg[key] = value
    return cfg


# ----------------------------------------------------------------------- identities

class Identities:
    """Union-find over identity keys (email:, name:, login:)."""

    def __init__(self, cfg):
        self.cfg = cfg
        self.parent = {}
        self.names = defaultdict(Counter)
        self.logins = defaultdict(set)
        self.emails = defaultdict(set)
        self.associations = defaultdict(set)
        # login keys known for sure (GitHub API or noreply email), as opposed to
        # logins guessed from the local part of an internal email address
        self.strong = set()
        self.recent_emails = defaultdict(set)
        self.generic = {norm_name(n) for n in cfg.get("generic_names", [])}
        self.internal_domains = [d.lower() for d in cfg["internal_domains"]]

    def _find(self, k):
        self.parent.setdefault(k, k)
        while self.parent[k] != k:
            self.parent[k] = self.parent[self.parent[k]]
            k = self.parent[k]
        return k

    def union(self, *keys):
        keys = [k for k in keys if k]
        if not keys:
            return None
        root = self._find(keys[0])
        for k in keys[1:]:
            r = self._find(k)
            if r != root:
                self.parent[r] = root
        return root

    def add_git(self, name, email, recent=False):
        email = (email or "").lower()
        keys = []
        if email:
            keys.append("email:" + email)
            m = NOREPLY_RE.match(email)
            if m:
                keys.append("login:" + m.group(1).lower())
                self.strong.add(keys[-1])
            else:
                local, _, domain = email.partition("@")
                if domain in self.internal_domains and norm_name(local) not in self.generic:
                    keys.append("login:" + local)
        if name and norm_name(name) and norm_name(name) not in self.generic:
            keys.append("name:" + norm_name(name))
        key = keys[0] if keys else "name:unknown"
        self.union(*keys) if keys else self._find(key)
        self.names[key][name] += 1
        if email:
            self.emails[key].add(email)
            if recent:
                self.recent_emails[key].add(email)
        return key

    def add_login(self, login, association=None):
        key = "login:" + login.lower()
        if norm_name(login):
            self.union(key, "name:" + norm_name(login))
        else:
            self._find(key)
        self.strong.add(key)
        self.logins[key].add(login)
        if association:
            self.associations[key].add(association)
        return key

    def strong_logins(self):
        """root -> set of strong login keys currently attached to it."""
        res = defaultdict(set)
        for k in self.strong:
            res[self._find(k)].add(k)
        return res

    def apply_aliases(self):
        for group in self.cfg.get("aliases", []):
            self.union(*[k.lower() if ":" in k else "login:" + k.lower() for k in group])

    def person(self, key):
        return self._find(key)

    def build_people(self):
        people = {}
        members = defaultdict(list)
        for k in list(self.parent):
            members[self._find(k)].append(k)
        for root, keys in members.items():
            names, logins, emails, assoc, recent = Counter(), set(), set(), set(), set()
            for k in keys:
                names.update(self.names.get(k, {}))
                logins |= self.logins.get(k, set())
                emails |= self.emails.get(k, set())
                recent |= self.recent_emails.get(k, set())
                assoc |= self.associations.get(k, set())
            people[root] = {
                "id": root,
                "keys": sorted(keys),
                "logins": sorted(logins),
                "emails": sorted(emails),
                "recent_emails": sorted(recent),
                "associations": sorted(assoc),
                "name": self._display_name(names, logins, keys),
            }
            people[root]["category"] = self._category(people[root])
        return people

    @staticmethod
    def _display_name(names, logins, keys):
        if names:
            ranked = sorted(names.items(), key=lambda kv: (" " not in kv[0].strip(), -kv[1]))
            return ranked[0][0]
        if logins:
            return sorted(logins)[0]
        return keys[0].split(":", 1)[1]

    def _matches(self, person, values):
        values = {v.lower() for v in values}
        idents = {person["name"].lower()} | {l.lower() for l in person["logins"]} | set(person["emails"])
        idents |= {k.split(":", 1)[1] for k in person["keys"]}
        return bool(idents & values)

    def _category(self, person):
        cfg = self.cfg
        idents = [person["name"]] + person["logins"] + person["emails"] + [k.split(":", 1)[1] for k in person["keys"]]
        if self._matches(person, cfg["bots"]) or any(
            re.search(p, i, re.I) for p in cfg["bot_patterns"] for i in idents
        ):
            return "bot"
        if any(re.search(p, i, re.I) for p in cfg["ai_patterns"] for i in idents):
            return "ai"
        if self._matches(person, cfg["external"]):
            return "external"
        if self._matches(person, cfg["internal"]):
            return "internal"
        internal_domain = lambda emails: any(e.split("@")[-1] in self.internal_domains for e in emails)
        # 1. internal email address used during the analysed period
        if internal_domain(person["recent_emails"]):
            return "internal"
        # 2. GitHub organisation membership
        if set(person["associations"]) & set(cfg["internal_associations"]):
            return "internal"
        # 3. known to GitHub as a non-member: former employees now contributing from outside
        if person["associations"]:
            return "external"
        # 4. no GitHub information: fall back on any internal email address ever used
        return "internal" if internal_domain(person["emails"]) else "external"


# ------------------------------------------------------------------------- git data

def resolve_integration_branches(repo, remote, requested):
    refs = set(git(repo, "for-each-ref", "--format=%(refname:short)", f"refs/remotes/{remote}").split())
    if requested:
        names = [b.strip() for b in requested.split(",") if b.strip()]
    else:
        names = []
        try:
            head = git(repo, "symbolic-ref", f"refs/remotes/{remote}/HEAD").strip()
            names.append(head.rsplit("/", 1)[-1])
        except subprocess.CalledProcessError:
            pass
        for candidate in ("develop", "main", "master"):
            if candidate not in names:
                names.append(candidate)
    result = [f"{remote}/{n}" for n in names if f"{remote}/{n}" in refs]
    if not result:
        raise SystemExit("No integration branch found, use --integration-branches")
    return result


def list_branches(repo, remote, integration):
    out = git(
        repo, "for-each-ref", "--sort=-committerdate",
        "--format=%(refname:short)\x1f%(committerdate:iso-strict)\x1f%(authorname)\x1f%(authoremail)",
        f"refs/remotes/{remote}",
    )
    branches = []
    for line in out.splitlines():
        ref, date, name, email = line.split("\x1f")
        if ref in integration or ref == f"{remote}/HEAD" or ref == remote:
            continue
        branches.append({
            "ref": ref, "name": ref[len(remote) + 1:], "last_commit": date,
            "tip_author_name": name, "tip_author_email": email.strip("<>"),
        })
    return branches


def read_commits(repo, revs, since, until):
    fmt = "\x1e%H\x1f%aN\x1f%aE\x1f%aI\x1f%cI\x1f%s\x1f%B\x1d"
    args = ["log", "--no-merges", "--numstat", "-M", f"--format={fmt}", *revs]
    if since:
        args.append(f"--since={since}")
    if until:
        args.append(f"--until={until}")
    raw = git(repo, *args)
    commits = []
    for rec in raw.split("\x1e")[1:]:
        head, _, stats = rec.partition("\x1d")
        sha, name, email, adate, cdate, subject, body = head.split("\x1f", 6)
        files = []
        for line in stats.strip().splitlines():
            parts = line.split("\t")
            if len(parts) != 3:
                continue
            add, dele, path = parts
            if add == "-":  # binary
                continue
            files.append((numstat_path(path), int(add), int(dele)))
        commits.append({
            "sha": sha, "author_name": name, "author_email": email, "author_date": adate,
            "commit_date": cdate, "subject": subject, "body": body, "files": files,
            "coauthors": COAUTHOR_RE.findall(body),
        })
    return commits


def merge_pr_numbers(repo, integration, since, until):
    """PR numbers of merge commits ("Merge pull request #N") on integration branches."""
    args = ["log", "--merges", "--format=%H\x1f%s\x1f%aN\x1f%aE\x1f%cI", *integration]
    if since:
        args.append(f"--since={since}")
    if until:
        args.append(f"--until={until}")
    res = {}
    for line in git(repo, *args).splitlines():
        sha, subject, name, email, cdate = line.split("\x1f")
        m = MERGE_PR_RE.match(subject)
        if m:
            res[int(m.group(1))] = {"sha": sha, "author_name": name, "author_email": email, "date": cdate}
    return res


class PathClassifier:
    def __init__(self, cfg):
        self.exclude = cfg["exclude_paths"]
        self.areas = cfg["areas"]
        self.cache = {}

    def area(self, path):
        if path in self.cache:
            return self.cache[path]
        result = None
        if not any(fnmatch.fnmatch(path, p) for p in self.exclude):
            for name, globs in self.areas:
                if any(fnmatch.fnmatch(path, g) for g in globs):
                    result = name
                    break
        self.cache[path] = result
        return result

    @staticmethod
    def domain(path):
        parts = path.split("/")
        if len(parts) > 2 and parts[0] in ("src", "tests"):
            return parts[1]
        if parts[0] == "rust-plugins":
            return "rust"
        return None


# ---------------------------------------------------------------------- GitHub data

class GitHub:
    def __init__(self, repo, token, cache_dir=None):
        self.repo = repo
        self.token = token
        self.cache_dir = cache_dir
        if cache_dir:
            os.makedirs(cache_dir, exist_ok=True)

    def _get(self, url):
        headers = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        for attempt in range(4):
            try:
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=60) as resp:
                    return json.load(resp), resp.headers
            except urllib.error.HTTPError as exc:
                if exc.code in (502, 503, 504) and attempt < 3:
                    continue
                raise
            except urllib.error.URLError:
                if attempt < 3:
                    continue
                raise

    def pulls(self, since):
        prs, page = [], 1
        while True:
            url = (f"https://api.github.com/repos/{self.repo}/pulls?state=all&sort=created"
                   f"&direction=desc&per_page=100&page={page}")
            data, _ = self._get(url)
            prs.extend(data)
            if not data or (since and data[-1]["created_at"] < since):
                break
            page += 1
        return prs

    def reviews(self, number, cacheable):
        path = os.path.join(self.cache_dir, f"reviews-{number}.json") if self.cache_dir else None
        if path and cacheable and os.path.exists(path):
            with open(path, encoding="utf-8") as fh:
                return json.load(fh)
        data, _ = self._get(f"https://api.github.com/repos/{self.repo}/pulls/{number}/reviews?per_page=100")
        slim = [{"login": (r.get("user") or {}).get("login"), "state": r.get("state"),
                 "submitted_at": r.get("submitted_at"), "association": r.get("author_association")}
                for r in data]
        if path and cacheable:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(slim, fh)
        return slim


# ------------------------------------------------------------------------ analysis

STOPWORDS = {"new", "plugin", "mode", "modes", "feat", "enh", "fix", "add", "the", "for", "and", "ctor",
             "with", "from", "support", "pack", "update", "api", "restapi", "snmp"}


def title_similarity(a, b):
    """1.0 when both titles name the same plugin path, else a Jaccard index on words."""
    a, b = a.lower(), b.lower()
    ta, tb = set(PLUGIN_TOKEN_RE.findall(a)), set(PLUGIN_TOKEN_RE.findall(b))
    if ta & tb:
        return 1.0
    wa = set(WORD_RE.findall(a)) - STOPWORDS
    wb = set(WORD_RE.findall(b)) - STOPWORDS
    return len(wa & wb) / len(wa | wb) if wa and wb else 0.0


def is_ai_assisted(text, cfg):
    text = (text or "").lower()
    return any(re.search(p, text) for p in cfg["ai_markers"])


def build_report(args, cfg):
    repo = args.repo_path
    since_dt = dt.datetime.fromisoformat(args.since).replace(tzinfo=dt.timezone.utc)
    until_dt = (dt.datetime.fromisoformat(args.until).replace(tzinfo=dt.timezone.utc) + dt.timedelta(days=1, seconds=-1)
                if args.until else dt.datetime.now(dt.timezone.utc))
    in_window = lambda d: d is not None and since_dt <= d <= until_dt

    integration = resolve_integration_branches(repo, args.remote, args.integration_branches)
    log(f"Integration branches: {', '.join(integration)}")
    classifier = PathClassifier(cfg)
    ids = Identities(cfg)

    # --- git: integrated commits (delivered work)
    integ_commits = read_commits(repo, integration, args.since, args.until)
    integ_shas = set(git(repo, "rev-list", *integration).split())
    log(f"Integrated commits in window: {len(integ_commits)}")

    # --- git: branch-only commits, assigned to the most recently active branch containing them
    branches = list_branches(repo, args.remote, integration)
    branch_of = {}
    for b in branches:
        unique = git(repo, "rev-list", "--no-merges", b["ref"], "--not", *integration).split()
        b["ahead"] = len(unique)
        b["behind"] = int(git(repo, "rev-list", "--count", integration[0], "--not", b["ref"]).strip())
        for sha in unique:
            branch_of.setdefault(sha, b["name"])
    branch_commits = [c for c in read_commits(repo, [b["ref"] for b in branches] + ["--not", *integration],
                                              None, None)
                      if c["sha"] not in integ_shas]
    log(f"Branches: {len(branches)}, branch-only commits (all time): {len(branch_commits)}")

    merges = merge_pr_numbers(repo, integration, args.since, args.until)

    # --- identities from git
    for c in integ_commits + branch_commits:
        recent = in_window(parse_date(c["commit_date"])) or in_window(parse_date(c["author_date"]))
        c["pkey"] = ids.add_git(c["author_name"], c["author_email"], recent)
        c["co_pkeys"] = [ids.add_git(n, e, recent) for n, e in c["coauthors"]]
    for b in branches:
        b["pkey"] = ids.add_git(b["tip_author_name"], b["tip_author_email"])

    # --- GitHub pull requests
    prs = []
    gh_enabled = bool(args.github_repo) and not args.no_github
    if gh_enabled:
        token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
        gh = GitHub(args.github_repo, token, args.cache_dir)
        try:
            raw_prs = gh.pulls(args.since)
        except urllib.error.HTTPError as exc:
            log(f"GitHub API unavailable ({exc}); continuing with git data only")
            raw_prs, gh_enabled = [], False
        repo_full = args.github_repo.lower()
        for p in raw_prs:
            created = parse_date(p["created_at"])
            merged = parse_date(p.get("merged_at"))
            closed = parse_date(p.get("closed_at"))
            if not (in_window(created) or in_window(merged) or in_window(closed) or p["state"] == "open"):
                continue
            head_repo = ((p.get("head") or {}).get("repo") or {}).get("full_name", "") or ""
            login = (p.get("user") or {}).get("login") or "ghost"
            prs.append({
                "number": p["number"], "title": p["title"], "url": p["html_url"],
                "login": login, "association": p.get("author_association"),
                "pkey": ids.add_login(login, p.get("author_association")),
                "created_at": p["created_at"], "merged_at": p.get("merged_at"),
                "closed_at": p.get("closed_at"), "state": p["state"], "draft": bool(p.get("draft")),
                "head_ref": (p.get("head") or {}).get("ref"), "base_ref": (p.get("base") or {}).get("ref"),
                "from_fork": head_repo.lower() != repo_full,
                "ai_assisted": is_ai_assisted(p.get("body"), cfg),
                "mentions": {int(n) for n in PR_MENTION_RE.findall(p.get("body") or "")},
            })
        log(f"Pull requests in scope: {len(prs)}")

        if not args.no_reviews:
            def fetch(pr):
                cacheable = pr["state"] == "closed"
                try:
                    return pr["number"], gh.reviews(pr["number"], cacheable)
                except urllib.error.HTTPError as exc:
                    log(f"reviews #{pr['number']}: {exc}")
                    return pr["number"], []
            with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
                reviews = dict(pool.map(fetch, prs))
            for pr in prs:
                pr["reviews"] = reviews.get(pr["number"], [])
                for r in pr["reviews"]:
                    if r["login"]:
                        r["pkey"] = ids.add_login(r["login"], r.get("association"))

    # --- link PR logins with git identities through the squash / merge commits
    commit_by_pr = {}
    for c in integ_commits:
        m = PR_REF_RE.search(c["subject"])
        if m:
            commit_by_pr.setdefault(int(m.group(1)), c)
    # A squash commit is normally authored by the PR author, but not always (bot
    # rewrites, PR taken over by a maintainer...): only link when the git identity
    # is not already owned by another GitHub account and does not look like a bot.
    claimed = ids.strong_logins()
    bot_re = [re.compile(p, re.I) for p in cfg["bot_patterns"] + cfg["ai_patterns"]]
    for pr in prs:
        c = commit_by_pr.get(pr["number"])
        if not (c and pr["merged_at"]):
            continue
        if any(r.search(c["author_name"]) or r.search(c["author_email"]) for r in bot_re):
            continue
        owners = claimed.get(ids.person(c["pkey"]), set())
        if owners and pr["pkey"] not in owners:
            continue
        ids.union(pr["pkey"], c["pkey"])
        claimed = ids.strong_logins()
    ids.apply_aliases()
    people = ids.build_people()
    P = ids.person

    # --- commit metrics
    def commit_stats(c):
        stats = {"add": 0, "del": 0, "files": 0, "areas": Counter(), "domains": Counter(), "code": 0,
                 "code_add": 0, "code_del": 0}
        for path, add, dele in c["files"]:
            area = classifier.area(path)
            if area is None:
                continue
            stats["add"] += add
            stats["del"] += dele
            stats["files"] += 1
            stats["areas"][area] += add + dele
            if area not in cfg["non_code_areas"]:
                stats["code"] += add + dele
                stats["code_add"] += add
                stats["code_del"] += dele
            dom = classifier.domain(path)
            if dom:
                stats["domains"][dom] += add + dele
        return stats

    commits_out = []
    for c in integ_commits:
        s = commit_stats(c)
        date = parse_date(c["commit_date"])
        m = PR_REF_RE.search(c["subject"])
        commits_out.append({
            "sha": c["sha"][:10], "person": P(c["pkey"]), "date": c["commit_date"], "week": week_start(date),
            "kind": "integrated", "branch": None, "pr": int(m.group(1)) if m else None,
            "ai": is_ai_assisted(c["body"], cfg), "subject": c["subject"],
            "coauthors": sorted({P(k) for k in c["co_pkeys"]} - {P(c["pkey"])}), **s,
        })
    for c in branch_commits:
        date = parse_date(c["author_date"])
        if not in_window(date):
            continue
        s = commit_stats(c)
        commits_out.append({
            "sha": c["sha"][:10], "person": P(c["pkey"]), "date": c["author_date"], "week": week_start(date),
            "kind": "branch", "branch": branch_of.get(c["sha"]), "pr": None,
            "ai": is_ai_assisted(c["body"], cfg), "subject": c["subject"],
            "coauthors": sorted({P(k) for k in c["co_pkeys"]} - {P(c["pkey"])}), **s,
        })

    # --- PR metrics
    pr_by_head = defaultdict(list)
    for pr in prs:
        pr["person"] = P(pr["pkey"])
        pr["category"] = people[pr["person"]]["category"]
        created, merged = parse_date(pr["created_at"]), parse_date(pr["merged_at"])
        pr["lead_time_h"] = round(hours_between(created, merged), 1) if merged else None
        first = None
        reviewers = set()
        for r in pr.get("reviews", []):
            if not r.get("login") or r["state"] == "PENDING" or not r.get("submitted_at"):
                continue
            rp = P(r["pkey"])
            if rp == pr["person"] or people[rp]["category"] == "bot":
                continue
            reviewers.add(rp)
            t = parse_date(r["submitted_at"])
            first = t if first is None or t < first else first
        pr["reviewers"] = sorted(reviewers)
        pr["first_review_h"] = round(hours_between(created, first), 1) if first else None
        c = commit_by_pr.get(pr["number"])
        if c:
            s = commit_stats(c)
            pr["size"] = s["add"] + s["del"]
            pr["code_size"] = s["code"]
        else:
            pr["size"] = pr["code_size"] = None
        if not pr["from_fork"] and pr["head_ref"]:
            pr_by_head[pr["head_ref"]].append(pr)
        pr.pop("reviews", None)
        pr.pop("pkey", None)

    # --- external contributions: merged directly, carried by an internal PR
    #     (closed then re-integrated with a Co-authored-by trailer), or dropped
    pr_index = {p["number"]: p for p in prs}
    carried_by = {}
    for p in prs:  # 1. internal merged PR explicitly mentioning the external one
        if p["merged_at"] and p["category"] == "internal":
            for n in sorted(p["mentions"]):
                q = pr_index.get(n)
                if q and q["category"] == "external" and q["state"] == "closed" and not q["merged_at"]:
                    carried_by.setdefault(n, p["number"])
    integrated = [c for c in commits_out if c["kind"] == "integrated"]
    for q in prs:  # 2. co-authored integrated commit with a similar title
        if q["category"] != "external" or q["state"] != "closed" or q["merged_at"] or q["number"] in carried_by:
            continue
        created, best = parse_date(q["created_at"]), None
        for c in integrated:
            if q["person"] not in c["coauthors"] or parse_date(c["date"]) < created:
                continue
            score = title_similarity(q["title"], c["subject"])
            if score >= 0.35 and (best is None or score > best[0]):
                best = (score, c)
        if best and best[1]["pr"]:
            carried_by[q["number"]] = best[1]["pr"]
    for p in prs:
        p["carried_by"] = carried_by.get(p["number"])
        p["carries_external"] = sorted(n for n, by in carried_by.items() if by == p["number"])
        p["outcome"] = ("merged" if p["merged_at"] else "carried" if p["carried_by"] else
                        "open" if p["state"] == "open" else "closed")
        carrier = pr_index.get(p["carried_by"]) if p["carried_by"] else None
        p["integrated_at"] = p["merged_at"] or (carrier["merged_at"] if carrier else None)
        p.pop("mentions", None)

    # --- branch status
    now = until_dt
    for b in branches:
        linked = sorted(pr_by_head.get(b["name"], []), key=lambda p: p["created_at"], reverse=True)
        b["person"] = P(b.pop("pkey"))
        last = parse_date(b["last_commit"])
        b["age_days"] = (now - last).days
        if linked:
            pr = linked[0]
            b["pr"] = pr["number"]
            b["status"] = ("merged" if pr["merged_at"] else
                           "draft" if pr["state"] == "open" and pr["draft"] else
                           "open" if pr["state"] == "open" else "closed")
        else:
            b["pr"] = None
            b["status"] = "no_pr_active" if b["age_days"] <= cfg["stale_days"] else "no_pr_dormant"
        if b["ahead"] == 0 and b["status"].startswith("no_pr"):
            b["status"] = "merged_or_empty"
    branch_status = {b["name"]: b["status"] for b in branches}
    for c in commits_out:
        if c["kind"] == "branch":
            c["branch_status"] = branch_status.get(c["branch"], "unknown")

    return aggregate(args, cfg, people, commits_out, prs, branches, merges, integration,
                     since_dt, until_dt, gh_enabled)


def aggregate(args, cfg, people, commits, prs, branches, merges, integration, since_dt, until_dt, gh_enabled):
    cats = ["internal", "external", "bot", "ai"]
    in_window = lambda s: s is not None and since_dt <= parse_date(s) <= until_dt

    # weeks axis
    weeks = []
    w = dt.date.fromisoformat(week_start(since_dt))
    while w <= until_dt.date():
        weeks.append(w.isoformat())
        w += dt.timedelta(days=7)
    months = sorted({w[:7] for w in weeks})

    def per_week():
        return {c: {wk: 0 for wk in weeks} for c in cats}

    merged_w, opened_w, lines_w, wip_w = per_week(), per_week(), per_week(), per_week()
    ext_w = {o: {wk: 0 for wk in weeks} for o in ("merged", "carried")}
    lead_m = defaultdict(lambda: defaultdict(list))
    review_m = defaultdict(lambda: defaultdict(list))

    person_stats = defaultdict(lambda: {
        "prs_opened": 0, "prs_merged": 0, "prs_closed_unmerged": 0, "prs_open": 0, "lead_times": [],
        "first_reviews": [], "reviews_given": 0, "commits_integrated": 0, "commits_branch": 0,
        "add": 0, "del": 0, "code": 0, "wip_lines": 0, "weeks": set(), "areas": Counter(),
        "domains": Counter(), "ai_prs": 0, "ai_commits": 0, "prs_carried": 0,
        "coauthored_commits": 0, "coauthored_lines": 0, "carried_external": 0,
    })

    merged_prs = [p for p in prs if in_window(p["merged_at"])]
    for p in prs:
        ps = person_stats[p["person"]]
        cat = p["category"]
        if in_window(p["created_at"]):
            ps["prs_opened"] += 1
            wk = week_start(parse_date(p["created_at"]))
            if wk in opened_w[cat]:
                opened_w[cat][wk] += 1
        if in_window(p["merged_at"]):
            ps["prs_merged"] += 1
            ps["lead_times"].append(p["lead_time_h"])
            if p["ai_assisted"]:
                ps["ai_prs"] += 1
            wk = week_start(parse_date(p["merged_at"]))
            if wk in merged_w[cat]:
                merged_w[cat][wk] += 1
            lead_m[month_of(parse_date(p["merged_at"]))][cat].append(p["lead_time_h"])
        elif p["state"] == "closed" and in_window(p["closed_at"]):
            ps["prs_closed_unmerged"] += 1
            if p["carried_by"]:
                ps["prs_carried"] += 1
        if p["category"] == "external" and p["outcome"] in ("merged", "carried") and in_window(p["integrated_at"]):
            wk = week_start(parse_date(p["integrated_at"]))
            if wk in ext_w[p["outcome"]]:
                ext_w[p["outcome"]][wk] += 1
        if p["state"] == "open":
            ps["prs_open"] += 1
        if in_window(p["created_at"]) and p["first_review_h"] is not None:
            ps["first_reviews"].append(p["first_review_h"])
            review_m[month_of(parse_date(p["created_at"]))][cat].append(p["first_review_h"])
        for r in p["reviewers"]:
            if in_window(p["created_at"]) or in_window(p["merged_at"]):
                person_stats[r]["reviews_given"] += 1

    area_totals = defaultdict(Counter)
    domain_totals = defaultdict(Counter)
    for c in commits:
        ps = person_stats[c["person"]]
        cat = people[c["person"]]["category"]
        ps["weeks"].add(c["week"])
        if c["ai"]:
            ps["ai_commits"] += 1
        if c["kind"] == "integrated":
            ext_co = [k for k in c["coauthors"] if people[k]["category"] == "external"]
            for k in ext_co:
                person_stats[k]["coauthored_commits"] += 1
                person_stats[k]["coauthored_lines"] += c["code"]
                person_stats[k]["weeks"].add(c["week"])
            if ext_co and cat == "internal":
                ps["carried_external"] += 1
            ps["commits_integrated"] += 1
            ps["add"] += c["add"]
            ps["del"] += c["del"]
            ps["code"] += c["code"]
            ps["areas"].update(c["areas"])
            ps["domains"].update(c["domains"])
            area_totals[cat].update(c["areas"])
            domain_totals[cat].update(c["domains"])
            if c["week"] in lines_w[cat]:
                lines_w[cat][c["week"]] += c["code"]
        else:
            ps["commits_branch"] += 1
            if c.get("branch_status") in ("open", "draft", "no_pr_active", "no_pr_dormant", "closed"):
                ps["wip_lines"] += c["code"]
            if c["week"] in wip_w[cat]:
                wip_w[cat][c["week"]] += 1

    total_weeks = max(len(weeks), 1)
    people_rows = []
    for pid, s in person_stats.items():
        person = people[pid]
        row = {
            "id": pid, "name": person["name"], "logins": person["logins"], "category": person["category"],
            "team": team_of(person, cfg),
            "prs_opened": s["prs_opened"], "prs_merged": s["prs_merged"],
            "prs_closed_unmerged": s["prs_closed_unmerged"], "prs_open": s["prs_open"],
            "lead_time_median_h": median(s["lead_times"]),
            "first_review_median_h": median(s["first_reviews"]),
            "reviews_given": s["reviews_given"],
            "commits_integrated": s["commits_integrated"], "commits_branch": s["commits_branch"],
            "lines_added": s["add"], "lines_deleted": s["del"], "code_lines": s["code"],
            "wip_lines": s["wip_lines"], "active_weeks": len(s["weeks"]),
            "activity_rate": round(len(s["weeks"]) / total_weeks, 2),
            "top_areas": [a for a, _ in s["areas"].most_common(3)],
            "top_domains": [d for d, _ in s["domains"].most_common(3)],
            "ai_prs": s["ai_prs"], "ai_commits": s["ai_commits"], "prs_carried": s["prs_carried"],
            "coauthored_commits": s["coauthored_commits"], "coauthored_lines": s["coauthored_lines"],
            "carried_external": s["carried_external"],
        }
        if any(row[k] for k in ("prs_opened", "prs_merged", "reviews_given", "commits_integrated",
                                "commits_branch", "prs_open", "coauthored_commits")):
            people_rows.append(row)
    people_rows.sort(key=lambda r: (-r["prs_merged"], -r["commits_integrated"], -r["commits_branch"]))

    def group_summary(key):
        groups = defaultdict(lambda: Counter())
        members = defaultdict(set)
        lt = defaultdict(list)
        for r in people_rows:
            g = r[key]
            members[g].add(r["id"])
            for k in ("prs_opened", "prs_merged", "prs_closed_unmerged", "prs_carried", "reviews_given",
                      "commits_integrated", "commits_branch", "code_lines", "wip_lines", "ai_prs",
                      "coauthored_commits", "carried_external"):
                groups[g][k] += r[k]
        for p in merged_prs:
            g = p["category"] if key == "category" else team_of(people[p["person"]], cfg)
            lt[g].append(p["lead_time_h"])
        out = []
        for g, c in groups.items():
            decided = c["prs_merged"] + c["prs_closed_unmerged"]
            out.append({
                "group": g, "contributors": len(members[g]), **c,
                "merge_rate": round(c["prs_merged"] / decided, 2) if decided else None,
                "integration_rate": round((c["prs_merged"] + c["prs_carried"]) / decided, 2) if decided else None,
                "lead_time_median_h": median(lt[g]), "lead_time_p90_h": percentile(lt[g], 0.9),
            })
        return sorted(out, key=lambda r: -r["prs_merged"])

    # external contributions detail
    ext_prs = [p for p in prs if p["category"] == "external" and in_window(p["created_at"])]
    ext_outcomes = Counter(p["outcome"] for p in ext_prs)
    ext_decided = ext_outcomes["merged"] + ext_outcomes["carried"] + ext_outcomes["closed"]
    ext_integ_delay = [hours_between(parse_date(p["created_at"]), parse_date(p["integrated_at"]))
                       for p in ext_prs if p["integrated_at"]]
    first_timers = sorted({p["login"] for p in ext_prs if p["association"] == "FIRST_TIME_CONTRIBUTOR"})

    human = [p for p in merged_prs if p["category"] in ("internal", "external")]
    open_prs = [p for p in prs if p["state"] == "open"]
    code_integrated = sum(c["code"] for c in commits if c["kind"] == "integrated"
                          and people[c["person"]]["category"] != "bot")

    status_counter = Counter(b["status"] for b in branches)
    branch_rows = sorted(branches, key=lambda b: b["last_commit"], reverse=True)
    for b in branch_rows:
        b["person_name"] = people[b["person"]]["name"]
        b["category"] = people[b["person"]]["category"]

    kpis = {
        "prs_merged": len(merged_prs),
        "prs_merged_human": len(human),
        "prs_merged_internal": sum(p["category"] == "internal" for p in merged_prs),
        "prs_merged_external": sum(p["category"] == "external" for p in merged_prs),
        "prs_merged_bot": sum(p["category"] == "bot" for p in merged_prs),
        "prs_merged_per_week": round(len(human) / total_weeks, 1),
        "lead_time_median_h": median([p["lead_time_h"] for p in human]),
        "lead_time_p90_h": percentile([p["lead_time_h"] for p in human], 0.9),
        "first_review_median_h": median([p["first_review_h"] for p in prs
                                         if in_window(p["created_at"]) and p["category"] in ("internal", "external")]),
        "pr_size_median": median([p["code_size"] for p in human if p["code_size"] is not None]),
        "code_lines_integrated": code_integrated,
        "active_internal": sum(1 for r in people_rows if r["category"] == "internal" and r["active_weeks"]),
        "active_external": sum(1 for r in people_rows if r["category"] == "external"
                               and (r["active_weeks"] or r["prs_opened"])),
        "open_prs": len(open_prs),
        "open_prs_external": sum(p["category"] == "external" for p in open_prs),
        "ai_assisted_prs": sum(p["ai_assisted"] for p in merged_prs),
        "ai_assisted_commits": sum(c["ai"] for c in commits if c["kind"] == "integrated"),
        "commits_integrated": sum(c["kind"] == "integrated" for c in commits),
        "commits_branch": sum(c["kind"] == "branch" for c in commits),
        "branches": len(branches),
        "branches_without_pr": status_counter["no_pr_active"] + status_counter["no_pr_dormant"],
    }

    line_index = {}
    commit_lines = []
    for c in sorted(commits, key=lambda c: c["date"]):
        if c["person"] not in line_index:
            line_index[c["person"]] = len(line_index)
        commit_lines.append([
            parse_date(c["date"]).astimezone(dt.timezone.utc).date().isoformat(), line_index[c["person"]],
            "i" if c["kind"] == "integrated" else "b", c.get("branch_status") or "",
            c["code_add"], c["code_del"], c["add"] - c["code_add"], c["del"] - c["code_del"],
        ])
    line_people = [{"name": people[pid]["name"], "category": people[pid]["category"],
                    "team": team_of(people[pid], cfg)} for pid in line_index]

    def month_series(src):
        return {c: [median(src[m][c]) if src[m][c] else None for m in months] for c in ("internal", "external")}

    return {
        "meta": {
            "repository": args.github_repo or os.path.basename(os.path.abspath(args.repo_path)),
            "since": since_dt.date().isoformat(), "until": until_dt.date().isoformat(),
            "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
            "integration_branches": integration, "github": gh_enabled,
            "reviews": gh_enabled and not args.no_reviews,
            "non_code_areas": cfg["non_code_areas"], "exclude_paths": cfg["exclude_paths"],
            "internal_domains": cfg["internal_domains"],
            "has_teams": bool(cfg.get("teams")),
        },
        "kpis": kpis,
        "weeks": weeks, "months": months,
        "series": {
            "merged_prs": {c: list(merged_w[c].values()) for c in cats},
            "opened_prs": {c: list(opened_w[c].values()) for c in cats},
            "code_lines": {c: list(lines_w[c].values()) for c in cats},
            "branch_commits": {c: list(wip_w[c].values()) for c in cats},
            "external_integrated": {o: list(ext_w[o].values()) for o in ext_w},
            "lead_time_median_h": month_series(lead_m),
            "first_review_median_h": month_series(review_m),
        },
        "areas": {c: dict(area_totals[c]) for c in cats},
        "domains": {c: dict(domain_totals[c].most_common(15)) for c in cats},
        "by_category": group_summary("category"),
        "by_team": group_summary("team") if cfg.get("teams") else [],
        "people": people_rows,
        "external": {
            "prs": len(ext_prs),
            "outcomes": dict(ext_outcomes),
            "integration_rate": round((ext_outcomes["merged"] + ext_outcomes["carried"]) / ext_decided, 2)
            if ext_decided else None,
            "integration_delay_median_h": median(ext_integ_delay),
            "first_review_median_h": median([p["first_review_h"] for p in ext_prs]),
            "coauthored_commits": sum(1 for c in commits if c["kind"] == "integrated" and any(
                people[k]["category"] == "external" for k in c["coauthors"])),
            "carried": [slim_pr(p) for p in ext_prs if p["outcome"] == "carried"],
            "first_time_contributors": first_timers,
            "open": [slim_pr(p) for p in open_prs if p["category"] == "external"],
        },
        "open_prs": sorted([slim_pr(p) for p in open_prs], key=lambda p: p["created_at"]),
        "branch_status": dict(status_counter),
        "branches": [{k: b[k] for k in ("name", "last_commit", "age_days", "person_name", "category",
                                         "ahead", "behind", "pr", "status")} for b in branch_rows],
        "pull_requests": [slim_pr(p) for p in prs],
        "line_people": line_people,
        # one row per commit in the window, for day / week line charts built in the page:
        # [date (UTC, YYYY-MM-DD), person index, kind (i = integrated, b = branch only),
        #  branch status, code added, code deleted, fixtures added, fixtures deleted]
        "commit_lines": commit_lines,
    }


def slim_pr(p):
    return {k: p.get(k) for k in ("number", "title", "url", "login", "category", "association", "created_at",
                                   "merged_at", "closed_at", "state", "draft", "base_ref", "head_ref",
                                   "from_fork", "lead_time_h", "first_review_h", "code_size", "ai_assisted",
                                   "outcome", "carried_by", "carries_external", "integrated_at")}


def team_of(person, cfg):
    teams = cfg.get("teams") or {}
    idents = {person["name"].lower()} | {l.lower() for l in person["logins"]} | set(person["emails"])
    idents |= {k.split(":", 1)[1] for k in person["keys"]}
    for team, members in teams.items():
        if idents & {m.lower() for m in members}:
            return team
    return {"internal": "Interne (sans équipe)", "external": "Externe", "bot": "Bots", "ai": "Agents IA"}[
        person["category"]]


# ---------------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo-path", default=".", help="local clone with the full history of all branches")
    ap.add_argument("--remote", default="origin")
    ap.add_argument("--github-repo", help="owner/name, enables pull request metrics")
    ap.add_argument("--since", default=(dt.date.today() - dt.timedelta(days=365)).isoformat())
    ap.add_argument("--until", help="end date (default: now)")
    ap.add_argument("--integration-branches", help="comma separated (default: remote HEAD + develop/main/master)")
    ap.add_argument("--config", help="JSON config file (see config.example.json)")
    ap.add_argument("--out-dir", default="velocity-report")
    ap.add_argument("--cache-dir", help="cache directory for immutable GitHub API responses")
    ap.add_argument("--no-github", action="store_true", help="git data only")
    ap.add_argument("--no-reviews", action="store_true", help="skip per-PR review calls")
    ap.add_argument("--fetch", action="store_true", help="git fetch --unshallow/--prune all branches first")
    args = ap.parse_args()

    if args.fetch:
        if git(args.repo_path, "rev-parse", "--is-shallow-repository").strip() == "true":
            git(args.repo_path, "fetch", "--unshallow", "--prune", args.remote,
                f"+refs/heads/*:refs/remotes/{args.remote}/*")
        else:
            git(args.repo_path, "fetch", "--prune", args.remote, f"+refs/heads/*:refs/remotes/{args.remote}/*")
    elif git(args.repo_path, "rev-parse", "--is-shallow-repository").strip() == "true":
        log("WARNING: shallow clone, history is incomplete (use --fetch)")

    cfg = load_config(args.config)
    report = build_report(args, cfg)

    os.makedirs(args.out_dir, exist_ok=True)
    json_path = os.path.join(args.out_dir, "velocity-report.json")
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=1)
    with open(os.path.join(SCRIPT_DIR, "report_template.html"), encoding="utf-8") as fh:
        template = fh.read()
    data = json.dumps(report, ensure_ascii=False).replace("</", "<\\/")
    html_path = os.path.join(args.out_dir, "velocity-report.html")
    with open(html_path, "w", encoding="utf-8") as fh:
        fh.write('<!doctype html>\n<html lang="fr">\n')
        fh.write(template.replace("/*__REPORT_DATA__*/null", data))
        fh.write("\n</html>\n")
    log(f"Written {json_path} and {html_path}")


if __name__ == "__main__":
    main()
