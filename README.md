# redirect-hub

One Netlify site that 301-redirects every legacy Fernando Labastida domain into
**viralgeniusinstitute.com**.

Built 2026-08-10, implementing `gOS/viral-genius/DOMAIN-CONSOLIDATION-CHECKLIST.md` (2026-08-03).

There is no build step. Netlify serves the repo root and reads `_redirects`.

---

## Why this exists

On 2026-08-10, seven Fernando Labastida domains were live, none redirected, and each made a
different promise. Perplexity, asked *"what is the Viral Genius Framework,"* answered from
**viralgeniusframework.com** — describing the retired VGF 1.0 content-cascade offer — and showed
that domain as the featured source card. Two days earlier it had been one cited source among
several. The wrong answer is consolidating, not fading.

**One Netlify site can serve all the legacy domains** with per-domain rules in a single
`_redirects` file. No hunting down old hosts, no per-domain deploys.

---

## ⚠️ Read before touching DNS

**1 · MX records are sacred.**
`aimarketingcasestudies.com` is the primary email domain (`fernando@aimarketingcasestudies.com`).
Redirecting a *website* means changing **A and CNAME records only**. Never touch MX.
`viralgeniusframework.com` also still receives mail until that Workspace account is retired.

Verify before and after, and compare the output:

```bash
dig MX aimarketingcasestudies.com +short
dig MX viralgeniusframework.com +short
```

**2 · Never let these domains expire.**
A 301 passes accumulated link authority to the destination. That only keeps working while the
domain is registered and pointed here. Letting one lapse throws away every backlink earned since
2009. Redirect forever; renew forever.

**3 · Two things to salvage before the old sites go dark.**
- `getstartupbook.com` — the Joe Pulizzi interview and the **two Spanish-language articles**.
  There is no Spanish content on viralgeniusinstitute.com and there is a Spanish-speaking network.
- `aimarketingcasestudies.com` — confirm the podcast episodes live on a hosting platform and not
  only on that site.

**4 · The VGF Google Drive folder** ("Viral Genius Methodology Documents") is owned by the
`fernando@viralgeniusframework.com` account. Transfer ownership to
`fernando@aimarketingcasestudies.com` **before** that Workspace account is ever cancelled.
This does not block the redirect. It blocks the account cancellation.

---

## Deploy

**Step 1 — push this repo**

```bash
cd ~/Documents/GitHub/redirect-hub
git remote add origin git@github.com:<your-account>/redirect-hub.git
git push -u origin main
```

**Step 2 — create the Netlify site**

Netlify → Add new site → Import from Git → pick `redirect-hub`.
Build command: empty. Publish directory: `.`

**Step 3 — add each domain as an alias**

Site settings → Domain management → Add domain alias. Add, in this order:

1. `viralgeniusframework.com` and `www.viralgeniusframework.com` ← **do this one first**
2. `labastida.com` and `www.labastida.com`
3. `getstartupbook.com` and `www.getstartupbook.com`
4. `strikemarketinginstitute.com` and `www.strikemarketinginstitute.com`
5. `aimarketingcasestudies.com` and `www.aimarketingcasestudies.com` ← **do this one last**

**Step 4 — point DNS at each registrar**

Safest method for every domain, and the *only* acceptable method for the email domains:
leave the nameservers where they are and change records only.

| Record | Value |
|---|---|
| `A` @ | `75.2.60.5` |
| `CNAME` www | `<your-site-name>.netlify.app` |

Do **not** move nameservers to Netlify DNS on any domain that carries email unless you recreate
every MX record inside Netlify DNS first.

**Step 5 — verify**

```bash
./verify.sh
```

Every line should report `301` and a destination on viralgeniusinstitute.com.

---

## After the redirects are live

**Update the schema on viralgeniusinstitute.com.** The Person entity currently declares:

```json
"sameAs": [
  "https://www.linkedin.com/in/flabastida/",
  "https://labastida.com",
  "https://viralgeniusframework.com",
  "https://youxai.live"
]
```

Two of those are about to become redirects. `sameAs` asserts *"these URLs are also me"* — pointing
it at the retired positioning is what told the engines the old story was authoritative. Once the
301s are live, drop the redirected domains and point it at properties that still stand on their
own: LinkedIn, YouTube, youxai.live.

Also worth trimming in the same pass: `knowsAbout` still lists *"content marketing"* and
*"Latin America technology marketing"*. Both true historically, both pulling the entity back
toward the identity being replaced.

**And fix the sitemap declaration.** `robots.txt` points at `/sitemap-index.xml`; the file that
actually resolves with content is `/sitemap-0.xml`. Both return 200, so this is minor, but it is
a one-line fix.

---

## Not redirected, deliberately

**`b2bevents.live`** — a live Substack publication, not a legacy marketing site. It was not in the
2026-08-03 decision table and redirecting it would kill something that is running. It has a
separate problem: only **411 characters of visible text** render without JavaScript, which makes it
effectively invisible to AI crawlers. That is a content-surface decision, not a DNS one.

**`youxai.live`** — live property, appears in the VGI `sameAs` array, out of scope here.

---

## Files

| File | What it does |
|---|---|
| `_redirects` | Every rule. First match wins, so specific paths sit above the wildcards. |
| `netlify.toml` | No-build config plus security headers. |
| `index.html` | Fallback for anyone hitting the hub's own Netlify URL. `noindex`. |
| `verify.sh` | Curls every mapped URL and prints the status and destination. |
