# Decommission runbook — retire the WordPress sites, move DNS to the registrars, leave SiteGround

**Goal.** Five legacy websites gone. All content archived locally. DNS answering from the
registrars. Google Workspace mail unaffected on all four mail domains. SiteGround cancelled.

**Written 2026-08-10.** Companion to `DNS-EMAIL-BASELINE.md`, which is the record of every DNS
record as it stood before any change.

---

## The one rule

**Mail is the only thing here that cannot be un-broken by trying again.** A redirect that lands
wrong is a five-minute fix. A DKIM record pasted with a line break inside it fails silently, and
you find out when someone tells you a week later that your reply went to their spam folder.

Every step below is ordered around protecting four live Google Workspace domains.

---

## Order of operations

Do not reorder these. Steps 1 and 2 must both be complete before step 3.

```
1. Archive the content            ← sites must still be live
2. Build the new DNS zones        ← built but NOT switched
3. Cut over  (one move: DNS + redirect together)
4. Verify mail, hard
5. Wait a week
6. Cancel SiteGround
```

**The cutover is deliberately a single move.** The new zone is built with the A record already
pointing at Netlify, so switching nameservers migrates DNS *and* activates the redirect at the same
instant. One propagation window instead of two, and one thing to verify instead of two.

---

## Step 1 · Archive, while the sites are still up

**Two things per site. Both are needed.**

**a. The WordPress XML export — the content.**
*Tools → Export → All content.* Posts, pages, categories, metadata. Re-importable into any future
WordPress. This is the whole archive as far as text goes.

**b. The `wp-content/uploads` folder — the media.**

⚠️ **The XML export does not contain your images.** It stores references to them —
`<wp:attachment_url>` pointing at `/wp-content/uploads/...`. Those resolve while the site is live
and become dead URLs the moment the account is gone.

Pull the folder through *Site Tools → Site → File Manager* (or FTP), zip it, keep it beside the XML.
One folder per site.

**Store both in Dropbox, one folder per domain.** Not on the laptop only.

✅ **Podcast audio is safe.** Confirmed 2026-08-10: the `aimarketingcasestudies.com` episodes are
hosted on Substack, not in the WordPress uploads folder. Nothing on SiteGround is a master copy of
anything. That was the only irreplaceable-asset risk in this project and it does not exist.

### Content specifically worth keeping

| Site | What matters |
|---|---|
| `getstartupbook.com` | The Joe Pulizzi interview · **the two Spanish-language articles** — there is no Spanish content on viralgeniusinstitute.com and there is a Spanish-speaking network · the webinar pages with named guests |
| `aimarketingcasestudies.com` | Show-notes pages only — the audio lives on Substack. Little unique content; the site is near-empty at 1,737 visible characters. Lowest-value archive of the five. |
| `labastida.com` | ~15 years of blog posts. Mostly superseded, occasionally quotable. |
| `strikemarketinginstitute.com` | The most copy of any property, 17,058 characters. Recent, and the flatline framing may be worth cannibalising. |
| `viralgeniusframework.com` | VGF 1.0 methodology pages. Historical record of the framework's earlier form. |

---

## Step 2 · Build the new DNS zones — built, not switched

At each registrar, create the zone and enter every record **before** changing nameservers. Most
registrars let you pre-build a zone that stays dormant until delegation points at it.

### What each zone needs

**MX — identical on all four mail domains** (standard Google Workspace):

```
1   aspmx.l.google.com.
5   alt1.aspmx.l.google.com.
5   alt2.aspmx.l.google.com.
10  alt3.aspmx.l.google.com.
10  alt4.aspmx.l.google.com.
```

⚠️ `viralgeniusframework.com` currently uses the single-record form, `1 smtp.google.com.` Either
form works. Use the five-record set everywhere for consistency.

**SPF — simplify while you are here.**

The current records include `*.spf.auto.dnssmarthost.net`. **That is a SiteGround service.** Once
you leave SiteGround it is at best meaningless and at worst a dead include. Two of the records also
carry `+a +mx`, which authorises the web server to send — and there will be no web server.

For Google Workspace only, the correct record on all four is:

```
v=spf1 include:_spf.google.com ~all
```

That is already exactly what `getstartupbook.com` and `strikemarketinginstitute.com` use. Make the
other two match.

**DKIM — do NOT copy this from the old DNS.**

The keys in `DNS-EMAIL-BASELINE.md` are shown split across two quoted strings, because that is how
DNS returns long TXT values. Reassembling them by hand is the single most common way a migration
silently breaks mail.

**Get it from the source instead:** Google Admin → *Apps → Google Workspace → Gmail → Authenticate
email*. Select the domain, and it displays the exact host and value to enter. If a domain has no
DKIM configured there, generate it. Two of the five had no key on the default selector.

**DMARC — keep what is there**, from the baseline file. Note the policies differ by domain
(`p=reject`, `p=quarantine`, `p=none`). Migrate each as-is; tightening them is a separate decision.

**Verification TXT — carry these across:**

- `aimarketingcasestudies.com` — `google-site-verification=jG8olzULP0soDLULUg4tIIBd2oEWLe7P1W-x-LEB3QE`
- `viralgeniusframework.com` — `google-site-verification=sXC5CezS7cLlmkCCUJUJeu9GYmyZ5_GvpBRluTYlbSk`
  **and** `openai-domain-verification=dv-DnWBX7gephauFvi9shauPMuS`
- `strikemarketinginstitute.com` — `google-site-verification=evHyFJ7qlXGZxAfoBBSehaWcJDfinn5_ZVIpYkfchII`

Losing a Google verification TXT can lock you out of Workspace admin for that domain.

**A and CNAME — point at Netlify from the start:**

```
A     @      75.2.60.5
CNAME www    vgi-redirect-hub.netlify.app
```

### Consider Cloudflare instead of registrar DNS

You said registrar level, and that works. Worth one line of consideration: **Cloudflare DNS is
free, faster than most registrar DNS, and puts all five zones in one dashboard** regardless of who
each domain is registered with. It also imports an existing zone automatically, which removes most
of the hand-entry risk in this step. Registrar DNS quality varies a lot; Cloudflare's does not.

Either way the record values above are identical.

---

## Step 3 · Cut over, one domain at a time

**Never more than one domain per sitting.** If something breaks you want to know exactly which
change caused it.

Order — least risk to most:

1. `strikemarketinginstitute.com` — already on Netlify, already resolves to `75.2.60.5`. Release it
   from the old `strike-marketing-institute` Netlify project first.
2. `getstartupbook.com` — clean SPF, no `+a`
3. `labastida.com` — no `+a`, DMARC only `p=quarantine`
4. `viralgeniusframework.com` — has `+a`, DMARC `p=reject`. Highest risk, highest value.
5. `aimarketingcasestudies.com` — **the primary email address.** Last, always.

For each: add the domain as an alias in the `vgi-redirect-hub` Netlify project, then switch
nameservers at the registrar. Then step 4 before moving to the next domain.

---

## Step 4 · Verify, and mean it

```bash
cd ~/Documents/GitHub/redirect-hub && ./verify.sh <domain-fragment>
```

Redirects should show `301` to viralgeniusinstitute.com.

Then the part that matters more:

```bash
dig MX <domain> +short
dig TXT <domain> +short
dig TXT _dmarc.<domain> +short
dig TXT google._domainkey.<domain> +short
```

Compare every line against `DNS-EMAIL-BASELINE.md`.

**Then send real mail.** Automated checks do not catch a malformed DKIM key; receiving systems do.

- Send **from** that domain to a Gmail address you control, and to a non-Google address
- Reply **to** that domain from both
- In Gmail, open *Show original* and confirm **SPF: PASS, DKIM: PASS, DMARC: PASS**

A DKIM failure here is the whole reason this runbook exists. Find it now, not in a month.

---

## Step 5 · Wait

**A full week per domain before considering it done, and a full week after the last one before
step 6.** Mail problems surface on the cadence of your correspondents, not your testing. Someone
emails you fortnightly; you will not hear about a bounce for a fortnight.

---

## Step 6 · Cancel SiteGround

Only after every domain has been through steps 3–5 and mail has been verified in production.

**Before cancelling, confirm:**

- [ ] All three archive layers downloaded and in Dropbox, for all five sites
- [ ] `dig NS <domain>` shows the registrar's nameservers, not SiteGround's, on all five
- [ ] SPF, DKIM and DMARC pass on all four mail domains, verified in a received message header
- [ ] The **VGF Google Drive folder** ("Viral Genius Methodology Documents") has been transferred
      out of the `fernando@viralgeniusframework.com` account — this gates that Workspace
      cancellation, separately from SiteGround
- [x] Podcast audio confirmed on Substack, not SiteGround — verified 2026-08-10

Then cancel.

---

## What stays, forever

| Thing | Why |
|---|---|
| All five **domain registrations** | A 301 only passes authority while the domain is registered and delegated. Letting one lapse discards every backlink earned since 2009. Renew forever. |
| `aimarketingcasestudies.com` **Workspace account** | Primary email address. |
| The `vgi-redirect-hub` Netlify site | Free, and it is what serves every redirect. |
| `DNS-EMAIL-BASELINE.md` | The only record of what the zones looked like before any of this. |
