#!/usr/bin/env bash
# The ONLY component that opens books.csv. Python's standard CSV module
# handles commas and quotes correctly; all orchestration remains in Bash.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 - "${BOOK_DB:-$HERE/books.csv}" "$@" <<'PY'
import csv
import os
from pathlib import Path
import sys
import tempfile

path = Path(sys.argv[1])
args = sys.argv[2:]
fields = 'id title author genre year status rating owned'.split()
statuses = {'want-to-read', 'reading', 'finished'}

def fail(message):
    sys.exit('Database: ' + message)

def key(title, author):
    return (' '.join(title.casefold().split()), ' '.join(author.casefold().split()))

def emit(row):
    print('|'.join(row[f] for f in fields))

def validate(row):
    if any(any(ord(c) < 32 or ord(c) == 127 or c == '|' for c in v) for v in row.values()):
        fail('fields cannot contain pipes, tabs, newlines or control characters.')
    if not row['title'].strip() or not row['author'].strip():
        fail('title and author are required.')
    if row['status'] not in statuses:
        fail('status must be want-to-read, reading or finished.')
    if row['rating'] not in {'', '1', '2', '3', '4', '5'}:
        fail('rating must be blank or an integer from 1 to 5.')
    if row['owned'] not in {'yes', 'no'}:
        fail('owned must be yes or no.')
    if row['year'] and (not row['year'].isdigit() or len(row['year']) != 4):
        fail('year must be blank or four digits.')

def run():
    if not args:
        fail('use list, search TERM, exists TITLE AUTHOR, add, status ID VALUE, rating ID VALUE, owned ID VALUE.')
    command, *values = args
    counts = {'list': 0, 'search': 1, 'exists': 2, 'add': 7, 'edit': 5, 'status': 2, 'rating': 2, 'owned': 2}
    if command not in counts or len(values) != counts[command]:
        fail('wrong command or arguments; see README.md.')
    rows = []
    if path.exists():
        with path.open(newline='', encoding='utf-8') as stream:
            reader = csv.DictReader(stream)
            if reader.fieldnames != fields:
                fail('unexpected CSV header; original file was not changed.')
            rows = list(reader)
        for row in rows:
            if set(row) != set(fields) or any(v is None for v in row.values()):
                fail('malformed CSV row; original file was not changed.')
            validate(row)
            if not row['id'].isdigit():
                fail('invalid book ID.')
        if len({r['id'] for r in rows}) != len(rows):
            fail('duplicate book ID.')
    if command in {'list', 'search'}:
        for row in rows:
            if command == 'list' or values[0].casefold() in ' '.join(row.values()).casefold():
                emit(row)
        return
    if command == 'exists':
        sys.exit(0 if any(key(r['title'], r['author']) == key(*values) for r in rows) else 1)
    if command == 'add':
        title, author, genre, year, status, rating, owned = (v.strip() for v in values)
        if any(key(r['title'], r['author']) == key(title, author) for r in rows):
            fail('that title and author are already saved.')
        book_id = str(max((int(r['id']) for r in rows), default=0) + 1)
        row = dict(zip(fields, [book_id, title, author, genre, year, status, rating, owned]))
        validate(row)
        rows.append(row)
    else:
        row = next((r for r in rows if r['id'] == values[0]), None)
        if row is None:
            fail('book ID not found.')
        if command == 'edit':
            title, author, genre, year = (v.strip() for v in values[1:])
            if any(r['id'] != row['id'] and key(r['title'], r['author']) == key(title, author) for r in rows):
                fail('that title and author are already saved.')
            row.update(title=title, author=author, genre=genre, year=year)
        else:
            row[command] = values[1]
        validate(row)
    # Replace only after a complete file has been written successfully.
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', newline='', encoding='utf-8',
                                         dir=path.parent, delete=False) as stream:
            temporary = stream.name
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        os.replace(temporary, path)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)
    emit(row)

try:
    run()
except (OSError, csv.Error, ValueError) as error:
    fail(str(error))
PY
