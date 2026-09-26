---
name: hashiiiii-zig
description: Use when writing, editing, or reviewing Zig implementation, tests, build files, or CI.
---

# Zig

Write the smallest implementation that preserves the required behavior.
Use the project's Zig version. Read a few matching examples in that version's standard library before choosing syntax or APIs.

## Structure

- Keep unit tests in the implementation file: tests for `src/parser.zig` belong in `src/parser.zig`.
- Put end-to-end tests in `e2e/` at the repository root. Exercise real public API flows.
- Use `src/root.zig` for library exports and `src/main.zig` for executables.
- Ensure the test root references files containing tests; Zig does not discover every source file automatically.

## Implementation

- Prefer concrete types, `const`, inferred `.{ ... }` literals, `struct`, `enum`, `union(enum)`, and exhaustive `switch`.
- Use ordinary functions and runtime loops when they express the behavior directly.
- Prefer file imports within a module, such as `@import("parser.zig")`. Use named imports for separate module dependencies.
- Use `comptime` or `inline` when evaluation must happen at compile time. Use `anytype` or reflection for necessary type-dependent code.
- Propagate errors with `try`; use `catch` for recovery or translation. Reserve `unreachable` for proven invariants.
- Use `defer` for cleanup and `errdefer` for error returns. A failure returned as a union value does not run `errdefer`.
- Accept allocators explicitly. Store resource owners by value unless retained pointers or allocator handles require a stable address.
- Make owned and borrowed slices clear. Copy retained input when the result must outlive it.
- Use `undefined` only for storage initialized before reading. Add casts only when inference or representation requires them.

## Tests

- Keep or add tests only when at least 80% confident they are necessary. Remove lower-confidence tests and add missing necessary ones.
- Judge user impact, regression risk, and overlap with other tests. The threshold concerns necessity, not code coverage.
- Use native `test` blocks and `std.testing` expectations. Name the concrete behavior being checked.
- Assert public behavior, not private layout or dependencies' own guarantees.
- Write each test from setup to assertion. Keep inputs and expected values literal and setup local.
- Avoid shared fixtures, computed expectations, and case-table loops that make readers reconstruct the behavior.
- Explain why the behavior matters in comments. Use real dependencies; never use mocks or stubs.
- For allocations, use `std.testing.allocator` and release owned resources with `defer`.

```zig
test "parse rejects duplicate modifiers" {
    // Duplicate modifiers can hide configuration mistakes.
    try std.testing.expectError(error.InvalidKey, KeySpec.parse("Ctrl+Ctrl+x"));
}
```

## Build and CI

- Keep `build.zig` direct. Run unit and end-to-end tests through `zig build test`.
- Give tests a separate module when their imports would add dependencies or generators to consumer builds.
- After changing module wiring, build a small real consumer and inspect its dependency steps.
- Include source paths used by the distributed build in `build.zig.zon` `.paths`, including `e2e/` when present.
- Run `zig fmt --check` on changed Zig paths and `zig build test` with the project's toolchain.
- Check Debug and ReleaseSafe when changing ownership or error paths.
- Keep CI jobs for distinct risks. Avoid duplicate push and pull-request runs for the same change.

References: [Zig sources](https://codeberg.org/ziglang/zig), [Readable Test Code](https://speakerdeck.com/jnchito/number-vstat).
