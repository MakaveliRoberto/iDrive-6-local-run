# GitHub Push Strategy for Large Repository

## Problem
- Repository is 15GB
- GitHub has 100MB file size limit
- HTTP 500 errors when pushing large files
- Many files > 50MB in system dump

## Solutions

### Option 1: Git LFS (Recommended)
1. Install Git LFS: `brew install git-lfs`
2. Track large files: `git lfs track "nbtevo-system-dump/**/*"`
3. Migrate existing files: `git lfs migrate import --include="nbtevo-system-dump/**/*" --everything`
4. Push: `git push -u origin main`

### Option 2: Push Without System Dump First
1. Remove system dump from git temporarily
2. Push repository structure and scripts
3. Add system dump later with LFS or separate method

### Option 3: External Storage
- Upload system dump to external storage (Google Drive, Dropbox, etc.)
- Include download link in README
- Keep repository with scripts and documentation only

### Option 4: Split Repository
- Main repo: Scripts, documentation, patched kernel
- Separate repo: System dump (or use releases)

## Recommended Approach

For now, let's:
1. Push repository structure first (scripts, docs, kernel)
2. Add system dump using Git LFS in separate commit
3. Or provide system dump as downloadable archive

