# Setup and submission

I did these steps below

## Windows: Git Bash

1. Installed Git for Windows: https://git-scm.com/downloads/win
2. Installed Python 3: https://www.python.org/downloads/windows/
   Enabled its PATH option, and open a new Git Bash window.
3. Installed Gum in PowerShell:

   ```powershell
   winget install charmbracelet.gum
   ```

   Closed and reopened Git Bash so the PATH change takes effect.
   The official Gum instructions are at https://github.com/charmbracelet/gum.
4. Extracted the project ZIP. Open Git Bash in the extracted parent folder.

   ```bash
   cd book-manager
   bash --version
   gum --version
   python3 --version
   bash app.sh
   ```

If `python3` is unavailable but `python --version` reports Python 3, add a
Git Bash wrapper once:

```bash
mkdir -p "$HOME/bin"
printf '#!/usr/bin/env bash\nexec python "$@"\n' > "$HOME/bin/python3"
chmod +x "$HOME/bin/python3"
export PATH="$HOME/bin:$PATH"
```

Add `export PATH="$HOME/bin:$PATH"` to `~/.bashrc` if needed in future sessions.
When navigating a folder containing spaces, quote the complete path, e.g.
`cd "/c/Users/limyu/Downloads/book-manager"` (adjust to your actual location).
Run scripts with `bash`; there is no need to source them.

## macOS / Linux

Installed Gum using its official instructions and ensured `python3` is available.
On macOS with Homebrew, Gum's documented command is `brew install gum`.
Ran `bash app.sh` from the project folder. No network is used at runtime.

## Tried three operations

1. Added **Thinking in Systems**, author **Donella H. Meadows**. Selected a status
   and ownership value that fit my actual situation. Its genre/year I filled in.
2. Browsed/searched for `systems`; choose the book to update its rating/status.
3. Got recommendations; watched the three running/done messages, inspected a reason,
   and saved one suggestion to my want-to-read list.

## Published my finished assignment

Created an empty repository in my own GitHub account. In a parent folder
containing only this `book-manager/` project, I ran:

```bash
git init
git add book-manager
git commit -m "Build personal book manager"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

I replaced both placeholders with my repository details. Reviewed `books.csv`
before publishing: it contained the books I saved. Recorded my narrated demo,
added the video and its working link to README.md, then commit and pushed that
change. Finally, I entered my repository URL in the class sheet's
**Assignment No 2** column.

## Verification in the build environment

The macOS CI job in `.github/workflows/bash-compatibility.yml` uses `/bin/bash`
and verifies version 3.2, including child scripts. It runs the core smoke tests
and `bash tests/recommendations_screen.sh`, which checks displaying and saving
recommendations with empty and populated libraries using scripted Gum choices.
This checks screen control flow; actual Gum appearance still needs a terminal.

- Bash syntax and temporary-database integration tests: passed.
- CSV commas/quotes, duplicate prevention, updates, empty library, metadata,
  piped search, ranking, deduplication, saved-book exclusion: tested.
- Three-worker concurrency and failure handling: tested.
- Menu/add/browse/search/save interaction routes: tested with a scripted Gum
  substitute; this checks control flow, not real rendering or key handling.
- Actual Gum terminal appearance and Windows execution: not tested here.
  Gum was absent and the external binary download timed out. Run the actual
  interface locally before recording and submitting.
