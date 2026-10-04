[🇫🇷 Français](README.md) · 🇬🇧 **English**

# 20 MILLISECONDS

### *one Commodore 64 frame, cycle by cycle*

A book that teaches the Commodore 64's graphics chip — the VIC-II — to someone who **can
program a little**, in any language, but who knows **neither the C64 nor assembly**.

Every twenty milliseconds, a C64 draws a complete frame: 312 lines, 19,656 clock beats. The
book tells what happens during **one single** such frame, zooming in chapter after chapter —
the frame, the line, the cycle — until the machine does things its designers never planned for.

📄 **[20-MILLISECONDS.pdf](20-MILLISECONDS.pdf)** — 66 pages · **[markdown
source](20-MILLISECONDS.md)**

*The English edition is a translation of the French original, made with AI assistance (Claude);
it has not yet been reviewed by a bilingual human reader. The French original is
[20-MILLISECONDES.pdf](20-MILLISECONDES.pdf) ([source](20-MILLISECONDES.md)). Program labels,
file names and the screenshots are kept as in the original.*

---

## What sets this book apart

**Every image in this book is real.** It was produced by the program printed right above it,
assembled and run on a real machine — a C64 Ultimate — then captured from its video output.
None was drawn, simulated or retouched.

And this promise is **checked mechanically**, not just asserted:

| Check | Result |
|---|---|
| The 16 printed programs assemble and give the official binary | **16 / 16**, bit for bit |
| Each program reproduces what the book says, **with memory fully dirtied before launch** | **19 / 19** |
| Listings split by a page break (copy-pasting them would not survive) | **0** |

The book imposes two other constraints, which give it its shape:

- **Thirteen assembly instructions, not one more**, from the first chapter to the FLI. Each
  one arrives with its own mini-card, at the moment it is needed.
- **The ritual, in every chapter**: a question you can see on the screen → a short program →
  what you observe → the explanation. Never the other way round.

---

## Project structure

```
20-millisecondes/
│
├── 20-MILLISECONDES.md        THE BOOK (French) — single source (~3,100 lines)
├── 20-MILLISECONDES.pdf       its rendering (66 pages)
├── 20-MILLISECONDS.md         the English edition (translation)
├── 20-MILLISECONDS.pdf        its rendering (66 pages)
├── README.md                  this page, in French
├── README.en.md               this page, in English
├── LICENSE.md                 the licenses (in French)
│
├── livre-pas-a-pas/           ONE FOLDER PER CHAPTER
│   └── ch00/ … ch09/          for each: the .a sources and the -hw.png screenshots
│
└── reference/
    ├── AU-COEUR-DU-METAL.md            the reference volume (internal version)
    ├── AU-COEUR-DU-METAL-C64-U64.md    its public edition — the one the book cites
    ├── AU-COEUR-DU-METAL-C64-U64.pdf
    ├── tools-latex/                    the LaTeX toolchain of these volumes (+ TikZ figures)
    └── sources/                        THE CORPUS: 14 original documents (§ Sources)
```

The `.prg` files are not versioned: they are products, and `acme` rebuilds them on demand.

---

## The programs

Nineteen assembly sources, one per experiment. All were assembled with **ACME**, run on a
**C64 Ultimate** and captured. The first sixteen are printed in the book; the last three are
variants that the text describes without reprinting them.

| Chapter | Source | Lines | What it does |
|---|---|---|---|
| **0** | [`teaser.a`](livre-pas-a-pas/ch00/teaser.a) | 28 | The trailer: waves of color, line by line. The reader does not understand it yet — it is the destination. |
| **1** | [`bordure.a`](livre-pas-a-pas/ch01/bordure.a) | 12 | Three instructions: the border turns red, and BASIC takes control back. |
| **1** | [`stroboscope.a`](livre-pas-a-pas/ch01/stroboscope.a) | 9 | Black, white, black, white, as fast as possible. You don't get a flicker: you get stripes. |
| **2** | [`bande.a`](livre-pas-a-pas/ch02/bande.a) | 19 | Watching for the beam to lay down a band of color. |
| **3** | [`degrade.a`](livre-pas-a-pas/ch03/degrade.a) | 29 | The trailer, rewritten and explained: a color planned in advance for each line. |
| **4** | [`badline.a`](livre-pas-a-pas/ch04/badline.a) | 7 | The visual stopwatch: two instructions that make the Bad Line visible to the naked eye. |
| **4** | [`eteint.a`](livre-pas-a-pas/ch04/eteint.a) | 9 | The control experiment: screen off, no more Bad Lines, the stripes become perfect again. |
| **4** | [`patience.a`](livre-pas-a-pas/ch04/patience.a) | 12 | A calibrated wait: 20 cycles instead of 9, and the predicted staircase appears (−24 px per line). |
| **4** | [`chrono.a`](livre-pas-a-pas/ch04/chrono.a) | 7 | *(unprinted variant)* the same stopwatch, painted on the border instead of the background. |
| **5** | [`matrice.a`](livre-pas-a-pas/ch05/matrice.a) | 29 | Writing straight into the thousand screen lockers — no `PRINT`, no operating system. |
| **5** | [`demenage.a`](livre-pas-a-pas/ch05/demenage.a) | 31 | Building a second, invisible matrix, then switching the screen over to it with a single write. |
| **6** | [`unsprite.a`](livre-pas-a-pas/ch06/unsprite.a) | 42 | A 24 × 21-pixel creature, drawn in binary, floating above the text. |
| **6** | [`huit.a`](livre-pas-a-pas/ch06/huit.a) | 82 | Eight sprites in a row, eight colors, every value written by hand: nothing is hidden. |
| **6** | [`voleurs.a`](livre-pas-a-pas/ch06/voleurs.a) | 79 | The stopwatch and the eight sprites together: you *see* the cycles they steal. |
| **7** | [`chute.a`](livre-pas-a-pas/ch07/chute.a) | 24 | FLD: prevent the Bad Line, and the whole screen falls forty lines. |
| **8** | [`sansbord.a`](livre-pas-a-pas/ch08/sansbord.a) | 57 | Dodging the border's two comparisons: it no longer happens, and a sprite walks around in it. |
| **8** | [`fantome.a`](livre-pas-a-pas/ch08/fantome.a) | 57 | *(described variant)* the same, with the ghost byte forced, to show what the VIC reads there. |
| **9** | [`fli.a`](livre-pas-a-pas/ch09/fli.a) | 38 | The FLI: a Bad Line triggered on every line, 192 lines of free colors. |
| **9** | [`flirate.a`](livre-pas-a-pas/ch09/flirate.a) | 53 | *(the failure, kept on purpose)* the counting loop, right to the cycle, that breaks anyway. |

Each source is self-contained: it holds its BASIC stub, its data and its code. None depends on
what another program might have left in memory — this has been measured, with the memory-dirtying
tool.

---

## The gallery

The book fits in these nineteen screens. Each was produced by the chapter's program, assembled
and run on a real machine, then captured from its video output. Taken in order, they trace the
path of the book — from three instructions to mastery of the cycle.

| | | |
|---|---|---|
| ![](livre-pas-a-pas/ch00/teaser-hw.png) **0 · the trailer**<br><sub>Six instructions, one color per line. You don't understand it yet: it is the destination.</sub> | ![](livre-pas-a-pas/ch01/bordure-hw.png) **1 · red border**<br><sub>The reader's first program. Three instructions, and `READY.` comes back.</sub> | ![](livre-pas-a-pas/ch01/stroboscope-hw.png) **1 · the stroboscope**<br><sub>Changing color as fast as possible gives no flicker but stripes: the beam is slower than we are.</sub> |
| ![](livre-pas-a-pas/ch02/bande-hw.png) **2 · the steady band**<br><sub>By watching for the beam. The C64 knows no rectangles, only instants.</sub> | ![](livre-pas-a-pas/ch03/degrade-hw.png) **3 · one color per line**<br><sub>A table computed in advance, read at the index of the current line. The book's signature pattern.</sub> | ![](livre-pas-a-pas/ch04/badline-hw.png) **4 · the Bad Line, to the naked eye**<br><sub>One line in eight, the processor is frozen: that line stays a single color.</sub> |
| ![](livre-pas-a-pas/ch04/eteint-hw.png) **4 · the control experiment**<br><sub>Screen off: nothing to read, nothing stolen. Six boundaries per line, zero drift.</sub> | ![](livre-pas-a-pas/ch04/patience-hw.png) **4 · the predicted staircase**<br><sub>A calibrated wait, and 63 mod 20 = 3 cycles: the measured shift is −24 pixels per line.</sub> | ![](livre-pas-a-pas/ch04/chrono-hw.png) **4 · the stopwatch on the border**<br><sub>The first version: each stripe marks nine elapsed cycles.</sub> |
| ![](livre-pas-a-pas/ch05/matrice-hw.png) **5 · writing into the screen**<br><sub>A thousand lockers, one byte per character. No `PRINT`, no operating system.</sub> | ![](livre-pas-a-pas/ch05/demenage-hw.png) **5 · the screen moves house**<br><sub>A second matrix built in secret, then a single write: the screen is just an address.</sub> | ![](livre-pas-a-pas/ch06/unsprite-hw.png) **6 · a creature**<br><sub>24 × 21 pixels drawn with 0s and 1s, placed to the pixel above the text.</sub> |
| ![](livre-pas-a-pas/ch06/huit-hw.png) **6 · the eight in a row**<br><sub>A single drawing in memory, eight copies on screen, eight colors.</sub> | ![](livre-pas-a-pas/ch06/voleurs-hw.png) **6 · the eight thieves**<br><sub>The same ones, laid across the stopwatch: you see the cycles they take.</sub> | ![](livre-pas-a-pas/ch07/chute-hw.png) **7 · the screen falls**<br><sub>By preventing the Bad Line, the VIC reads nothing more: everything drops forty lines.</sub> |
| ![](livre-pas-a-pas/ch08/sansbord-hw.png) **8 · no more border**<br><sub>Two comparisons dodged, and the frame no longer happens. The creature floats where the screen doesn't exist.</sub> | ![](livre-pas-a-pas/ch08/fantome-hw.png) **8 · the ghost byte**<br><sub>What the VIC displays when it has nothing to read: a single memory locker, repeated forever.</sub> | ![](livre-pas-a-pas/ch09/flirate-hw.png) **9 · the failure, kept on purpose**<br><sub>Forty-eight right lines, then the collapse. The error was not in the calculation but in the assumption.</sub> |
| ![](livre-pas-a-pas/ch09/fli-hw.png) **9 · the FLI**<br><sub>192 lines each with their own colors, where the machine promises 24. And its 24-pixel scar, which nobody has ever managed to erase.</sub> | | |

---

## Contents

| | |
|---|---|
| **0** | The Machine from Above |
| **1** | 6502 Survival Kit |
| **2** | The Frame: Seeing Time |
| **3** | The Line: 63 Beats |
| **4** | The Bad Line: When the Artist Requisitions the Corridor |
| **5** | The Cells: Where Characters Come From |
| **6** | Sprites: Eight Free Objects |
| **7** | The Hidden Counters, and the Screen That Falls |
| **8** | Opening the Border |
| **9** | The Grand Finale: All the Colors at Once |
| **10** | The Same Machine in 2026 |
| | *Appendix: Three Pages to Keep at Hand · Sources* |

---

## The companion volume: « Au cœur du métal »

**[Au cœur du métal — Commodore 64 & Ultimate 64](reference/AU-COEUR-DU-METAL-C64-U64.pdf)**
is the reference of which this book is the guided tour. Every "Under the hood" box points to
it, by chapter and by section. *(The volume exists only in French.)*

The two do not have the same job, and that is deliberate:

|  | **Au cœur du métal** | **20 milliseconds** |
|---|---|---|
| what it does | **attests** the rule | **shows** the phenomenon |
| how you read it | you look things up in it | you follow it from start to finish |
| what it assumes | that you already know | that you know nothing |

It is **not a primary source**: it was written *from* the original documents (Christian Bauer's
article, Marko Mäkelä's timing charts, the 6510 cycle tables…), which it gathers, cross-checks
and translates, anchoring each claim on the document that attests it. And it **has no teaching
ambition**, which it embraces: it states, it does not explain. A beginner would drown in it by
the third page.

**It is the elder of the two, and this book was born from reading it**: everything in it was
right, and nobody could learn from it.

The [`reference/`](reference/) folder contains the two volumes, their LaTeX toolchain, and the
[corpus of primary sources](reference/sources/) on which everything rests.

---

## Assembling and running a program

```bash
cd livre-pas-a-pas/ch04 && acme badline.a      # produces badline.prg
```

The `.prg` runs on a C64 Ultimate or a real machine (`LOAD"BADLINE",8,1` then `RUN`), or in the
VICE emulator (`x64sc`): drag the file onto the window.

**Prerequisite**: [ACME](https://sourceforge.net/projects/acme-crossass/) 0.95 or later.

Each chapter has its folder in [`livre-pas-a-pas/`](livre-pas-a-pas/): the assembly sources and
the screenshots.

---

## How this book was made

Written by an artificial intelligence (Claude) under the direction of **Johnny Piette**, then
audited from three complementary angles: a fact-checker confronting every figure with the
sources, a reader playing the **total beginner** ("on which page do you drop out?"), and a reader
playing the **typist**, who has only the printed book and types what they see.

Each found what the others could not see: a sprite pointing to a drawing that was never written,
two chapters contradicting each other, a code block that was never closed. The book was then
re-read from end to end by several independent AI reviewers, and every contested figure was
re-checked against the sources or measured on the machine.

---

## License, and the coffee

The book — text, PDF and **all screenshots** — is under
**[Creative Commons BY-SA 4.0](LICENSE.md)**: share it, adapt it, even commercially, provided
you credit the source and share alike.

The **programs** are under the **MIT license**, deliberately more permissive: a reader must be
able to take a listing from the book into their own code without it committing them to
anything.

⚠️ The [`reference/`](reference/) folder is an exception: it contains third-party documents
(some of them "all rights reserved") kept as a working copy. **It must not be redistributed** —
see [LICENSE.md](LICENSE.md) (in French), which also explains how to replace it with the list
of download addresses.

*And if you enjoyed the book, you can buy me a coffee ☕ — it's optional, and changes nothing
about your rights to the work.*

---

*July 2026 — for the Commodore 64, forty-four years later. English edition: October 2026.*
