# neoscroll.yazi

Smooth, non-overlapping scrolling for Yazi, heavily inspired by neoscroll.nvim

Unlike simple smooth-scroll implementations that launch a new animation
for every keypress, neoscroll.yazi queues additional movement into the
currently running scroll animation.

## Installation

```sh
ya pkg add HiFiveJazz/neoscroll
```

## Usage
Add to `~/.config/yazi/keymap.toml`:
```toml
[[mgr.append_keymap]]
on = ["<C-j>"]
run = "plugin neoscroll -- 21"
desc = "Smooth scroll down"

[[mgr.append_keymap]]
on = ["<C-k>"]
run = "plugin neoscroll -- -21"
desc = "Smooth scroll up"
```
