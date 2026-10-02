# Record your narrated demo

Aim for about 2 minutes. Increase your terminal font size and keep the full Gum
menu visible. Use a screen recorder with your microphone enabled. This is a
recording outline, not a claim that a video already exists.

1. **Launch (15 seconds).** Run `bash app.sh`.
   Explain that this is a personal book manager composed of small Bash programs.
2. **Add a book (30 seconds).** Add `Thinking in Systems` by
   `Donella H. Meadows`, select an honest reading status, and indicate ownership.
   Explain that the workflow looks up metadata in the offline catalog before
   asking the data layer to save the book.
3. **Browse and rate (25 seconds).** Browse, select the book, and give it a rating
   if you have read it. Point out that ownership and reading status are separate.
4. **Get recommendations (35 seconds).** Show the running/done messages, select
   a recommendation, explain its reason, and save it. Explain that three
   independent processes run concurrently and the refiner removes duplicates
   and books already saved, while keeping room for discovery.
5. **Architecture (15 seconds).** Show the project folders. Explain that the UI
   calls workflows and that only the data layer opens `books.csv`.

Use your own words and be ready to open a file and explain it. If you already
saved the example book, choose another catalog title instead. After recording,
watch the video to check terminal readability, microphone audio, and that all
operations succeeded. Add `demo.mp4` or a working external video link to README.
