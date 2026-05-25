#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const bundle = path.resolve(here, "../dist/pk-plannotator-bun.js");

const result = spawnSync("bun", [bundle, ...process.argv.slice(2)], {
  stdio: "inherit",
  shell: process.platform === "win32",
});

if (result.error) {
  if (result.error.code === "ENOENT") {
    console.error("pk-plannotator requires bun. Install bun from https://bun.sh, then rerun this command.");
  } else {
    console.error(result.error.message);
  }
  process.exit(1);
}

process.exit(result.status ?? 0);
