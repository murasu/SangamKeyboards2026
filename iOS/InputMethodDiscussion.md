Architecture Questions to Consider

1. Where to Display Composition?
• Inline: Replace the composition buffer in-place in the text editor
• Candidate Window: Show composition in a separate overlay (like macOS IME)
• Underline: Show composition with underline to indicate it's not committed

2. Undo Behavior
• Should backspace within composition edit the buffer or delete previous translation?
• How to handle undo when composition is committed?

3. Selection/Cursor Management
• What happens if user moves cursor while composing?
• Should we commit composition when cursor moves?

4. Multiple Translation Candidates
• Does your translator return multiple options?
• How to cycle through candidates (Tab, arrow keys)?


1. Yes, in-line. We can show the composition buffer in a different color or underlined.
2. Backspace can also be passed to the translator. It'll do the delete appropriately.
3. Yes, commit the composition when cursor is moved.
4. Translation is independant of candidates. Once translation returns, we update the buffer and then call getCandidates with the word in the buffer. If user than picks a candidate, we commit that candidate instead of the buffer.


Questions for You

1. Display Style: Do you want inline composition (like iOS) or candidate window (like macOS IME)?

2. Commit Keys: Besides space and return, what other keys should commit? (punctuation, numbers, arrows?)

3. Cancellation: Should Escape cancel current composition without committing?

4. Multiple Candidates: Does your translator provide alternatives, or just one result per composition?

5. Platform Differences: Should this work the same on iOS and macOS, or adapt to platform conventions?


Other questions:
1. Composition is inline - perhaps with a different attribute. This editor is targeted at iPads mainly so candidates can be a dropdown below the composition. Five candidates at max
2. If isTranslatableKey returns false, it's a commit key
3. Escape is usually not present in iPad keyboad - but if its a 3rd party kbs, it should just hide the candidate window and allow composition to continue for the current word without predictions
4. Up to 5 candidates max per word being composed
5. The mechanics is the same, the UI can be different - but since this is specifically targeted at external keyboard usage, we can use the iPad convension as the default.

Let's focus on the composition and translation first. For candidates, use 3 to 5 random Tamil words for now. Let's start with the key translation alone first.
