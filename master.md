# YesWeHack Master Bug Hunting & Penetration Testing Playbook

**Programs:** Verda Bug Bounty Program and Superbank Public Bug Bounty Program  
**Hunter:** `inventashif`  
**Platform:** YesWeHack  
**Document version:** 1.1  
**Document release date:** 2026-07-27  
**Program snapshot status:** working snapshot supplied by the researcher; revalidation required before every session  
**Purpose:** authorized, minimum-impact web, API, SDK, cloud-service, and Android security research. The listed iOS asset is recorded for scope awareness but iOS testing is intentionally outside this Android-focused version.

> **Authority rule:** the current program page, scope table, and triager instructions always override this file. Program scope can change. Re-read and save the current rules before every hunting session. A discovered host, route, IP, mobile endpoint, third-party service, or historical URL is **not authorization**.
>
> **Completeness rule:** this is a broad hypothesis and test-case catalog, not a promise that every possible vulnerability is listed. New application behavior should create new threat-model-specific test cases.
>
> **Production-safety rule:** use the least invasive proof that establishes a security boundary failure. Never turn a valid observation into unnecessary data access, persistence, lateral movement, service impact, or user impact.

---

## 1. Non-Negotiable Operating Model

Use this decision chain for every action:

```text
Current program rules
        ↓
Exact asset allowlist
        ↓
Is the technique permitted on production?
        ↓
Own account / own object / harmless canary
        ↓
Smallest request count that can answer the hypothesis
        ↓
Stop at first conclusive impact
        ↓
Redact, preserve evidence, and report
```

A technique being demonstrated in PortSwigger Academy, HackTricks, a public write-up, or a disclosed report does **not** make it permitted against a live target. Labs teach techniques; the program rules define authorization.

### 1.1 Universal hard stops

Immediately stop the test and preserve evidence if any of the following occurs:

- A request reveals another real user's data, credentials, tokens, financial information, KYC material, private model data, or secrets.
- A test reaches an account, tenant, project, container, inference job, or file not controlled by the researcher.
- If a credential or secret appears valid, do not authenticate with it, exchange it, call `whoami`, query its permissions, or access data. Follow an exact validation procedure only when the current program explicitly provides one; otherwise preserve source-location evidence, redact the value, and report immediately.
- A test could change balances, trigger a transfer, create financial liability, consume meaningful paid compute, alter KYC state, send external communications, or affect another user.
- Service latency, error rate, availability, queues, resource usage, or normal behavior begins to degrade.
- A redirect, DNS result, API link, mobile configuration, or JavaScript reference leaves the exact allowlist.
- The next exploitation step would require persistence, destructive action, bulk access, internal network scanning, credential reuse, social engineering, or another person's session.

### 1.2 Universal prohibitions

Do not:

- Perform DoS/DDoS, resource exhaustion, large payload, regex backtracking, decompression bomb, fork bomb, queue flooding, storage exhaustion, or cost-amplification testing.
- Run high-volume scanners, default-concurrency crawlers, unrestricted fuzzers, mass port scans, password spraying, credential stuffing, OTP guessing, or rate-limit bypass campaigns.
- Use compromised accounts for post-authentication testing.
- Create, modify, or delete data through another person's account or authorization context.
- Exfiltrate, bulk-download, index, or retain sensitive data.
- Test third-party SaaS merely because an in-scope application links to it.
- Publicly disclose program findings or partial details when disclosure is forbidden.
- Include unredacted PII, live credentials, reusable tokens, or full secrets in notes, screenshots, videos, or reports.

### 1.3 Accidental exposure incident protocol

If another user's data or a live third-party secret appears unexpectedly:

1. Do not repeat the request, paginate, navigate further, download the object, or test another identifier.
2. Record only the timestamp, request/correlation ID, endpoint, status, and the minimum redacted field needed to establish the issue. Avoid screenshots if metadata is sufficient.
3. Do not place the material in ordinary notes, AI tools, public paste sites, third-party telemetry, or OAST systems.
4. Quarantine any unavoidable raw evidence in encrypted local storage with restricted access.
5. Notify the program promptly through YesWeHack and follow triager instructions for retention or secure deletion.
6. In the report, state exactly what was observed, what was not accessed, and that testing stopped immediately.

### 1.4 Production technique tiers

| Tier | Meaning | Examples |
|---|---|---|
| **A — default** | Manual, low-request, own-account testing | Browser mapping, Burp Repeater, A/B authorization checks on owned objects, static APK/JS/SDK review |
| **B — conditional** | Use only when current rules permit and the test is tightly bounded | Single-endpoint scripted replay, two-request race check on a reversible owned action, OAST callback to researcher infrastructure |
| **C — isolated-target approval only** | Never on shared production. Use only on a program-provided isolated target with exact written approval for the asset, technique, window, request budget, monitoring, and rollback | Request smuggling/desync, shared-cache poisoning, internal/metadata probing, container escape/host access, broad race testing, active service scanning |
| **D — do not perform** | Explicitly forbidden, intrinsically unsafe, or lacking an isolated program-provided target | DoS, destructive tests, real-fund manipulation, mass scanning, credential attacks, data dumping, persistence, Tier-C techniques on shared production |

---

## 2. Research Identity and Separation

### 2.1 Superbank registration identity

Use the program-linked YesWeHack alias where the registration flow supports it:

```text
inventashif-ywh-2a3528d70f9d0d2d@yeswehack.ninja
```

Superbank permits self-registration through its Android/iOS applications and permits an existing personal account. Never fabricate identity information or bypass KYC. Create a second account only if the program rules and the bank's legitimate onboarding rules permit it. If two controlled identities are unavailable, request test accounts rather than using another person's account.

### 2.2 Verda mandatory User-Agent

Every request to a Verda in-scope asset must append:

```text
verda-publicbb
```

Example:

```http
User-Agent: Mozilla/5.0 (...) verda-publicbb
```

Apply it to the browser, Burp, Playwright, curl, SDK tests, scripts, and every permitted automation path. **Append** the token; do not accidentally remove required browser compatibility text.

### 2.3 Isolation

Maintain separate browser profiles, Burp projects, cookie jars, environment files, API clients, storage states, notes, and OAST identifiers for each program. Never send the Verda marker, Superbank tokens, or one program's credentials to the other program.

---

## 3. Working Scope and Policy Snapshot

This section is the working snapshot supplied to this playbook; it is **not independently authenticated as the current program text**. Before testing, complete and hash the following record from the authenticated YesWeHack page:

| Program | Official program URL/ID | Retrieved at (UTC) | Saved snapshot | SHA-256 | Policy revision/status |
|---|---|---|---|---|---|
| Verda | `RECORD_FROM_YESWEHACK` | `YYYY-MM-DDThh:mm:ssZ` | `rules/verda-YYYYMMDD.*` | `RECORD_HASH` | `REVALIDATE` |
| Superbank | `RECORD_FROM_YESWEHACK` | `YYYY-MM-DDThh:mm:ssZ` | `rules/superbank-YYYYMMDD.*` | `RECORD_HASH` | `REVALIDATE` |

Keep four policy concepts separate:

1. **Authorized assets:** where active testing may occur.
2. **Prohibited testing:** techniques/actions that must not be performed even on an in-scope asset.
3. **Qualifying classes:** findings the program says it accepts.
4. **Non-qualifying findings:** generally not rewardable/reportable alone; this does not override prohibited-testing rules or expand scope.

The current YesWeHack page and triager instructions always take precedence.

### 3.1 Verda — exact allowlist

| Asset | Type | Value | Supplied reward range (Low / Medium / High / Critical) |
|---|---|---:|---:|
| `verda.com` | Web application | Medium | €100 / €300 / €1,200 / €2,000 |
| `console.verda.com` | Web application | Critical | €150 / €500 / €2,000 / €3,500 |
| `api.verda.com` | API | High | €150 / €400 / €1,500 / €3,000 |
| `github.com/verda-cloud/sdk-python` | SDK/source code | High | €150 / €400 / €1,500 / €3,000 |
| `inference.datacrunch.io` | Service | High | €150 / €400 / €1,500 / €3,000 |
| `containers.datacrunch.io` | Service | High | €150 / €400 / €1,500 / €3,000 |

Highest-priority asset: `console.verda.com`, followed by `api.verda.com` and their tenant/project authorization boundary.

**Explicit denylist:**

```text
trust.verda.com
docs.verda.com
forum.verda.com
status.verda.com
relay.datacrunch.io
vdp.verda.com
Support Chat Widget
Support Chat functionality
all unlisted domains, subdomains, IPs, and services
third-party SaaS unless the program explicitly authorizes the exact test
```

`https://vdp.verda.com/` is a disclosure fallback, not active-testing scope. A third-party issue that directly compromises an in-scope primary application may be relevant to a report, but this is not permission to test that third party.

**Prohibited testing (supplied rules):** DoS or degradation, high-volume automated scanning, social engineering, destructive or unnecessary data changes, post-authentication testing with a compromised account, bulk/sensitive-data extraction, public or partial disclosure, and unredacted PII. Every Verda request requires the User-Agent marker.

**Qualifying classes (supplied rules):** impactful SQL injection, XSS, RCE, IDOR/BOLA, horizontal or vertical privilege escalation, authentication bypass/broken authentication, business-logic vulnerabilities, LFI/RFI, XXE, SSRF/XSPA, impactful CORS/CSRF, open redirect, and exposed secrets/credentials that affect an in-scope asset.

**Non-qualifying alone (supplied rules):** broken links/social-media hijacking, tabnabbing, missing cookie flags, content/text injection without meaningful impact, clickjacking, DoS, CVEs inside the stated post-patch exclusion period, CVE/open-port/service-version identification without exploitability, social engineering, autocomplete attributes, outdated-browser/platform-only behavior, self-XSS, best-practice-only findings, generic SSL/TLS hygiene, and MITM/physical-access-required scenarios.

**Systemic-issue reward decay in the supplied snapshot:** `100% / 100% / 75% / 50% / 25% / 10%` for successive related reports. Treat this as volatile program-policy data and revalidate it before submission.

### 3.2 Superbank — exact allowlist

| Asset | Type | Value | Supplied reward range (Low / Medium / High / Critical) |
|---|---|---:|---:|
| Android package `id.co.bankfama.android` | Mobile | High | $150 / $400 / $1,000 / $2,000 |
| `https://apps.apple.com/id/app/superbank/id6444720285` | Mobile iOS | High | $150 / $400 / $1,000 / $2,000 |
| `api.super-id.net` | API | High | $150 / $400 / $1,000 / $2,000 |
| `ecosystem-experience.super-id.net` | Web application | Medium | $100 / $300 / $800 / $1,000 |
| `superbank.id` | Web application | Medium | $100 / $300 / $800 / $1,000 |

The following are **not** wildcards:

```text
*.super-id.net
*.superbank.id
```

Only the exact listed hosts are authorized. Mobile traffic to an unlisted backend is scope intelligence only; do not actively test it without scope confirmation.

**Prohibited testing (supplied rules):** DoS/DDoS or degradation, high-volume automated scanning, social engineering, destructive or unnecessary data manipulation, creating/modifying/deleting data through a compromised account, post-authentication testing with another person's compromised account, bulk/sensitive-data extraction, public disclosure, and unredacted PII. Do not manipulate real funds, KYC state, or other users.

**Qualifying classes (supplied rules):** impactful SQL injection, XSS, RCE, IDOR/BOLA, horizontal or vertical privilege escalation, authentication bypass/broken authentication, business-logic vulnerabilities, LFI/RFI, XXE, SSRF/XSPA, impactful CORS/CSRF, and open redirect.

**Non-qualifying alone (supplied rules):** the general exclusions listed for Verda plus missing security headers without a PoC; low-impact login/logout/cart CSRF; missing SPF/DKIM/DMARC; generic session-management issues; stack traces, paths, directory listings, versions, IPs, EXIF, or origin-IP disclosure without impact; CSV injection; generic EICAR/`.exe`/malicious-file upload; missing HSTS; incomplete subdomain-takeover claims; blind SSRF without meaningful proof; rate-limit, brute-force, captcha, user-enumeration, weak-password, spam, or flooding issues; exposed public Maps/Firebase/analytics keys; reset-token leakage only through Referer; secrets belonging only to third-party assets; pre-account-takeover OAuth claims; GraphQL introspection alone; task hijacking; self-crash; missing pinning, obfuscation, root/jailbreak detection, or anti-debugging; unencrypted local databases/preferences; EOL/rooted/jailbroken-only exploits; and generic Android/iOS platform vulnerabilities. Client hardening bypasses may be used only as a testing aid to discover a qualifying backend flaw.

**Systemic-issue reward decay in the supplied snapshot:** `100% / 100% / 75% / 50% / 25% / 0%` for successive related reports. Treat this as volatile program-policy data and revalidate it before submission.

### 3.3 Employment exclusions

Do not participate if prohibited by the current program terms. The supplied terms exclude current/former Verda employees or contractors for Verda and current/former employees or contractors of Superbank, Grab, OVO, GxS, or GxB for Superbank.

---

## 4. Workspace, Evidence, and Scope Guard

### 4.1 Project layout

```text
bugbounty/
├── superbank/
│   ├── rules/                 # dated program snapshots
│   ├── scope/                 # exact allow/deny lists
│   ├── recon/{dns,urls,js,endpoints}/
│   ├── burp/
│   ├── playwright/
│   ├── mobile/{apk,decoded,jadx,mobsf,dynamic}/
│   ├── api/
│   ├── auth/
│   ├── evidence/
│   ├── findings/
│   └── reports/
└── verda/
    ├── rules/
    ├── scope/
    ├── recon/{dns,urls,js,endpoints,sdk}/
    ├── burp/
    ├── playwright/
    ├── api/
    ├── auth/
    ├── evidence/
    ├── findings/
    └── reports/
```

Protect this directory as sensitive. Encrypt it at rest where possible. Do not commit raw tokens, cookies, APK account data, Burp projects, or evidence to a public repository.

### 4.2 Exact scope files

```text
# verda-allow.txt
verda.com
console.verda.com
api.verda.com
inference.datacrunch.io
containers.datacrunch.io

# verda-deny.txt
trust.verda.com
docs.verda.com
forum.verda.com
status.verda.com
relay.datacrunch.io
vdp.verda.com

# superbank-allow.txt
api.super-id.net
ecosystem-experience.super-id.net
superbank.id
```

The GitHub SDK repository and mobile store/package identifiers belong in typed scope records rather than HTTP hostname lists.

### 4.3 Redirect-safe scope guard

Any script must:

1. Parse and normalize the URL.
2. Reject userinfo, malformed hosts, wildcard suffix assumptions, and non-HTTPS URLs unless the exact target behavior requires otherwise.
3. Compare the normalized hostname for an **exact** allowlist match.
4. Disable automatic redirects or validate every redirect hop before following it.
5. Re-resolve and re-check the destination when DNS behavior matters; do not continue to private or unlisted infrastructure.
6. Add the Verda User-Agent marker only to Verda requests.
7. Log timestamp, method, URL, test-case ID, account label, and response metadata without live secrets.

Illustrative Python guard:

```python
from urllib.parse import urlsplit

PROGRAM_HOSTS = {
    "verda": {
        "verda.com", "console.verda.com", "api.verda.com",
        "inference.datacrunch.io", "containers.datacrunch.io",
    },
    "superbank": {
        "api.super-id.net", "ecosystem-experience.super-id.net", "superbank.id",
    },
}

def checked_request(session, program, method, url, **kwargs):
    if program not in PROGRAM_HOSTS:
        raise ValueError(f"unknown program: {program!r}")

    parsed = urlsplit(url)
    if parsed.scheme.lower() != "https":
        raise ValueError("only HTTPS URLs are allowed")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("URL userinfo is forbidden")
    try:
        port = parsed.port  # Reject malformed/out-of-range ports.
    except ValueError as exc:
        raise ValueError("invalid URL port") from exc
    if port not in (None, 443):
        raise ValueError("non-default port requires a separately authorized service record")
    if not parsed.hostname:
        raise ValueError("missing URL hostname")

    try:
        host = parsed.hostname.rstrip(".").encode("idna").decode("ascii").lower()
    except UnicodeError as exc:
        raise ValueError("invalid IDNA hostname") from exc
    if host not in PROGRAM_HOSTS[program]:
        raise ValueError(f"blocked out-of-scope host: {host!r}")

    headers = dict(kwargs.pop("headers", {}))
    ua_values = [value for key, value in headers.items()
                 if key.lower() == "user-agent"]
    headers = {key: value for key, value in headers.items()
               if key.lower() != "user-agent"}
    ua = ua_values[-1] if ua_values else "Mozilla/5.0"
    if program == "verda" and "verda-publicbb" not in ua:
        ua = f"{ua} verda-publicbb"
    headers["User-Agent"] = ua

    return session.request(
        method, url, headers=headers, allow_redirects=False, timeout=15, **kwargs
    )
```

This guard fails closed for program, scheme, userinfo, malformed/non-default ports, IDNA hostnames, and exact host scope. Redirects remain disabled; if a workflow requires a redirect, validate each hop by calling the guard again. Hostname validation does not authorize direct-IP testing or eliminate DNS-rebinding/time-of-check-time-of-use risk. Where destination IP matters, resolve immediately before connection, reject private/link-local/loopback/unlisted destinations, and still treat the exact hostname allowlist as authoritative. This is a guardrail, not permission to automate testing.

### 4.4 Finding directory

```text
findings/VDA-AUTHZ-001-project-read/
├── hypothesis.md
├── timeline.md
├── request-owner.redacted.txt
├── response-owner.redacted.txt
├── request-nonowner.redacted.txt
├── response-nonowner.redacted.txt
├── poc.md
├── impact.md
└── screenshots/
```

Use synthetic labels such as `ACCOUNT_A`, `ACCOUNT_B`, `OBJECT_A`, and `TOKEN_REDACTED`. Store unredacted evidence only when essential, locally protected, and never in the submitted report unless the platform securely requires it.

---

## 5. Test-Case and Coverage Model

Every hypothesis should have a record:

| Field | Required content |
|---|---|
| ID | Stable identifier, e.g. `WEB-AUTHZ-014` |
| Asset | Exact in-scope asset |
| Role/account | Anonymous, Account A, Account B, legitimate role |
| Preconditions | State needed without rule circumvention |
| Trust boundary | User, tenant, role, service, origin, parser, or device boundary |
| Baseline | Expected normal request/response |
| Mutation | One controlled change |
| Oracle | Status, body field, side effect, OAST hit, or owned-object state |
| Request budget | Small explicit maximum |
| Stop condition | First conclusive result or unexpected impact |
| Cleanup | Only researcher-owned reversible data |
| Evidence | Redacted requests, responses, screenshots, timestamps |
| Eligibility | Why this is reportable under this program |
| Status | `UNTESTED`, `BLOCKED`, `NEGATIVE`, `CANDIDATE`, `CONFIRMED`, `REPORTED` |

A `200` response alone is not proof. Compare semantic outcome, returned owner identifiers, side effects, and object state. Conversely, a `403` may still leak data in its body or complete a side effect.

---

## 6. Tool Policy and Safe Workflow

### 6.1 Default permitted workflow

```text
Passive public intelligence
        ↓
Normal browser through scoped Burp project
        ↓
Manual endpoint inventory
        ↓
Repeater: one mutation at a time
        ↓
Comparer: owner/non-owner and role differences
        ↓
Small scripts only for already-understood, allowed repetitions
        ↓
Manual impact validation
```

### 6.2 Tools by role

| Activity | Preferred tools | Constraint |
|---|---|---|
| Passive DNS/history | certificate transparency, passive `subfinder`, `amass -passive`, `gau`, `waybackurls` | Discovery only; do not probe unlisted assets |
| Web mapping | Browser, Burp Proxy/Logger, DevTools | Normal human interaction rate |
| Request testing | Burp Repeater/Comparer/Decoder | One endpoint and one hypothesis at a time |
| Browser repeatability | Playwright through Burp | Known routes only; low concurrency; exact scope guard |
| JS/source maps | Local download and static grep | Only files served by exact in-scope hosts |
| API | Burp, curl, jq, schema viewers | Do not spray undocumented endpoints |
| Android static | `jadx`, `apktool`, `apkanalyzer`, MobSF local | Static analysis is preferred and low impact |
| Android dynamic | Dedicated test device/AVD, `adb`, Burp, Frida | Bypasses are testing aids, not standalone Superbank findings |
| SDK | Local Git review, Semgrep, dependency audit, unit harness | Do not run untrusted repo code with real secrets |
| OAST | Unique researcher-controlled callback domain | No data exfiltration; correlate a single canary |

### 6.3 Not default-approved

Do not run `nuclei`, Burp active scan, large `ffuf`/dirsearch lists, mass `httpx`, active `amass`, broad `nmap`, SQLMap, NoSQLMap, Commix, automated GraphQL batching, Turbo Intruder, or similar production automation merely because a low-rate flag exists. The supplied rules prohibit high-volume/automated scanning; use these only in labs/local targets or a program-provided isolated target when the current rules explicitly authorize the exact tool and budget. Passive mode and local/static analysis are different from active production scanning.

### 6.4 Burp configuration

- One project and one browser profile per program.
- Target scope contains exact hosts only; never use suffix wildcards.
- Drop out-of-scope requests and prevent third-party extensions from receiving traffic.
- Disable automatic active scanning.
- Use match/replace for Verda so the existing `User-Agent` receives `verda-publicbb`.
- Redact `Authorization`, cookies, OTPs, access/refresh tokens, account numbers, KYC fields, and signed URLs before export.
- Keep Collaborator/OAST interactions uniquely labeled by test-case ID.
- Treat Proxy history as the primary captured HTTP timeline, then reconcile it with native/mobile logs, HTTP/3 or bypassed traffic, WebSocket/SSE events, server correlation IDs, and OAST evidence; AI/MCP analysis may classify traffic but may not autonomously send payloads.

### 6.5 Playwright safety pattern

Use automation to replay known workflows, not discover arbitrary URLs. Keep `storage_state` encrypted and out of source control.

```python
from pathlib import Path
from playwright.sync_api import sync_playwright
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode, unquote
import json, os, re

BASE = "https://console.verda.com"
ALLOWED = {"console.verda.com", "api.verda.com"}
UA = "Mozilla/5.0 (X11; Linux x86_64) verda-publicbb"
seen = []

def parsed_scope_url(url):
    p = urlsplit(url)
    if p.scheme.lower() != "https" or p.username is not None or p.password is not None:
        raise ValueError("unsafe URL scheme or userinfo")
    try:
        port = p.port
    except ValueError as exc:
        raise ValueError("invalid port") from exc
    if port not in (None, 443) or not p.hostname:
        raise ValueError("unauthorized port or missing host")
    host = p.hostname.rstrip(".").encode("idna").decode("ascii").lower()
    return p, host

def in_scope(url):
    try:
        _, host = parsed_scope_url(url)
        return host in ALLOWED
    except (UnicodeError, ValueError):
        return False

def redacted_url(url):
    try:
        p, host = parsed_scope_url(url)
    except (UnicodeError, ValueError):
        return "REDACTED_INVALID_URL"
    # Preserve route shape and parameter names, never likely IDs/tokens, values,
    # userinfo, or fragments. Add target-specific sensitive patterns locally.
    safe_segments = []
    for segment in p.path.split("/"):
        decoded = unquote(segment)
        sensitive = (
            decoded.isdigit() or "@" in decoded or len(decoded) > 20 or
            re.fullmatch(r"[0-9a-fA-F-]{32,36}", decoded) is not None
        )
        safe_segments.append("REDACTED" if sensitive else segment)
    safe_path = "/".join(safe_segments)
    query = urlencode([(name, "REDACTED") for name, _ in parse_qsl(
        p.query, keep_blank_values=True
    )])
    return urlunsplit(("https", host, safe_path, query, ""))

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        user_agent=UA,
        storage_state="ACCOUNT_A.storage.json",  # temporary decrypted file
        proxy={"server": "http://127.0.0.1:8080"},
    )
    page = context.new_page()
    page.route("**/*", lambda route: route.continue_() if in_scope(route.request.url)
               else route.abort())
    page.on("request", lambda req: seen.append({
        "method": req.method,
        "url": redacted_url(req.url),
        "resource_type": req.resource_type,
    }))
    page.goto(f"{BASE}/dashboard", wait_until="domcontentloaded")

    output = Path("captured_requests.redacted.json")
    output.write_text(json.dumps(seen, indent=2))
    os.chmod(output, 0o600)
    browser.close()
```

Do not log request bodies, headers, full query values, fragments, OAuth codes, signed URLs, or PII by default. `storage_state` must be decrypted only for the run into a mode-`0600` temporary file, then securely removed or re-encrypted; rotate/revoke it after testing when appropriate. Do not automate destructive clicks, financial operations, provisioning, broad crawling, or IDOR replay without per-request human review.

### 6.6 Burp MCP / AI-assisted analysis

Use an AI/MCP layer as a constrained analyst, not an autonomous attacker:

```text
Scoped browser/mobile traffic → Burp → redaction/filter → MCP analyst
→ endpoint/object/hypothesis queue → human approval → manual Repeater validation
```

- Default MCP access to read-only history/search/classification tools.
- Filter scope before export and strip credentials, cookies, OTPs, PII, account numbers, KYC, signed URLs, and response bodies that are not needed.
- Keep raw traffic local; do not send program data to a third-party model unless the program and the model/data-handling agreement permit it.
- Let the agent identify IDs, role differences, state transitions, parser candidates, and missing evidence; do not let it spray payloads or send requests automatically.
- Require an explicit test-case ID, exact asset, account, request budget, stop condition, and human approval before any write-capable tool call.
- Record every AI-suggested mutation and actual request separately so generated hypotheses are never mistaken for evidence.

---

## 7. Phase 0 — Session Authorization Checklist

Before every session:

- [ ] Save a dated copy/screenshot of each current program scope and rules page.
- [ ] Diff it against the previous copy.
- [ ] Confirm exact assets, eligible classes, exclusions, disclosure rules, and account rules.
- [ ] Confirm Verda's User-Agent marker is present using a harmless request.
- [ ] Confirm Burp and automation block out-of-scope redirects and hosts.
- [ ] Confirm no stale cookies or tokens from the other program are loaded.
- [ ] Record the current egress IP/VPN profile for attribution; never rotate addresses to evade limits or controls.
- [ ] Define today's hypotheses and a request budget.
- [ ] Define stop conditions and cleanup before sending a mutated request.
- [ ] Confirm evidence storage and screen recording will not capture unrelated PII.

---

## 8. Phase 1 — Passive Reconnaissance and Asset Intelligence

### 8.1 Passive collection

Collect without actively probing discovered infrastructure:

- Certificate transparency names and certificate history.
- Passive DNS and public DNS records.
- Historical URLs from Internet Archive/Common Crawl indexes.
- Public JavaScript filenames and source-map references.
- Public API documentation, OpenAPI/Postman references, mobile store metadata, package names, SDK docs, release notes, and public GitHub code.
- Technology indicators, authentication providers, CDN/WAF patterns, and frontend frameworks from normal in-scope responses.
- APK version code, target/min SDK, signing certificate identity, native ABIs, and publicly retrievable app metadata.

Example passive commands:

```bash
subfinder -d verda.com -silent -all > discovered-verda.txt
amass enum -passive -d verda.com -o amass-verda.txt
printf '%s\n' verda.com console.verda.com api.verda.com | gau > historical-verda.txt
printf '%s\n' api.super-id.net ecosystem-experience.super-id.net superbank.id | gau > historical-superbank.txt
```

These outputs must be passed through exact-host filtering before any request. Do not use `--subs` to turn a narrow scope into a wildcard.

### 8.2 Historical URL triage

Do not request every result. Classify locally by:

- Exact host and scheme.
- Route family and API version.
- Authentication/account lifecycle.
- Object identifiers and tenant/project references.
- Upload/download/export/import behavior.
- OAuth/OIDC/SAML/WebAuthn callbacks.
- GraphQL, WebSocket, gRPC-web, OpenAPI, Swagger, and source-map indicators.
- Cloud/container/inference operations.
- Admin/debug/internal/setup paths.
- Potentially sensitive extensions and backup names.

Interesting names are hypotheses, not findings. A historical endpoint should be requested manually only if its host remains exactly in scope.

### 8.3 JavaScript and source-map analysis

For in-scope bundles, extract:

- API base URLs and versions.
- REST routes, GraphQL operation names/persisted-query hashes, WebSocket topics, gRPC-web service names.
- Feature flags, role names, object model properties, hidden form fields, enum values, and state-machine transitions.
- OAuth client IDs, redirect URIs, scopes, PKCE handling, and post-login return routes.
- DOM sources/sinks, `postMessage` handlers, service worker scope, WebView bridges, and deep-link construction.
- Error telemetry endpoints and third-party boundaries.
- Secret-shaped strings, then classify whether they are public identifiers, restricted keys, or actual credentials.

Do not validate a key against an out-of-scope third party. For an apparent in-scope secret, follow the minimum-validity rule and stop.

### 8.4 No broad active discovery

Because these programs prohibit disruptive/high-volume automation, broad directory brute force, virtual-host brute force, port sweeps, and scanner templates are not part of the default workflow. Prefer routes already observed through the browser, mobile app, SDK, JavaScript, public docs, and history.

---

## 9. Phase 2 — Application and Trust-Boundary Mapping

Build an endpoint inventory from normal use:

```text
ID | ASSET | PROTOCOL | METHOD/OPERATION | PATH/TOPIC
AUTHN | ROLE | TENANT | OBJECT TYPE | OBJECT SOURCE
INPUT LOCATIONS | SIDE EFFECT | SENSITIVITY | NOTES
```

Map at least:

- Anonymous pages and public APIs.
- Registration, verification, login, logout, reset, MFA, device enrollment, recovery, and account linking.
- Profile/security settings and account lifecycle.
- Organizations, tenants, projects, users, roles, invites, memberships, and ownership transfer.
- Billing, credits, subscriptions, invoices, payment setup, and refunds without manipulating real value.
- API key/token create/list/read/rotate/revoke flows.
- Upload, download, preview, import, export, and signed URL flows.
- Container registry/jobs/images/logs and inference models/jobs/endpoints/data sources.
- Banking onboarding, KYC state, beneficiary/payee, account, transaction, statement, notification, and support flows — observe only the actions legitimately available to the researcher.
- REST, GraphQL, WebSocket, server-sent events, gRPC-web, and mobile-only APIs.

For every sensitive action, identify five bindings:

```text
identity → session/token → role → tenant/project → object/action
```

Any binding that appears supplied only by the client becomes a hypothesis.

---

## 10. Phase 3 — Accounts and Test Data

### 10.1 Account matrix

Use only legitimate researcher-controlled accounts and roles:

| Label | Ownership | Tenant | Role | Purpose |
|---|---|---|---|---|
| Account A | Researcher | Tenant A | Normal | Object owner/baseline |
| Account B | Researcher | Tenant B | Normal | Horizontal isolation, if legitimately available |
| Account C | Researcher | Tenant A | Legitimately granted alternate role | Role comparison, if the normal workflow permits |

Do not self-grant a higher role to create Account C. Do not fabricate Superbank KYC data. If only one legitimate account is available, use state transitions, anonymous/authenticated comparisons, and request program test accounts.

### 10.2 Synthetic objects

Name owned test objects with recognizable canaries, for example:

```text
YWH-ACCOUNT-A-PROJECT-001
YWH-ACCOUNT-B-FILE-001
YWH-VDA-INFERENCE-001
```

Use non-sensitive content. Avoid production-like PII, real customer data, copyrighted model data, executable malware, and secrets.

---

# Part II — Advanced Web and API Test Catalog

## 11. Authentication, Recovery, MFA, and Identity

### 11.1 Registration and verification

Test cases:

- [ ] Server enforces required verification before sensitive authenticated actions, not only in the UI.
- [ ] Verification token is bound to the intended account, purpose, and current email/phone state.
- [ ] A token from Account A cannot verify Account B or a different pending change.
- [ ] Resending invalidates or correctly handles prior tokens; replay does not repeat a privileged transition.
- [ ] Changing the destination after issuance does not redirect verification to an attacker-controlled destination.
- [ ] Alternate API versions/mobile routes enforce the same state prerequisites.
- [ ] Duplicate/canonicalized identifiers cannot create account confusion (`case`, whitespace, Unicode, plus-addressing) — do not use this for enumeration or spam.
- [ ] Invitation and registration flows cannot overwrite an existing identity, tenant, or role.

Minimum proof: a controlled state transition on the researcher's own account that the server should reject. Do not mass-register, enumerate users, or send repeated email/SMS.

### 11.2 Login and MFA

- [ ] Direct access to post-MFA endpoints is blocked until the MFA state is completed server-side.
- [ ] MFA challenge is bound to account, login transaction, device/session, purpose, and freshness.
- [ ] A challenge/approval from Account A cannot complete Account B's login.
- [ ] Recovery codes are single-use and invalidated appropriately; test one owned code only.
- [ ] Changing a client-side step, response field, redirect, or route cannot skip MFA.
- [ ] Alternate channels and legacy/mobile API versions enforce equivalent controls.
- [ ] Device trust or “remember this device” tokens cannot be transplanted to another owned account/session.
- [ ] Security-sensitive actions re-authenticate server-side where the application claims they do.

Do not brute-force passwords, OTPs, recovery codes, or rate limits. Superbank explicitly excludes rate-limit/brute-force/captcha findings.

### 11.3 Password reset and account recovery

- [ ] Reset tokens are bound to one user, one purpose, and an appropriate lifetime.
- [ ] Token replay after use or after a newer token is issued does not reset again.
- [ ] Host/forwarded-host input cannot poison reset links; test only with an address and inbox you control.
- [ ] Reset initiation/confirmation does not accept mismatched account IDs, emails, transaction IDs, or sessions.
- [ ] Password change/reset invalidates sensitive sessions or refresh paths when necessary for real account-takeover impact.
- [ ] Recovery does not remove MFA or change contact details without equivalent authorization.
- [ ] API/mobile/web recovery implementations agree on state.

For Superbank, generic session behavior alone is non-qualifying; report only when it forms a concrete account compromise chain.

### 11.4 OAuth 2.0 / OpenID Connect / social or partner login

Map authorization endpoint, token endpoint, callback, issuer, client ID, redirect URI, response mode/type, scopes, `state`, `nonce`, PKCE, and account-linking behavior.

- [ ] Exact redirect URI validation; no parser mismatch, suffix, path, scheme, userinfo, or open-redirect chaining.
- [ ] `state` is present, unpredictable, transaction-bound, and consumed once.
- [ ] OIDC `nonce`, issuer, audience, authorized party, token type, and signature are validated.
- [ ] Authorization code is bound to client, redirect URI, PKCE verifier, session, and single use.
- [ ] Access/ID tokens from one client, issuer, environment, or audience are rejected by another.
- [ ] Scope is enforced at the resource server, not trusted from UI claims.
- [ ] Account linking requires fresh authorization and cannot link an attacker identity to a victim identifier.
- [ ] Email/phone claims used for identity are verified and issuer-trusted.
- [ ] Login CSRF/session swapping cannot authenticate the victim browser into the attacker's account.
- [ ] Tokens/codes do not leak through URLs, Referer, logs, analytics, or out-of-scope redirect hops.
- [ ] Mobile custom-scheme/App Link callbacks return to the initiating app/session and cannot be hijacked.
- [ ] If PAR/JAR/JARM is used, request objects, `request_uri`, signed authorization responses, issuer/audience, and one-time/freshness semantics bind to the intended client and transaction.
- [ ] If OAuth device flow is used, device/user codes, verification session, polling client, account, and final token remain transaction-bound; do not brute-force codes or accelerate polling.

Use only owned OAuth identities and callbacks. Do not register unauthorized clients or test the identity provider outside scope.

### 11.5 SAML and WebAuthn/passkeys, if present

SAML:

- [ ] Validate signature coverage, issuer, audience, destination, recipient, timing, and assertion-to-session binding.
- [ ] Reject unsigned/partially signed or replayed assertions.
- [ ] Role/group attributes are authorized server-side and cannot be injected through duplicate/wrapped values.
- [ ] IdP-initiated and SP-initiated flows preserve tenant binding.

WebAuthn/passkeys:

- [ ] Registration/authentication challenges bind user, session, relying party, origin, and operation.
- [ ] Challenge replay, ceremony swapping, and cross-account completion fail.
- [ ] Adding/removing a passkey requires appropriate current authorization.
- [ ] Cross-device/QR approval authenticates the browser that initiated the intended ceremony only.

Do not attack an out-of-scope IdP or browser implementation.

---

## 12. Session, Token, and JWT Security

### 12.1 Session boundary tests

- [ ] Anonymous-to-authenticated transition rotates or securely binds the session where fixation would enable takeover.
- [ ] Logout, password/security changes, account disablement, and token revocation affect all relevant access paths consistently.
- [ ] Cookies/tokens are accepted only by their intended domains, clients, tenants, environments, and audiences; intentional SSO sharing remains narrowly scoped and documented.
- [ ] Concurrent sessions do not cause identity mix-ups or cross-account cached responses.
- [ ] Sensitive responses are not stored in shared caches or exposed after logout through application-controlled caching.
- [ ] Browser, mobile, WebSocket, and background refresh sessions agree on account state.

Missing flags or generic session observations alone are non-qualifying under the supplied rules; prove an actual boundary crossing.

### 12.2 JWT/JWS/JWE test matrix

Inspect header and claims without assuming a JWT is vulnerable:

- [ ] Signature is required and verified; altered payload/header is rejected.
- [ ] Algorithm is server-selected/allowlisted; no `none` or symmetric/asymmetric confusion.
- [ ] `iss`, `aud`, `sub`, `exp`, `nbf`, token type, scope, tenant, and client claims are validated for the endpoint.
- [ ] Access token, ID token, refresh token, email-verification token, and reset token are not interchangeable.
- [ ] `kid`, `jku`, `jwk`, `x5u`, or similar key-selection fields cannot cause path traversal, SSRF, untrusted-key acceptance, or key confusion.
- [ ] Duplicate claims/headers and JSON parser differences are rejected when ambiguous, or are parsed deterministically with one security interpretation across every component.
- [ ] Revoked/rotated keys and tokens do not remain privileged beyond an explicitly documented grace period or intended audience.
- [ ] A token issued for one in-scope service is not accepted by another unless explicitly intended and correctly scoped.

Do not brute-force JWT secrets. A weak-secret campaign conflicts with the programs' traffic/credential restrictions. Prefer code/config evidence or a single clearly authorized validation.

---

## 13. Authorization: IDOR/BOLA, BFLA, BOPLA, and Tenant Isolation

This is the highest-priority family for both programs.

### 13.1 Object matrix

For each object type, test every legitimate operation:

```text
CREATE | LIST | READ | UPDATE | DELETE | RESTORE
DOWNLOAD | EXPORT | IMPORT | SHARE | INVITE | TRANSFER
ROTATE | REVOKE | EXECUTE | CANCEL | RETRY | VIEW LOGS
```

Object references may appear in:

- Path segments, query parameters, JSON/form/XML bodies.
- Headers, cookies, GraphQL variables, WebSocket messages, gRPC fields.
- Nested arrays/objects, filenames, signed URLs, storage keys, cursor tokens.
- Numeric IDs, UUIDs, slugs, opaque IDs, hashes, composite keys.

### 13.2 Four-way authorization comparison

For each controlled object:

1. Owner + owner object — baseline success.
2. Non-owner + owner object — should fail without data or side effect.
3. Owner + non-owner route/function — should enforce role.
4. Anonymous/expired/revoked context + owner object — should fail.

Also compare list endpoints, search, autocomplete, exports, counts, error messages, audit logs, notifications, and side-channel metadata. Do not enumerate unknown IDs; exchange IDs only between researcher-controlled accounts.

### 13.3 BFLA/vertical privilege escalation

- [ ] Directly call hidden/admin/role-specific functions observed in client code or normal role traffic.
- [ ] Change HTTP method, content type, route version, GraphQL operation, or gRPC method while retaining the same harmless owned object.
- [ ] Test multi-step workflows where the first step is checked but confirmation/execution is not.
- [ ] Confirm server ignores client-supplied role, permission, approval, ownership, or status fields.
- [ ] Check bulk endpoints and background-job endpoints for missing function authorization.
- [ ] Check export/report/download operations separately from UI visibility.

### 13.4 BOPLA/excessive property exposure and mass assignment

Build a field matrix from create/read/update/admin models:

```text
FIELD | readable by role? | writable by role? | server-controlled? | observed endpoints
```

Candidate fields include `role`, `permissions`, `owner_id`, `user_id`, `tenant_id`, `project_id`, `status`, `verified`, `approved`, `balance`, `credit`, `scope`, `is_admin`, and nested relationships.

- [ ] Add one server-controlled field to a harmless owned-object request.
- [ ] Test nested and array properties, aliases/casing, `null`, duplicate keys, and merge/patch semantics.
- [ ] Compare POST/PUT/PATCH, form/JSON, and old/new API versions.
- [ ] Confirm sensitive fields are not returned to roles that do not need them.

Never modify real financial, KYC, billing, approval, or privileged state. A harmless marker field or clearly reversible owned-object property should prove binding behavior; seek triager guidance if privilege impact cannot be shown safely.

### 13.5 Signed URLs and indirect references

- [ ] URL is bound to object, operation, method, content type, and appropriate lifetime.
- [ ] Changing path, bucket/key, query, filename, response headers, or object ID invalidates the signature.
- [ ] Revoked/deleted membership removes access where expected.
- [ ] A URL for upload cannot be reused for download or another object.
- [ ] Redirects do not leak signatures to third parties.

Use only owned objects; do not test guessed storage keys.

---

## 14. Business Logic and State Machines

Model each important workflow as:

```text
state + actor + prerequisite + invariant → permitted transition → side effects
```

### 14.1 General scenarios

- [ ] Skip, reorder, repeat, or directly call later steps.
- [ ] Reuse single-use approvals, invites, links, quotes, uploads, exports, or confirmation objects.
- [ ] Change object/tenant/actor between initiation and confirmation.
- [ ] Change a value after server calculation but before commit.
- [ ] Omit required fields; use duplicate keys, empty/null/negative/boundary values only when harmless.
- [ ] Compare browser/mobile/API versions and asynchronous worker behavior.
- [ ] Test stale tabs, concurrent sessions, expired state, rollback, cancel, retry, and recovery.
- [ ] Confirm server recalculates security-sensitive totals, scopes, ownership, and status.
- [ ] Test invite acceptance, role change, membership removal, ownership transfer, and resource lifecycle using controlled accounts.
- [ ] Test archive/delete/restore and soft-deleted-object authorization on owned data.

### 14.2 Banking safety overlay

Do not alter balances, settlement state, KYC approval, loan/credit state, limits, beneficiaries belonging to others, or real transfers. For financial workflows:

- Prefer preview/quote/validation stages and sandbox-like values exposed by the normal app.
- Do not attempt negative-value, precision, currency, duplicate-transfer, refund, or race proofs if they could move money or create liability.
- If a logic flaw appears capable of financial impact, stop before execution and report the pre-commit evidence, or request a safe test mechanism.

### 14.3 Verda cost/compute safety overlay

Do not provision meaningful paid compute, bypass quotas at scale, run cryptocurrency workloads, consume another tenant's resources, or create service load. Demonstrate with metadata/state on the smallest researcher-owned resource, then stop.

---

## 15. Race Conditions and Concurrency

Race-condition labs often use many synchronized requests; that is incompatible with these production restrictions by default.

### 15.1 Safe eligibility gate

Only test when all are true:

- The operation is idempotent or fully reversible on a researcher-owned object, and the rollback was verified first.
- It sends no messages, triggers no external/background fan-out, moves no money, creates no paid resource, and cannot affect availability.
- Normal sequential baselines have been recorded.
- The initial concurrency budget is at most two requests and the current program rules explicitly permit the bounded test.

### 15.2 Candidate invariants

- Single-use token/approval consumed once.
- One owner or role transition at a time.
- Idempotency key produces one effect.
- Quota/credit checked atomically — observe only where no real value is consumed.
- Invite/membership state cannot be accepted and revoked inconsistently.
- Object cannot be updated after deletion/cancellation.
- API key rotation does not leave both old and new keys privileged beyond the documented overlap/grace period.

Use a two-request proof first and stop on an anomaly. If the safe eligibility gate is not met, do not perform live concurrency testing. Turbo Intruder, larger synchronized batches, limit-overrun attempts, and resource/cost races are Tier D on shared production and may be used only on a program-provided isolated target under Tier-C controls.

---

## 16. REST and General API Testing

Cross-reference the OWASP API Security Top 10:

1. BOLA.
2. Broken authentication.
3. Broken object property-level authorization.
4. Unrestricted resource consumption — **do not production-test through exhaustion**.
5. Broken function-level authorization.
6. Unrestricted access to sensitive business flows — assess manually without automation abuse.
7. SSRF.
8. Security misconfiguration with demonstrated impact.
9. Improper inventory/version management.
10. Unsafe consumption of third-party APIs.

### 16.1 API inventory and differential tests

- [ ] Compare documented vs frontend/mobile-used operations.
- [ ] Compare `/v1`, `/v2`, legacy, alternate host paths, and content types only when exact host is in scope.
- [ ] Test missing, expired, malformed, wrong-audience, wrong-scope, and revoked authentication.
- [ ] Compare GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS only on safe operations; method switching must not trigger destructive behavior.
- [ ] Compare JSON, form, multipart, and XML only where the server advertises or accepts them.
- [ ] Test duplicate parameters/keys and query/body precedence with harmless values.
- [ ] Test unknown fields, nested objects, arrays, and partial updates.
- [ ] Check list filters, sort, search, pagination, cursors, expansions, sparse fields, and includes for authorization/data leakage.
- [ ] Check batch/bulk endpoints: every inner operation needs authorization and atomic error handling.
- [ ] Check asynchronous jobs: create/status/result/cancel/download each needs ownership checks.
- [ ] Check error responses for data and side effects, not just status codes.
- [ ] Confirm idempotency keys are scoped to user, endpoint, payload, and appropriate time window.

Do not turn resource-consumption or sensitive-business-flow categories into load testing or automated abuse.

### 16.2 Server-side parameter pollution and parser discrepancies

- [ ] Identify endpoints that construct requests to internal APIs from user input.
- [ ] Test one harmless duplicate/nested/delimiter variation and compare behavior.
- [ ] Check path/query/body precedence and URL decoding exactly once per hypothesis.
- [ ] Compare proxy, application, framework, and downstream interpretation using an owned object.

Do not use parser discrepancies to route to internal or unlisted systems on shared production. Such routing tests require a program-provided isolated target under the Tier-C controls.

---

## 17. GraphQL

Introspection alone is explicitly non-qualifying for Superbank and is normally only recon elsewhere.

- [ ] Locate endpoint and accepted methods/content types from normal traffic.
- [ ] Inventory operations from bundles, mobile code, errors, and permitted introspection.
- [ ] Test authorization on every resolver, node lookup, nested relationship, mutation, subscription, and file/signed-URL field.
- [ ] Replace only controlled IDs in variables; do not enumerate global IDs.
- [ ] Check aliases/fragments do not bypass field authorization or produce excessive sensitive fields.
- [ ] Check mutation input for mass assignment and server-controlled properties.
- [ ] Check error objects/extensions for sensitive data with actual impact.
- [ ] Check persisted queries: hash/operation binding and authorization must remain server-side.
- [ ] Check GET-based mutations and simple content types for impactful CSRF.
- [ ] Check subscriptions for authentication at handshake and authorization per event/topic.
- [ ] Revalidate authorization after role/membership/session changes.

Do not use large alias batches, deep recursion, expensive queries, circular fragments, or subscription floods. Those are resource-exhaustion tests.

---

## 18. WebSockets, SSE, and gRPC-Web

### 18.1 WebSockets/SSE

- [ ] Authentication is required at connection/upgrade and revalidated when appropriate.
- [ ] `Origin` and browser credential behavior prevent cross-site WebSocket hijacking where sensitive actions/data exist.
- [ ] Topic/channel/room/object subscriptions enforce tenant and object authorization.
- [ ] Client-supplied user, role, tenant, or channel identifiers are not trusted.
- [ ] Replayed messages and message-type changes cannot repeat single-use actions.
- [ ] Server rejects malformed state transitions without disclosing data.
- [ ] Membership removal/logout/token revocation stops future sensitive events.
- [ ] SSE URLs and resume identifiers do not expose another user's stream.

Use researcher-owned rooms/objects and a few messages only.

### 18.2 gRPC-web/protobuf

- [ ] Extract service/method/message schemas from served descriptors or generated clients.
- [ ] Test per-method authentication and function authorization.
- [ ] Test field-level and nested-object authorization with owned IDs.
- [ ] Compare unary vs streaming behavior and web/mobile gateways.
- [ ] Check unknown/default fields and enum values for state confusion.
- [ ] Check metadata headers and deadlines do not select identity/tenant insecurely.

Do not fuzz binary parsers or stream volume in production.

### 18.3 Webhooks, callbacks, and event delivery

Where observed:

- [ ] Callback registration, test delivery, update, deletion, event selection, and delivery logs enforce tenant/role ownership.
- [ ] Signatures cover the raw canonical payload plus timestamp/event identity; verification rejects stale or replayed events.
- [ ] Signing secrets rotate safely and are not disclosed after creation.
- [ ] Event IDs and idempotency controls prevent duplicate state changes without enabling enumeration.
- [ ] Retries preserve the original authorized tenant/object and do not send to a changed destination unintentionally.
- [ ] Callback destinations follow the SSRF rules in §20 and do not receive unrelated credentials/headers.
- [ ] Incoming partner callbacks do not trust client-supplied account, amount, role, status, or tenant values without server-side verification.

Use only researcher-controlled callback endpoints and synthetic events exposed through normal application functionality. Do not forge third-party financial/identity-provider events.

### 18.4 Cross-origin leaks, service workers, and browser-managed state

- [ ] Cross-origin windows/frames cannot infer sensitive state through response-size/timing, navigation, focus, cache, or error oracles with concrete impact.
- [ ] CORP/COOP/COEP and fetch metadata are assessed as mitigations, not standalone findings; prove a real cross-origin disclosure or action.
- [ ] Service worker registration path, scope, update source, and caches cannot be controlled by untrusted input.
- [ ] Service worker/Cache Storage data is separated across logout and account/tenant switching.
- [ ] Background Sync, push handlers, and cached API responses reauthorize sensitive actions and do not replay under a different account.

Do not perform high-sample timing attacks or cross-origin probing that could create load. Use owned sessions and a small deterministic proof.

---

## 19. Injection Test Catalog

Use a progression: syntax canary → differential behavior → harmless execution proof → stop. Never dump databases, read system files, execute discovery commands, establish shells, or persist access.

### 19.1 SQL injection

Inputs: query/path parameters, JSON, filters, search, sort, report builders, IDs, GraphQL variables, headers used in queries.

- [ ] Single-character syntax change produces a repeatable differential response.
- [ ] Paired true/false predicates produce semantic differences.
- [ ] Safe, short timing pair is repeatable without creating load; avoid long delays and repeated sampling.
- [ ] Second-order behavior is checked only through owned records and normal later use.
- [ ] Error messages establish backend query influence without extracting data.
- [ ] Alternate encoding/content type/API version does not change validation.

Minimum proof: controlled boolean or minimal time differential. Do not enumerate schema, users, tables, files, or data.

### 19.2 NoSQL/JSON operator injection

- [ ] Strings remain strings; object/array/operator values are rejected where scalar input is expected.
- [ ] Duplicate keys and nested properties do not alter authentication/filter semantics.
- [ ] Regex/operator behavior is tested with bounded harmless values, never expensive expressions.
- [ ] Boolean differential uses only owned/known records.
- [ ] JavaScript-like query execution is not inferred without a safe proof.

Do not use ReDoS patterns or broad record extraction.

### 19.3 OS command injection

Candidate sinks: diagnostics, conversions, filenames, repository/URL operations, model/container commands, export tools.

- [ ] Start with inert metacharacter/error behavior.
- [ ] If permitted, prove only with a harmless deterministic marker such as an application-visible `printf` result or one unique OAST callback.
- [ ] Test argument injection separately from shell metacharacters.
- [ ] Check asynchronous worker output/logs on researcher-owned jobs.

Never run reconnaissance commands, access files, spawn a shell, create persistence, or pivot.

### 19.4 Server-side template injection

- [ ] Use harmless arithmetic/string expressions to distinguish rendering from reflection.
- [ ] Identify template context/engine from safe errors only.
- [ ] Confirm sandbox/object exposure without reading secrets or invoking system functions.
- [ ] Test stored templates only in researcher-owned content.

Stop once server-side evaluation is established. Do not escalate to RCE unless the program requests a minimal follow-up.

### 19.5 LDAP, XPath, ORM/RSQL, and expression-language injection

- [ ] Identify structured filter/search syntax from normal behavior.
- [ ] Use paired harmless predicates against owned known records.
- [ ] Check escaping, type coercion, and nested filter objects.
- [ ] Check Spring/SpEL or framework expression sinks only when technology and behavior support the hypothesis.

No broad directory search, user enumeration, or data extraction.

### 19.6 CRLF, header, and email injection

- [ ] Input cannot create a second response/request header.
- [ ] Redirect/download filenames do not split headers.
- [ ] Forwarded headers and host overrides do not alter security links, tenant routing, or cache identity.
- [ ] Email display names/subjects cannot add recipients or headers; use only researcher-owned inboxes.
- [ ] Log injection has concrete security impact beyond cosmetic entries.

Avoid sending mail/SMS to third parties.

---

## 20. SSRF, URL Fetchers, XXE, and Unsafe API Consumption

### 20.1 SSRF candidate inventory

Look for webhooks, URL import, avatar/image fetch, previews, PDF/rendering, repository/model/data import, OAuth metadata, callback validation, feed parsers, container/inference data sources, and SDK-configurable base URLs.

### 20.2 Safe SSRF progression

1. Researcher-controlled HTTPS endpoint with a unique token.
2. Confirm one server-originated callback and record method/headers without collecting credentials.
3. Test redirect handling between two researcher-controlled URLs.
4. Test URL parser validation with non-routable/harmless variants, avoiding private services.
5. Stop and report if server-side fetching is proven with meaningful impact. Do not attempt internal, link-local, cloud-metadata, or port-probing confirmation on shared production; such work is allowed only in a program-provided isolated target under the Tier-C approval controls.

- [ ] Scheme allowlist and redirect revalidation.
- [ ] DNS/IP validation at connection time and after redirects.
- [ ] Credentials/headers are not forwarded to untrusted destinations.
- [ ] Response content is not reflected into a sensitive parser or browser context.
- [ ] Tenant-controlled webhooks cannot reach privileged internal services.
- [ ] Third-party API responses are treated as untrusted and authorization decisions are not delegated blindly.

Do not scan internal ports/hosts, access cloud metadata, target link-local/private addresses, or exfiltrate response data on shared production. Internal or metadata probing is permitted only in a program-provided isolated environment under the Tier-C controls. Superbank lists blind SSRF without proof as non-qualifying; do not compensate with risky internal probing.

### 20.3 XXE/XML/XInclude

Candidate inputs: SOAP/XML APIs, SVG/Office uploads, SAML, XML content-type alternatives, import/export parsers.

- [ ] External entities are disabled.
- [ ] A single OAST entity callback can establish parsing when permitted.
- [ ] XInclude and transformation features are not unexpectedly enabled.
- [ ] File-upload parsers treat XML-based formats safely.
- [ ] XML parser behavior is consistent across API versions.

Do not read local files or use entity expansion. Entity expansion is DoS.

---

## 21. File, Path, Archive, and Document Handling

### 21.1 Upload lifecycle

Map initiate → signed upload → finalize → scan/process → preview → download → share → delete.

- [ ] Authorization on each stage and object ownership.
- [ ] Filename, extension, MIME, magic bytes, and content-disposition handling.
- [ ] Stored XSS/client execution when viewed by a different controlled role, not self-XSS.
- [ ] Server-side parser behavior using inert canaries.
- [ ] Upload location is non-executable and isolated.
- [ ] Replacing an object, changing metadata, or reusing a signed URL cannot cross ownership.
- [ ] Processing jobs/results/logs inherit correct tenant binding.

Superbank excludes generic malicious-file/EICAR/executable-upload findings. Pursue only concrete account/API/security impact.

### 21.2 Path traversal/LFI/RFI

- [ ] Download/preview/export paths cannot escape the owned object namespace.
- [ ] Encoded, normalized, mixed-separator, absolute, and archive-entry paths resolve safely.
- [ ] Static-file aliases and framework routes agree on normalization.
- [ ] File identifiers are authorized independently of path secrecy.
- [ ] Remote include behavior is not tested against third parties.

Use an application-created harmless researcher-owned canary as the target. Do not read system files or other users' files.

### 21.3 Archive extraction and generated documents

- [ ] ZIP/TAR entries cannot write outside a researcher-owned extraction area.
- [ ] Symlinks/hardlinks are rejected or safely handled.
- [ ] Generated CSV/PDF/HTML/Office documents do not execute attacker content across a trust boundary.
- [ ] HTML-to-PDF/image processors do not fetch arbitrary URLs or local files.
- [ ] Metadata and hidden layers do not leak other users' data.

CSV/formula injection is explicitly non-qualifying for Superbank; do not report it alone.

---

## 22. XSS, DOM, postMessage, and Browser Trust Boundaries

### 22.1 XSS workflow

For each input, record source → transformations → sink → execution context → affected principal.

- [ ] Reflected HTML/attribute/JavaScript/URL/template contexts.
- [ ] Stored content viewed by a second researcher-controlled account/role.
- [ ] DOM sources: URL, fragment, referrer, storage, messages, API responses.
- [ ] Sinks: HTML insertion, script evaluation, navigation, template compilation, dangerous URL assignment.
- [ ] Framework-specific escaping and hydration/client rendering.
- [ ] CSP/Trusted Types are defense-in-depth; demonstrate actual execution rather than only policy weakness.
- [ ] Service worker or persistent client behavior only when a safe own-origin proof is possible.

Self-XSS is non-qualifying. A proof should show execution in another controlled security context or a meaningful chain. Use a benign marker such as setting a DOM attribute; do not steal cookies/tokens or send victim data out of band.

### 22.2 postMessage and cross-window communication

- [ ] Receiver validates exact `event.origin` and, where needed, `event.source`.
- [ ] Message schema and action authorization are enforced.
- [ ] Sensitive messages use explicit target origins, not `*`.
- [ ] Message data cannot reach HTML, script, navigation, storage, or privileged action sinks unsafely.
- [ ] Embedded frames/popups cannot confuse account or tenant state.

Use researcher-controlled origins and accounts only.

### 22.3 Client-side prototype pollution and DOM clobbering

- [ ] Query/JSON/storage inputs cannot modify inherited properties.
- [ ] Dangerous keys such as prototype/constructor paths are blocked recursively.
- [ ] Identify an actual gadget and security impact; pollution alone is not enough.
- [ ] DOM named properties cannot override trusted configuration or security-sensitive references.
- [ ] Server-side prototype hypotheses use harmless reflected/status behavior only.

Do not attempt server-side RCE gadget chains in production without explicit permission.

---

## 23. CSRF, CORS, Clickjacking, and Cross-Origin Controls

### 23.1 CSRF

Prioritize email/security changes, API-key lifecycle, account configuration, role/invite/project changes, and other meaningful state changes.

- [ ] Authentication cookies are automatically sent cross-site for the tested request context.
- [ ] CSRF token is required, session-bound, purpose-bound, and validated regardless of method.
- [ ] Origin/Referer validation handles absent/malformed values safely.
- [ ] Content-type and method switching cannot reach the same action.
- [ ] SameSite assumptions are not defeated by same-site sibling behavior; do not test out-of-scope siblings.
- [ ] GraphQL GET/simple-content mutations and WebSocket handshakes receive equivalent protection.

Use only owned accounts and reversible actions. Login/logout or low-impact CSRF is excluded by Superbank; demonstrate real impact.

### 23.2 CORS

- [ ] Origin matching is exact and does not reflect arbitrary/null/malformed origins.
- [ ] Credentials are allowed only for trusted origins.
- [ ] Preflight and actual responses agree.
- [ ] Sensitive endpoints expose only required methods/headers.
- [ ] Cache variation by `Origin` is correct.
- [ ] An attacker origin can actually read a sensitive response; headers alone are not impact.

PoC must use an origin controlled by the researcher and the researcher's account. Never read another user's response.

### 23.3 Clickjacking

Clickjacking is listed as non-qualifying in the supplied rules. Do not spend time on framing alone. Only retain it as a possible chain when combined with an otherwise qualifying, concrete security action and when the program permits the chain.

---

## 24. Redirects, Host Handling, Caches, and HTTP Parsing

### 24.1 Open redirect

Test `redirect`, `redirect_uri`, `return`, `returnTo`, `next`, `continue`, `callback`, `url`, and navigation sinks.

- [ ] Server/client parsing handles absolute, scheme-relative, encoded, userinfo, slash/backslash, and path-normalization cases safely.
- [ ] Redirect cannot leak tokens/codes or bypass OAuth allowlists.
- [ ] Redirect cannot become an SSRF or trusted-domain phishing/account-takeover chain.

A standalone low-impact redirect may receive low priority; show concrete scope-relevant impact without targeting real users.

### 24.2 Host and forwarding headers

- [ ] `Host` and forwarded host/proto/port values do not poison reset/verification links.
- [ ] Routing does not expose restricted in-scope functionality.
- [ ] Absolute URLs, canonical links, signed links, and tenant selection use trusted configuration.
- [ ] Cache keys include security-relevant host/scheme variations.

Do not virtual-host brute-force IPs or route to unlisted internal services.

### 24.3 Web cache deception/poisoning

Shared-cache testing can affect other users and is **Tier D on shared production**.

Default safe work:

- Inspect cache headers and route normalization on unique, non-sensitive researcher-owned URLs.
- Compare only your own requests with a unique nonce.
- Never place executable or sensitive content into a shared cache.
- Never request another user's cached page.

Do not confirm cache poisoning/deception on a shared production cache. Report passive/self-contained evidence or use only a program-provided isolated target under the Tier-C asset/technique/window/request-budget/monitoring/rollback controls.

### 24.4 Request smuggling/desync and response queue attacks

These techniques can corrupt shared connections, capture other users' traffic, poison caches, or degrade service. They are **Tier D on shared production** for these programs. Practice them in PortSwigger labs. Live confirmation is limited to a program-provided isolated target under the Tier-C controls; otherwise perform passive architecture analysis and report supporting evidence without sending desynchronization probes. This restriction includes HTTP/1 request smuggling, HTTP/2 downgrade/desync, client-side desync, response queue poisoning, pause-based variants, and HTTP/3-to-backend parser discrepancies.

---

## 25. Deserialization, Dynamic Evaluation, and Supply-Chain Inputs

- [ ] Identify serialized formats in cookies, bodies, files, queues, and SDK models.
- [ ] Integrity/signature checks cover the complete object and context.
- [ ] Type/class allowlists prevent arbitrary object construction.
- [ ] A harmless property mutation cannot change role/owner/state.
- [ ] YAML, pickle, Java/PHP/.NET/native object formats are not accepted from untrusted sources unsafely.
- [ ] Import/export and job payloads do not trigger gadget behavior.

Do not deploy gadget chains, execute commands, or cause parser crashes in production. Establish unsafe deserialization through harmless state change or code review, then coordinate further proof.

Dependency confusion, package registry attacks, typosquatting, or publishing packages to namespaces used by the target can affect build systems and third parties. Do not perform them without explicit written authorization. Static evidence of an unsafe dependency source can be reported without publishing a package.

---

## 26. Secrets, Information Exposure, and Misconfiguration

Classify exposed material:

| Class | Examples | Action |
|---|---|---|
| Public identifier | analytics ID, OAuth client ID, public Firebase config | Usually not a finding |
| Restricted API key | key with origin/API restrictions | Do not exercise unless it is researcher-owned or the program gives an exact validation procedure |
| Credential/secret | private key, client secret, token, cloud credential | Never log in, exchange, call `whoami`, query permissions, or access data; preserve source-location/type/fingerprint evidence, redact, and report |
| Sensitive data | account/KYC/project/model/log information | Stop immediately; retain only minimum redacted metadata under §1.3 |

Check normal responses, JS/source maps, SDK examples/tests, package artifacts, public Git history, CI configuration, errors, GraphQL fields, mobile resources/native strings, logs, exports, signed URLs, and debug endpoints.

A version banner, stack trace, internal path/IP, directory listing, EXIF data, or origin IP alone is explicitly non-qualifying for Superbank. Require a concrete exploit chain. For Verda, exposed secrets must affect an in-scope asset; do not pivot after validity is established.

---

# Part III — Verda-Specific Advanced Coverage

## 27. Verda Trust Model

```text
User/session
   ↓
Organization / tenant / membership / role
   ↓
Project
   ↓
API key / service credential / billing authority
   ↓
Container image/job or inference model/job/endpoint
   ↓
Artifacts, logs, data sources, outputs, and signed URLs
```

Test every arrow as an independent server-side authorization binding.

## 28. `console.verda.com` and `api.verda.com`

### 28.1 Tenant, project, and membership

- [ ] Organization/project list and direct read are isolated.
- [ ] Invite creation, acceptance, cancellation, resend, and role assignment bind tenant and inviter authority.
- [ ] Removed members lose API, WebSocket, signed URL, and cached access.
- [ ] Ownership transfer and last-owner safeguards cannot be bypassed.
- [ ] Project IDs cannot be swapped during resource creation, cloning, import, or billing operations.
- [ ] Hidden/admin operations found in bundles enforce function authorization.
- [ ] Audit logs, usage, metrics, invoices, and exports enforce tenant scope.

### 28.2 API keys and service credentials

- [ ] Create/list/reveal/rotate/revoke require correct role and fresh authorization where expected.
- [ ] Secret value is shown only at intended creation time.
- [ ] Key scope is enforced by API, project, action, and resource.
- [ ] Revocation propagates to containers/inference/background jobs.
- [ ] A project key cannot select another project through a body/header/path field.
- [ ] Logs, errors, SDK debug output, redirects, or browser storage do not expose full keys.
- [ ] Keys cannot be confused with user/session/other-environment tokens.

Use a disposable researcher-owned key and revoke it after testing.

### 28.3 Billing, credit, quota, and provisioning

- [ ] Client-supplied price, plan, credit, currency, discount, quota, region, or resource parameters are server-validated.
- [ ] Quote/preview is bound to the final request.
- [ ] Retry/cancel/restore does not create duplicate owned resources or charges.
- [ ] Tenant billing visibility and invoice downloads are isolated.
- [ ] Quota checks apply consistently across console/API/SDK.

Do not attempt to obtain free value, exceed quota, create meaningful paid instances, or test races that consume resources. Stop at pre-provision validation evidence.

## 29. `containers.datacrunch.io`

Use only the documented/observed service behavior on the exact host.

- [ ] Registry/job authentication and token audience/scope.
- [ ] Repository/image/tag/digest ownership and tenant isolation.
- [ ] Push/pull/delete/list authorization on researcher-owned minimal artifacts.
- [ ] Signed upload/download URL binding.
- [ ] Cross-project image import/clone references.
- [ ] Job create/status/log/cancel/result authorization.
- [ ] Environment variables, command metadata, logs, crash output, and build artifacts do not leak secrets.
- [ ] Webhook/callback/data-source URLs follow SSRF controls.
- [ ] Image metadata cannot alter another tenant's resource or route.
- [ ] OCI manifest, tag, digest, referrer/signature/SBOM, and registry bearer-token scopes bind repository, tenant, and action correctly.
- [ ] Volume, snapshot, build-cache, artifact, and provenance records enforce project ownership.
- [ ] Exec/terminal/attach/log-stream capabilities require fresh per-resource authorization and cannot cross projects.
- [ ] Service-account/workload credentials are least-scoped, rotate/revoke correctly, and are not exposed in artifacts or logs.
- [ ] SDK/console/container API authorization remains consistent.

Do not attempt container escape, host access, cryptocurrency workloads, privileged mounts, destructive payloads, or attacks on shared infrastructure on production. Container escape/host-access testing is allowed only in a program-provided isolated target under the Tier-C controls. A safe report can often establish the missing control before runtime execution.

## 30. `inference.datacrunch.io`

- [ ] Model, endpoint, deployment, job, dataset reference, output, metrics, and log IDs enforce tenant ownership.
- [ ] Inference/API keys are scoped to project, model, endpoint, and operation.
- [ ] Private model names/configuration/artifacts are not discoverable cross-tenant.
- [ ] Batch job status/result/cancel/download operations authorize independently.
- [ ] Data-source/model-import URLs are SSRF-safe.
- [ ] Streaming responses and WebSocket/SSE channels remain bound to the correct tenant/job.
- [ ] Caching cannot mix prompts, model outputs, or authorization contexts across tenants.
- [ ] Errors/telemetry do not expose prompts, datasets, environment secrets, or other tenant data.
- [ ] Usage accounting and quota checks cannot be bypassed without creating cost.
- [ ] Tool/function/plugin integrations, if any, authorize every invocation, constrain egress, and cannot access secrets or services outside intended scope.
- [ ] RAG/vector-store/embedding indexes, fine-tuning datasets, adapters, checkpoints, and generated artifacts enforce tenant/project ownership independently.
- [ ] System prompts, templates, connectors, retrieval sources, and model configuration do not leak across tenants.
- [ ] Cache keys include tenant, principal, model/version, policy, and relevant authorization context.
- [ ] Service-account/workload credentials and delegated tool tokens are scoped, short-lived, and excluded from prompts, outputs, logs, and traces.

Prompt injection or model-quality behavior alone is not automatically a security vulnerability. Require a crossed authorization boundary, secret/data exposure, unauthorized action, or backend compromise. Use synthetic prompts and non-sensitive data.

## 31. Verda Python SDK Review

Repository: `https://github.com/verda-cloud/sdk-python`

### 31.1 Safe local review

Clone locally, inspect without real credentials, and run static tools in an isolated environment. Review:

- Credential discovery, precedence, storage, logging, exception handling, and redaction.
- Base URL/endpoint overrides and whether auth headers can leak on redirects or to untrusted hosts.
- TLS verification defaults and proxy behavior.
- Request signing, token refresh, tenant/project selection, pagination, retries, and idempotency.
- Deserialization of API responses, YAML/pickle use, archive extraction, temp files, and subprocess calls.
- File permissions and symlink handling for config/token files.
- Debug logging of request bodies, headers, signed URLs, and secrets.
- Dependency pins, build backend, package metadata, release workflow, CI secrets, artifacts, examples, tests, and Git history.
- API/SDK authorization inconsistencies: fields or methods unavailable in the console but accepted by the API.
- SSRF through configurable endpoints, webhooks, imports, or generated URLs.
- Cross-platform path/URL normalization.

### 31.2 Safe validation

Use mocked local servers first. If production validation is necessary, point only at exact in-scope hosts with a disposable researcher-owned key and the mandatory User-Agent marker. Never execute repository code with privileged cloud credentials.

A vulnerable dependency/version alone is non-qualifying unless the SDK's reachable code path and in-scope impact are demonstrated, respecting any CVE grace period.

---

# Part IV — Superbank Android and Mobile/API Coverage

## 32. Android Scope and Reportability Gate

Package:

```text
id.co.bankfama.android
```

The Android client is a path to qualifying mobile/backend impact. Under the supplied Superbank rules, do not report missing pinning, obfuscation, anti-debugging, root/emulator detection, encrypted local storage, task hardening, or other client hardening alone. Do not rely on rooted/EOL-device-only behavior. Use instrumentation only to understand the app and test exact in-scope APIs.

If the APK references an unlisted host, record it but do not actively test that host.

## 33. Acquisition and Reproducibility

For every APK tested, record:

- Official source and retrieval time.
- Package name, app version, version code.
- SHA-256 of APK/split APKs.
- Signing certificate fingerprint and scheme.
- `minSdk`, `targetSdk`, supported ABIs.
- Device/emulator model, Android/API level, patch level.
- Whether the device is rooted/instrumented and whether behavior reproduces on a supported non-rooted device when reportability requires it.

Do not redistribute the APK or extracted proprietary code.

## 34. Android Static Analysis

### 34.1 Manifest and build configuration

- [ ] Enumerate activities, services, receivers, providers, aliases, permissions, intent filters, schemes/hosts/paths, task affinity, backup/data extraction rules, and network security config.
- [ ] Identify every exported component and its required permission.
- [ ] Check `debuggable`, `testOnly`, cleartext settings, custom permissions, shared UID, and legacy storage behavior.
- [ ] Map every exported component to reachable code and a concrete sensitive action/data path.
- [ ] Identify FileProvider roots and path mappings.
- [ ] Record native libraries, dynamic-feature modules, and third-party SDKs.

A manifest flag alone is not a finding. Demonstrate unauthorized account/API/security impact on a supported configuration.

### 34.2 Endpoint, token, and secret inventory

Search resources, bytecode, native strings, assets, and configs for:

- API hosts, WebSocket endpoints, GraphQL operations, gRPC descriptors.
- OAuth client/redirect configuration, deep links, App Links, and custom schemes.
- Token names, keystore aliases, cryptographic parameters, feature flags, environment URLs.
- Firebase/analytics/public keys vs actual privileged credentials.
- Logging statements and error/reporting payloads.
- JavaScript interfaces and WebView URL allowlists.

Do not validate secrets against out-of-scope services.

## 35. Exported Components and IPC

### 35.1 Activities and activity aliases

- [ ] External launch cannot skip login/MFA/onboarding/KYC or open a privileged screen with server-authorized behavior.
- [ ] Extras, data URI, ClipData, nested intents, flags, and serialized objects are treated as untrusted.
- [ ] A privileged internal intent is not forwarded from an exported component without validation.
- [ ] Activity result data does not leak tokens/account data to the caller.
- [ ] Task/back-stack behavior does not expose authenticated content to another app in a meaningful supported-device attack.

Use `adb am start` only against the scoped package and your own account/device. Do not claim UI access when the backend still correctly rejects actions.

### 35.2 Services and bound services

- [ ] Exported service methods require a suitable permission and caller authorization.
- [ ] Binder/Messenger/AIDL commands cannot trigger account or API actions for an unauthorized caller.
- [ ] Binder caller identity is preserved across asynchronous work/delegation and not replaced by the app's own privileged identity before authorization.
- [ ] IntentService/JobService inputs cannot select another user's object or unsafe URL/file.
- [ ] Callback PendingIntents/Binder objects are not exposed to untrusted callers.

### 35.3 Broadcast receivers

- [ ] Exported receivers authenticate the sender for sensitive actions.
- [ ] Broadcast extras cannot change account/session/transaction state.
- [ ] Sensitive broadcasts are explicit/protected and do not leak data.
- [ ] Dynamically registered receivers use the correct exported/not-exported flags and permissions for supported Android versions.
- [ ] Sticky broadcasts or implicit responses do not expose secrets.

### 35.4 ContentProviders and FileProvider

- [ ] URI read/write permissions match the intended data.
- [ ] Path, selection, projection, sort, and MIME handling cannot disclose or modify protected data.
- [ ] `grantUriPermissions` and temporary grants are narrow and revoked appropriately.
- [ ] FileProvider path canonicalization prevents traversal and unintended roots.
- [ ] Provider filenames/metadata are not trusted by downstream file operations.

Use only the app's test data on the dedicated device. Local storage exposure alone is non-qualifying for Superbank unless it enables a concrete supported attack chain.

## 36. Deep Links, App Links, OAuth Callbacks, and Navigation

Inventory every scheme/host/path and test:

- [ ] Verified App Link association and intended custom-scheme use.
- [ ] Authentication/authorization is enforced after navigation, not assumed from the link.
- [ ] Parameters cannot skip workflow stages or select another user's object.
- [ ] Redirect/return URLs cannot open arbitrary WebView content or external apps with secrets.
- [ ] OAuth code/state/PKCE transaction binds to the initiating app session and cannot be replayed or captured by another app.
- [ ] Credential Manager/passkey and Custom Tabs callbacks bind to the intended package, relying party/origin, browser transaction, and account.
- [ ] Sensitive links require confirmation/re-authentication where appropriate.
- [ ] Link canonicalization handles encoding, case, path traversal, duplicate parameters, and nested URLs consistently.
- [ ] Deferred deep links/notifications do not apply stale actions after account switching.

A deep link merely opening a screen is not enough; show unauthorized data/action/account impact using your own account.

## 37. WebViews and Hybrid Content

For each WebView, map allowed origins, navigation callbacks, JavaScript state, bridges, file/content access, mixed content, and external intent handling.

- [ ] Untrusted intent/deep-link input cannot control the loaded URL.
- [ ] Scheme, host, port, userinfo, redirects, and subdomain checks use parsed exact origins.
- [ ] `addJavascriptInterface` methods are minimal and unavailable to untrusted content.
- [ ] JavaScript cannot access native account/token/file functions from an unauthorized origin.
- [ ] File/content URL access and universal access are disabled unless strictly needed.
- [ ] SSL errors are not ignored in release behavior.
- [ ] `shouldOverrideUrlLoading` does not forward dangerous intents or leak tokens.
- [ ] Downloads/uploads and chooser callbacks do not expose unintended files.
- [ ] Web messages, including `WebMessageListener`/message-channel handlers, verify exact allowed origins and source context.
- [ ] Cached/historical content cannot show another account after switching/logout.

Use researcher-controlled pages and data. Do not target third-party content.

## 38. PendingIntents, Notifications, Intents, and URI Grants

- [ ] PendingIntents are immutable unless mutation is necessary.
- [ ] Mutable PendingIntents constrain component, action, data, and extras.
- [ ] Creator identity and one-shot/cancel behavior are appropriate.
- [ ] Notification actions bind to the current account/session/object and reauthorize server-side.
- [ ] Nested/forwarded intents cannot redirect to private components or attacker-controlled URLs.
- [ ] URI grants are narrow, temporary, and not propagated unexpectedly.
- [ ] Account switching does not execute a stale notification action in the new account.

Task hijacking alone is explicitly excluded by Superbank; require a qualifying account/API impact chain.

## 39. Local Data, Logs, Clipboard, Screenshots, and Backups

Inspect only the researcher's dedicated device:

- SharedPreferences, databases, files, cache, external storage.
- Keystore use and token key material.
- Logs, crash reports, analytics payloads, notification text.
- Clipboard, screenshots/recent-task thumbnails, keyboard/autofill surfaces.
- Backup/data extraction behavior.

Questions:

- [ ] Are reusable server credentials exposed to another realistic app/user context on a supported non-rooted device?
- [ ] Does local state allow server-side account/session/authorization compromise?
- [ ] Can tampering with local flags bypass a server control?
- [ ] Are account-switch/logout boundaries respected in caches and files?
- [ ] Do backup and device-to-device transfer rules exclude or correctly rebind credentials, account state, and device-bound keys?
- [ ] Do work-profile, multi-user, cloned-app, and account-switch contexts preserve the intended app and server isolation on supported devices?

Unencrypted local data, hardening gaps, or root-only reads are non-qualifying alone. Report only a demonstrated qualifying chain.

## 40. Android Cryptography and Authentication UX

- [ ] Sensitive server actions do not trust a local `isAuthenticated`, biometric result, device-trust, or KYC-complete flag.
- [ ] Biometric-protected secrets use appropriate keystore authorization and cannot be used without the intended user authentication.
- [ ] Cryptographic keys/nonces/IVs are not hardcoded or reused in a way that enables account/API compromise.
- [ ] Encryption/MAC covers complete context and fails closed.
- [ ] Randomness for security tokens is suitable.
- [ ] Device enrollment and key rotation are bound to the account and server.

A local biometric prompt bypass that reveals no protected server capability is usually insufficient. Trace the backend consequence.

## 41. Android Network and Backend Correlation

Instrumentation/pinning bypass may be used as a test aid, but is not the finding.

Map each app action to:

```text
UI state → Android component → request → token/audience/scope
→ API operation → object/tenant → response → local side effect
```

- [ ] API enforces all states and roles regardless of local UI.
- [ ] Tokens are scoped to correct client/device/account/audience.
- [ ] Device registration and push tokens cannot be reassigned cross-account.
- [ ] Mobile attestation is not the sole authorization control; bypass impact must be a qualifying backend flaw.
- [ ] Logout/account switch clears or invalidates background workers, WebSockets, notifications, and queued requests appropriately.
- [ ] Offline queues do not replay an action under a different account.
- [ ] Refresh and token-exchange endpoints bind device/session/account correctly.
- [ ] Mobile API versions do not expose older authorization behavior.
- [ ] Error/retry behavior does not duplicate sensitive operations.

Actively test only `api.super-id.net` unless another backend is explicitly added to scope.

## 42. Native Code, Dynamic Loading, and Third-Party SDKs

- [ ] Native/JNI boundaries validate lengths, types, file paths, and untrusted data.
- [ ] Dynamic code, DEX, plugins, or WebView content are loaded only from trusted/integrity-checked sources.
- [ ] Update/config mechanisms cannot redirect code/content to untrusted origins.
- [ ] Third-party SDK callbacks/deep links/activities do not expose Superbank account capabilities.
- [ ] JavaScript/native bridges enforce origin and authorization.

Do not fuzz for crashes on production, exploit generic Android/Chromium vulnerabilities, or attack third-party SDK infrastructure. Self-crash and generic platform issues are excluded.

## 43. Dynamic Android Test Run

Use a dedicated supported device or AVD with synthetic/non-sensitive data.

1. Record APK/device hashes and versions.
2. Start Burp capture and label the account/session.
3. Walk registration/login/onboarding normally.
4. Map routes, API calls, tokens, deep links, notifications, background jobs, and WebViews.
5. Reproduce one hypothesis at a time through the UI and Burp Repeater.
6. Compare server behavior with local client behavior.
7. Use `adb`/Frida only to reach code paths or observe arguments; do not treat bypassing client defenses as impact.
8. Stop at first backend boundary violation.
9. Remove test account data/tokens from the device according to normal app controls; do not delete evidence needed for the report.

---

# Part V — Curriculum and Coverage Crosswalk

## 44. PortSwigger Web Security Academy Topic Crosswalk

Use Academy labs to train safely before any production hypothesis. Coverage derived from the Academy's detailed topic index:

| Academy family | Production handling in this playbook |
|---|---|
| SQL injection | §19.1, minimum boolean/time proof; no extraction |
| Cross-site scripting | §22, require non-self impact |
| CSRF | §23.1, meaningful owned action only |
| Clickjacking | Non-qualifying unless a permitted qualifying chain |
| DOM-based vulnerabilities | §22 |
| CORS | §23.2, prove readable sensitive response |
| XXE | §20.3, no files/entity expansion |
| SSRF | §20, controlled callback first |
| HTTP request smuggling/desync | Lab-first; Tier D on shared production; isolated Tier-C target only |
| OS command injection | §19.3, harmless marker only |
| SSTI | §19.4, arithmetic proof only |
| Path traversal | §21.2, owned canary only |
| Access control/IDOR | §13, highest priority |
| Authentication | §§11–12 |
| WebSockets | §18 |
| Web cache poisoning | §24.3, Tier D on shared production |
| Insecure deserialization | §25, no gadget execution |
| Information disclosure | §26, require qualifying impact |
| Business logic | §14 |
| HTTP Host header | §24.2 |
| OAuth/OIDC | §11.4 |
| File upload | §21.1 |
| JWT | §12.2 |
| Prototype pollution | §22.3 |
| GraphQL | §17 |
| Race conditions | §15, two-request safe gate |
| NoSQL injection | §19.2 |
| API testing/parameter pollution | §16 |
| Web cache deception | §24.3, Tier D on shared production |
| Web LLM/AI attack surface | §30; require concrete backend/security impact |
| Essential skills/encoding | Apply to parser analysis, never to evade program controls |

Complete labs locally rather than reproducing aggressive lab exploit steps on production.

## 45. OWASP and Platform Crosswalk

- **WSTG:** information gathering, configuration/deployment, identity, authentication, authorization, session management, input validation, error handling, cryptography, business logic, client-side, and API testing are represented across §§7–26. Use the [OWASP WSTG current web-testing index](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/) to attach the applicable WSTG test ID to each hypothesis.
- **API Security Top 10 2023:** all ten categories are mapped in §16 from the [official OWASP API Security edition](https://owasp.org/API-Security/editions/2023/en/0x00-toc/), with resource-exhaustion and business-flow automation explicitly constrained.
- **MASVS/MASTG:** storage, crypto, auth, network, platform, code, resilience, and privacy-related areas are represented in §§32–43. Attach the applicable [OWASP MASTG Android test](https://mas.owasp.org/MASTG/0x05b-Android-Security-Testing/) and MASVS control to each mobile hypothesis.
- **Android platform guidance:** exported components, deep links, WebViews, storage, intent/URI handling, and platform risks should be checked against the current [Android Developers security-risk index](https://developer.android.com/privacy-and-security/risks).
- **PortSwigger:** §44 maps this playbook to the [current Academy topic index](https://portswigger.net/web-security/all-materials/detailed); use labs only as training and technique references.

Program-policy facts in §3 must be traced only to the locally saved official YesWeHack snapshots recorded in the §3 source matrix, not to methodology sites or public write-ups.

---

# Part VI — Hypothesis Priorities

## 46. Verda Priority Queue

1. `console.verda.com` tenant/project/object authorization.
2. Console/API role and operation mismatch.
3. API key lifecycle, scope, and cross-project use.
4. Invite/membership/ownership state machine.
5. Billing/quote/provisioning validation without consuming value.
6. Container image/job/log/artifact ownership.
7. Inference model/job/result/stream ownership and cache separation.
8. URL import/webhook/data-source SSRF with controlled callback.
9. Signed URL and asynchronous-job authorization.
10. SDK credential handling, endpoint override, redirect leakage, deserialization, and API inconsistency.
11. Injection/client-side classes on mapped, high-value inputs.

## 47. Superbank Priority Queue

1. Android-to-`api.super-id.net` endpoint and state mapping.
2. Authentication/MFA/recovery transaction binding.
3. BOLA/BFLA/BOPLA on account-owned objects and documents.
4. Mobile/web/API state mismatch.
5. Deep-link/OAuth callback/account-linking security.
6. Exported component or WebView chain to qualifying account/API impact.
7. Notification/PendingIntent/offline queue/account-switch confusion.
8. Business-logic state transitions without real funds/KYC manipulation.
9. `ecosystem-experience.super-id.net` authenticated authorization and origin boundaries.
10. `superbank.id` OAuth/redirect/client-side routes with concrete impact.

---

# Part VII — Evidence, Validation, and Reporting

## 48. Candidate Validation Workflow

```text
Observation
   ↓
Rule/scope re-check
   ↓
Clean baseline with owned object
   ↓
Single controlled mutation
   ↓
Repeat once if safe
   ↓
Confirm semantic impact, not status code
   ↓
Stop exploitation
   ↓
Redact evidence
   ↓
Eligibility/duplicate review
   ↓
Report
```

Do not repeatedly exploit a confirmed issue across endpoints or users. A systemic pattern can be described from one or two controlled examples.

## 49. Reportability Gate

- [ ] Asset is exactly in scope today.
- [ ] Testing method complied with current rules.
- [ ] Vulnerability class is eligible or the impact clearly makes it eligible.
- [ ] Behavior is reproducible with researcher-controlled accounts/data.
- [ ] A security boundary is crossed; it is not only a best-practice gap.
- [ ] Concrete confidentiality, integrity, or authorization impact is explained.
- [ ] No unnecessary data was accessed and no service/user was affected.
- [ ] Evidence contains request/response pairs and meaningful state proof.
- [ ] Tokens, secrets, KYC, account numbers, emails, and PII are redacted.
- [ ] Known non-qualifying categories have been addressed explicitly.
- [ ] Steps are deterministic and do not require prohibited tools.
- [ ] Duplicate/systemic relationship was checked in the available program history/Hacktivity.

## 50. Severity and Impact

Lead with the real attacker outcome, prerequisites, affected population, and repeatability. Separate:

- **Primitive:** e.g. missing object authorization.
- **Exploit condition:** e.g. authenticated user with a known controlled object ID.
- **Boundary:** cross-user, cross-tenant, cross-role, origin, device/app, or service.
- **Impact:** data read, unauthorized change, account takeover, secret exposure, code execution, or financial/compute authority.
- **Constraints:** user interaction, object-ID knowledge, role, supported device, or race window.

Do not inflate severity through hypothetical chains that were not safely demonstrated. Include CVSS only if useful/requested, state the version/vector, and allow the program to make the final severity decision.

## 51. Report Template

```markdown
# [Impact] via [Vulnerability] in [Affected Component]

## Summary
One paragraph describing actor, action, boundary crossed, and result.

## Program and Affected Asset
- Program: Verda / Superbank
- Asset: exact in-scope host/package/repository
- Endpoint/operation/component:
- Method/protocol:
- Tested app/API version and timestamp:

## Vulnerability Class
CWE/category and concise root cause.

## Prerequisites
- Researcher-controlled Account A
- Researcher-controlled Account B (if legitimately available)
- Researcher-owned Object A

## Steps to Reproduce
1. Establish the owner baseline.
2. Capture the redacted request.
3. Change only the described authorization/input field.
4. Send the request in the permitted context.
5. Observe the semantic result.
6. Confirm using the owned object/state.

## Proof of Concept
Minimal redacted HTTP/mobile evidence. Mark every changed value.

## Actual Result
Exact observed behavior.

## Expected Result
Expected authorization/validation behavior.

## Security Impact
Concrete confidentiality/integrity/account/tenant impact and realistic prerequisites.

## Safety and Data Handling
State that only researcher-controlled accounts/data were used, no bulk access occurred,
and testing stopped after confirmation.

## Evidence
- Redacted owner/non-owner request and response
- Screenshot/video with PII hidden
- Timestamp/correlation ID/OAST event where applicable
- APK/API/SDK version or commit

## Remediation
Central server-side authorization at every object/function/property operation; bind workflow
state to identity/tenant/purpose; reject untrusted fields; invalidate stale capability URLs/tokens;
and add regression tests matching the reproduction.

## Severity
- Suggested severity:
- CVSS version/vector (optional):
- Rationale and limitations:
```

## 52. Daily Board and Coverage Ledger

### Daily start

- [ ] Scope/rules diffed.
- [ ] Profiles/projects isolated.
- [ ] Verda UA verified.
- [ ] Tokens/test data labeled.
- [ ] Today's request budgets and stop conditions recorded.

### Mapping

- [ ] New normal UI/mobile workflows captured.
- [ ] Endpoint inventory updated.
- [ ] New object types and identifiers mapped.
- [ ] JS/APK/SDK version changes reviewed.
- [ ] Unlisted hosts quarantined as intelligence only.

### High-value testing

- [ ] Authentication transaction bindings.
- [ ] Account A/B object operations.
- [ ] Role/function differences.
- [ ] Property-level read/write controls.
- [ ] Workflow state invariants.
- [ ] Async jobs, signed URLs, streams, logs, and exports.
- [ ] Mobile deep-link/component-to-API chains.

### Closeout

- [ ] Candidate reproduced cleanly once.
- [ ] Unnecessary sensitive data deleted securely from working copies.
- [ ] Credentials/tokens rotated or revoked where appropriate.
- [ ] PII redaction verified.
- [ ] Coverage ledger/status updated.
- [ ] Reportability gate completed.

Suggested ledger:

```text
TEST-ID | ASSET | FEATURE | ROLE | OBJECT | HYPOTHESIS
DATE | REQUEST COUNT | RESULT | EVIDENCE PATH | NEXT ACTION | REPORTABILITY
```

---

# Part VIII — Public Research and Training Sources

The following sources informed and expand this playbook. They are references for training and hypothesis generation, not authorization to run every technique on production.

## 53. Primary methodology references

- [PortSwigger Web Security Academy — all topics](https://portswigger.net/web-security/all-topics)
- [PortSwigger Web Security Academy — detailed learning materials](https://portswigger.net/web-security/all-materials/detailed)
- [PortSwigger Web Security Academy — all labs](https://portswigger.net/web-security/all-labs)
- [PortSwigger API testing](https://portswigger.net/web-security/api-testing)
- [HackTricks web vulnerabilities methodology](https://book.hacktricks.wiki/en/pentesting-web/web-vulnerabilities-methodology.html)
- [HackTricks Android APK checklist](https://book.hacktricks.wiki/en/mobile-pentesting/android-checklist.html)
- [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/)
- [OWASP API Security Top 10 — 2023](https://owasp.org/API-Security/editions/2023/en/0x00-toc/)
- [OWASP Mobile Application Security project](https://owasp.org/www-project-mobile-app-security/)
- [OWASP MASTG Android testing](https://mas.owasp.org/MASTG/0x05b-Android-Security-Testing/)
- [OWASP MASTG deep-link test](https://mas.owasp.org/MASTG/tests/android/MASVS-PLATFORM/MASTG-TEST-0028/)
- [OWASP MASTG IPC exposure test](https://mas.owasp.org/MASTG/tests/android/MASVS-PLATFORM/MASTG-TEST-0029/)
- [OWASP MASTG WebView JavaScript test](https://mas.owasp.org/MASTG/tests/android/MASVS-PLATFORM/MASTG-TEST-0031/)
- [Android Developers — security risk guidance](https://developer.android.com/privacy-and-security/risks)
- [Android Developers — unsafe deep links](https://developer.android.com/privacy-and-security/risks/unsafe-use-of-deeplinks)
- [Android Developers — exported-component access control](https://developer.android.com/privacy-and-security/risks/access-control-to-exported-components)

## 54. Public disclosure pattern mining

Use disclosed reports to study root causes, evidence quality, and remediation patterns. Never copy payloads blindly, target programs outside their rules, or infer that a past disclosure authorizes current testing.

- [YesWeHack Hacktivity](https://yeswehack.com/hacktivity)
- [HackerOne Hacktivity documentation](https://docs.hackerone.com/en/articles/8410358-hacktivity)
- [Public HackerOne report index by vulnerability type](https://github.com/reddelexc/hackerone-reports)
- [Curated Android security resources and write-ups](https://github.com/saeidshirazi/awesome-android-security)

When studying write-ups, extract a reusable pattern:

```text
feature → trust assumption → attacker-controlled input/state
→ missing server/platform check → smallest proof → impact → remediation
```

Do not reproduce report-specific victim identifiers, secrets, proprietary endpoints, or unnecessarily invasive proof steps.

> Content derived from internet sources was paraphrased and reorganized for compliance with licensing restrictions. Follow the links for the original, complete, and current material.

---

## 55. Final Operating Principle

Do not use:

```text
scan everything → collect alerts → submit noise
```

Use:

```text
confirm authorization
→ understand the application and mobile/backend architecture
→ map identities, roles, tenants, objects, and state transitions
→ form one falsifiable security hypothesis
→ test with an owned canary and minimal requests
→ stop at the first conclusive boundary crossing
→ preserve clean redacted evidence
→ submit a reproducible impact-focused report
```

For Verda, the strongest expected research areas are console/API tenant isolation, project/resource authorization, API-key scope, container/inference object ownership, asynchronous jobs, and SDK/API inconsistencies. For Superbank, the strongest expected areas are Android-to-API state correlation, authentication transaction binding, BOLA/BFLA/BOPLA, deep-link/OAuth flows, and mobile component/WebView issues that produce a qualifying backend or account-security impact.
