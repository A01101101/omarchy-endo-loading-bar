# AI install guide: Endo Loading Bar (Omarchy plugin)

You are an AI coding assistant. Follow these steps to install and verify this plugin
for a user. Do not skip verification.

## What this is

An Omarchy **shell plugin** (QML, kind `service`). It draws a 2 px strip on the bottom
edge of each screen and follows the active Omarchy theme. It is driven by IPC calls to
the target `endo-loading-bar`. `bin/endo-bar` wraps a command and sends its progress.

## 0. Prerequisites

```bash
echo "$OMARCHY_PATH"                    # should be /usr/share/omarchy
omarchy plugin list | head -3           # the omarchy CLI must exist
omarchy-shell shell ping                # the shell must be running
```

If the user is not on Omarchy, this plugin does not apply. Point them to the standalone
version: https://github.com/A01101101/endo-loading-bar

## 1. Install

```bash
omarchy plugin add https://github.com/A01101101/omarchy-endo-loading-bar.git --enable
```

If the CLI asks for confirmation and you cannot answer, pass `--yes`. Adding a plugin
installs code that runs inside the user's desktop shell, so tell the user before doing it.

To install from a local checkout instead:

```bash
git clone https://github.com/A01101101/omarchy-endo-loading-bar.git
omarchy plugin validate ./omarchy-endo-loading-bar
ln -sfn "$PWD/omarchy-endo-loading-bar" ~/.config/omarchy/plugins/endo-loading-bar
omarchy-shell shell rescanPlugins
omarchy plugin enable endo-loading-bar
```

## 2. Verify (required)

```bash
omarchy-shell endo-loading-bar status       # expect: idle 0% · scheme: <name>
omarchy-shell endo-loading-bar demo
sleep 2
omarchy-shell endo-loading-bar status       # expect: demo N% ...
hyprctl layers | grep endo-loading-bar      # expect one 2px-high layer per monitor at the bottom edge
omarchy-shell endo-loading-bar hide
```

If `status` says `Target not found.`:

1. Check `omarchy plugin list | grep endo` shows `enabled`.
2. Check the log: `journalctl --user --since "-2min" --no-pager | grep -i endo`.
3. A message like `service plugin load failed ... Type Engine unavailable` means a QML error.
   Fix it, then restart the shell with `omarchy restart shell`, because the shell caches a
   plugin's QML by path and will not reload a fixed file under the same id. Tell the user
   before restarting; the bar blinks for a second.

You cannot see the screen. Report what you verified (status output, `hyprctl layers`) and say
that how it looks is unconfirmed until the user confirms it.

## 3. Use it

```bash
omarchy-shell endo-loading-bar set 40        # 0..100
omarchy-shell endo-loading-bar done
omarchy-shell endo-loading-bar hide
omarchy-shell endo-loading-bar scheme nord   # or "auto"
omarchy-shell endo-loading-bar height 3
```

To show a real download, wrap the command; pass it as **one quoted string**:

```bash
~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar "curl -# -L -O URL"
~/.config/omarchy/plugins/endo-loading-bar/bin/endo-bar "cmd" --watch FILE --total BYTES
```

Rules: use `curl -#` or default output, never `-s`; the tool must print a percentage, or use
`--watch` with the expected size; the wrapper can only wrap a command it starts itself, not
attach to a download that is already running; run it detached if you must keep working.

## 4. Changing colours

Schemes live in `schemes.json` (one entry per Omarchy theme slug with `tail`, `mid`, `head`,
`drift`, `layer`). After editing:

```bash
python3 tools/gen.py        # regenerates Schemes.js and docs/themes.{md,html}
omarchy plugin validate .
omarchy restart shell       # needed to pick up the new QML/JS (path cache); warn the user
```

Never edit `Schemes.js` by hand; it is generated.

## 5. Uninstall

```bash
omarchy plugin remove endo-loading-bar --yes
```

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Target not found.` | Plugin not enabled or failed to load | Steps in section 2 |
| Bar never appears with `set` | Plugin loaded under an old failed state | `omarchy restart shell` |
| Wrong colours | Theme has no hand-made scheme | It uses a derived one; add an entry to `schemes.json` |
| `endo-bar` shows nothing | Command prints no percentage | Use `--watch FILE --total BYTES` |
| Dimmer than expected on a light theme | A 2 px bar over white is subtle | Raise `height`, or tune the scheme |
