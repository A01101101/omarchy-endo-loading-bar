# Endo Loading Bar for Omarchy

A hairline loading bar flush to the bottom edge of every screen, for the
[Omarchy](https://omarchy.org) shell. Slow, wide waves of light drift along it, it breathes,
and its colours follow your theme: it ships with **a hand-made colour scheme for each of
the 24 default Omarchy themes** and switches the moment you change theme.

It is click-through, sits on the overlay layer above your windows, and draws nothing
at all while idle.

See the [colour schemes](docs/themes.md) or open [docs/themes.html](docs/themes.html) for a preview.

## Install

```bash
omarchy plugin add https://github.com/A01101101/omarchy-endo-loading-bar.git --enable
```

Then try it:

```bash
omarchy-shell endo-loading-bar demo
```

## Use

Control it with IPC (target `endo-loading-bar`) from any script:

```bash
omarchy-shell endo-loading-bar set 40       # show the bar at 40%
omarchy-shell endo-loading-bar done         # fill, hold, fade out
omarchy-shell endo-loading-bar hide         # hide immediately
omarchy-shell endo-loading-bar demo         # looping 8 second demo
omarchy-shell endo-loading-bar scheme nord  # force a scheme; "auto" follows the theme
omarchy-shell endo-loading-bar schemes      # list scheme names
omarchy-shell endo-loading-bar height 3     # bar height in px (1 to 12, default 2)
omarchy-shell endo-loading-bar status
```

### Show a real download

`bin/endo-bar` wraps any command, reads its progress from the output, and drives the bar:

```bash
~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar "curl -# -L -O https://example.com/file.zip"
~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar "wget https://example.com/file.zip"
~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar "yt-dlp URL"
```

Put it on your PATH if you like:

```bash
ln -s ~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar ~/.local/bin/endo-bar
```

- It runs the command on a pseudo-terminal, so tools print their progress meter, and the
  output still appears in your terminal.
- Anything that prints a percentage works: `45%`, `78.5%`, and curl's default meter. For
  curl use `-#` or the default meter, not `-s`.
- If a tool prints no percentage, track the file it writes:
  `endo-bar "cmd" --watch out.bin --total 734003200`.
- On success the bar fills, holds, and fades. On failure it hides. The command's exit
  code is passed through, and Ctrl+C stops both.
- Multi-file jobs (several packages in a row) will stall and jump, because each file
  restarts at 0%. Progress never moves backwards.

### Show every terminal download automatically

`bin/endo-watch` runs in the background and puts any `curl` or `wget` download on the bar
without wrapping it. Install it as a user service:

```bash
ln -s ~/.config/omarchy/plugins/endo-loading-bar/systemd/endo-watch.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now endo-watch.service
```

- Once a second it finds your `curl`/`wget` processes that are writing to a file, asks the
  server for the file's size once (a `HEAD` request, or a one-byte ranged `GET`), and fills
  the bar from how much of the file is on disk. Several downloads show as one combined bar.
- A finished download fills and fades. One that stops early hides the bar.
- It ignores files under 5 MiB (`--min-size`), output to a pipe or the terminal (API calls,
  `curl | sh`), and anything `endo-bar` is already driving.
- It needs the size from the server: downloads that send auth headers or cookies, or
  servers that report no size, are skipped. `aria2c` and `yt-dlp` aren't tracked; wrap
  them with `endo-bar`.
- `bin/endo-watch --once` prints what it would track. Logs: `journalctl --user -u endo-watch`.
- Tests: `python3 tools/test_endo_watch.py`.

## How it looks

- A gradient from tail to body to a softly glowing tip, with a faint ripple flowing through it
- Wide light waves that swell in, glide at constant speed, and dissolve into the tip
- A slower second layer of waves in a third colour, weaving through the first
- Gentle breathing (about 8 s per cycle) and a very slow drift between two colours
- Theme changes crossfade instead of snapping

## Themes

Each default theme has five hand-picked colours: **tail**, **mid**, **head**, **drift**, and
**layer**. The full table is in [docs/themes.md](docs/themes.md). Themes that are not in the
table, such as your own or Aether-generated ones, get a scheme derived from their
`colors.toml` automatically.

To change a scheme, edit `schemes.json` and run `python3 tools/gen.py`. That regenerates
`Schemes.js` (which the plugin loads) and the docs.

## Notes and limits

- **Fractional scaling:** at a scale like 1.25 a 2 px bar covers 2.5 physical pixels, so its
  top edge is slightly soft. That is the compositor, not a bug.
- **Light themes** are tuned with deeper colours so the bar still shows up on light windows,
  but a 2 px bar over a white page is always subtle.
- **Developing the plugin:** the shell caches a plugin's QML by path. If a version fails to load
  and you fix it, restart the shell (`omarchy restart shell`) or give the plugin a new id.
- Tested on Arch Linux (Omarchy) with Hyprland 0.56 and the Omarchy shell on Wayland.
  Not tested: live theme switching with the plugin loaded (the file watcher is wired to
  Omarchy's `theme.generation` file), and non-Hyprland compositors.

## For AI agents

If you are an AI assistant asked to install or modify this, read [AI-INSTALL.md](AI-INSTALL.md).

## Standalone version

There is also a standalone Python and Qt version for any Wayland or X11 desktop:
[endo-loading-bar](https://github.com/A01101101/endo-loading-bar).

## License

MIT. See [LICENSE](LICENSE).
