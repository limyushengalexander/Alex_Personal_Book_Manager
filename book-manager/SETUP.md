# Setup and submission

## Windows: Git Bash

1. Install Git for Windows if needed: https://git-scm.com/downloads/win
2. Install Python 3 if needed: https://www.python.org/downloads/windows/
   Enable its PATH option, and open a new Git Bash window.
3. Install Gum in PowerShell:

   ```powershell
   winget install charmbracelet.gum
   ```

   Close and reopen Git Bash so the PATH change takes effect.
   The official Gum instructions are at https://github.com/charmbracelet/gum.
4. Extract the project ZIP. Open Git Bash in the extracted parent folder.

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

Install Gum using its official instructions and ensure `python3` is available.
On macOS with Homebrew, Gum's documented command is `brew install gum`.
Then run `bash app.sh` from the project folder. No network is used at runtime.

## Try three operations

1. Add **Thinking in Systems**, author **Donella H. Meadows**. Select a status
   and ownership value that fit your actual situation. Its genre/year fill in.
2. Browse or search for `systems`; choose the book to update its rating/status.
3. Get recommendations; watch the three running/done messages, inspect a reason,
   and save one suggestion to your want-to-read list.

## Publish your finished assignment

Create an empty repository in your own GitHub account. In a parent folder
containing only this `book-manager/` project, run:

```bash
git init
git add book-manager
git commit -m "Build personal book manager"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

Replace both placeholders with your repository details. Review `books.csv`
before publishing: it contains the books you saved. Record your narrated demo,
add the video or its working link to the README, then commit and push that
change. Finally, enter your repository URL in the class sheet's
**Assignment No 2** column. The sheet URL is in the assignment PDF.

## Verification in the build environment

- Bash syntax and temporary-database integration tests: passed.
- CSV commas/quotes, duplicate prevention, updates, empty library, metadata,
  piped search, ranking, deduplication, saved-book exclusion: tested.
- Three-worker concurrency and failure handling: tested.
- Menu/add/browse/search/save interaction routes: tested with a scripted Gum
  substitute; this checks control flow, not real rendering or key handling.
- Actual Gum terminal appearance and Windows execution: not tested here.
  Gum was absent and the external binary download timed out. Run the actual
  interface locally before recording and submitting.
