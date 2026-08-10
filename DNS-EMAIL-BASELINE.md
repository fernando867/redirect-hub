# Email DNS baseline — captured before any redirect work

**Captured 2026-08-10 15:58 CDT from a clean lookup.**

⚠️ **Fernando sends and receives mail on four of these domains.** Every record below must survive
the DNS changes. Re-run `./verify.sh` after each registrar edit and compare against this file.

Only two records change per domain: `A @` and `CNAME www`. Everything here stays.


---

## ⚠️ Read this before changing any A record

All five domains run **Google Workspace**. Two consequences.

### Inbound mail is safe

Google routes inbound mail by **MX record only**. The A record has nothing to do with receiving
mail. As long as the MX lines above are untouched, changing `A @` cannot stop mail arriving. That
is the whole reason the A/CNAME-only method is safe.

### But two domains have `+a` in their SPF, and that DOES move

| Domain | SPF | `+a` present | DMARC policy |
|---|---|---|---|
| **viralgeniusframework.com** | `v=spf1 +a +mx include:…dnssmarthost.net ~all` | ⚠️ **yes** | **`p=reject`, `aspf=s`** — strictest |
| **aimarketingcasestudies.com** | `v=spf1 +a +mx include:…dnssmarthost.net ~all` | ⚠️ **yes** | `p=none` — lenient |
| labastida.com | `v=spf1 include:_spf.google.com include:…dnssmarthost.net ~all` | no | `p=quarantine`, `pct=90` |
| getstartupbook.com | `v=spf1 include:_spf.google.com ~all` | no | `p=reject`, `aspf=s` |
| strikemarketinginstitute.com | `v=spf1 include:_spf.google.com ~all` | no | `p=reject`, `aspf=s` |

`+a` means *"the IP in this domain's A record is authorised to send mail for this domain."*

Repoint the A record and that authorisation silently moves from the current web host to Netlify's
load balancer. Netlify never sends mail, so the practical effect is that **anything still sending
mail from the old web server stops being authorised.**

**What that actually breaks:** WordPress form notifications, transactional mail, contact-form
sends — anything the site itself emails. Not Gmail. Never Gmail.

**Why it mostly does not matter here:** once the domain is a redirect, there is no WordPress
sending anything. The exposure only exists if the old site keeps running somewhere and keeps
sending. Check for form notifications before you point each of these two.

**viralgeniusframework.com is the one to watch.** It is first in the redirect order, it carries
`+a`, and its DMARC is `p=reject` with strict alignment. Under `p=reject`, mail that fails
alignment is refused outright rather than sent to spam. Confirm nothing sends from that site
before repointing it.

**Optional cleanup, unrelated to redirects:** once each site is gone, `+a +mx` can be dropped from
those two SPF records, leaving `v=spf1 include:_spf.google.com include:…dnssmarthost.net ~all`.
Tighter, and matches what the other three already do.

### Three domains reference `dnssmarthost.net` in SPF

`labastida.com`, `aimarketingcasestudies.com` and `viralgeniusframework.com` all include a
`*.spf.auto.dnssmarthost.net` mechanism. That is a managed-DNS provider's SPF flattening service.
Find out who runs it before moving anything — if that provider also hosts the zone, the registrar
may not be where these records actually live.

### strikemarketinginstitute.com is already on Netlify

Its `A` is already `75.2.60.5` and `www` is a CNAME to **`strike-marketing-institute.netlify.app`**.
It belongs to a different Netlify project. Netlify will not let two sites claim the same domain —
**release it from that project first**, then add it to `vgi-redirect-hub`. Its DNS is already
correct, so no registrar visit should be needed.

---

## labastida.com

```
MX:
  5 alt1.aspmx.l.google.com.
  1 aspmx.l.google.com.
  10 alt4.aspmx.l.google.com.
  10 alt3.aspmx.l.google.com.
  5 alt2.aspmx.l.google.com.

TXT (SPF / verification):
  "v=spf1 include:_spf.google.com include:labastida.com.spf.auto.dnssmarthost.net ~all"

DMARC:
  "v=DMARC1; p=quarantine; rua=mailto:fernando@labastida.com; pct=90; sp=none"

DKIM (google selector):
  "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAttXBomn6X+Gc2WDS8M3r7spfpsJRahH4+uGzuO6ob7kgu7ctdvY4fCT7qhiyInZCwvzZImreNyK6QxUituIeOwROCb7KZE+jrhmRz/DBHXXwKczdomECwKl8JJvTWOm2HTMLRLIW+2UYzpJqgQXUB+6hDztCYUaiSnJ0CNjYwx+Vw/UxU95pGJfQIMIi7HKuR" "bbfed90v4Y8GTcPE2pJ4TwMUtsc4c5WOPfDSWD63PC6xtOOjkvQ9ub8H88DQHKtVz0YEn+1OdYdK7FkpxpLQGYWnuI8onyoSBS8mGqiYywlTUJqtpXmCa97iDG+cf8tzf9M4LAw5Xhd43gr6x6j5QIDAQAB"

Current A (this is what changes):
  35.209.55.101

Current www:
  35.209.55.101
```

---

## aimarketingcasestudies.com

```
MX:
  10 alt4.aspmx.l.google.com.
  5 alt2.aspmx.l.google.com.
  5 alt1.aspmx.l.google.com.
  1 aspmx.l.google.com.
  10 alt3.aspmx.l.google.com.

TXT (SPF / verification):
  "v=spf1 +a +mx include:aimarketingcasestudies.com.spf.auto.dnssmarthost.net ~all"
  "google-site-verification=jG8olzULP0soDLULUg4tIIBd2oEWLe7P1W-x-LEB3QE"

DMARC:
  "v=DMARC1; p=none;"

DKIM (google selector):

Current A (this is what changes):
  34.174.214.127

Current www:
  34.174.214.127
```

---

## viralgeniusframework.com

```
MX:
  1 smtp.google.com.

TXT (SPF / verification):
  "openai-domain-verification=dv-DnWBX7gephauFvi9shauPMuS"
  "google-site-verification=sXC5CezS7cLlmkCCUJUJeu9GYmyZ5_GvpBRluTYlbSk"
  "v=spf1 +a +mx include:viralgeniusframework.com.spf.auto.dnssmarthost.net ~all"

DMARC:
  "v=DMARC1; p=reject; adkim=s; aspf=s; pct=100; rua=fernando@viralgeniusframework.com; ruf=fernando@viralgeniusframework.com; fo=1; sp=reject"

DKIM (google selector):

Current A (this is what changes):
  34.174.57.27

Current www:
  34.174.57.27
```

---

## getstartupbook.com

```
MX:
  5 alt2.aspmx.l.google.com.
  10 alt3.aspmx.l.google.com.
  10 alt4.aspmx.l.google.com.
  5 alt1.aspmx.l.google.com.
  1 aspmx.l.google.com.

TXT (SPF / verification):
  "v=spf1 include:_spf.google.com ~all"

DMARC:
  "v=DMARC1; p=reject; adkim=s; aspf=s; pct=100; rua=fernando@getstartupbook.com; ruf=fernando@getstartupbook.com; fo=1; sp=reject"

DKIM (google selector):
  "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxzxlnV4IWI1mq8pcrVP0qCXasG+8yOMgamvE1ATpx7hV2pmV1a9hVKu6f/l5d1dbdU6QkZVTxBXK2FJNpDiCVO+qg5vr0wsOvarztYbkLI9GJl5AXXtCueaVZ3oUFHuettDEZiOwDWS1iAHl+4XsuOI0ac1aPAEmagq3MVO8Fazw0LGj5ruKQgPGtJQZk3EWD" "ruENjIKdWwY+C3pHxEIz/OAI5nEJwO8t4JqOKqw7JXjblB+dtSJ+hP4MHClGNaFA9l8loWC0NF5XP8r+Pc7octeI5Z9nyYoGAzeCSneD2lFtigrMvg/OxryFit4JLGN0tD5vcMTLPH8ddKaDJWrpwIDAQAB"

Current A (this is what changes):
  34.174.63.157

Current www:
  34.174.63.157
```

---

## strikemarketinginstitute.com

```
MX:
  10 alt4.aspmx.l.google.com.
  5 alt1.aspmx.l.google.com.
  1 aspmx.l.google.com.
  10 alt3.aspmx.l.google.com.
  5 alt2.aspmx.l.google.com.

TXT (SPF / verification):
  "v=spf1 include:_spf.google.com ~all"
  "google-site-verification=evHyFJ7qlXGZxAfoBBSehaWcJDfinn5_ZVIpYkfchII"

DMARC:
  "v=DMARC1; p=reject; adkim=s; aspf=s; pct=100; rua=fernando@aimarketingcasestudies.com; ruf=fernando@aimarketingcasestudies.com; fo=1; sp=reject"

DKIM (google selector):
  "v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtpdqWqrwkqg4UQGIBk+GdYxdwDoOsPw47m8t7BF0FPvyB6w7LLwUIKnRpkIi4VL8/6R+u8Hi+IEo1Aa26xVEvLC7LqjBkioU12v3AnEJAqyBUYjykGZfFz9SsckwRfayfdT0yRY1PbgZlt36rQ4VeJrGAIBPfmQDv7P3eHSDwZpOCc+ZIBamD/mceXlzhf0sa3M" "QfYZCdKnq0Y6ReIolQibGhAn0n9cPlOKrMLLtgKxFeWiQnJN/O9EuVoFY3LwY3o4GRQgPzKY7UMH2lyBHHNlW25m8M3v0ApXiFdOiXrAy5BxvDawzFuzhp7pOGVD+mdwbDcfL309AgsqrSLgaBwIDAQAB"

Current A (this is what changes):
  75.2.60.5

Current www:
  strike-marketing-institute.netlify.app.
  strike-marketing-institute.netlify.app.
  18.208.88.157
  98.84.224.111
```

---

## 🚨 The DNS zones live at SiteGround. Read this twice.

Confirmed by Fernando 2026-08-10: the registrars delegate to **SiteGround**, which hosts both the
WordPress sites and the **DNS zones** — MX, SPF, DKIM and DMARC included. That is what the
`*.spf.auto.dnssmarthost.net` includes are.

### Where the change actually happens

**Not at the registrar.** In SiteGround: *Site Tools → Domain → DNS Zone Editor.*

Per domain, exactly two edits:

| Record | Change to |
|---|---|
| `A` @ | `75.2.60.5` |
| `CNAME` www | `vgi-redirect-hub.netlify.app` |

Everything else in that zone stays exactly as it is. Nameservers do not move.

### ⚠️ The trap: do not cancel SiteGround

The obvious reason to retire these sites is to stop paying for them. **If the SiteGround account
goes away, the DNS zones go with it — and the MX, SPF, DKIM and DMARC records for four domains
carrying live Google Workspace mail disappear at the same moment.**

Mail would not degrade. It would stop.

Redirecting the websites is safe precisely *because* SiteGround keeps answering DNS. The redirect
and the hosting cancellation are two different projects and must not be done in the same week.

### If SiteGround is ever cancelled, this is the order

1. Move each DNS zone to a permanent home — the registrar's own DNS, Cloudflare, or Netlify DNS.
2. Recreate **every** record from this file: MX, SPF, DKIM, DMARC, verification TXT.
   ⚠️ DKIM keys are long and split across two quoted strings in the lookups above. They must be
   re-entered as a single value with no introduced whitespace.
3. Update nameservers at the registrar and wait for full propagation.
4. **Send and receive a test message on every one of the four mail domains.**
5. Only then cancel SiteGround.

This file is the source of truth for step 2. Do not delete it.

### Useful side effect

Once `A` points at Netlify, the WordPress installs still exist at SiteGround — they are simply no
longer reachable by domain name. They stay accessible through SiteGround's temporary URL, which is
how to retrieve the content worth salvaging:

- `getstartupbook.com` — the Joe Pulizzi interview and the two Spanish-language articles
- `aimarketingcasestudies.com` — the podcast episodes, if they live only on that install

### One thing to check first

These are live WordPress sites, so any of them may be sending mail through contact forms. That
matters for the two domains carrying `+a` in SPF, above. Check for form notifications on
`viralgeniusframework.com` before repointing it — it is first in the order and runs DMARC
`p=reject`.

