# How the application fits together

## Files and responsibilities

| File | Input | Output / responsibility |
| --- | --- | --- |
| `app.sh` | launch | checks tools; starts the main menu |
| `ui/main_menu.sh` | Gum choice | opens the relevant screen |
| `ui/library_screen.sh` | add/browse/search and user input | renders records; calls management workflow |
| `ui/recommendations_screen.sh` | user selection | renders shortlist and optionally saves a book |
| `workflows/manage_library.sh` | operation and arguments | coordinates metadata, search and database |
| `workflows/get_recommendations.sh` | optional shortlist size | runs workers concurrently, waits, pipes results to refiner |
| `books/fetch_book_metadata.sh` | title and author | one enriched metadata record |
| `books/search_books.sh` | argument or piped search term | matching library records |
| `books/catalog.psv` | curated reference data | title, author, genre and original publication year |
| `recommendations/recommend_from_history.sh` | library via database | scored candidates based on saved genres/authors |
| `recommendations/recommend_from_interests.sh` | interests and catalog | scored topic matches |
| `recommendations/recommend_for_discovery.sh` | library, interests, catalog | candidates from unfamiliar genres |
| `recommendations/refine_recommendations.sh` | candidates on stdin | deduplicated, ranked, unsaved shortlist |
| `data/book_database.sh` | operation and arguments | the sole reader/writer of persistent library storage |
| `data/books.csv` | database writes | persistent library |
| `config/interests.txt` | user edits | one interest per line; blank lines and `#` comments ignored |
| `tests/smoke.sh` | none | isolated integration checks; no changes to your library |

## Data contracts

Between programs, the records use `|` as the delimiter and have no header:

```text
Metadata:   title|author|genre|year
Library:    id|title|author|genre|year|status|rating|owned
Candidate:  title|author|genre|year|score|strategy|reason
```

The persisted file is real CSV, with a header and proper quoting. Its fields
are the same as the library record. The database performs the format conversion.
Missing genre, year or rating is an empty field. IDs are stable positive integers.
Statuses are `want-to-read`, `reading`, and `finished`; ownership is `yes`/`no`;
ratings are blank or integers from 1 to 5. Error messages use stderr and failures
return a nonzero exit code. `exists` returns 0 for found and 1 for absent.

## Trying the components directly

Run from `book-manager/`:

```bash
bash workflows/manage_library.sh add "Thinking in Systems" "Donella H. Meadows" want-to-read "" no
bash workflows/manage_library.sh list
printf 'systems\n' | bash books/search_books.sh
bash workflows/manage_library.sh status 1 finished
bash workflows/manage_library.sh rating 1 5
bash workflows/manage_library.sh owned 1 yes
bash data/book_database.sh exists "Thinking in Systems" "Donella H. Meadows"
bash books/fetch_book_metadata.sh "The Box" "Marc Levinson"
bash workflows/get_recommendations.sh 5
```

Use the actual book ID rather than assuming it is 1. Repeating the add command
returns a duplicate error. `BOOK_DB=/absolute/path/books.csv` selects a different
library; `BOOK_INTERESTS=/absolute/path/topics.txt` selects a different interests
file. These overrides are also how tests stay separate from personal data.

## Trace: Get Recommendations

1. The main menu opens `ui/recommendations_screen.sh`.
2. That screen calls `workflows/get_recommendations.sh` and captures stdout.
   Progress on stderr remains visible while the command runs.
3. The workflow starts all three workers with `&`. `$!` gives each worker's PID,
   which is stored in an array. Each worker has a separate temporary output file,
   so their output cannot become interleaved.
4. Only after all launches does the workflow call `wait` for each PID. A failed
   worker stops the workflow from returning a misleading partial shortlist.
   Completion messages are reported in launch order; fast workers can finish
   before their done message is printed.
5. `cat history interests discovery | bash refine_recommendations.sh` combines
   records and passes them through a real pipe. The refiner reads stdin, consults
   the database, and returns the shortlist. It buffers candidates for ranking.
6. The UI renders the result with Gum and asks whether to save the chosen book.
   Saving goes through the management workflow and database, with want-to-read
   status and owned=no. Temporary files are removed on exit.

The progress messages demonstrate streaming. Recommendations themselves are
combined after synchronization, not streamed as individual workers produce them.

## Recommendation rules

- History: each saved book contributes weight 3 if finished, otherwise 1, plus
  its rating if present. Books rated 1 or 2 contribute nothing. Each catalog
  candidate receives 70 plus matching genre and author weights, if any.
- Interests: case-insensitive literal substring matches against title and genre;
  score = 70 + 5 per matching interest. These are simple rules, not semantic AI.
- Discovery: genres not represented in saved books, excluding candidates that
  match any stated interest. Each gets score 45.
- Refinement: title+author form the identity key, ignoring case and repeated
  whitespace. Already-saved books are removed. Duplicate candidates retain the
  highest-scoring strategy. Sort by descending score, then alphabetically; keep
  five by default. If discovery would otherwise be excluded, replace the last
  item with the best discovery candidate. These scores are ranking heuristics,
  not probabilities. A size-one shortlist favors discovery when available.

## Why these choices?

No network calls or paid models are required, so the workflow is reproducible
and easy to explain. The tradeoff is a finite catalog and simple matching.
To add a catalog item, append `Title|Author|genre|YYYY` with no header. Use the
same genre labels consistently. Unknown manually added books have no metadata
until you add them to the catalog before saving; there is no automatic refresh.

Python is deliberately confined to CSV handling in the data-layer Bash file.
Splitting CSV on commas in Bash would corrupt valid book titles containing
commas. The database writes a temporary complete file and then replaces the
old one; failed validation leaves the original untouched. It does not implement
multi-writer locking. There is no delete action, login, cloud sync, or LLM call.
