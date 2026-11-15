---
name: hashiiiii-zig
description: Use when writing, editing, or reviewing Zig implementation, tests, build files, or CI.
---

# Zig

Write the smallest implementation that preserves required behavior. Use the project's Zig version and check matching standard-library examples before choosing syntax or APIs.

## Structure

- Keep unit tests in the implementation file. Put end-to-end tests in root `e2e/` and exercise public API flows.
- Export libraries from `src/root.zig` and executables from `src/main.zig`.
- Ensure the test root references test files; Zig does not discover every source file automatically.

## Implementation

- Prefer concrete types, `const`, inferred `.{...}` literals, structs, enums, tagged unions, exhaustive `switch` statements, ordinary functions, and runtime loops. Use `comptime`, `inline`, `anytype`, or reflection only when required.
- Use file imports within a module and named imports across modules.
- Propagate errors with `try`; use `catch` for recovery or translation. Reserve `unreachable` for proven invariants.
- Use `defer` for cleanup and `errdefer` for error returns. A union-valued failure does not run `errdefer`.
- Accept allocators explicitly. Make ownership clear, copy retained input when needed, and store resource owners by value unless a stable address is required.
- Use `undefined` only for storage initialized before reading; cast only when inference or representation requires it.

## Tests

- Add or keep a test only when at least 80% confident it is necessary, based on user impact, regression risk, and overlap with existing tests. This threshold concerns necessity, not coverage.
- Use native `test` blocks and `std.testing`; name and assert the public behavior under test, not private layout or dependency guarantees.
- Keep each test self-contained with literal inputs and expected values. Avoid shared fixtures, computed expectations, and case tables that obscure the assertion.
- Comment on why behavior matters. Use real dependencies; never use mocks or stubs.
- For allocations, use `std.testing.allocator` and release owned resources with `defer`.

```zig
test "parse rejects duplicate modifiers" {
    // Duplicate modifiers can hide configuration mistakes.
    try std.testing.expectError(error.InvalidKey, KeySpec.parse("Ctrl+Ctrl+x"));
}
```

## Build and CI

- Keep `build.zig` direct; run unit and end-to-end tests with `zig build test`.
- Keep test-only imports or generators out of consumer builds with a separate test module. After changing module wiring, build a real consumer and inspect its dependency steps.
- List distributed source paths in `build.zig.zon` `.paths`, including `e2e/` when used.
- Run `zig fmt --check` on changed Zig files and `zig build test` with the project toolchain. Check Debug and ReleaseSafe when changing ownership or error paths.
- Keep CI jobs focused on distinct risks; avoid duplicate push and pull-request runs for the same change.

References: [Zig sources](https://codeberg.org/ziglang/zig), [Readable Test Code](https://speakerdeck.com/jnchito/number-vstat).
