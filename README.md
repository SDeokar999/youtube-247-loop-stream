# 24/7 YouTube Loop Stream

Streams `video/loop.mp4` to a YouTube Live broadcast on an infinite loop,
using `ffmpeg` over RTMP, driven by a GitHub Actions workflow that costs
nothing on a public repo.

## How it works

`.github/workflows/stream.yml` runs on a cron schedule (every 6 hours) plus a
manual trigger. Each run checks out the repo, then hands off to
`scripts/stream-loop.sh`, which runs `ffmpeg -stream_loop -1` against your
video and pipes it into YouTube's RTMP ingest. If `ffmpeg` ever dies
(dropped connection, transient error) the script restarts it immediately.
The job stops itself ~5 minutes before GitHub's hard 6-hour job limit; the
next scheduled run then picks the stream back up.

## Why GitHub Actions, and its one real limitation

GitHub-hosted runners are **free and unlimited on public repos** — that's
what makes this deployable at zero cost. But every *job* is hard-capped at 6
hours with no way to raise it, and cron triggers on GitHub are "best effort"
(can fire a few minutes late under load). So this setup **will have a short
gap in the stream every ~6 hours** — typically a couple of minutes, sometimes
more. `ffmpeg` also has no built-in reconnect and a long unbroken loop can
accumulate a little audio/video drift, both mitigated but not eliminated by
the restart wrapper.

If those gaps matter to you (e.g. you want a truly unbroken stream), the
honest answer is that **a persistent server beats GitHub Actions**, full
stop — see the comparison below.

## Options considered

| Option | Cost | Gap-free? | Notes |
|---|---|---|---|
| **GitHub Actions + ffmpeg** (this repo) | Free (public repo) | No — small gap every ~6h | What you asked for: zero infra, deploys from a git push, no server to maintain. |
| **Free-tier cloud VM** (Oracle Cloud "Always Free", GCP `e2-micro`) running ffmpeg as a `systemd` service | Free | Yes | A real persistent process — no 6h restart, systemd auto-restarts on crash. Most reliable free option overall, but it's a VM you provision and maintain yourself, not "on GitHub." |
| **Cheap always-on VPS** (~$4-6/mo droplet) | Paid | Yes | Same as above minus the free-tier account setup friction. What most "24/7 lofi stream" tutorials actually use in production. |
| **Desktop app (OBS Studio + Loop playback)** | Free | Only while the PC is on | Reliable software, but it's not "virtual" — your computer has to stay on, awake, and connected 24/7. Defeats the point of deploying it away from your machine. |
| **Mobile app** (any phone streaming app) | Free | No | Ruled out: mobile OSes suspend/kill backgrounded apps, the phone needs to stay charged, unlocked or screen-on in many cases, and on a stable connection indefinitely. Fine for a one-off live stream, not for unattended 24/7 looping. |

**Recommendation:** this repo (GitHub Actions) for a genuinely free,
maintenance-free setup with occasional brief gaps. If gapless matters more
than "must be free/GitHub," say so and I'll build the Oracle Cloud
`systemd` version instead — it's a small variant of the same `ffmpeg`
command in `scripts/stream-loop.sh`, just run directly on a VM instead of
restarted by cron.

## Setup

### 1. Enable Live Streaming on your YouTube channel (do this first — there's a wait)

1. YouTube Studio → Settings → Channel → Feature eligibility → verify your
   phone number.
2. **Wait 24 hours** after verifying before your first live stream will work
   — YouTube enforces this with no way to skip it, so do this step first if
   your channel hasn't gone live before.
3. YouTube Studio → **Go Live** → **Stream** → copy your **Stream key**
   (looks like `abcd-efgh-ijkl-mnop-qrst`). Keep this private — treat it like
   a password. Don't paste it into this repo's files.

### 2. Add your video

Compress and drop it at `video/loop.mp4` — see [video/README.md](video/README.md)
for the exact ffmpeg command and size guidance.

### 3. (Optional but recommended) Test locally first

```powershell
$env:YT_STREAM_KEY = "your-stream-key-here"
.\scripts\test-local.ps1
```

Confirms your video and key work before you rely on GitHub Actions. Requires
`ffmpeg` on PATH (`winget install ffmpeg`).

### 4. Create the GitHub repo

Needs to be **public** — a private repo only gets 2,000 free Actions
minutes/month (~33 hours), nowhere near enough for 24/7. Public repos get
unlimited minutes. That also means your video file and code are publicly
downloadable from the repo — fine for a generic loop video, worth knowing if
it's not.

```bash
git init
git add .
git commit -m "Initial 24/7 loop stream setup"
gh repo create youtube-247-loop-stream --public --source=. --push
```

(Or create the repo on github.com and `git remote add origin ...` + push, if
you'd rather not use the `gh` CLI.)

### 5. Add the stream key as a GitHub secret

Repo → Settings → Secrets and variables → Actions → **New repository
secret** → name it `YT_STREAM_KEY`, paste the value from step 1. This keeps
it out of the code entirely.

### 6. Kick it off

Actions tab → "24/7 YouTube Loop Stream" → **Run workflow** (manual trigger,
via `workflow_dispatch`) to start immediately and confirm it works. After
that the cron schedule keeps it running indefinitely without you touching
anything.

## Known limitations

- **Gap every ~6 hours** at the job restart boundary (cron jitter + the
  hard 6h job cap) — see above.
- **No mid-stream failover**: if `ffmpeg` or the RTMP connection dies, the
  wrapper script restarts it within 5 seconds, but that's still a few
  seconds of dead air, not a seamless cut.
- **Public repo required** for the free-minutes math to work — see step 4.
- Rotating your YouTube stream key (Studio → Stream → reset) breaks the
  stream until you update the `YT_STREAM_KEY` secret to match.
