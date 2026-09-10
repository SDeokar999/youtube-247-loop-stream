# Put your video here

Drop your looping video at `video/loop.mp4` (exact filename — the workflow
and scripts both look for it there).

**Before committing it, compress it.** This file gets pulled down fresh by
every GitHub Actions run (4x/day), and gets stored in plain git (not Git LFS,
which has a 1GB/month free bandwidth cap that a 4x-daily checkout would blow
through fast). Recommended target: 720p, H.264, under ~50MB for a 5-minute
clip. Quick way to (re)compress with ffmpeg:

```bash
ffmpeg -i your-source.mp4 -vf scale=1280:-2 -c:v libx264 -crf 23 -preset slow -c:a aac -b:a 128k video/loop.mp4
```

GitHub hard-blocks any single file over 100MB, and warns above 50MB — stay
under 50MB if you can.
