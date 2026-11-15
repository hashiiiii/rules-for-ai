import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rename, rm, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const skill = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const digest = (bytes) => createHash('sha256').update(bytes).digest('hex');

async function runtimeDirectory() {
  const lock = await readFile(join(skill, 'package-lock.json'));
  const base = process.env.XDG_CACHE_HOME || join(homedir(), '.cache');
  return join(base, 'rules-for-ai', 'english', digest(lock));
}

async function setup(directory) {
  try {
    await readFile(join(directory, '.ready'));
    return;
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  await mkdir(dirname(directory), { recursive: true });
  const staging = await mkdtemp(`${directory}-`);
  try {
    for (const file of ['package.json', 'package-lock.json']) {
      await writeFile(join(staging, file), await readFile(join(skill, file)));
    }
    // A user-owned cache also works when plugin resources are read-only.
    const installed = spawnSync('npm', ['ci', '--ignore-scripts', '--no-audit', '--no-fund'], {
      cwd: staging,
      stdio: ['ignore', 'inherit', 'inherit'],
      shell: process.platform === 'win32',
    });
    if (installed.error) throw installed.error;
    if (installed.status !== 0) throw new Error('npm ci failed; the English checker was not installed.');
    await writeFile(join(staging, '.ready'), '');
    try {
      await rename(staging, directory);
    } catch (error) {
      // Concurrent setup can finish first; only accept its completed installation.
      if (!['EEXIST', 'ENOTEMPTY'].includes(error.code)) throw error;
      await readFile(join(directory, '.ready'));
    }
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
}

async function main() {
  const args = process.argv.slice(2);
  const directory = await runtimeDirectory();
  if (args.length === 1 && args[0] === 'setup') {
    await setup(directory);
    console.log(`English checker installed in ${directory}`);
    return;
  }
  let dialect = 'American';
  if (args[0] === '--dialect') {
    const names = ['American', 'British', 'Australian', 'Canadian', 'Indian'];
    dialect = names.find((name) => name.toLowerCase() === args[1]?.toLowerCase());
    if (!dialect) throw new Error(`Choose a dialect: ${names.join(', ')}.`);
    args.splice(0, 2);
  }
  if (args.length !== 1 || args[0].startsWith('-')) {
    throw new Error('Usage: node check.mjs setup | [--dialect American|British|Australian|Canadian|Indian] FILE');
  }
  const file = resolve(args[0]);
  const bytes = await readFile(file);
  const text = bytes.toString('utf8');
  try {
    await readFile(join(directory, '.ready'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    throw new Error(`Run setup first: node ${JSON.stringify(fileURLToPath(import.meta.url))} setup`);
  }
  const engine = join(directory, 'node_modules', 'harper.js');
  const { LocalLinter, Dialect, SuggestionKind } = await import(pathToFileURL(join(engine, 'dist/index.js')));
  // The inlined WebAssembly data avoids network access during checks.
  const { binaryInlined: binary } = await import(pathToFileURL(join(engine, 'dist/binaryInlined.js')));
  const linter = new LocalLinter({ binary, dialect: Dialect[dialect] });
  try {
    const groups = await linter.organizedLints(text, {
      language: /\.(md|markdown|mdx)$/i.test(file) ? 'markdown' : 'plaintext',
      dedup: false,
    });
    const diagnostics = [];
    for (const [rule, lints] of Object.entries(groups)) {
      for (const lint of lints) {
        const span = lint.span();
        // Harper.js spans use UTF-16 offsets; displayed columns count Unicode characters.
        const prefix = text.slice(0, span.start);
        const lines = prefix.split('\n');
        diagnostics.push({
          rule,
          line: lines.length,
          column: Array.from(lines.at(-1)).length + 1,
          problem: lint.get_problem_text(),
          message: lint.message(),
          suggestions: lint.suggestions().map((suggestion) => ({
            kind: suggestion.kind() === SuggestionKind.Remove ? 'remove' : 'replace',
            text: suggestion.get_replacement_text(),
          })),
        });
      }
    }
    diagnostics.sort((a, b) => a.line - b.line || a.column - b.column);
    const { version } = JSON.parse(await readFile(join(engine, 'package.json'), 'utf8'));
    console.log(JSON.stringify({ engine: 'Harper', version, dialect, file, sha256: digest(bytes), diagnostics }, null, 2));
  } finally {
    await linter.dispose();
  }
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
});
