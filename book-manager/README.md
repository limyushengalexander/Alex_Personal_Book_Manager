# The Reading Route

A small personal book manager for Problem Set 02, built from Bash programs.
Add books, search your shelf, update reading status and ratings, and combine
three independent recommendation strategies. It runs offline with no API key.

## Run

You need **Bash, Gum, Python 3, and standard Unix tools** (`awk`, `sort`, `mktemp`).
Python's built-in CSV module is used only inside the data layer; no pip packages
are needed. Windows users should run the application in **Git Bash**, not CMD
or PowerShell. See [SETUP.md](SETUP.md) for Windows instructions.

```bash
cd book-manager
bash app.sh
```

Use arrow keys and Enter to choose actions. Escape cancels the current prompt.
Your saved books stay in `data/books.csv`. The initial library is empty.

## Architecture

`app.sh` launches the Gum UI. The UI gathers input and calls workflows, which
coordinate book components, recommendation components, and the data layer.
Only `data/book_database.sh` opens `books.csv`. The recommendation workflow
starts three Bash workers using `&`, records their PIDs with `$!`, synchronizes
them with `wait`, and pipes their combined output into the refiner. Progress
goes to stderr and records go to stdout, keeping the pipeline clean. Small
AWK programs score and filter records; a Python block in the database component
handles CSV quoting and replacement safely.

## Personalization

The starting interests are transportation, logistics, and systems thinking,
with related books in an editable offline catalog. History recommendations
favor authors and genres from saved books, especially finished and highly rated
books. Interest recommendations match topics in `config/interests.txt`.
Discovery recommends unfamiliar genres, and the refiner reserves one shortlist
place for exploration. Ownership is tracked separately from reading status,
so owning a book does not imply having read it. Change the interests and catalog
to reflect your own choices; the initial settings are suggestions.

## Test and understand

```bash
bash tests/smoke.sh
bash workflows/get_recommendations.sh
```

Tests use a temporary library. Read [GUIDE.md](GUIDE.md) for file responsibilities,
interfaces, scoring rules, and a complete traced workflow.

## Narrated demo — recording still required

Follow [DEMO.md](DEMO.md) to record a short terminal demo **with your own
narration**. Put it at `demo.mp4` in this repository and add a working link here,
or replace this paragraph with a link to your uploaded video. No video has been
recorded yet. Repository creation, pushing to GitHub, and entering the repository
URL in the class sheet remain submission steps; see [SETUP.md](SETUP.md).

## Scope

This is an intentionally small, single-user, **one-writer-at-a-time** application.
Metadata and recommendations come from 18 bundled books, not a live service or
an LLM. Unknown titles are saved with blank genre/year. Genre labels are curated
for this app, and years refer to original publication. To improve coverage, edit
`books/catalog.psv`. Do not run simultaneous editing sessions against one CSV.
Titles may contain commas, quotation marks and Unicode; the internal record
format excludes pipes, tabs, newlines and control characters.
