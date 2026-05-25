# pk-plannotator

Private pk build of Plannotator.

## Quickstart

```sh
npm install -g pk-plannotator
plannotator --version
pk-plannotator --version
```

Both commands should print `pk-plannotator 0.19.22-pk.1`.

This package installs both `plannotator` and `pk-plannotator` command aliases. It runs the same Bun-targeted bundle hosted by `https://plan.artificialgarden.org` and requires Bun to be installed.

For Claude Code, install the plugin after the CLI:

```text
/plugin marketplace add kingkillery/pk-plannotator
/plugin install plannotator@plannotator
```
