# Branching Model

We follow a lightweight **Git Flow** variant:

```
main           ── production-ready, tagged releases only
  │
  └── develop  ── integration branch for the next release
       │
       ├── feature/<short-name>
       ├── bugfix/<short-name>
       └── release/<version>
```

## Conventions

- Branch from `develop` for new work.
- One concern per branch — keep PRs < ~400 LOC.
- Use **conventional commits** (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`).
- PRs require ≥1 review and a green CI run.

## Release flow

1. Create `release/v1.x.y` from `develop`.
2. Bug-fix only on this branch; bump `pubspec.yaml`.
3. Merge into `main` and `develop`; tag `v1.x.y` on `main`.

## Hotfix flow

```
main ── hotfix/<short-name>
```

1. Branch from `main`.
2. Merge back into both `main` and `develop`.

## Commit message template

```text
<type>(scope): short description

body (optional)
```

Example: `feat(auth): add login screen with email/password fields`