# 20 MILLISECONDES

### *une image de Commodore 64, cycle par cycle*

Un livre qui apprend la puce graphique du Commodore 64 — le VIC-II — à quelqu'un qui **sait
programmer un peu**, dans n'importe quel langage, mais qui ne connaît **ni le C64, ni
l'assembleur**.

Toutes les vingt millisecondes, un C64 dessine une image complète : 312 lignes, 19 656
battements d'horloge. Le livre raconte ce qui se passe pendant **une seule** de ces images, en
zoomant chapitre après chapitre — la trame, la ligne, le cycle — jusqu'à faire faire à la
machine des choses que ses concepteurs n'avaient pas prévues.

📄 **[20-MILLISECONDES.pdf](20-MILLISECONDES.pdf)** — 65 pages · **[la source
markdown](20-MILLISECONDES.md)**

---

## Ce qui distingue ce livre

**Chaque image de ce livre est vraie.** Elle a été produite par le programme imprimé
juste au-dessus d'elle, assemblé et exécuté sur une machine réelle — un C64 Ultimate —, puis
capturée sur sa sortie vidéo. Aucune n'a été dessinée, simulée ou retouchée.

Et cette promesse est **vérifiée mécaniquement**, pas seulement affirmée :

| Contrôle | Résultat |
|---|---|
| Les 16 programmes imprimés s'assemblent et donnent le binaire officiel | **16 / 16**, au bit près |
| Chaque programme reproduit ce que le livre annonce, **mémoire entièrement salie avant le lancement** | **19 / 19** |
| Listings coupés par un saut de page (le copier-coller y survivrait mal) | **0** |

Le livre s'impose deux autres contraintes, qui font sa forme :

- **Treize instructions d'assembleur, pas une de plus**, du premier chapitre au FLI. Chacune
  arrive avec sa mini-fiche, au moment où elle sert.
- **Le rituel, à chaque chapitre** : une question qu'on peut voir à l'écran → un programme
  court → ce qu'on observe → l'explication. Jamais l'inverse.

---

## Ce que le lecteur fabrique en chemin

| | |
|---|---|
| ![une bande de couleur immobile](livre-pas-a-pas/ch02/bande-hw.png) | **Chapitre 2** — une bande de couleur parfaitement immobile, obtenue en guettant le faisceau. Le C64 ne sait pas dessiner de rectangle : il connaît les instants. |
| ![la Bad Line visible](livre-pas-a-pas/ch04/badline-hw.png) | **Chapitre 4** — un chronomètre à l'écran, où l'on voit le processeur se faire voler quarante cycles une ligne sur huit. Mesuré dans la capture : 0,29 changement de couleur contre 4 à 5 partout ailleurs. |
| ![le FLI](livre-pas-a-pas/ch09/fli-hw.png) | **Chapitre 9** — le FLI : 192 lignes ayant chacune ses propres couleurs, là où la fiche technique en promet 24. Avec sa cicatrice de 24 pixels à gauche, que personne n'a jamais su effacer. |

---

## Sommaire

| | |
|---|---|
| **0** | La machine vue de haut |
| **1** | Kit de survie 6502 |
| **2** | La trame : voir le temps |
| **3** | La ligne : 63 battements |
| **4** | La Bad Line : quand l'artiste réquisitionne le couloir |
| **5** | Les cellules : d'où viennent les caractères |
| **6** | Les sprites : huit objets libres |
| **7** | Les compteurs cachés, et l'écran qui tombe |
| **8** | Ouvrir la bordure |
| **9** | Le grand final : toutes les couleurs à la fois |
| **10** | La même machine en 2026 |
| | *Annexe : quatre pages à garder sous la main · Sources* |

---

## Le volume compagnon : « Au cœur du métal »

**[Au cœur du métal — Commodore 64 & Ultimate 64](reference/AU-COEUR-DU-METAL-C64-U64.pdf)**
est la référence dont ce livre est le guide de visite. Chaque encadré « Sous le capot » y
renvoie, par chapitre et par section.

Les deux n'ont pas le même métier, et c'est voulu :

|  | **Au cœur du métal** | **20 millisecondes** |
|---|---|---|
| ce qu'il fait | **atteste** la règle | **montre** le phénomène |
| comment on le lit | on le consulte | on le suit du début à la fin |
| ce qu'il suppose | qu'on sait déjà | qu'on ne sait rien |

Il **n'est pas une source primaire** : il a été écrit *à partir* des documents d'origine
(l'article de Christian Bauer, les chronogrammes de Marko Mäkelä, les tables de cycles du
6510…), qu'il rassemble, recoupe et traduit, en ancrant chaque affirmation sur celui qui
l'atteste. Et il **n'a aucune vocation pédagogique**, ce qu'il assume : il énonce, il
n'explique pas. Un débutant s'y noierait dès la troisième page.

**C'est l'aîné des deux, et c'est de sa lecture que ce livre est né** : tout y était juste, et
personne ne pouvait l'apprendre.

Le dossier [`reference/`](reference/) contient les deux volumes, leur chaîne LaTeX, et le
[corpus des sources primaires](reference/sources/) sur lequel tout repose.

---

## Fabriquer, exécuter, vérifier

```bash
./tools/build_pdf.sh                            # markdown → LaTeX → PDF
./tools/shoot.sh livre-pas-a-pas/ch04/badline.a # assembler, lancer sur le C64 Ultimate,
                                                #   et capturer ce qu'il affiche vraiment
python3 tools/verifie.py                        # les cinq contrôles mécaniques
```

**Prérequis** : [ACME](https://sourceforge.net/projects/acme-crossass/) 0.95 ou plus récent,
`pandoc` + `xelatex`, `python3` avec Pillow. Pour les captures : un C64 Ultimate joignable sur
le réseau (variable `C64U_IP`).

Chaque chapitre a son dossier dans [`livre-pas-a-pas/`](livre-pas-a-pas/) : les sources
assembleur, les captures, et de quoi tout rejouer. Le protocole de l'essai de reproductibilité
— salir toute la mémoire, puis vérifier que chaque programme tient encore sa promesse — est
consigné dans [REPRODUCTIBILITE.md](livre-pas-a-pas/REPRODUCTIBILITE.md).

---

## Comment ce livre a été fait

Rédigé par une intelligence artificielle (Claude) sous la direction de **Johnny Piette**, puis
audité par trois regards complémentaires : un vérificateur de faits confrontant chaque chiffre
aux sources, un lecteur jouant le **débutant total** (« à quelle page décroches-tu ? »), et un
lecteur jouant le **dactylo**, qui ne possède que le livre imprimé et tape ce qu'il voit.

Chacun a trouvé ce que les autres ne pouvaient pas voir : un sprite pointant vers un dessin
jamais écrit, deux chapitres qui se contredisaient, un bloc de code jamais refermé. Le
détail de ces passes, et les corrections qui en sont sorties, est dans
[CLAUDE.md](CLAUDE.md) — c'est aussi le document à lire pour reprendre le travail.

---

*Juillet 2026 — pour le Commodore 64, quarante-quatre ans après.*
