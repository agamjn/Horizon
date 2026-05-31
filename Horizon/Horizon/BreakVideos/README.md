# Break videos

Horizon plays a calming, looping nature clip behind the break message. Clips live in this
folder and are picked up automatically — any `.mp4`, `.mov`, or `.m4v` file here is eligible,
and one is chosen at random per break (audio plays only on your active screen).

## Why this folder ships empty

The video files are **not committed** to the repository. Typical free-stock licenses
(Pexels, Pixabay, Mixkit, …) let you *use* footage inside an app but restrict redistributing
the raw files on their own — which a public repo effectively does. So:

- **The app works without any clips** — it falls back to a calm gradient when this folder is empty.
- **To add clips locally:** drop `.mp4` / `.mov` / `.m4v` files in here and rebuild. They're
  git-ignored by default (see `.gitignore`), so your downloaded footage won't be committed.
- **To ship clips in the repo:** use **CC0 / public-domain** footage (no redistribution
  restriction), then add a `.gitignore` exception for those files.

Keep clips short (≈15–25 s) and ~1080p so the app stays light; they loop seamlessly.
