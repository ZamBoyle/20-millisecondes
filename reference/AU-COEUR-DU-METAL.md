# AU CŒUR DU MÉTAL
### Le livre de référence Arena64 — C64 & Ultimate 64

*Synthèse du corpus de sources primaires (20 documents, `docs/`), fusionnée avec les mesures
matérielles du projet Arena64. Rédigé par Claude (extraction multi-agents), audité par Codex
contre les sources. Version 1.0 — 26 juillet 2026.*

---

## Mode d'emploi (À LIRE : le contrat de ce livre)

**Ce livre est le PREMIER arrêt pour toute question matérielle.** Il condense la couche
conceptuelle du corpus sans perte normative : les règles numérotées, formules, tables de
registres et diagrammes de cycles y sont quasi-verbatim. Chaque section porte une **ancre**
`[Source §x.y]` : pour toute décision critique au cycle près, VÉRIFIER contre le texte
primaire ancré avant de coder. Le livre indexe ; les sources prouvent.

**Hiérarchie de confiance** (discipline du projet, apprise à la dure) :
1. **Mesure sur le VRAI C64 Ultimate** (192.168.178.148) — l'instrument final ;
2. **Ce livre + sa source ancrée** — la théorie de référence ;
3. Tout le reste (souvenirs, forums, intuition) — hypothèses à vérifier.

**Convention hexadécimale** : le ch.1 conserve les minuscules de Bauer (`$d011`) ; les autres
chapitres suivent la casse de leurs sources (majuscules le plus souvent).

**Les trois dictionnaires ne sont PAS fusionnés ici** (les fusionner = les détruire) ;
ils restent entiers à côté, ce livre pointe dedans :
- `mapping-c64-leemon-project64.txt` — chaque adresse mémoire, commentée (539 Ko) ;
- `c64prg-reference-guide-project64.txt` — le manuel officiel Commodore (979 Ko) ;
- `c64disasm-rom-commented-en.txt` — BASIC+KERNAL désassemblés ligne à ligne (545 Ko).

**⚠️ Spécificité de CE projet** : la machine est un **C64 Ultimate firmware COMMODORE**
(fork réduit, « 1.0 »/« 3.14 »), pas un C64 d'époque ni un U64 firmware Gideon plein.
Le chapitre « Couche empirique » PRIME sur la théorie quand ils divergent — chaque
divergence y est mesurée, datée, reproduite.

## Table des matières
1. Le VIC-II — règles complètes (d'après Bauer, rév. 2024)
2. Timing fin : chronogrammes, vols de cycles, sprite crunch (Mäkelä, Ojala, Åkesson)
3. Le 6510 : cycles et interruptions (64doc)
4. SID & CIA (datasheet 6581, modèle Lorenz)
5. Le REU : DMA `$DF00` (programmation + registres)
6. L'Ultimate 64 : REST, streams, turbo, UCI (docs Gideon — à vérifier sur notre fork)
7. **La couche empirique Arena64** — nos mesures, nos pièges, nos règles
8. Index des adresses du projet → dictionnaires

---

# Chapitre 1 — Le VIC-II : règles complètes (Bauer, révision 2024)

## VIC-II 6567/6569 — Condensé de référence normatif
*(D'après : Christian Bauer, « The MOS 6567/6569 video controller (VIC-II) and its application in the Commodore 64 », révision 2024-09-29. Toutes les valeurs hex/cycles/registres sont reprises telles quelles de la source.)*

---

## 1. Contexte système : bus, phases, BA/AEC [Bauer §2.2–2.4]

- Un cycle d'horloge (ϕ2, 985,248 kHz PAL / 1022,7 kHz NTSC) = deux phases : **le VIC accède au bus en première phase (ϕ2 bas), le 6510 en seconde phase (ϕ2 haut)**. AEC suit ϕ2 de près. Les deux puces font un accès mémoire à **chaque** cycle, même inutile (pas de wait states, pas de cache ; chaque accès tient en un cycle). Le VIC ne fait que des lectures. [Bauer §2.4.3]
- **BA** : normalement haut. Quand le VIC a besoin de la seconde phase (pointeurs de caractères : 40 cycles supplémentaires ; données sprite : 2 cycles par sprite), BA passe bas **3 cycles avant** la prise de bus (3 = nombre maximal d'écritures successives du 6510 ; RDY est ignoré en écriture). Après ces 3 cycles, AEC reste bas aussi en seconde phase et le VIC sort ses adresses. Un accès lecture du 6510 pendant BA bas l'arrête (« x » devient « X » dans les diagrammes). [Bauer §2.3, Bauer §2.4.3]
- **AEC** : met en tri-state les drivers d'adresse du 6510 ; bas = le VIC tient le bus. Normalement bas en phase 1, haut en phase 2. [Bauer §2.3]
- **Bus vidéo** : 14 bits d'adresse (16 Ko) ; les 2 bits manquants viennent des **bits 0/1 inversés du port A de CIA 2** (choix d'une des 4 banques de 16 Ko). Bus de données 12 bits : 8 bits vers la RAM principale, 4 bits supérieurs vers la Color RAM (1K×4, adressée par les 10 bits bas de l'adresse VIC, donc disponible dans toutes les banques). La **Char ROM** apparaît aux adresses VIC `$1000`–`$1fff` dans les **banques 0 et 2**. [Bauer §2.3, Bauer §2.4.2]
- Les 47 registres du VIC sont mappés en `$d000` et **répétés tous les 64 octets dans `$d000`–`$d3ff`** (décodage incomplet). [Bauer §2.4.1]
- Unités d'affichage et unités d'accès mémoire sont **séparées** (tampon de données entre les deux) : on peut les découpler par programmation et afficher des données sans les avoir relues (contenu résiduel du tampon). [Bauer §3.1]

---

## 2. Table complète des registres `$d000`–`$d02e` [Bauer §3.2]

| # | Adr. | Bit7 | Bit6 | Bit5 | Bit4 | Bit3 | Bit2 | Bit1 | Bit0 | Fonction |
|---|------|------|------|------|------|------|------|------|------|----------|
| 0 | `$d000` | ←M0X→ | | | | | | | | Coordonnée X sprite 0 |
| 1 | `$d001` | ←M0Y→ | | | | | | | | Coordonnée Y sprite 0 |
| 2 | `$d002` | ←M1X→ | | | | | | | | Coordonnée X sprite 1 |
| 3 | `$d003` | ←M1Y→ | | | | | | | | Coordonnée Y sprite 1 |
| 4 | `$d004` | ←M2X→ | | | | | | | | Coordonnée X sprite 2 |
| 5 | `$d005` | ←M2Y→ | | | | | | | | Coordonnée Y sprite 2 |
| 6 | `$d006` | ←M3X→ | | | | | | | | Coordonnée X sprite 3 |
| 7 | `$d007` | ←M3Y→ | | | | | | | | Coordonnée Y sprite 3 |
| 8 | `$d008` | ←M4X→ | | | | | | | | Coordonnée X sprite 4 |
| 9 | `$d009` | ←M4Y→ | | | | | | | | Coordonnée Y sprite 4 |
| 10 | `$d00a` | ←M5X→ | | | | | | | | Coordonnée X sprite 5 |
| 11 | `$d00b` | ←M5Y→ | | | | | | | | Coordonnée Y sprite 5 |
| 12 | `$d00c` | ←M6X→ | | | | | | | | Coordonnée X sprite 6 |
| 13 | `$d00d` | ←M6Y→ | | | | | | | | Coordonnée Y sprite 6 |
| 14 | `$d00e` | ←M7X→ | | | | | | | | Coordonnée X sprite 7 |
| 15 | `$d00f` | ←M7Y→ | | | | | | | | Coordonnée Y sprite 7 |
| 16 | `$d010` | M7X8 | M6X8 | M5X8 | M4X8 | M3X8 | M2X8 | M1X8 | M0X8 | MSB des coordonnées X |
| 17 | `$d011` | RST8 | ECM | BMM | DEN | RSEL | YS2 | YS1 | YS0 | Registre de contrôle 1 (YSCROLL = bits 0–2) |
| 18 | `$d012` | ←RASTER→ | | | | | | | | Compteur raster |
| 19 | `$d013` | ←LPX→ | | | | | | | | Crayon optique X |
| 20 | `$d014` | ←LPY→ | | | | | | | | Crayon optique Y |
| 21 | `$d015` | M7E | M6E | M5E | M4E | M3E | M2E | M1E | M0E | Sprite activé |
| 22 | `$d016` | – | – | RES | MCM | CSEL | XS2 | XS1 | XS0 | Registre de contrôle 2 (XSCROLL = bits 0–2) |
| 23 | `$d017` | M7YE | M6YE | M5YE | M4YE | M3YE | M2YE | M1YE | M0YE | Expansion Y des sprites |
| 24 | `$d018` | VM13 | VM12 | VM11 | VM10 | CB13 | CB12 | CB11 | – | Pointeurs mémoire |
| 25 | `$d019` | IRQ | – | – | – | ILP | IMMC | IMBC | IRST | Registre d'interruption (latch) |
| 26 | `$d01a` | – | – | – | – | ELP | EMMC | EMBC | ERST | Interruptions autorisées |
| 27 | `$d01b` | M7DP | M6DP | M5DP | M4DP | M3DP | M2DP | M1DP | M0DP | Priorité sprite/données |
| 28 | `$d01c` | M7MC | M6MC | M5MC | M4MC | M3MC | M2MC | M1MC | M0MC | Sprite multicolore |
| 29 | `$d01d` | M7XE | M6XE | M5XE | M4XE | M3XE | M2XE | M1XE | M0XE | Expansion X des sprites |
| 30 | `$d01e` | M7M | M6M | M5M | M4M | M3M | M2M | M1M | M0M | Collision sprite–sprite |
| 31 | `$d01f` | M7D | M6D | M5D | M4D | M3D | M2D | M1D | M0D | Collision sprite–données |
| 32 | `$d020` | – | – | – | – | ←EC→ | | | | Couleur de bordure |
| 33 | `$d021` | – | – | – | – | ←B0C→ | | | | Couleur de fond 0 |
| 34 | `$d022` | – | – | – | – | ←B1C→ | | | | Couleur de fond 1 |
| 35 | `$d023` | – | – | – | – | ←B2C→ | | | | Couleur de fond 2 |
| 36 | `$d024` | – | – | – | – | ←B3C→ | | | | Couleur de fond 3 |
| 37 | `$d025` | – | – | – | – | ←MM0→ | | | | Multicolore sprite 0 |
| 38 | `$d026` | – | – | – | – | ←MM1→ | | | | Multicolore sprite 1 |
| 39 | `$d027` | – | – | – | – | ←M0C→ | | | | Couleur sprite 0 |
| 40 | `$d028` | – | – | – | – | ←M1C→ | | | | Couleur sprite 1 |
| 41 | `$d029` | – | – | – | – | ←M2C→ | | | | Couleur sprite 2 |
| 42 | `$d02a` | – | – | – | – | ←M3C→ | | | | Couleur sprite 3 |
| 43 | `$d02b` | – | – | – | – | ←M4C→ | | | | Couleur sprite 4 |
| 44 | `$d02c` | – | – | – | – | ←M5C→ | | | | Couleur sprite 5 |
| 45 | `$d02d` | – | – | – | – | ←M6C→ | | | | Couleur sprite 6 |
| 46 | `$d02e` | – | – | – | – | ←M7C→ | | | | Couleur sprite 7 |

**Notes normatives** [Bauer §3.2] :
- Les bits marqués « – » ne sont pas connectés et **se lisent à « 1 »**.
- Registres répétés tous les 64 octets dans `$d000`–`$d3ff`.
- Les adresses inutilisées **`$d02f`–`$d03f`** se lisent `$ff` ; l'écriture y est ignorée.
- **`$d01e` et `$d01f` ne peuvent pas être écrits** et sont automatiquement remis à zéro **à la lecture**.
- Le bit **RES** (`$d016` bit 5) n'a aucune fonction connue sur 6567/6569 (sur le 6566, il arrête le VIC).
- **RST8** (`$d011` bit 7) est le bit 8 de `$d012` ; l'ensemble s'appelle « RASTER ». **L'écriture** dans ces bits fixe la ligne de comparaison pour l'interruption raster.

---

## 3. Palette [Bauer §3.3]

16 couleurs câblées, codées sur 4 bits :

| N° | Couleur | N° | Couleur |
|----|---------|----|---------|
| 0 | noir | 8 | orange |
| 1 | blanc | 9 | brun |
| 2 | rouge | 10 | rouge clair |
| 3 | cyan | 11 | gris foncé |
| 4 | rose (« pink ») | 12 | gris moyen |
| 5 | vert | 13 | vert clair |
| 6 | bleu | 14 | bleu clair |
| 7 | jaune | 15 | gris clair |

Génération analogique (pas de RGB) : mélange sinus/cosinus dérivé de ϕCOLOR, phase+amplitude modulées par couleur. Luminance : les anciennes révisions (6569R1) produisaient **5 niveaux** distincts, les plus récentes **9 niveaux**. Pas d'entrelacement : sortie toujours progressive. [Bauer §2.3, Bauer §3.3]

---

## 4. Dimensions d'affichage, RSEL/CSEL, types de VIC [Bauer §3.4]

Convention de repérage : Y = numéro de ligne raster (RASTER, `$d011`/`$d012`) ; X = système de coordonnées **des sprites** ; 8 pixels = 1 cycle d'horloge (une coordonnée X de sprite est donc 8× plus précise qu'un numéro de cycle). Le rendu lu en mémoire est affiché avec un **retard de 12 pixels** [Bauer §3.6.1].

**Fenêtre d'affichage (display window)** — immobile au centre ; RSEL/CSEL ne déplacent **que** le début/la fin de l'affichage de la bordure ; la position de la fenêtre, sa résolution et la matrice vidéo (toujours 40×25) ne changent pas :

| RSEL | Hauteur | Première ligne | Dernière ligne |
|------|---------|----------------|----------------|
| 0 | 24 lignes texte / 192 pixels | 55 (`$37`) | 246 (`$f6`) |
| 1 | 25 lignes texte / 200 pixels | 51 (`$33`) | 250 (`$fa`) |

| CSEL | Largeur | Première coord. X | Dernière coord. X |
|------|---------|-------------------|--------------------|
| 0 | 38 caractères / 304 pixels | 31 (`$1f`) | 334 (`$14e`) |
| 1 | 40 caractères / 320 pixels | 24 (`$18`) | 343 (`$157`) |

RSEL=0 : les bordures haute et basse gagnent chacune 4 pixels sur la fenêtre. CSEL=0 : la bordure gauche gagne 7 pixels, la droite 9.

**XSCROLL** (`$d016` bits 0–2) et **YSCROLL** (`$d011` bits 0–2) : décalage de la graphique dans la fenêtre de 0 à 7 pixels vers la droite/le bas. Alignement de la graphique avec la fenêtre : **XSCROLL=0 et YSCROLL=3** pour 25 lignes/40 colonnes ; **7 et 7** pour 24 lignes/38 colonnes.

**Types de VIC** :

| Type | Système | Lignes | Lignes visibles | Cycles/ligne | Pixels visibles/ligne |
|------|---------|--------|------------------|--------------|------------------------|
| 6567R56A | NTSC-M | 262 | 234 | 64 | 411 |
| 6567R8 | NTSC-M | 263 | 235 | 65 | 418 |
| 6569 | PAL-B | 312 | 284 | 63 | 403 |

| Type | 1re ligne vblank | Dernière ligne vblank | 1re coord. X de la ligne | 1re coord. X visible | Dernière coord. X visible |
|------|------------------|------------------------|--------------------------|----------------------|----------------------------|
| 6567R56A | 13 | 40 | 412 (`$19c`) | 488 (`$1e8`) | 388 (`$184`) |
| 6567R8 | 13 | 40 | 412 (`$19c`) | 489 (`$1e9`) | 396 (`$18c`) |
| 6569 | 300 | 15 | 404 (`$194`) | 480 (`$1e0`) | 380 (`$17c`) |

Le début de ligne = front descendant d'IRQ raster, qui **ne coïncide pas** avec X=0 mais avec la « 1re coord. X de la ligne ». Les X montent jusqu'à **`$1ff` (`$1f7` seulement sur 6569)**, puis vient X=0.

---

## 5. Bad Lines — définition exacte [Bauer §3.5]

Le VIC a besoin de **40 cycles de bus supplémentaires** pour lire les pointeurs de caractères (les 63–65 premières phases par ligne ne suffisent pas pour lire pointeurs **et** pixels). Il « assomme » donc le processeur pendant **40–43 cycles** dans la première ligne raster de chaque ligne texte. L'accès aux pointeurs a lieu **aussi en mode bitmap** (la matrice vidéo y sert de couleur).

**Définition (à prendre littéralement)** :

> Une condition de Bad Line (Bad Line Condition) existe à n'importe quel cycle d'horloge si, **au front descendant de ϕ0 au début du cycle *(ϕ0 = l'horloge système côté VIC — le même signal que ϕ2/Phi ; cf. équivalences ch.2)***, (1) **RASTER ≥ `$30` et RASTER ≤ `$f7`**, et (2) **les trois bits inférieurs de RASTER sont égaux à YSCROLL**, et si (3) **le bit DEN a été à 1 pendant un cycle quelconque de la ligne raster `$30`**.

On peut créer/annuler la condition **plusieurs fois dans une même ligne** (`$30`–`$f7`) en modifiant YSCROLL, et ainsi rendre chaque ligne totalement ou partiellement Bad Line, ou déclencher/supprimer toutes les fonctions qui y sont liées. Si YSCROLL=0, une Bad Line Condition survient en ligne `$30` dès que DEN est mis à 1. Normalement, chaque 8e ligne de la fenêtre (première ligne raster de chaque ligne texte) est une Bad Line ; leur position dépend de YSCROLL.

---

## 6. Accès mémoire [Bauer §3.6]

### 6.1 Coordonnées X [Bauer §3.6.1]
Le VIC n'a pas de registre lisible pour X. La position absolue a été mesurée via **LPX** (IRQ relié à l'entrée LP), les autres X déterminés relativement ; le front descendant de BA en Bad Line mesuré pareil, résultat cohérent. Hypothèse implicite : coordonnées LPX = coordonnées X des sprites (aucune indication du contraire).

### 6.2 Zones et types d'accès [Bauer §3.6.2]
Zones :
- **Matrice vidéo** : 1000 adresses (40×25, **12 bits** chacune), déplaçable par pas de 1 Ko via VM10–VM13 (`$d018`). La Color RAM en fait partie (4 bits supérieurs). Les données lues sont stockées dans le tampon interne « **video matrix/color line** » de 40×12 bits.
- **Générateur de caractères** : 2048 octets, pas de 2 Ko via CB11–CB13 ; **bitmap** : 8000 octets, pas de 8 Ko via **CB13 seul**.
- **Pointeurs de sprites** : les 8 octets **après la fin de la matrice vidéo** ; chacun sélectionne un bloc de 64 octets parmi 256.
- **Données sprite** : 63 octets par sprite, déplaçables par pas de 64 octets.

Types d'accès :

| Type | Cible | Largeur |
|------|-------|---------|
| **c** | matrice vidéo + Color RAM | 12 bits |
| **g** | générateur de caractères / bitmap | 8 bits |
| **p** | pointeurs de sprites | 8 bits |
| **s** | données de sprites | 8 bits |
| **r** | rafraîchissement DRAM | 5 lectures/ligne |
| **i** (idle) | lecture à l'adresse vidéo **`$3fff`** (soit `$3fff`/`$7fff`/`$bfff`/`$ffff` selon la banque), résultat jeté | — |

### 6.3 Chronologie d'une ligne raster [Bauer §3.6.3]
La séquence d'accès est **câblée, identique pour toute ligne et tout mode**. La ligne commence au cycle 1 (= front descendant de l'IRQ raster = moment où RASTER est incrémenté). **Exception ligne 0** : IRQ et incrément/reset de RASTER y ont lieu **un cycle plus tard** ; par convention le début de la ligne 0 est défini un cycle avant l'IRQ. 63 cycles (6569), 64 (6567R56A), 65 (6567R8).

Disposition (6569, phases 1 sauf mention ; d'après les diagrammes de la source) :

| Cycles (6569) | Accès VIC |
|---------------|-----------|
| 1, 3, 5, 7, 9 | p-accès sprites **3, 4, 5, 6, 7** (les s-accès d'un sprite occupent les **3 demi-cycles suivant immédiatement son p-accès**) |
| 11–15 | 5 accès **r** (refresh) |
| 15–54 (phase 2) | 40 **c-accès** (si Bad Line ; BA bas **cycles 12–54**) |
| 16–55 | 40 **g-accès** |
| 56, 57 | idle |
| 58, 60, 62 | p-accès sprites **0, 1, 2** |

Sur les diagrammes (raccourcis) des modèles NTSC : p3–p7 aux mêmes cycles 1–9 et refresh 11–15 ; p0/p1/p2 = cycles **59/61/63** (6567R56A) et **60/62/64** (6567R8). Pour les sprites 0–2, les s-accès tombent donc toujours **dans la ligne précédant** leur affichage. Pour les s-accès, BA passe bas 3 cycles avant l'accès, comme pour les Bad Lines. Cycle 1 phase 1 = X `$194` (6569) ; 8 pixels par cycle, 4 par phase. La bordure est générée env. **8 pixels plus tard** que la projection « Graph. » des diagrammes.

Méthode pratique de calage donnée par la source : modifier un octet de mémoire graphique avec le 6510 et observer à partir de quel caractère le changement est visible — l'écriture a eu lieu dans la phase d'horloge immédiatement précédente.

---

## 7. État display / état idle [Bauer §3.7.1]

- **État display** : c- et g-accès ont lieu, adresses et interprétation selon le mode.
- **État idle** : seuls des g-accès, toujours à **`$3fff`** (**`$39ff`** si ECM=1) ; la graphique est affichée comme en display, mais les données de matrice vidéo sont traitées comme des bits « 0 ».
- **Transition idle→display : dès qu'il y a une Bad Line Condition.**
- **Transition display→idle : au cycle 58 d'une ligne si RC=7 et pas de Bad Line Condition.**

Si `$d011` n'est pas modifié en cours de trame : display dans la fenêtre, idle dehors. (Avec YSCROLL≠3 en fenêtre 25 lignes et un octet ≠0 en `$3fff`, on voit les bandes noires du séquenceur en idle en haut/bas de la fenêtre.)

---

## 8. VC, RC, VMLI — les règles [Bauer §3.7.2]

Registres :
- **VC** (video counter) : compteur 10 bits, chargeable depuis VCBASE.
- **VCBASE** : registre 10 bits avec entrée de reset, chargeable depuis VC.
- **RC** (row counter) : compteur 3 bits avec reset.
- **VMLI** (video matrix line index) : en réalité un **registre à décalage de 40 bits** qui promène un unique bit « 1 » adressant une cellule de la video matrix/color line ; en display un nouveau « 1 » est injecté à l'entrée, en idle le registre s'est vidé (raison probable du noir de l'idle : plus d'information couleur). Des manipulations (Bauer §3.14.6) peuvent y mettre plusieurs bits → comportement très instable, dépendant de la révision et même de la température ; sans usage pratique connu, la source le traite ensuite comme un simple **compteur 6 bits avec reset**.

**Règles (quasi-verbatim)** :

1. Une fois quelque part **hors de la plage de lignes raster `$30`–`$f7`** (hors plage des Bad Lines), **VCBASE est remis à zéro**. Vraisemblablement en ligne raster 0 ; l'instant exact ne peut être déterminé et est sans importance.
2. Dans la **première phase du cycle 14** de chaque ligne, **VC est chargé depuis VCBASE** (VCBASE→VC) et **VMLI est mis à zéro**. S'il y a une **Bad Line Condition dans cette phase, RC est aussi remis à zéro**.
3. S'il y a une Bad Line Condition dans les **cycles 12–54**, **BA passe bas** et les c-accès démarrent. Une fois démarrés, un c-accès a lieu dans la **seconde phase de chaque cycle de la plage 15–54**. La donnée lue est rangée dans la video matrix/color line à la position **VMLI**, et relue en interne à la position VMLI à chaque g-accès en état display.
4. **VC et VMLI sont incrémentés après chaque g-accès en état display.**
5. Dans la **première phase du cycle 58**, le VIC vérifie si **RC=7**. Si oui, la logique vidéo passe en **idle** et **VCBASE est chargé depuis VC** (VC→VCBASE). Si la logique vidéo est en display (toujours le cas s'il y a une Bad Line Condition), **RC est incrémenté**.

Ces règles font normalement compter à VC les 1000 adresses de la matrice par trame et à RC les 8 lignes de pixels de chaque ligne texte ; via YSCROLL, le processeur garde un contrôle partiel.

---

## 9. Les 8 modes graphiques [Bauer §3.7.3]

Sélection par **ECM/BMM/MCM** (`$d011`/`$d016`). Trois des huit combinaisons sont « invalides » et sortent du noir. Le cœur du séquenceur graphique est un **registre à décalage 8 bits**, décalé d'un bit par pixel, rechargé après chaque g-accès ; **XSCROLL retarde le rechargement de 0–7 pixels**. Si XSCROLL est **augmenté** en milieu de ligne, le séquenceur produit des pixels de couleur de fond supplémentaires ; s'il est **diminué**, l'affichage des 8 pixels suivants démarre en avance et tronque le caractère en cours. Le séquenceur sort la graphique dans la colonne d'affichage tant que la bascule de bordure verticale est à 0 ; sinon (et hors colonne), c'est la **dernière couleur de fond courante** qui est affichée. Si **ECM=1**, le générateur d'adresses force les **bits d'adresse 9 et 10 à 0** sans autre changement (idle → `$39ff`).

**c-accès (identique pour tous les modes)** : adresse = `VM13 VM12 VM11 VM10 | VC9…VC0` (14 bits). En idle : pas de c-accès, données = 12 bits à 0.

| Mode (ECM/BMM/MCM) | Adresse du g-accès | Interprétation |
|---|---|---|
| **Texte standard (0/0/0)** [Bauer §3.7.3.1] | `CB13 CB12 CB11 \| D7…D0 \| RC2 RC1 RC0` | 8 px 1 bit : « 0 » = fond 0 (`$d021`) ; « 1 » = couleur bits 8–11 du c-data. 256 caractères. |
| **Texte multicolore (0/0/1)** [Bauer §3.7.3.2] | idem texte std | Bit 11 du c-data = drapeau MC. MC=0 : comme texte std, couleurs 0–7 seulement (bits 8–10). MC=1 : 4 px 2 bits — « 00 » fond 0 (`$d021`), « 01 » fond 1 (`$d022`), « 10 » fond 2 (`$d023`), « 11 » couleur bits 8–10. « 01 » compte comme **fond** pour priorité/collisions. |
| **Bitmap standard (0/1/0)** [Bauer §3.7.3.3] | `CB13 \| VC9…VC0 \| RC2 RC1 RC0` | 8 px 1 bit : « 0 » = couleur bits 0–3 du c-data, « 1 » = bits 4–7. 320×200, bloc 8×8 formé de 8 octets successifs. |
| **Bitmap multicolore (0/1/1)** [Bauer §3.7.3.4] | idem bitmap std | 4 px 2 bits : « 00 » fond 0 (`$d021`) ; « 01 » bits 4–7 ; « 10 » bits 0–3 ; « 11 » bits 8–11 du c-data. 160×200. « 01 » = fond. |
| **Texte ECM (1/0/0)** [Bauer §3.7.3.5] | `CB13 CB12 CB11 \| 0 0 \| D5…D0 \| RC2 RC1 RC0` | Comme texte std mais fond choisi par bits 6/7 du c-data : 00→`$d021`, 01→`$d022`, 10→`$d023`, 11→`$d024` ; « 1 » = bits 8–11. Jeu réduit à **64 caractères**. |
| **Texte invalide (1/0/1)** [Bauer §3.7.3.6] | `CB13 CB12 CB11 \| 0 0 \| D5…D0 \| RC` | **Écran noir.** Le séquenceur génère quand même des données valides (structure ~texte MC, 64 caractères) lisibles via collisions de sprites (avant/arrière-plan seulement, pas la couleur). |
| **Bitmap invalide 1 (1/1/0)** [Bauer §3.7.3.7] | `CB13 \| VC9 VC8 \| 0 0 \| VC5…VC0 \| RC` | **Noir.** Structure ~bitmap std, bits 9/10 d'adresse à 0 → quatre « sections » répétées quatre fois. Lisible par collisions. |
| **Bitmap invalide 2 (1/1/1)** [Bauer §3.7.3.8] | idem bitmap invalide 1 | **Noir.** Structure ~bitmap MC ; « 01 » = fond. Lisible par collisions. |

**État idle** [Bauer §3.7.3.9] : g-accès à `$3fff` (`$39ff` si ECM), l'octet est répété, matrice = « 0 ». Affichage : modes texte std/MC/ECM → « 0 » = fond 0 (`$d021`), « 1 » = **noir** ; bitmap std/texte invalide/bitmap invalide 1 → noir (0=fond, 1=avant-plan) ; bitmap MC → « 00 » = fond 0 (`$d021`), « 01 » noir (fond), « 10 »/« 11 » noir (avant-plan) ; bitmap invalide 2 → tout noir (« 00 »/« 01 » fond, « 10 »/« 11 » avant-plan).

---

## 10. Sprites [Bauer §3.8]

24×21 pixels, 8 sprites indépendants (« MOBs »). Y sur 8 bits, X sur 9 bits (MSB dans `$d010`). Activation MxE (`$d015`), expansion ×2 en X (`$d01d`) et/ou Y (`$d017`) — résolution inchangée —, multicolore MxMC (`$d01c`) → 12×21 pixels doublés, priorité MxDP (`$d01b`), couleurs `$d027`–`$d02e`.

### 10.1 Accès mémoire et affichage [Bauer §3.8.1]
- 63 octets linéaires, 3 octets par ligne de sprite. **p-accès à chaque ligne raster** depuis les 8 derniers octets de la matrice vidéo → 8 bits hauts de l'adresse des s-accès ; 6 bits bas = compteur **MC** (on peut changer le pointeur en cours d'affichage).
- s-accès : dans les **3 demi-cycles suivant directement le p-accès du sprite**, avec BA/AEC comme pour les Bad Lines (BA bas 3 cycles avant).
- **Expansion X** : le séquenceur sort les pixels à demi-fréquence. **Expansion Y** : le générateur d'adresses relit **les mêmes adresses deux lignes de suite**.
- Par sprite : registre à décalage **24 bits**, **MC** (compteur 6 bits chargeable depuis MCBASE), **MCBASE** (registre 6 bits chargeable depuis MC ou remis à zéro), et une bascule « **advance line** » (avance de ligne) pour l'expansion Y.

**Règles d'affichage (quasi-verbatim ; numéros de cycles valables pour le 6569 uniquement).** *(La révision 2024 numérote 1–7 plus 7a ; il n'y a pas de règle « 8 » distincte dans cette version. ⚠️ Lecteurs de la version 1996 : l'ancienne formulation « MCBASE += 2 au cycle 15, += 1 au cycle 16 » a été **remplacée** dans la révision 2024 par la sémantique de copie MC→MCBASE présentée ici — correction issue des travaux de Kahlin, Nuotio, Lankila et Matthies, crédités par Bauer.)*

1. La bascule d'avance de ligne est **maintenue à 1 tant que le bit MxYE (`$d017`) est à 0**.
2. Dans les **premières phases des cycles 55 et 56**, le VIC vérifie pour chaque sprite si **MxE (`$d015`) est à 1** et si la **coordonnée Y du sprite (registres impairs `$d001`–`$d00f`) égale les 8 bits bas de RASTER**. Si oui et que le **DMA du sprite est encore éteint** : le DMA est allumé, **MCBASE est mis à zéro**, et la bascule d'avance de ligne est mise à 1.
3. Si le bit **MxYE est à 1 dans la seconde phase du cycle 56** et que le DMA du sprite est allumé, la bascule d'avance de ligne est **inversée**.
4. Dans la **première phase du cycle 58**, le **MC de chaque sprite est chargé depuis son MCBASE** (MCBASE→MC) et le VIC vérifie si le DMA est allumé **et** si la coordonnée Y égale les 8 bits bas de RASTER. Si oui, **l'affichage du sprite est allumé**. Sinon, si le DMA est éteint, l'affichage est éteint aussi.
5. Si le DMA d'un sprite est allumé, **trois s-accès** sont effectués dans les cycles attribués au sprite. **Les p-accès ont toujours lieu, même sprite éteint.** 1er accès → 8 bits hauts du registre à décalage, 2e → 8 bits du milieu, 3e → 8 bits bas. **MC est incrémenté après chaque s-accès.**
6. Si l'affichage du sprite est allumé, le registre à décalage est décalé **à gauche d'un bit par pixel dès que la coordonnée X courante du faisceau égale la coordonnée X du sprite (registres pairs `$d000`–`$d00e`)**, et les bits sortants sont affichés. Si **MxXE** (`$d01d`) est à 1, le décalage n'a lieu qu'**un pixel sur deux** (sprite deux fois plus large). En multicolore, deux bits adjacents forment un pixel.
7. Dans la **première phase du cycle 16**, le VIC vérifie pour chaque sprite si sa bascule d'avance de ligne est à 1. Si oui, **MCBASE est chargé depuis MC** (MC→MCBASE), avançant l'affichage à la ligne suivante. Ensuite, le VIC vérifie si **MCBASE = 63** et, le cas échéant, **éteint le DMA** du sprite.
7a. Cas particulier : si le CPU a **remis MxYE à 0 au cycle 15** et que la bascule d'avance de ligne du sprite **n'était pas** à 1, alors la bascule est mise à 1 et au cycle suivant (16) le VIC charge MCBASE non pas depuis MC mais selon :
   **`MCBASE = (101010₂ & (MCBASE & MC)) | (010101₂ & (MCBASE | MC))`**
   (bits impairs = ET de MCBASE et MC, bits pairs = OU ; formule reproduite de la source — équivalente à la forme `0x15`/`0x2a` d'Åkesson au ch.2 (§3.2) : %010101 = `$15`, %101010 = `$2a`).

**Conséquences normatives** :
- Le test de la règle 2 étant fait en fin de ligne, la valeur écrite dans le registre Y doit être **la position Y désirée − 1** ; l'affichage ne commence qu'à la ligne suivante, après lecture des premières données (sauf sprite placé à droite de la coordonnée X **`$164`** — cycle 58, règle 4).
- **Multiplexage vertical possible** (re-déclenchement en changeant Y après la fin d'affichage — fonctionnalité officielle) ; **impossible horizontalement** : après 24 pixels le registre est vide, max **8 sprites par ligne raster**.
- Sur 6569, les X **`$1f8`–`$1ff` rendent le sprite invisible** (jamais atteints par le compteur X) ; un pixel à gauche de X=0 → X=**`$1f7`**.

**Adresses** : p-accès = `VM13…VM10 | 1 1 1 1 1 1 1 | n° de sprite (3 bits)` → donnée MP7…MP0 ; s-accès = `MP7…MP0 | MC5…MC0`. Données : MxMC=0 → 8 px 1 bit (« 0 » transparent, « 1 » couleur `$d027`–`$d02e`) ; MxMC=1 → 4 px 2 bits (« 00 » transparent, « 01 » multicolore 0 `$d025`, « 10 » couleur sprite, « 11 » multicolore 1 `$d026`).

### 10.2 Priorités et collisions [Bauer §3.8.2]
- Hiérarchie fixe entre sprites : **sprite 0 = priorité la plus haute, sprite 7 la plus basse**.
- Partition avant/arrière-plan de la graphique décidée par **MCM (`$d016`) seul**, indépendamment de l'état du séquenceur et des bits BMM/ECM — valable aussi pour la graphique d'état idle :

| | MCM=0 | MCM=1 |
|---|---|---|
| Bits/pixel | 1 | 2 |
| Pixels/octet | 8 | 4 |
| Fond | « 0 » | « 00 », « 01 » |
| Avant-plan | « 1 » | « 10 », « 11 » |

- **MxDP=0** : priorité croissante = fond < avant-plan < sprite x < bordure. **MxDP=1** : fond < sprite x < avant-plan < bordure. (La table de [2], la spec Commodore, est fausse.) La **bordure a toujours la priorité maximale**.
- Avec MxDP=1, les pixels d'avant-plan recouvrant un pixel de sprite non transparent « héritent » de la priorité du sprite (comme « incrustés » dans l'image du sprite) : ils restent visibles même par-dessus des sprites de numéro supérieur configurés MxDP=0. Dans les modes invalides, l'avant-plan (noir) redevient ainsi visible par-dessus les sprites.
- **Collision sprite–sprite** : détectée dès que **deux séquenceurs de sprites ou plus** sortent un pixel non transparent en même temps (**y compris hors zone visible**) → bits MxM dans **`$d01e`** + interruption si autorisée. Bits conservés jusqu'à **lecture du registre, qui les efface**.
- **Collision sprite–graphique** : un séquenceur de sprite sort un pixel non transparent pendant que le séquenceur graphique sort un **pixel d'avant-plan** → bits MxD dans **`$d01f`** (même effacement à la lecture).
- Si la **bascule de bordure verticale** est à 1, la sortie du séquenceur graphique est coupée → **aucune collision sprite–graphique**.

---

## 11. Unité de bordure [Bauer §3.9]

Deux bascules : **principale** (affiche `$d020` si à 1, priorité d'affichage maximale, recouvre graphique et sprites) et **verticale** (si à 1 : la principale ne peut pas être remise à 0, et la sortie du séquenceur graphique est coupée — il affiche la couleur de fond). 2×2 comparateurs par bascule, valeurs câblées selon CSEL/RSEL ; **la comparaison n'est vraie que si la valeur est atteinte exactement (pas de test d'intervalle)**.

| Comparaison X | CSEL=0 | CSEL=1 |
|---|---|---|
| Gauche | 31 (`$1f`) | 24 (`$18`) |
| Droite | 335 (`$14f`) | 344 (`$158`) |

| Comparaison Y | RSEL=0 | RSEL=1 |
|---|---|---|
| Haut | 55 (`$37`) | 51 (`$33`) |
| Bas | 247 (`$f7`) | 251 (`$fb`) |

**Règles** :
1. Quand X atteint la valeur de comparaison **droite**, la bascule principale est **mise à 1**.
2. Quand Y atteint la valeur **basse** au **cycle 63**, la bascule verticale est **mise à 1**.
3. Quand Y atteint la valeur **haute** au **cycle 63** et que **DEN** (`$d011`) est à 1, la bascule verticale est **remise à 0**.
4. Quand X atteint la valeur **gauche** et Y la valeur **basse**, la bascule verticale est **mise à 1**.
5. Quand X atteint la valeur **gauche**, Y la valeur **haute** et que **DEN est à 1**, la bascule verticale est **remise à 0**.
6. Quand X atteint la valeur **gauche** et que la bascule verticale **n'est pas** à 1, la bascule principale est **remise à 0**.

Y est donc testé une ou deux fois par ligne : au cycle 63 et quand X atteint la comparaison gauche.

---

## 12. DEN (Display Enable) [Bauer §3.10]

Bit 4 de `$d011`, normalement à 1. Deux effets :
- Une **Bad Line Condition ne peut survenir que si DEN a été à 1 au moins un cycle quelque part dans la ligne raster `$30`**.
- DEN à 0 → **l'entrée de reset de la bascule de bordure verticale est désactivée** : la bordure haut/bas ne s'éteint jamais.

DEN=0 empêche donc normalement toute Bad Line (donc tout c/g-accès) et l'écran entier affiche la couleur de bordure.

---

## 13. Crayon optique [Bauer §3.11]

Sur front descendant de LP : **LPX (`$d013`) = 8 bits hauts (sur 9) de X** (résolution horizontale 2 pixels), **LPY (`$d014`) = 8 bits bas (sur 9) de Y**. **Un seul front reconnu par trame** ; les suivants sont ignorés jusqu'au début de la trame suivante. LP partage une ligne avec la matrice clavier → déclenchable par logiciel via **bit 4 du port B de CIA A (`$dc01`/`$dc03`)**, ce qui permet de lire la position X du faisceau (synchronisation cycle-exacte possible). Référence = fin du cycle du déclenchement ; ex. : déclenchement au cycle 20 → LPX=`$1e` (coordonnée sprite `$03c`). Peut aussi déclencher une interruption (une fois par trame).

---

## 14. Interruptions [Bauer §3.12]

IRQ du VIC → IRQ du 6510 (masquable par le flag I). Quatre sources ; chaque source a un bit dans le **latch `$d019`** et un bit d'autorisation dans **`$d01a`**. Événement → bit du latch mis à 1. **Le VIC n'efface jamais le latch lui-même : le processeur doit écrire un « 1 »** sur le bit pour l'effacer, avant de rendre la main (l'entrée IRQ du 6510 est sensible à l'état → sinon re-déclenchement immédiat). Si (latch ∧ enable) ≠ 0, le VIC tient IRQ bas. **Bit 7 de `$d019` = état inversé de la sortie IRQ.**

| Bit | Nom | Condition |
|---|---|---|
| 0 | RST | Atteinte de la ligne raster de comparaison (écrite via `$d012` + bit 7 de `$d011`, mémorisée en interne). **Test au cycle 1 de chaque ligne (cycle 2 pour la ligne 0).** Une écriture dans `$d011`/`$d012` peut déclencher immédiatement, mais **jamais plus d'une fois par ligne raster**. |
| 1 | MBC | Collision d'au moins un sprite avec la graphique (pixel de sprite non transparent simultané à un pixel d'avant-plan). |
| 2 | MMC | Collision de deux sprites ou plus (deux séquenceurs sortent un pixel non transparent en même temps). |
| 3 | LP | Front descendant sur l'entrée LP. |

MBC/MMC : **seule la première collision déclenche** (si `$d01f` resp. `$d01e` valait zéro avant — MBC surveille `$d01f` [sprite-graphique], MMC `$d01e` [sprite-sprite]) ; pour ré-armer, lire (donc effacer) le registre de collision.

---

## 15. Rafraîchissement DRAM [Bauer §3.13]

**5 lectures de refresh par ligne raster.** Compteur **REF** 8 bits : mis à **`$ff` en ligne raster 0**, décrémenté après chaque accès, boucle à `$ff` après passage sous zéro. Adresse = `1 1 1 1 1 1 | REF7…REF0` (`$3fxx`). Ligne 0 : `$3fff`, `$3ffe`, `$3ffd`, `$3ffc`, `$3ffb` ; ligne 1 : `$3ffa`…`$3ff6` ; etc.

---

## 16. Effets et applications [Bauer §3.14]

### 16.1 Hyperscreen (ouverture de bordure) [Bauer §3.14.1]
La bordure est **commutée à des coordonnées précises**, pas affichée sur un intervalle : si la comparaison n'est jamais vraie, la bordure ne s'allume jamais. Bordure haut/bas :
1. Dans la partie haute de l'écran, passer **RSEL=1**.
2. Attendre RASTER dans **248–250** (la bascule verticale est encore à 0 : la comparaison RSEL=1 est à la ligne 251).
3. Mettre **RSEL=0** : le comparateur bascule sur 247, déjà passée → le VIC « oublie » d'allumer la bordure verticale.
4. Après la ligne 251, remettre RSEL=1 et reprendre en 2.

Passer RSEL 0→1 dans les lignes **52–54** → la bordure ne s'éteint jamais et couvre tout l'écran (comme DEN=0, mais les Bad Lines continuent). Bordure gauche/droite : passage **CSEL 1→0 exactement au cycle 56** pour ouvrir ; **CSEL 0→1 au cycle 17** empêche l'extinction. Pour ouvrir gauche/droite dans la zone de bordure haut/bas, il faut soit commencer avant que la bascule verticale soit à 1, soit ouvrir aussi le haut/bas (règle 6 : la principale ne se remet à 0 que si la verticale est à 0). Dans la zone ouverte : sprites, et graphique d'état idle (aucune Bad Line hors Y `$30`–`$f7`) ; première méthode → seule la couleur de fond y est visible, seconde → la graphique idle.

### 16.2 FLD (Flexible Line Distance) [Bauer §3.14.2]
La Bad Line est le « signal de départ » de chaque ligne texte. En modifiant YSCROLL on **supprime/retarde** la condition à volonté → on choisit les lignes raster où démarrent les lignes texte (ex. trois Bad Lines en `$50`, `$78`, `$a0` → trois lignes texte, séquenceur idle entre elles). Retarder seulement la première Bad Line = **scrolling vertical vers le bas** de tout l'écran sans déplacer un octet.

### 16.3 FLI (Flexible Line Interpretation) [Bauer §3.14.3]
Créer artificiellement une **Bad Line supplémentaire avant la fin de la ligne texte en cours** : en rendant chaque ligne raster Bad Line (via YSCROLL), le VIC relit la matrice vidéo **à chaque ligne** → nouvelle info couleur par ligne ; en bitmap multicolore, chacun des 4×8 pixels d'un bloc peut avoir sa couleur.
- **Problème 1** : une nouvelle Bad Line avant la fin de la ligne texte → **VCBASE n'est pas incrémenté** (Bauer §3.7.2) : le VIC relit **les mêmes adresses de matrice** qu'à la ligne précédente. Trop lent à changer par CPU → on commute la base de la matrice avec **VM10–VM13 (`$d018`)**. En pratique : **8 matrices vidéo** en mémoire, utilisées cycliquement (en base 0 : ligne raster n → rangée ⌊n/8⌋ de la matrice (n mod 8)). **La Color RAM, elle, ne peut pas être commutée** → choix des couleurs pas entièrement libre.
- **Problème 2 (le « FLI-bug »), cause exacte** : l'accès à `$d011` créant la Bad Line **ne doit pas survenir avant le cycle 14** (sinon RC serait remis à 0 à chaque ligne, cassant l'affichage bitmap). Mais alors **les trois premiers c-accès de chaque ligne lisent des données invalides** : le premier c-accès au cycle 15 exigerait BA bas dès le cycle 12 pour qu'AEC puisse rester bas au cycle 15 (**AEC ne reste bas que trois cycles après le front descendant de BA — c'est câblé, sans contournement**). La Bad Line étant créée au cycle 14, BA est bas au cycle 15 mais **AEC encore haut** → les portes de bus internes **D0–D7 du VIC sont fermées et il lit `$ff`** au lieu des données de matrice (les portes D8–D11 sont ouvertes, détail en Bauer §3.14.6). Ces données parasites forment des **bandes de 24 pixels de large au bord gauche** de l'écran.
- Variantes : **AFLI** (bitmap standard, dégradés simulés par pixels adjacents de couleurs proches), **IFLI** (alternance de deux trames, entrelacement simulé).

### 16.4 Linecrunch [Bauer §3.14.4]
**Avorter une Bad Line commencée en annulant la condition avant le cycle 14.** Conséquences :
- Le séquenceur est en display → la graphique s'affiche.
- **RC n'est pas remis à 0** (si on avorte la toute première ligne de la trame, RC vaut encore 7, hérité de la dernière ligne de la trame précédente).
- Au cycle 58, RC vaut toujours 7 → passage en idle et **VCBASE chargé depuis VC** ; or VC a été incrémenté après chaque g-accès de la ligne → **VCBASE a effectivement augmenté de 40**. RC ne déborde pas, il reste à 7.

La ligne texte est réduite à sa dernière ligne raster (« crunch »). Répété à chaque ligne : RC reste à 7, **pas de c-accès**, VCBASE +40 par ligne → dépasse la limite des 1000 octets et le VIC affiche les **24 derniers octets normalement invisibles de la matrice (dont les pointeurs de sprites)** ; **VCBASE boucle à 0 en atteignant 1024**. Usage : scrolling **vers le haut** de grandes distances sans déplacer la mémoire ; les lignes « crunchées » s'empilent en haut de l'écran (on peut les masquer avec un mode invalide).

### 16.5 Lignes de texte doublées [Bauer §3.14.5]
Normalement une ligne texte finit quand RC=7 (idle au cycle 58). Si on **crée une Bad Line Condition entre les cycles 54 et 57 de la dernière ligne raster**, le séquenceur reste en display et **RC est incrémenté encore une fois (débordement à 0)** : le VIC réaffiche la ligne texte précédente à la ligne suivante — aucune nouvelle donnée de matrice n'ayant été lue, elle est simplement **affichée deux fois**.

### 16.6 DMA delay / VSP [Bauer §3.14.6]
Créer une **Bad Line Condition dans les cycles 15–53** d'une ligne où le séquenceur est en idle (p. ex. rendre YSCROLL égal aux 3 bits bas de RASTER via `$d011`). Le VIC met **BA bas dès le cycle suivant**, passe en display et lit la matrice. Mais **AEC suit encore ϕ0 pendant trois cycles** (câblé). Pendant ces trois premiers cycles : les lignes D0–D7 du VIC sont en tri-state → le VIC lit **`$ff` comme pointeurs de caractères** ; les lignes hautes (la source écrit ici « D8–D13 », mais « D8–D11 » en Bauer §3.14.3 — incohérence dans la source ; le bus vidéo étant **12 bits** [Bauer §2.3], D8–D11 est nécessairement la bonne lecture) n'ont pas de drivers tri-state et restent en entrée, mais la Color RAM n'est pas sélectionnée (AEC haut → le 6510 est maître du bus) ; un **commutateur analogique 4 bits, U16**, relie alors les bits de données **D0–D3 du processeur** aux bits de données de la Color RAM. Résultat : pour la couleur, le VIC lit **les 4 bits bas de l'opcode suivant l'accès à `$d011`**. Ensuite seulement, lectures normales.
Les c/g-accès continuent jusqu'au cycle 54 ; ayant commencé en cours de ligne, **moins de 40 accès ont eu lieu → VC n'est plus multiple de 40** en fin de ligne, et ce **désalignement persiste sur toutes les lignes suivantes** (fonctionnement de VC, Bauer §3.7.2) : **tout l'écran apparaît décalé à droite d'autant de caractères que l'accès `$d011` a eu lieu de cycles après le cycle 14**. Marche aussi en bitmap (VC sert aussi aux accès bitmap). Combiné à FLD + Linecrunch : scrolling de tout l'écran dans toutes les directions à coût CPU minime.
Variante avec **DEN** : YSCROLL=0 (la ligne `$30` devient Bad Line dès que DEN passe à 1) et basculer **DEN 0→1 au milieu de la ligne `$30`**.

### 16.7 Sprite stretching / sprite crunch [Bauer §3.14.7]
**Stretching** (répéter une ligne de sprite 3 fois ou plus, facteur d'agrandissement Y arbitraire) — mécanisme complet (cycles 6569) : cycle 55 d'une ligne où le sprite 0 (M0YE=1) matche en Y → DMA on, MCBASE=0, bascule d'avance mise à 1, puis **inversée au cycle 56** (M0YE=1). BA bas pour les s-accès des secondes phases des cycles 58 et 59 ; au cycle 58 phase 1, MC←MCBASE (=0), p-accès puis 3 s-accès, MC=3. À la ligne suivante, **au cycle 16 la bascule d'avance n'est pas à 1 → MCBASE reste à 0**. On **efface alors M0YE (ce qui met la bascule à 1) puis on le remet aussitôt à 1** : M0YE étant à 1, la bascule est **réinvertie au cycle 56, donc remise à 0** — exactement l'état du cycle 56 de la ligne précédente. Le VIC « croit » être encore dans la première ligne raster d'un sprite étendu et, MC étant (rechargé) à zéro, relit la première ligne de sprite **deux fois de plus — trois fois au total**.
**Sprite crunch** : même procédé, mais effacer M0YE **dans la seconde phase du cycle 15** (et non après le cycle 16) → **MCBASE est mis à 1** (cas 7a). La ligne suivante est lue avec **MC=1..3**, un octet trop haut ; le désalignement persiste sur tout l'affichage. La condition d'arrêt du DMA au cycle 16 (**la source écrit ici « MC=63 » ; la règle 7 parle de MCBASE=63**) n'est pas remplie → le sprite est **affiché deux fois de suite** ; le DMA ne s'éteint qu'à la fin du second affichage, quand la valeur atteint 63.

---

## 17. « Ghost bytes » : `$de00`, Color RAM, adresses 0/1 [Bauer §4]

- `$de00`–`$dfff` (zones I/O 1/2 ouvertes) et les nibbles hauts de `$d800`–`$dbff` se lisent « aléatoires », mais **sur certains C64** (pas tous, pas toujours fiable) la valeur lue = **le dernier octet lu par le VIC en première phase du cycle**. Applications : mesurer le timing du VIC entièrement en logiciel ; faire exécuter au 6510 du code dans la zone `$de00` ou dans la Color RAM si le VIC lit des opcodes valides.
- **Écriture en RAM 0/1** : lors d'une écriture CPU vers 0/1 (port I/O interne), les drivers de données du 6510 restent en tri-state mais **R/W est bas** → c'est **l'octet lu par le VIC dans la première phase** qui est écrit en RAM. Pour écrire une valeur choisie : écrire n'importe quoi en 0/1 en s'assurant que le VIC vient de lire la valeur voulue au cycle précédent.
- **Lecture de 0/1** : via la zone `$de00`, ou par **collisions de sprites** (bitmap basée à l'adresse 0, sprite d'un seul pixel promené sur les bits des deux premiers octets ; collision/pas collision = bit 1/0).

---

# Chapitre 2 — Timing fin & vols de cycles (Mäkelä 1994, Ojala 1992, Åkesson 2016)

## Timing fin & vols de cycles

Ce chapitre rassemble les trois sources primaires du corpus Arena64 sur le vol de cycles du VIC-II : l'article fondateur de Pasi Ojala (1992), les chronogrammes mesurés de Marko Mäkelä (1994) — qui corrigent explicitement Ojala, qu'il qualifie d'« inexact » mais de bonne introduction — et l'exploitation extrême du DMA sprite par Linus Åkesson (2016). Statut des affirmations : Mäkelä = **mesuré** (sur vrai matériel), Ojala = **documenté** (avec approximations connues), Åkesson = **mesuré** (démo fonctionnelle) sauf mention contraire.

---

### 1. [pal.timing] Chronogrammes du 6569 — Marko Mäkelä, 3 juin 1994

**Titre original** : *The memory accesses of the MOS 6569 VIC-II and MOS 8566 VIC-IIe Video Interface Controller*.

#### 1.1 Méthode et matériel

Les résultats reposent sur : des mesures de taille d'écran chez Peter Andersson (Suède), les diagrammes « inexacts » d'Ojala, et surtout le programme d'Andreas Boose qui détermine **quelles adresses le VIC lit**, en lisant l'espace d'adressage non connecté **`$DE00`–`$DFFF`** : le bus de données y reflète la donnée lue par le VIC au **cycle Phi-1 précédent** (découvert par Mäkelä chez Boose, fin mars 1994). Attention : ce truc n'est **pas fiable sur tous les C64/C128** (certains bits restent collés à 0 ou 1 ; seuls 2 des 6 machines testées étaient « `$DE00`-compatibles » — question de blindage RF).

Matériel mesuré : deux C64, un C128D, un C128DCR ; puces : 6569R1 céramique, 6569R3 céramique, 6569R3 plastique (+ 8566 des C128, révisions inconnues). **Les accès mémoire sont identiques sur toutes ces puces, mais pas le timing complet** : il existe des différences au moins dans le timing sprite du 6569R1.

#### 1.2 Les six chronogrammes (verbatim)

```
Bad scan line, no sprites:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3-4-5-6-7-rrrrrgggggggggggggggggggggggggggggggggggggggg--0-1-2- Phi-1 6569R3
              cccccccccccccccccccccccccccccccccccccccc          Phi-2 6569R3
xxxxxxxxxxxXXX========================================xxxxxxxxx Phi-2 6510


Normal scan line, no sprites:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3-4-5-6-7-rrrrrgggggggggggggggggggggggggggggggggggggggg--0-1-2- Phi-1 6569R3
                                                                Phi-2 6569R3
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Phi-2 6510


Overscan raster line (vertical border) or blanked screen, no sprites:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3-4-5-6-7-rrrrr++++++++++++++++++++++++++++++++++++++++--0-1-2- Phi-1 6569R3
                                                                Phi-2 6569R3
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Phi-2 6510


Bad scan line, at least the sprites 3--7 active on the current scan
line and the sprites 0--2 on the following scan line:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3s4s5s6s7srrrrrgggggggggggggggggggggggggggggggggggggggg--0s1s2s Phi-1 6569R3
ssssssssss    cccccccccccccccccccccccccccccccccccccccc   ssssss Phi-2 6569R3
==========xXXX========================================***====== Phi-2 6510


Normal scan line, no sprites on the current scan line but at least the
sprites 1 and 2 active on the following scan line:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3-4-5-6-7-rrrrrgggggggggggggggggggggggggggggggggggggggg--0-1s2s Phi-1 6569R3
                                                           ssss Phi-2 6569R3
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXX==== Phi-2 6510


Two successive overscan raster lines (vertical border),
sprites 1, 3 and 7 active on the latter:

         1         2         3         4         5         6
123456789012345678901234567890123456789012345678901234567890123
         [      {                                      }   ]
3-4-5-6-7-rrrrr++++++++++++++++++++++++++++++++++++++++--0-1s2- Phi-1 6569R3
                                                           ss   Phi-2 6569R3
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXX==** Phi-2 6510

3s4-5-6-7srrrrr++++++++++++++++++++++++++++++++++++++++--0-1-2- Phi-1 6569R3
ss      ss                                                      Phi-2 6569R3
==xxxXXX==xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Phi-2 6510
```

#### 1.3 Légende complète (verbatim)

```
Note:   The left edge of the diagrams is the start of the raster line,
        as indicated by the Raster Counter register ($D012/$D011).

Legend: [ left edge of the overscan screen (sprite co-ordinate $1E0 at
                                            the beginning of this cycle)
        { left edge of the text screen (at the beginning of this cycle)
        } right edge of the text screen (at the end of this cycle)
        ] right edge of the overscan screen (a bit after the end of this cycle)

        - idle bus cycle (reads from the last byte of the video bank,
          e.g. (video bank base address) + $3FFF)
        + idle bus cycle (just like '-', but reads from
          (video bank base address) + $39FF if ECM ($D011 bit 6) is selected)
        0 pointer fetch for sprite 0
        1 pointer fetch for sprite 1
        2 pointer fetch for sprite 2
        3 pointer fetch for sprite 3
        4 pointer fetch for sprite 4
        5 pointer fetch for sprite 5
        6 pointer fetch for sprite 6
        7 pointer fetch for sprite 7
        r memory refresh cycle
        g graphics fetch
        c character pointer and/or color data fetch

        x processor executes instructions (BA high, AEC high)
        X bus request pending, bus still available (BA low, AEC high);
          processor may execute write cycles, stops on the next read cycle.
        * bus request pending, bus still available (BA low, AEC high);
          processor is blocked because it would like to read something.
        = bus unavailable (BA low, AEC low);
          processor is blocked because it would like to read something.
```

**Glose des quatre états du bus 6510** — c'est le cœur du chapitre :

| Symbole | BA | AEC | État du 6510 |
|---|---|---|---|
| `x` | haut | haut | exécution normale |
| `X` | bas | haut | requête bus en attente ; le CPU peut encore exécuter des **cycles d'écriture**, il s'arrête au prochain cycle de **lecture** |
| `*` | bas | haut | bus encore disponible, mais CPU bloqué car il voudrait **lire** |
| `=` | bas | bas | bus retiré ; CPU bloqué |

**Horloges — équivalences de notation** : *Phi-1 = première phase du cycle (ϕ2 bas) = phase VIC ; Phi-2 = seconde phase (ϕ2 haut) = phase CPU.* Les symboles **ϕ0/ϕ2** (Bauer), **Phi** (Mäkelä) et **ø2** (datasheet SID, ch.4) désignent la même horloge système.

À noter : l'origine des diagrammes de Mäkelä est le **début de la ligne raster** (`$D012`/`$D011`), contrairement à Ojala dont le bord gauche est la coordonnée sprite X=0 (voir §2).

#### 1.4 Notes clés de Mäkelä

- **Écran overscan** (mesuré) : **411 × 284 points** (ses notes disent 411,5 en horizontal — incertitude reconnue par l'auteur : « peut-être le point le plus à droite était à demi-largeur », ambigu dans la source). Tout à gauche (coord. sprite `$1D8`) : barre verticale de 8 pixels couleur 8 (brun foncé), puis barre blanche de 2 pixels (`$1E0`–`$1E1`). Zone contrôlable par programme : coordonnées **`$1E2` à `$17C`** inclus. Lignes raster **`$0`–`$137`** inclus, visibles **`$10`–`$12B`**. Écran texte par défaut : coordonnées horizontales **`$18`–`$157`**, lignes **`$33`–`$F9`**. *(NB : les **403** « pixels visibles » de Bauer [ch.1 §4] mesurent la fenêtre affichée hors blanking — définition différente de la zone overscan de 411 points : les deux chiffres sont exacts.)*
- **Latence couleur** : les couleurs changent **8,5 pixels après le début du cycle d'écriture** dans un registre VIC-II (John West dit « un cycle après l'écriture » pour les registres `$20`–`$2F` — les deux formulations coexistent dans la source). Puces plus récentes que 6569/6567 : point gris clair parasite quand on change une couleur en cours d'utilisation (test : `FORA=1TO1E37:POKE53281,0:NEXT`).
- **Coordonnées Y des sprites = ligne raster − 1** : le VIC préfetche les données sprite de la ligne *suivante* juste après l'affichage des caractères de la ligne courante, et la ligne raster ne s'incrémente qu'au moment du fetch de données du quatrième sprite (formulation de la source : « the data for the fourth sprite » — sprite 3 en numérotation 0, ambigu dans la source).
- **Badline** : les pointeurs de caractères sont lus **un cycle avant** les données image de la première scanline d'une ligne texte ; de même les données graphiques sont lues un cycle avant affichage (buffering).
- **Sprites bufferisés** : sprite 0 collé au bord droit de l'overscan → bord droit distordu (le VIC est en train de fetcher ses données à cet endroit). Les données sprite sont fetchées **même hors de l'écran overscan** et pendant le retour vertical, si la coordonnée X sprite *(sic — la source écrit « horizontal », mais Bauer règle 2 [ch.1 §10.1] et la conséquence « Y 0–55 → double fetch » de la phrase suivante imposent la coordonnée **Y**)* correspond aux 8 bits bas du compteur raster ; conséquence : avec Y sprite entre **0 et 55 inclus**, les données sont **fetchées deux fois par frame** (sprite visible en haut ET en bas si bordures ouvertes ; avec expansion Y : haut du sprite en bas d'écran, bas du sprite en haut, sprite entier près du haut).
- **Bordure verticale ouverte** (bascule 24/25 lignes pendant la 25e ligne texte) : les cycles `-` affichent le dernier octet de la banque vidéo (`$3FFF` par défaut), graphisme toujours noir (« ou c'est ce qu'on nous a dit » — l'auteur demande si quelqu'un sait le colorer).
- **Modes illégaux** : ECM+BMM → écran noir, adresses bitmap ANDées avec **`$B9FF`** ; les cycles `+` lisent `$39FF` en bordure aussi dans ce mode hybride. ECM+MCM : écran noir mais adressage singulier — A13–A11 = base générateur de caractères, A10–A9 = 0, **A8–A5 = bits de base de la matrice texte**, A4–A3 apparemment toujours 0, A2–A0 = scanline du caractère (1–7 hors badline ; 0 sur badline, non mesurable sans matériel supplémentaire). Probablement un mode de test d'usine. **Tous les modes illégaux ont des badlines** — aucun intérêt pratique sauf obfuscation.
- **Refresh mémoire** : 5 cycles `r` par ligne. Première adresse rafraîchie sur une ligne raster donnée : **(base banque vidéo) OR `$3F00` OR (`$FF` AND (−1−5×ligne))**, compteur **décroissant**. Exemple (banque 0) : lignes `$36` et `$136` → lectures `$3FF1`, `$3FF0`, `$3FEF`, `$3FEE`, `$3FED`.
- **Horloges** : système = 17734472/18 Hz en PAL, 14318181/14 Hz en NTSC ; dot clock = 8×. PAL : 63 cycles/ligne, 312 lignes. NTSC : le 6567R8 testé avait 64 cycles/262 lignes (frame rate 60,9928 Hz), les 6567 habituels ont 65 cycles/263 lignes. *(⚠️ Divergence avec la table de Bauer [ch.1 §4] : 64 cy/262 lignes = 6567**R56A**, 65/263 = 6567**R8** — témoignages contradictoires entre sources, non résolus.)*

---

### 2. [Ojala] « Missing Cycles » — Pasi Ojala, C=Hacking #3 (écrit 15-mai-91, traduit 30-mai-92)

Tous les timings sont PAL ; le principe s'applique au NTSC.

#### 2.1 Le mécanisme du vol de cycles

Base : **63 cycles CPU par ligne**, sauf la « bad line » qui n'en laisse que **23**. Le VIC fait plus qu'afficher : sur chaque scanline il **rafraîchit 5 rangées mémoire** et **fetche 40 octets de données graphiques**, le tout pendant les cycles Phi-1 que le CPU n'utilise pas. Ces cycles ne suffisent plus quand le VIC doit aussi lire les codes caractère et couleur de la rangée suivante : le bus étant unique, l'accès CPU est refusé. Le bus VIC de **12 bits** permet heureusement de lire caractère (8 bits) et couleur (4 bits) **en même temps**.

**Sprites** : sur chaque ligne, les pointeurs image des sprites sont fetchés en Phi-1. Si le sprite est affiché sur cette ligne, les **3 octets** de données image sont fetchés juste après — **2 de ces 3 fetches ont lieu en Phi-2**, donc le CPU les perd. En moyenne : **2 cycles perdus par sprite affiché** (plus l'overhead BA, ci-dessous).

#### 2.2 Le signal BA — 3 cycles d'avance

Quand le VIC veut le bus, **BA (Bus Available) devient inactif 3 cycles avant** que le bus doive être libéré. Pendant ces 3 cycles, le CPU doit finir ses accès mémoire ou les différer. Il peut terminer l'instruction en cours dans les cycles restants (pendant BA bas le bus lui reste disponible tant qu'AEC est haut : ses **cycles d'écriture** passent encore ; il s'arrête au premier cycle de lecture), mais **il ne peut pas démarrer une nouvelle instruction tant qu'il n'a pas le bus**. C'est pourquoi des cycles « disparaissent » au-delà de ceux volés directement pour les sprites.

Compte théorique, 8 sprites sur la même ligne : 16 cycles de fetch (2×8) + **3 cycles d'overhead BA = 19 cycles** volés. En pratique souvent moins, car le CPU consomme une partie de la fenêtre BA en cycles d'écriture ; le texte dit « habituellement les 8 sprites prennent 17 cycles, un sprite en prend 3 » et ailleurs « 16 à 19 cycles selon le timing » — la table ci-dessous donne 46–49 cycles disponibles, soit 14–17 volés (ambigu dans la source ; Mäkelä signale précisément que les diagrammes d'Ojala sont inexacts).

**L'effet cliquet des fenêtres par sprite** : si on désactive le **sprite 4** alors que tous sont actifs, **aucun cycle n'est rendu au CPU** — pendant le fetch qui aurait été celui du sprite 4, le VIC signale déjà (BA bas) qu'il veut le bus pour le sprite 5 ; le CPU ne voit jamais BA remonter. De même, éteindre seulement les sprites **1, 3 et 5** ne rend **rien** : les sprites 0, 2, 4, 6, 7 ensemble coûtent autant que les huit.

#### 2.3 La table PAL (verbatim)

```
_Table for PAL VIC timing for the Missing cycles_


012345678901234567890123456789012345678901234567890123456789012 cycles

Normal scan line, 0 sprites
ggggggggggggggggggggggggggggggggggggggggrrrrr  p p p p p p p p  phi-1 VIC
                                                                phi-2 VIC
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx phi-2 6510
63 cycles available

Normal scan line, 8 sprites
ggggggggggggggggggggggggggggggggggggggggrrrrr  pspspspspspspsps phi-1 VIC
                                               ssssssssssssssss phi-2 VIC
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXX                 phi-2 6510
46-49 cycles available

Normal scan line, 4 sprites
ggggggggggggggggggggggggggggggggggggggggrrrrr  psp psp psp psp  phi-1 VIC
                                               ss  ss  ss  ss   phi-2 VIC
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXX              xx phi-2 6510
48-51 cycles available

Bad scan line, 0 sprites
ggggggggggggggggggggggggggggggggggggggggrrrrr  p p p p p p p p  phi-1 VIC
cccccccccccccccccccccccccccccccccccccccc                        phi-2 VIC
                                        xxxxxxxxxxxxxxxxxxxxxxx phi-2 6510
23 cycles available

Bad scan line, 8 sprites
ggggggggggggggggggggggggggggggggggggggggrrrrr  pspspspspspspsps phi-1 VIC
cccccccccccccccccccccccccccccccccccccccc       ssssssssssssssss phi-2 VIC
                                        xxxxXXX                 phi-2 6510
4-7 cycles available


g= grafix data fetch (character images or graphics data)
r= refresh
p= sprite image pointer fetch
c= character and color CODE fetch during a bad scan line
s= sprite data fetch
x= processor executing instructions
X= processor executing an instruction, bus request pending

Observe! The left edge of the chart is not the left edge of the screen nor
         the left edge of the beam, but the sprite x-coordinate 0. If you
         have opened the borders, you know what I mean. A sprite can be
         moved left from the coordinate 0 by using x-values greater than 500.
 ___________
|  _______  |<-- Maximum sized video screen
|||       | |
|||       |<-- Normal C64 screen
|||       | |
|||_______| |
||          |
||__________|
 ^ Sprite coordinate 0
```

Attention au repère : chez Ojala, le bord gauche du diagramme = **coordonnée sprite X 0** (pas le début de la ligne raster comme chez Mäkelä, ni le bord de l'écran). Un sprite peut être poussé à gauche de la coordonnée 0 avec X > 500.

#### 2.4 Les règles pratiques d'Ojala

1. **Budgets par type de ligne** (table ci-dessus) : 63 / 46–49 (8 sprites) / 48–51 (4 sprites) / 23 (badline) / **4–7 cycles** (badline + 8 sprites — le pire cas absolu).
2. **Dans les routines raster critiques, toujours activer les sprites dans l'ordre** : désactiver un sprite « au milieu » (fenêtres BA jointives) ne rend aucun cycle.
3. **Synchronisation par sprite** : normalement, à l'entrée d'une IRQ raster, le CPU finit une instruction de longueur indéterminée (2 à 7 cycles de gigue). Avec un sprite bien placé, un simple **DEC ou INC au bon endroit** synchronise : si le CPU est en avance, il attend le bus ; sinon il continue son instruction. Il faut une instruction dont un cycle **peut s'exécuter pendant BA bas** — p. ex. `INC $3FFF` : son 5ᵉ cycle est une **écriture** (ch.3 §3.3), que le CPU exécute encore bus-réclamé (état `X` de la glose ci-dessus) — c'est précisément pourquoi la synchronisation fonctionne. (Ojala n'a testé que DEC/INC ; d'autres « devraient marcher aussi ».)
4. **8 pixels par cycle** : le faisceau parcourt 8 pixels par cycle d'horloge, d'où la précision requise pour un effet raster horizontal.

#### 2.5 Le programme de démonstration (résumé)

Barres de couleur : le fond (`$D020`) est changé **12 fois par ligne** sur 104 lignes (LDY #103 ; « réduire pour NTSC, 55 ? »). Sync : IRQ à la ligne RASTER=`$FA`, **sprite 0 placé 20 lignes plus haut** (`$D001` = RASTER−20) pour que son DMA serve de point d'ancrage, puis `INC DUMMY` / `DEC DUMMY` (DUMMY=`$CFFF`, instructions à 6 cycles) réalisent la synchronisation ; boucle calibrée à 63 cycles exactement (`LDA #0` jette les 2 cycles restants ; ajouter des NOP pour NTSC, 65 cycles/ligne). La source complète (assembleur, chargeur BASIC avec checksums, binaires uuencodés PAL et NTSC) est dans le fichier `/home/zam/Programmation/c64/Arena64/docs/missing-cycles-ojala-1992.txt`.

---

### 3. [MISC] Massively Interleaved Sprite Crunch — Linus Åkesson, 19 déc. 2016

Effet introduit dans la démo **Lunatico** (partie greetings). Le MISC combine **trois techniques nouvelles** exploitant des bizarreries connues du VIC.

#### 3.1 DMA sprite normal : MCBASE et MC

Les pixels d'un sprite occupent **63 octets** (21 rangées × 3 octets), alignés sur 64 octets ; les bits hauts de l'adresse = pointeur sprite, les bits bas = **offset 6 bits** tenu dans le registre interne **MCBASE** (un par sprite). Fonctionnement normal : à l'activation, MCBASE = 0 ; à chaque ligne avec DMA actif, MCBASE est copié dans **MC**, MC est incrémenté pendant le fetch des 3 octets (donc MC = MCBASE + 3 mod 64 après la rangée) ; puis, **selon le latch d'expansion Y**, MCBASE est soit laissé tel quel, soit mis à MC. Répétition jusqu'à **MCBASE = 63**. En mode Y-expand, le latch bascule à chaque ligne → chaque rangée est fetchée deux fois. Contrainte fondamentale : un sprite activé reste actif jusqu'à émission de ses 21 lignes — **on ne peut pas l'avorter** à la ligne 10.

#### 3.2 Le bug « sprite crunch »

Découvert par **Pernod** dans *Rutig Banan* (1989), exploré et nommé par **Crossbow** dans *Krestage* (1997). Déclenchement : **désactiver Y-expand au 15e cycle d'horloge d'une rasterline**. Le latch bascule pendant que le VIC est en train de décider s'il assigne MCBASE depuis MC ou depuis lui-même ; le matériel, confus, produit :

```
MCBASE = ((MC | MCBASE) & 0x15) | ((MC & MCBASE) & 0x2a)
```

c'est-à-dire **OR bit à bit sur les bits pairs, AND sur les bits impairs** (ce n'est PAS équivalent à un OR global, précise Åkesson en commentaire). Explication probable (**hypothèse** de l'auteur, pas mesurée) : un bit sur deux est inversé dans la représentation interne — technique NMOS classique pour accélérer l'incrément de MC sur trois demi-cycles successifs — et l'opération réelle serait un AND global sur cette représentation. On peut donc **sauter dans les données du sprite**, mais uniquement selon un graphe prédéfini de transitions. Crossbow avait trouvé le plus court chemin début→fin : **17 nœuds**, d'où le « sprite minimum 17 lignes » — vrai seulement si on part du début. La séquence courte **15–18–1b–1e** (boucle de 4 lignes depuis l'offset `$15`) a servi dans *Edge of Disgrace* (2008) et *Shards of Fancy* (2013).

#### 3.3 Innovation 1 : boucles depuis l'offset `$35` — hauteurs possibles

En étudiant le graphe, Åkesson découvre qu'en partant de l'offset **`$35`**, on dispose de **huit boucles** de longueurs **1, 13, 14, 17, 18, 19, 20 et 21** lignes. En organisant les pixels avec le coin haut-gauche de l'objet à l'offset `$35`, on crée des **colonnes de sprites de hauteur variable**. Lunatico utilise quatre hauteurs (14, 17, 19, 21), avec ces *crunch schedules* (séquences d'offsets MCBASE, verbatim) :

```
35–38–3b–3e–15–18–1b–1e–21–25–28–2b–2e–31

35–38–3b–3e–01–05–08–0b–0f–17–1a–1d–20–23–27–2a–2d

35–38–3b–3e–01–04–07–0a–0d–15–18–1b–1e–21–25–28–2b–2e–31

35–38–3b–3e–01–05–08–0b–0e–11–14–17–1a–1d–20–23–26–29–2c–2f–32
```

Exemple pour la hauteur 17 : partir de `$35`, avancer normalement (+3) et **déclencher le glitch aux offsets `$01`, `$0b`, `$0f`, `$23` et `$2d`** — retour à `$35` en exactement 17 pas.

#### 3.4 Innovation 2 : la boucle pleine hauteur (21 lignes)

La dernière séquence ci-dessus boucle sur **21 lignes** — la hauteur normale d'un sprite — grâce à un crunch au bon moment (saut `$01`→`$05` ; possible aussi à `$03` ou à `$39`). Intérêt général : pour un **« tapis de sprites »** pleine largeur (grille de sprites bord à bord), il faut normalement **au moins 34 cycles par rangée de sprites** rien que pour réécrire les registres Y ; avec la boucle 21 lignes, **12 cycles** suffisent. Inconvénients : timing précis obligatoire, et **ne fonctionne pas sur les badlines**.

#### 3.5 Innovation 3 : le schedule encodé dans les pixels, lu par collision

Problème : avec les 8 sprites actifs, il ne reste que **44 cycles par rasterline** pour calculer et écrire les 8 bits du registre Y-expand au cycle près. Solution : **encoder le crunch schedule dans les pixels du sprite lui-même** et le lire via la **détection de collision sprite/fond** (`$D01F` — latches mis à 1 à la collision, effacés à la lecture, réutilisables plusieurs fois par frame). Chaque colonne est couverte d'une fine bande noire de pixels *foreground* cachée dans le bitmap (fond noir → invisible), sur les **pixels les plus à droite** de chaque sprite : quand ce pixel est allumé, il déclenche une collision. Lire `$D01F` en fin de ligne donne donc le pixel droit de la rangée courante des 8 sprites, **déjà emballé en un octet**, copié tel quel dans `$D017` (Y-expand). Les mises à jour des pointeurs sprite après chaque lettre aiguillent ensuite le parcours du graphe vers le schedule de la lettre suivante : la gestion de chaque crunch individuel se réduit à la gestion d'**une mise à jour de pointeur par lettre**.

#### 3.6 Contraintes de timing

- **Y-expand doit être activé avant d'être coupé au cycle 15** ; si on ne veut pas de crunch, il ne faut pas l'activer du tout (sinon une ligne s'affiche deux fois). L'information dynamique dans les pixels indique donc « faut-il armer Y-expand », et au cycle 15 on coupe pour tous les sprites.
- **Délai de 3 rasterlines** : données fetchées ligne 0 → affichées ligne 1 → échantillonnées (collision) tôt ligne 2 → crunch ligne 3. Le schedule doit être encodé **3 lignes avant** dans les pixels.
- Tous les schedules commencent par **35–38–3b–3e**, ce qui rend les coutures sûres ; impossible de mettre à jour 8 pointeurs sur une ligne → **sprites 0–4 sur lignes impaires, 5–7 sur lignes paires**, d'où la **rangée VIERGE (pixels vides) obligatoire à l'offset `$35`** (un pointeur en retard d'une ligne ne fetche que du vide — « blank » = transparent, PAS blanc).
- Le DMA sprite prend les **cycles 55 à 10** (le cycle 55 reste utilisable en écriture). Code d'une paire de lignes (verbatim, déroulé ~100 fois) :

```
;               Invariants: x = y = 0     Cycle

template
                nop                     ; 54 11

                sty     $d017           ; 12, crunch
                lda     $d01f           ; 16
                sta     $d017           ; 20
tem_s5
                lda     #$80            ; 24
                lda     vm+$3fd         ; 26
tem_s6
                lda     #$80            ; 30
                lda     vm+$3fe         ; 32
tem_s7
                lda     #$80            ; 36
                lda     vm+$3ff         ; 38

                nop                     ; 42
                nop                     ; 44
                nop                     ; 46
                nop                     ; 48
tem_rr
                lda     #$3e            ; 50
                sta     $d011           ; 52, repeat row

                shy     $d017,x         ; 11, crunch
                lda     $d01f           ; 16
                sta     $d017           ; 20
tem_s0
                lda     #$80            ; 24
                lda     vm+$3f8         ; 26
tem_s1
                lda     #$80            ; 30
                lda     vm+$3f9         ; 32
tem_s2
                lda     #$80            ; 36
                lda     vm+$3fa         ; 38
tem_s3
                lda     #$80            ; 42
                lda     vm+$3fb         ; 44
tem_s4
                lda     #$80            ; 48
                lda     vm+$3fc         ; 50
```

Détails : le crunch est déclenché par l'écriture dans `$d017` au **cycle 15** (dernier cycle du `sty`, 4 cycles ; ou du `shy`, illégal 5 cycles — nécessaire quand on revient du DMA au cycle 11, faute d'instruction à 1 cycle). L'écriture `$d011` au cycle 55 une ligne sur deux **repousse les badlines**, qui ruineraient le timing. `#$80` est une valeur factice : pendant le vblank, les pointeurs sprite sont écrits dans ces opérandes et les `lda` transformés en `sta` (puis remis en `lda` inoffensifs).

- **Initialisation** : les offsets de départ (`$35` n'est pas atteignable en séquence normale, tous les offsets normaux étant divisibles par 3) sont obtenus en démarrant les 8 sprites à la même coordonnée Y dans la bordure haute et en les crunchant tous à **`$2d`** (→ `$35`) ; ensuite, pendant N lignes (selon le scroll de chaque colonne), la valeur de `$D01F` est **forcée à 1**, ce qui crunche de `$35` vers `$35` (boucle de longueur 1) et « étire » le sprite. Masques pris dans une table de **22 octets** calculée pendant le vblank.
- **Animation** : seules 2 ou 3 colonnes bougent par frame (2 colonnes, appel du player musique, puis lecture de la position raster pour décider d'une 3e) — visuellement l'effet passe pour du 50 fps.

#### 3.7 Les trois techniques du MISC en une phrase chacune

1. **Boucles à hauteur variable depuis `$35`** : huit longueurs de boucle (1, 13, 14, 17, 18, 19, 20, 21) dans le graphe du crunch → colonnes de sprites de hauteur choisie.
2. **Boucle pleine hauteur 21 lignes** : un crunch au bon offset (`$01`→`$05`, ou à `$03`/`$39`) reboucle un sprite entier → tapis de sprites pour 12 cycles/rangée au lieu de 34.
3. **Schedule auto-porté** : les crunchs sont encodés dans le pixel droit de chaque rangée du sprite et récupérés en un octet via `$D01F` (collision sprite/fond), copié dans `$D017` — avec un délai obligatoire de 3 rasterlines.

---

### Croisement des trois sources

Les trois textes se recoupent exactement sur les invariants : **BA tombe 3 cycles avant la prise de bus** (Ojala §2.2 = états `X`/`*` de Mäkelä, où seuls les cycles d'écriture passent encore) ; **2 cycles Phi-2 volés par sprite + fenêtres jointives** (Ojala) = paires `s` en Phi-2 des chronogrammes de Mäkelä ; **DMA sprite en début/fin de ligne** (fenêtre 0s1s2s…7s de Mäkelä) = « cycles 55 à 10 » d'Åkesson, dont le template exploite précisément la règle d'Ojala (l'écriture au cycle 55 passe pendant BA bas). Divergences à retenir : les chiffres de cycles volés d'Ojala (16–19 dans le texte, 14–17 implicites dans sa table) sont approximatifs de son propre aveu, et Mäkelä — la référence mesurée — utilise une **origine de diagramme différente** (début de ligne raster vs coordonnée sprite X 0). Autre réconciliation : les **44 cycles** restants d'Åkesson (8 sprites) vs les **46–49** d'Ojala — le DMA sprite occupe les cycles 55 à 10 (19 cycles) → 63−19 = 44 ; Ojala crédite en plus les écritures que le CPU place encore dans les fenêtres BA. Pour Arena64 : ce chapitre explique pourquoi la badline gèle le CPU même au turbo (états `=` : le bus est au VIC, pas au 6510) et pourquoi tout sprite ajouté au HUD se paie en fenêtres BA, pas seulement en cycles de fetch.

Sources : `/home/zam/Programmation/c64/Arena64/docs/VIC-PAL-timing-Makela-1994.txt` · `/home/zam/Programmation/c64/Arena64/docs/missing-cycles-ojala-1992.txt` · `/home/zam/Programmation/c64/Arena64/docs/MISC-sprite-crunch-akesson-2016.txt`

---

# Chapitre 3 — Le 6510 : cycles et interruptions (64doc)

## 6510 : cycles et interruptions

**Source unique** : `docs/64doc-Makela-1994.txt` — « Documentation for the NMOS 65xx/85xx Instruction Set », John West & Marko Mäkelä, rév. 1.8 du 3 juin 1994 (fichier du projet X64). Tout ce chapitre est **documenté** (mesuré par les auteurs sur 6510/8502 NMOS réels) ; les points que la source elle-même qualifie d'incertains sont marqués.

---

### 1. Principes de base du séquencement

[64doc §6510 Instruction Timing, l.864–878]

- Le 65xx NMOS effectue **au moins deux lectures par instruction** : l'opcode, puis l'octet suivant (même pour les instructions à 1 octet — cet octet est lu et jeté).
- **Pipeline** : si le dernier cycle d'une instruction n'écrit pas en mémoire, le processeur y superpose le fetch de l'opcode suivant. `EOR #$FF` prend « vraiment » 3 cycles, mais le 3ᵉ est recouvert → 2 cycles effectifs. Les diagrammes ci-dessous incluent parfois ce fetch : pour le temps réel, soustraire le dernier cycle quand la source le précise (cas des branchements).
- **RMW = double écriture** : les instructions lecture-modification-écriture écrivent d'abord la valeur *non modifiée*, puis la valeur modifiée (« INC effectively does LDX loc;STX loc;INX;STX loc ») [l.812–813].
- **-RDY est ignoré pendant les écritures** : d'où l'attente de 3 cycles avant un DMA — le maximum d'écritures consécutives est 3, atteint pendant les séquences d'interruption (sauf -RESET) [l.815–818].
- **Lectures parasites (dummy reads)** : tout franchissement de page en mode indexé provoque d'abord une lecture à une adresse fausse (trop basse d'une page) [l.808–810] ; l'octet qui suit un branchement est toujours lu [l.802–806]. Conséquence pratique : ces accès parasites touchent réellement le bus (voir §4.4, acquittement d'interruptions par effets de bord).
- **Pas de gestion du franchissement de page en indirect** : pointeur `$xxFF` → l'octet haut est lu à `$xx00` (`JMP ($01FF)` lit PCH à `$0100` ; `LDA ($FF),Y` lit la base à `$FF` et `$00`). Idem en zéropage indexé : `LDA ($FF,X)` avec X=1 lit l'adresse effective à `$00`/`$01` [l.792–800].

### 2. Cycles par mode d'adressage — récapitulatif

Synthèse des diagrammes [64doc l.934–1374]. `+1*` = un cycle de plus si franchissement de page.

| Mode | Lecture | RMW | Écriture |
|---|---|---|---|
| Implicite / Accumulateur | 2 | — | — |
| Immédiat | 2 | — | — |
| Zéropage | 3 | 5 | 3 |
| Zéropage,X (ou ,Y) | 4 | 6 | 4 |
| Absolu | 4 | 6 | 4 |
| Absolu,X / Absolu,Y | 4 +1* | **7 (fixe)** | **5 (fixe)** |
| (indirect,X) | 6 | 8 | 6 |
| (indirect),Y | 5 +1* | **8 (fixe)** | **6 (fixe)** |

Instructions particulières :

| Instruction | Cycles | Instruction | Cycles |
|---|---|---|---|
| JMP absolu | 3 | PHA/PHP | 3 |
| JMP (indirect) | 5 | PLA/PLP | 4 |
| JSR | 6 | RTS | 6 |
| BRK | 7 | RTI | 6 |
| Branchement non pris | 2 | Branchement pris | 3 (+1 si page franchie) |
| IRQ / NMI | 7 | RESET | ~6 (« probably », ambigu dans la source) [l.929–930] |

Règles à retenir : **écriture indexée et RMW indexé paient toujours le cycle de correction de page**, pris ou pas (le CPU ne peut pas annuler une écriture à une adresse fausse, il lit donc d'abord) ; seule la *lecture* indexée économise ce cycle quand la page n'est pas franchie.

### 3. Détail cycle par cycle — les cas piégeux (verbatim)

#### 3.1 Lecture absolue indexée, franchissement de page [64doc l.1155–1176]

```
   #   address  R/W description
  --- --------- --- ------------------------------------------
   1     PC      R  fetch opcode, increment PC
   2     PC      R  fetch low byte of address, increment PC
   3     PC      R  fetch high byte of address,
                    add index register to low address byte,
                    increment PC
   4  address+I* R  read from effective address,
                    fix the high byte of effective address
   5+ address+I  R  re-read from effective address

  Notes: I denotes either index register (X or Y).
         * The high byte of the effective address may be invalid
           at this time, i.e. it may be smaller by $100.
         + This cycle will be executed only if the effective address
           was invalid during cycle #4, i.e. page boundary was crossed.
```

#### 3.2 Écriture absolue indexée : lecture parasite obligatoire (5 cycles fixes) [64doc l.1199–1217]

```
   #   address  R/W description
  --- --------- --- ------------------------------------------
   1     PC      R  fetch opcode, increment PC
   2     PC      R  fetch low byte of address, increment PC
   3     PC      R  fetch high byte of address,
                    add index register to low address byte,
                    increment PC
   4  address+I* R  read from effective address,
                    fix the high byte of effective address
   5  address+I  W  write to effective address

  Notes: * ... it may be smaller by $100. Because
           the processor cannot undo a write to an invalid
           address, it always reads from the address first.
```

#### 3.3 RMW absolu : la double écriture (6 cycles) [64doc l.1046–1057]

```
   #  address R/W description
  --- ------- --- ------------------------------------------
   1    PC     R  fetch opcode, increment PC
   2    PC     R  fetch low byte of address, increment PC
   3    PC     R  fetch high byte of address, increment PC
   4  address  R  read from effective address
   5  address  W  write the value back to effective address,
                  and do the operation on it
   6  address  W  write the new value to effective address
```

En RMW absolu,X (7 cycles), s'ajoutent la lecture parasite (cycle 4, adresse potentiellement fausse) puis la relecture, avant les deux écritures [l.1178–1196]. En RMW `(ind),Y` : 8 cycles fixes [l.1320–1334].

#### 3.4 Branchements (relatif) [64doc l.1220–1245]

```
   #   address  R/W description
  --- --------- --- ---------------------------------------------
   1     PC      R  fetch opcode, increment PC
   2     PC      R  fetch operand, increment PC
   3     PC      R  Fetch opcode of next instruction,
                    If branch is taken, add operand to PCL.
                    Otherwise increment PC.
   4+    PC*     R  Fetch opcode of next instruction.
                    Fix PCH. If it did not change, increment PC.
   5!    PC      R  Fetch opcode of next instruction,
                    increment PC.

  Notes: The opcode fetch of the next instruction is included to
         this diagram for illustration purposes. When determining
         real execution times, remember to subtract the last cycle.
         * The high byte of Program Counter (PCH) may be invalid
           at this time, i.e. it may be smaller or bigger by $100.
         + If branch is taken, this cycle will be executed.
         ! If branch occurs to different page, this cycle will be
           executed.
```

Donc : 2 cycles non pris, 3 pris même page, 4 pris avec page franchie — avec, en cas de franchissement, un fetch parasite dans l'ancienne page (adresse ±`$100`) [l.802–806].

#### 3.5 (indirect),Y lecture [64doc l.1297–1317]

```
   #    address   R/W description
  --- ----------- --- ------------------------------------------
   1      PC       R  fetch opcode, increment PC
   2      PC       R  fetch pointer address, increment PC
   3    pointer    R  fetch effective address low
   4   pointer+1   R  fetch effective address high,
                      add Y to low byte of effective address
   5   address+Y*  R  read from effective address,
                      fix high byte of effective address
   6+  address+Y   R  read from effective address
```
(Le pointeur est toujours lu en page zéro, sans gestion du wrap `$FF`→`$00`.)

#### 3.6 JMP (indirect) : le bug `$xxFF` [64doc l.1363–1374]

```
   #   address  R/W description
  --- --------- --- ------------------------------------------
   1     PC      R  fetch opcode, increment PC
   2     PC      R  fetch pointer address low, increment PC
   3     PC      R  fetch pointer address high, increment PC
   4   pointer   R  fetch low address to latch
   5  pointer+1* R  fetch PCH, copy latch to PCL

  Note: * The PCH will always be fetched from the same page
          than PCL, i.e. page boundary crossing is not handled.
```

#### 3.7 BRK (7 cycles) [64doc l.936–947]

```
   #  address R/W description
  --- ------- --- -----------------------------------------------
   1    PC     R  fetch opcode, increment PC
   2    PC     R  read next instruction byte (and throw it away),
                  increment PC
   3  $0100,S  W  push PCH on stack, decrement S
   4  $0100,S  W  push PCL on stack, decrement S
   5  $0100,S  W  push P on stack (with B flag set), decrement S
   6   $FFFE   R  fetch PCL
   7   $FFFF   R  fetch PCH
```

Autres accès pile : JSR = fetch opcode + fetch adr basse + 1 cycle interne pile + push PCH + push PCL + fetch adr haute (6 cy) [l.993–1003] ; RTS ajoute un incrément final de PC (6 cy) [l.962–971] ; RTI = 6 cy [l.950–959].

### 4. Interruptions [64doc §Interrupts, l.883–931]

#### 4.1 Reconnaissance et latence

- **NMI et IRQ prennent 7 cycles**, séquence analogue à BRK (mais B poussé à 0). IRQ n'est exécutée que si le flag I est à 0 ; IRQ et BRK positionnent I, **NMI ne touche pas I**.
- **Règle de latence** : le processeur termine l'instruction en cours avant la séquence d'interruption. Pour être traitée *avant* l'instruction suivante, « the interrupt must occur before the last cycle of the current instruction » [l.890–893]. Latence donc : 7 cycles + le reliquat de l'instruction en cours ; si l'IRQ tombe SUR le dernier cycle, elle rate la frontière et attend l'instruction SUIVANTE entière (reliquat au pire 8 cycles, RMW (ind),Y).
- **Le cas branch** : ⚠️ le raffinement bien connu « une branche prise retarde d'un cycle la prise en compte de l'IRQ » **n'est pas couvert par 64doc** — la source ne donne que la règle générale ci-dessus (ambigu dans la source pour ce cas précis). Ce que la source documente sur les branchements, c'est leurs fetchs parasites (§3.4) et leur usage pour acquitter des interruptions (§4.4).

#### 4.2 BRK détourné (hijack) et priorités

- **Exception unique à la règle** : si une interruption matérielle (NMI ou IRQ) survient **avant le « cycle d'empilement de P » de BRK** (la prose de 64doc l'appelle « fourth (flags saving) cycle » [l.895], mais sa table le place au cycle 5 [l.938] — conflit de numérotation interne à la source), BRK est « sauté » : le processeur saute au vecteur matériel, la séquence fait toujours 7 cycles — mais **le P empilé porte B=1** [l.895–903]. BRK+IRQ simultanés : bénin (l'IRQ re-survient après le RTI si sa source n'est pas acquittée). **BRK+NMI : fatal** si le handler NMI ne teste pas le flag B (et ne retranche pas 2 à l'adresse de retour) — le BRK est perdu [l.903–910].
- Officiellement BRK ne saute qu'au vecteur IRQ `$FFFE` ; en réalité un NMI pendant BRK détourne vers `$FFFA` avec B=1 empilé [l.229–234].
- **NMI et IRQ qui se chevauchent** : « le processeur sautera *très probablement* au vecteur NMI, puis au vecteur IRQ après la première instruction du handler NMI. Ceci n'a pas encore été mesuré » — il se pourrait aussi qu'un NMI soit perdu si une IRQ arrive dans les 4 cycles suivants (**ambigu dans la source**, hypothèse explicite des auteurs) [l.912–921].
- **RESET** : n'empile pas PC, dure « probablement » 6 cycles après relâchement du signal ; comme NMI, préserve tous les registres sauf PC [l.929–931] — d'où l'obligation d'initialiser D et I dans le handler RESET [l.822–823].

#### 4.3 Pipeline et fin de séquence

Après la séquence d'interruption, le fetch de la première instruction du handler est recouvert par le dernier cycle — même pipeline que les instructions normales [l.923–927].

#### 4.4 Acquittement par effets de bord (« Real Programmers ») [64doc l.1378–1610]

Applications directes des lectures/écritures parasites — utile en démo/raster :

- **RMW sur registre d'I/O** : `LSR $D019` acquitte l'IRQ VIC (cycle 5 = réécriture de la valeur lue) *et* récupère le flag raster dans C — un seul opcode pour tester et acquitter [l.1382–1401] :

```
     Operational diagram of LSR $D019:
       #  data  address  R/W
      --- ----  -------  ---  ---------------------------------
       1   4E     PC      R   fetch opcode
       2   19    PC+1     R   fetch address low
       3   D0    PC+2     R   fetch address high
       4   xx    $D019    R   read memory
       5   xx    $D019    W   write the value back, rotate right
       6  xx/2   $D019    W   write the new value back
```

- **Indexé avec page franchie** : `LDX #$10 : LDA $DCFD,X` lit parasitement `$DC0D` (cycle 4) puis `$DD0D` (cycle 5) → acquitte **les deux CIA** en une instruction [l.1405–1420]. Variante écriture : `STA $DDFD,X` lit `$DD0D` puis écrit `$DE0D`.
- **Branchements** : un `BPL` placé dans les registres CIA acquitte via ses fetchs parasites (cycles 3–4 lisent `$xx0D`) [l.1437–1538].
- **RTI logé en `$DD0C`** : le fetch systématique de l'octet suivant (`$DD0D` = ICR) acquitte le CIA 2 pendant le RTI lui-même — « the fastest possible interrupt handler in the 6500 family » [l.1540–1597].

### 5. Opcodes non documentés [64doc l.61–119, 308–582, 750–755]

Matrice complète en [l.61–100]. Légende source : `*` = non documenté, `**` = opération inhabituelle, `t` = bloque la machine, `*t` = bloque très rarement.

| Opcode(s) | Comportement (une ligne) |
|---|---|
| **SLO, RLA, SRE** (`$x3`/`$x7`/`$xF`/`$xB`…) | RMW combinés (classés avec ASL/ROL/LSR dans toutes les tables de timing RMW [l.1046+]) ; la source ne détaille pas leur opération, contrairement à RRA/ISB/DCP. |
| **RRA** | ROR mémoire + ADC, hérite du mode décimal de l'ADC officiel [l.750–753]. |
| **ISB** | INC mémoire + SBC, hérite du mode décimal ; flags insensibles à D comme SBC [l.750–755]. |
| **DCP** | DEC mémoire + CMP ; flags insensibles au flag D [l.754–755]. |
| **SAX** (`$87`/`$97`/`$8F`/`$83`) | Range (A & X) — le AND est fait par les drivers open-collector du bus, pas par l'ALU [l.349–353]. |
| **LAX** | Charge le même octet simultanément dans A et X [l.355–356]. |
| **NOP*** (variantes multi-modes) | Comme un load : lit l'opérande (dummy reads compris) mais ne stocke rien et ne touche aucun flag [l.116–119]. |
| **SBC `$EB`** | Identique au SBC officiel (« 'NOP' seems to completely disappear ») [l.496–498]. |
| **ANC** (`$0B`/`$2B`) | Immédiat AND A, puis l'opération accumulateur de sa colonne (ASL/ROL) — principe de la ligne `$0B` [l.500–507]. |
| **ASR** (`$4B`) | A = (A AND #imm) puis LSR A [l.500–507]. |
| **ARR** (`$6B`) | AND #imm + ROR A, mais flags hérités d'ADC : C = bit 6 du résultat, V = bit6 XOR bit5 ; mode décimal spécial avec fixup BCD des deux nybbles (code C complet [l.394–424]) [l.359–392]. |
| **SBX** (`$CB`) | X ← (A & X) − #imm ; flags façon CMP : D et C ignorés en entrée, C positionné par le résultat, V intact, pas de mode décimal [l.427–437]. |
| **ANE** (`$8B`) | A = (A \| #`$EE`) & X & #imm — la constante `$EE` varie (`$8C`/`$CC`/`$0C`/`$8E`… selon machine, DMA VIC, mode décimal) : **instable, ne pas utiliser** [l.314–323, 509–544, 567]. |
| **LXA** (`$AB`) | A = X = (A & #imm) ou variante ANE selon le processeur ; résultats aléatoires observés : **instable, ne pas utiliser** [l.325–328, 547–567]. |
| **SHA** (`$93`/`$9F`) | Range (A & X & (ADDR_HI + 1)) ; si page franchie, cette valeur écrase aussi l'octet haut de l'adresse effective [l.330–336, 569–581]. |
| **SHX** (`$9E`) | Range (X & (ADDR_HI + 1)), même corruption d'adresse si page franchie [l.331]. |
| **SHY** (`$9C`) | Range (Y & (ADDR_HI + 1)), idem [l.332]. |
| **SHS** (`$9B`) | SHA + TXS avec X remplacé par (A & X) : S ← A & X, et range (A & X & (ADDR_HI+1)) [l.333]. |
| **LAS/LAE** (`$BB`) | Marqué `**` dans la matrice et listé parmi les lectures absolue,Y [l.96, 1156] ; comportement non décrit (ambigu dans la source). |
| **t / *t** (`$02`, `$12`, `$22`… ; `$x2`) | `t` bloque la machine ; `*t` bloque très rarement [l.109–110]. |

Timing : les non documentés suivent exactement les diagrammes de leur classe (LAX = lecture ; SLO/SRE/RLA/RRA/ISB/DCP = RMW ; SAX/SHA/SHX/SHY = écriture) — ils figurent nommément dans les tables du §3.

### 6. Le port du 6510 : adresses `$00`/`$01` [64doc §Memory Management, l.1625–1656]

- `$00` = **DDR** (Data Direction Register), `$01` = **PR** (Peripheral Register). Bit à 1 dans le DDR → ligne en sortie pilotée par le bit PR ; bit à 0 → le bit PR reflète l'état de la ligne. 6 lignes (P0–P5) sur 6510 ; le 8502 (C128) en a 7 (P6 = touche Caps Lock).

```
     Direction  Line  Function
     ---------  ----  --------
        out      P5   Cassette motor control. (0 = motor spins)
        in       P4   Cassette sense. (0 = PLAY button depressed)
        out      P3   Cassette write data.
        out      P2   CHAREN
        out      P1   HIRAM
        out      P0   LORAM
```

- **Défauts** : DDR = `$2F`, PR = `$37` [l.1648–1650]. Une ligne de gestion mémoire passée en *entrée* lit « 1 » via les pull-ups externes ; -RESET remet toutes les lignes en entrée → les trois lignes LORAM/HIRAM/CHAREN montent à 1 → **les ROM sont toujours réactivées au reset** [l.1651–1656].
- LORAM/HIRAM/CHAREN + -EXROM/-GAME (port cartouche) sélectionnent la configuration mémoire (table complète des 9 configurations en [l.1684–1719]). CHAREN choisit entre I/O et ROM caractères en `$D000–$DFFF`. Toute écriture vers une zone ROM traverse vers la RAM sous-jacente (sauf configuration Ultimax) [l.1761–1778].
- **Écrire les octets RAM 0 et 1** (sous le port) : lors d'un STA vers 0/1, le CPU pose l'adresse et R/-W mais **ne pilote pas le bus de données** — c'est la dernière valeur laissée sur le bus par le VIC qui est écrite en RAM. Astuce documentée : faire lire `$3FFF` au VIC (bordure haut/bas) au moment du store [l.1862–1881] ; peu fiable sur toutes les machines [l.1905]. Lecture des octets 0/1 : via le VIC (bitmap/sprite en `$0000` + registres de collision) ou en lisant l'espace d'adressage ouvert `$DE00–$DFFF` juste après un accès VIC [l.1846–1903].

### 7. Divers normatifs utiles

- PHP (et BRK) empile **toujours B=1** [l.785].
- Comparaisons (CMP) : C supposé mis, insensibles au flag D — mais SBX prouve que CMP *force* temporairement D=0 en interne [l.734–737].
- Différences NMOS vs CMOS (65C00) à connaître pour ne pas se faire piéger par une doc CMOS : dummy read (adresse invalide vs dernier octet d'instruction), opcodes invalides (NOP sur CMOS), `JMP ($xxFF)` corrigé sur CMOS (+1 cycle), RMW = 2 lectures/1 écriture sur CMOS, D initialisé au reset sur CMOS, flags décimaux valides (+1 cycle), BRK non détourné par interruption sur CMOS [64doc §Different CPU types, l.826–858].

---

**Rappel Arena64** : la double écriture RMW (§3.3) et les lectures parasites indexées (§3.1–3.2) sont ce qui rend `LSR $D019` et `LDA $DCFD,X` légitimes pour l'acquittement d'IRQ raster ; et la règle « -RDY ignoré pendant les écritures » (§1) est la raison des 3 cycles de garde avant tout DMA — pertinent pour le VIC-II (badlines) comme pour la REU.

---

# Chapitre 4 — SID & CIA (datasheet 6581, modèle Lorenz)

## SID & CIA — référence technique (sources primaires)

Sources : datasheet MOS 6581 (scans zimmers.net `6581.zip`, 12 pages, OCR 2 colonnes — **entrelacement de colonnes par endroits, valeurs douteuses signalées**) et « A Software Model of the CIA6526 » de Wolfgang Lorenz, v2.15, mai 1997 (Emulator Developers Kit, accompagne `CIA6526.cpp/.h` + TESTSUIT.ZIP). Les ancres renvoient à la page du datasheet ([SID p.N]) ou à la section/programme de test du document Lorenz ([Lorenz §…]).

---

## 1. SID 6581 (Sound Interface Device)

### 1.1 Vue d'ensemble

Synthétiseur 3 voix mono-puce, compatible famille 65XX. Chaque voix = oscillateur/générateur de forme d'onde + générateur d'enveloppe + modulateur d'amplitude ; un filtre programmable commun permet la synthèse soustractive. Le CPU peut lire la sortie de l'oscillateur 3 et de l'enveloppe 3 comme sources de modulation (vibrato, balayages) ou de nombres aléatoires. [SID p.2]

Caractéristiques annoncées [SID p.1] : 3 oscillateurs (plage 0–4 kHz) ; 4 formes d'onde par oscillateur (triangle, dent de scie, pulse variable, bruit) ; 3 modulateurs d'amplitude (dynamique 48 dB) ; 3 enveloppes exponentielles (Attack 2 ms–8 s, Decay 6 ms–24 s, Sustain 0–pic, Release 6 ms–24 s) ; synchronisation d'oscillateurs ; ring modulation ; filtre programmable (coupure 30 Hz–12 kHz, pente 12 dB/octave, sorties passe-bas/passe-bande/passe-haut/notch, résonance variable) ; volume maître ; 2 interfaces A/N pour potentiomètres ; générateur de nombres aléatoires ; entrée audio externe.

### 1.2 Les 29 registres (`$D400`–`$D41C`)

29 registres 8 bits, **écriture seule** sauf les 4 derniers (**lecture seule**) [SID p.3, Table 1]. Le datasheet donne les offsets `$00`–`$1C` ; sur C64 la base est `$D400`. Les colonnes de bits de la Table 1 sont mutilées par l'OCR ; la décomposition ci-dessous est reconstruite depuis les descriptions de registres [SID p.4–6], cohérentes entre elles.

| Adresse | Reg | Nom | D7 … D0 | Type |
|---|---|---|---|---|
| `$D400` | 00 | Freq Lo V1 | F7–F0 | W |
| `$D401` | 01 | Freq Hi V1 | F15–F8 | W |
| `$D402` | 02 | PW Lo V1 | PW7–PW0 | W |
| `$D403` | 03 | PW Hi V1 | ––––, PW11–PW8 (b4–7 inutilisés) | W |
| `$D404` | 04 | Control V1 | NOISE·PULSE·SAW·TRI·TEST·RING·SYNC·GATE | W |
| `$D405` | 05 | Attack/Decay V1 | ATK3–0 · DCY3–0 | W |
| `$D406` | 06 | Sustain/Release V1 | STN3–0 · RLS3–0 | W |
| `$D407`–`$D40D` | 07–0D | Voix 2 | idem V1 | W |
| `$D40E`–`$D414` | 0E–14 | Voix 3 | idem V1 | W |
| `$D415` | 15 | FC Lo | –––––, FC2–FC0 (b3–7 inutilisés) | W |
| `$D416` | 16 | FC Hi | FC10–FC3 | W |
| `$D417` | 17 | RES/Filt | RES3–0 · FILTEX·FILT3·FILT2·FILT1 | W |
| `$D418` | 18 | Mode/Vol | 3OFF·HP·BP·LP · VOL3–0 | W |
| `$D419` | 19 | POTX | PX7–PX0 | R |
| `$D41A` | 1A | POTY | PY7–PY0 | R |
| `$D41B` | 1B | OSC3/Random | O7–O0 | R |
| `$D41C` | 1C | ENV3 | E7–E0 | R |

Les 3 emplacements restants (`$1D`–`$1F`) ne sont pas utilisés : écriture ignorée, lecture renvoie des données invalides [SID p.7].

### 1.3 Fréquence et largeur d'impulsion

- **Fréquence** (16 bits, linéaire) : `Fout = (Fn × Fclk / 16777216) Hz` ; à ø2 = 1,0 MHz : `Fout = Fn × 0,0596 Hz`. Résolution suffisante pour tout tempérament et pour un portamento sans marches audibles. [SID p.4]
- **Pulse width** (12 bits, b4–7 de PW Hi inutilisés) : `PWout = (PWn / 40,95) %`. La forme pulse doit être sélectionnée pour que PW ait un effet. PWn = 0 ou 4095 (`$FFF`) → sortie continue (DC) ; PWn = 2048 (`$800`) → signal carré. Balayage sans marches audibles. [SID p.4]

### 1.4 Registre de contrôle : les 4 formes d'onde et les bits d'effet

Registre 04 (et 0B, 12) [SID p.4] :

| Bit | Nom | Effet |
|---|---|---|
| 0 | GATE | 1 = déclenche Attack/Decay/Sustain ; 0 = lance Release. Le GATE contrôle seul l'amplitude finale : il est inutile de désélectionner la forme d'onde pour couper la voix. Gate/re-gate permis à tout instant (le cycle repart de l'amplitude atteinte). [SID p.4–5] |
| 1 | SYNC | Synchronisation « hard sync » de l'oscillateur sur l'autre voix : V1←Osc3, V2←Osc1, V3←Osc2. L'oscillateur source doit avoir une fréquence ≠ 0 (de préférence plus basse) ; aucun autre paramètre de la voix source n'intervient. [SID p.4–5] |
| 2 | RING MOD | Remplace la sortie **triangle** par la combinaison ring-modulée : V1 = Osc 1×3, V2 = Osc 2×1, V3 = Osc 3×2. Audible seulement si le triangle est sélectionné et si l'oscillateur source ≠ 0. Structures non harmoniques (cloches, gongs). (OCR : numéro de bit mutilé, position déduite de l'ordre Sync→Test.) [SID p.4–5] |
| 3 | TEST | 1 = remet à zéro et **verrouille** l'oscillateur ; sortie noise réinitialisée, pulse maintenu à un niveau DC. Sert au test, ou à synchroniser l'oscillateur sur un événement externe. [SID p.4] |
| 4 | TRIANGLE | Pauvre en harmoniques, doux, « flûte ». [SID p.4] |
| 5 | SAWTOOTH | Riche en harmoniques paires et impaires, brillant, « cuivré ». [SID p.4] |
| 6 | PULSE | Contenu harmonique réglé par PW ; du carré creux au pulse nasal ; balayage temps réel = effet de phasing. [SID p.4] |
| 7 | NOISE | Signal aléatoire changeant à la fréquence de l'oscillateur : du grondement au souffle blanc (explosions, vent, caisses claires, cymbales). [SID p.4] |

**Les formes d'onde ne sont PAS additives** : en sélectionner plusieurs produit un ET logique. Si une autre forme est active en même temps que NOISE, la sortie bruit peut se **verrouiller** (« lock up ») et reste muette jusqu'à un reset par le bit TEST ou par RES (broche 5) bas. [SID p.5]

### 1.5 Enveloppe ADSR

- Attack (b4–7 de `$05`) : temps de montée 0→pic ; Decay (b0–3) : temps pic→niveau sustain ; Sustain (b4–7 de `$06`) : 16 niveaux **linéaires**, 0 = silence, 15 (`$F`) = pic, 8 = mi-pic ; Release (b0–3) : chute sustain→0, **taux identiques au Decay**. [SID p.5]
- Les taux sont donnés pour ø2 = 1,0 MHz ; pour une autre horloge, multiplier par 1 MHz/ø2. [SID p.5]

**Table 2 — taux d'enveloppe** [SID p.5]. Note OCR : dans les lignes 9–15, l'OCR confond « S » et « 8 » ; les valeurs en secondes ci-dessous sont reconstruites par recoupement interne (page 1 : Attack max 8 s, Decay/Release max 24 s ; exemples p.11 : Release 9 = 750 ms, Release 3 = 72 ms, Attack 10 = 500 ms) — cohérent, mais à vérifier sur les scans.

| Valeur | Attack (temps/cycle) | Decay/Release (temps/cycle) |
|---|---|---|
| 0 (`$0`) | 2 ms | 6 ms |
| 1 (`$1`) | 8 ms | 24 ms |
| 2 (`$2`) | 16 ms | 48 ms |
| 3 (`$3`) | 24 ms | 72 ms |
| 4 (`$4`) | 38 ms | 114 ms |
| 5 (`$5`) | 56 ms | 168 ms |
| 6 (`$6`) | 68 ms | 204 ms |
| 7 (`$7`) | 80 ms | 240 ms |
| 8 (`$8`) | 100 ms | 300 ms |
| 9 (`$9`) | 250 ms | 750 ms |
| 10 (`$A`) | 500 ms | 1,5 s (OCR incertain : « 500 nS 158 ») |
| 11 (`$B`) | 800 ms | 2,4 s (OCR « 248 ») |
| 12 (`$C`) | 1 s | 3 s |
| 13 (`$D`) | 3 s (OCR « 38 ») | 9 s |
| 14 (`$E`) | 5 s (OCR « 58 ») | 15 s |
| 15 (`$F`) | 8 s | 24 s (OCR « 2458 ») |

**Enveloppes types** (Annexe B, valeurs du texte) [SID p.11] : violon/soutenu A=10 (`$A`, 500 ms), D=8 (300 ms), S=10 (`$A`), R=9 (750 ms) ; percussion/cymbale A=0 (2 ms), D=9 (750 ms), S=0, R=9 (750 ms) — décroît dès le pic quel que soit GATE ; piano/clavecin A=0, D=9 (750 ms), S=0, R=0 (6 ms) ; orgue A=0 (2 ms), D=0 (6 ms), S=15 (`$F`), R=0 (6 ms) ; « backwards » A=10 (`$A`, 500 ms), D=0 (6 ms), S=15 (`$F`), R=3 (72 ms).

### 1.6 Filtre

- **FC Lo/FC Hi (`$15`/`$16`)** : nombre 11 bits linéaire (b3–7 de FC Lo inutilisés) = fréquence de coupure/centre. Plage annoncée : « environ 30 Hz à 10 kHz » avec les condensateurs recommandés de 2200 pF [SID p.5] — mais la page 1 et la description des broches disent « ~30 Hz–12 kHz » [SID p.1, p.7] : divergence telle qu'imprimée (l'OCR p.5 lit « 1OKHz »).
- **RES/Filt (`$17`)** : b4–7 = résonance, 16 réglages linéaires de 0 (aucune) à 15 (`$F`, maximum) — accentue les composantes à la coupure, son plus « pointu ». b0–3 = routage vers le filtre : FILT1 (b0) voix 1, FILT2 (b1) voix 2, FILT3 (b2) voix 3, FILTEX (b3) entrée EXT IN (broche 26). Bit à 0 = la source va directement à la sortie audio, non filtrée. [SID p.6]
- **Mode/Vol (`$18`)** : LP (b4) passe-bas 12 dB/oct (sons pleins) ; BP (b5) passe-bande, atténuation 6 dB/oct de part et d'autre (sons fins, ouverts) ; HP (b6) passe-haut 12 dB/oct (sons métalliques) ; 3 OFF (b7) = coupe la voix 3 du chemin audio direct — avec FILT3 = 0, la voix 3 sert de modulateur sans sortie parasite. **Les modes de filtre SONT additifs** : LP+HP = notch (réjecteur de bande). Il faut au moins un mode sélectionné ET au moins une source routée pour un effet audible. b0–3 = VOL, 16 pas linéaires, 0 = muet, 15 (`$F`) = max ; un volume ≠ 0 est obligatoire pour tout son ; utilisable en trémolo dynamique. [SID p.6]
- **Condensateurs** : C1 entre broches 1–2 (CAP1A/B), C2 entre 3–4 (CAP2A/B), valeurs identiques ; 2200 pF pour la plage audio ; polystyrène de préférence, appairés en multi-SID. Coupure maximale : `FCmax = 2,6·10⁻⁵ / C` ; la plage s'étend ~9 octaves sous ce maximum. Des C plus gros privilégient les basses (applications à coût réduit). [SID p.7]

### 1.7 Registres en lecture (`$19`–`$1C`)

- **POTX `$19` / POTY `$1A`** : position du potentiomètre (0 à résistance min → 255/`$FF` à résistance max), **toujours valide, rafraîchie toutes les 512 périodes ø2**. [SID p.6]
- **OSC3/RANDOM `$1B`** : les 8 bits de poids fort de l'oscillateur 3, **jamais affecté par l'enveloppe**. Dent de scie → rampe 0→255 ; triangle → 0→255→0 ; pulse → saute entre 0 et 255 ; **noise → suite de nombres aléatoires** (générateur pour les jeux). Usage principal : générateur de modulation ajouté par logiciel aux registres de fréquence, de coupure ou de PW — sirène (scie→fréquence), sample & hold (noise→coupure filtre), vibrato (Osc3 ≈ 7 Hz, triangle mis à l'échelle→fréquence). Pendant ce temps, couper la voix 3 (3 OFF = 1 ; l'OCR imprime « 8 OFF = 4 »). [SID p.6–7]
- **ENV3 `$1C`** : sortie du générateur d'enveloppe de la voix 3 ; **doit être « gaté » pour produire une sortie**. Ajouté à la coupure du filtre → enveloppes harmoniques, wah-wah ; ajouté à une fréquence d'oscillateur → sons « phaser ». [SID p.7]

### 1.8 Broches essentielles

[SID p.7–8]
- **CAP1A/1B (1, 2), CAP2A/2B (3, 4)** : condensateurs du filtre (§1.6).
- **RES (5)** : reset actif bas ; maintenu bas **au moins dix cycles ø2** → tous les registres à zéro, sortie audio coupée.
- **ø2 (6)** : horloge maître (nominal 1,0 MHz) ; toutes les fréquences et taux d'enveloppe y sont référencés ; les transferts de données n'ont lieu que ø2 haut (agit comme chip select actif haut).
- **R/W (7), CS (8)** : lecture si CS bas + ø2 haut + R/W haut ; écriture si CS bas + ø2 haut + R/W bas.
- **A0–A4** (broches 9–13 — ligne OCR mutilée) : sélection d'un des 29 registres ; les 3 adresses restantes : écriture ignorée, lecture invalide.
- **GND (14)** : masse séparée des autres circuits numériques pour minimiser le bruit.
- **D0–D7 (15–22)** : bus bidirectionnel TTL, 2 charges TTL en sortie ; haute impédance hors lecture.
- **POTY (23), POTX (24)** : conversion A/N par constante de temps `R·C = 4,7·10⁻⁴` (R = résistance max du pot, C condensateur du pin vers la masse ; pot vers +5 V). Recommandé : **470 kΩ et 1000 pF** ; C plus gros = moins de gigue. Un pot + un condensateur par broche. (La p.6 imprime « POTY (pin 29) » — OCR douteux, la p.7 donne bien 24/23.)
- **Vcc (25)** : +5 V (ligne dédiée + condensateur de découplage).
- **EXT IN (26)** : entrée audio analogique, impédance ~100 kΩ ; le signal doit reposer sur 6 V DC et ne pas dépasser 3 V crête-à-crête ; couplage AC par électrolytique 1–10 µF. Chemin direct (FILTEX = 0) à gain unité → chaînage de plusieurs SID ; le volume maître affecte aussi les entrées externes.
- **AUDIO OUT (27)** : tampon « open-source » ; max ~3 V crête-à-crête sur niveau DC 6 V ; **résistance de source vers la masse obligatoire** (1 kΩ recommandé) ; couplage AC 1–10 µF vers l'ampli.
- **Vdd (28)** : +12 V (ligne dédiée + découplage).

**Valeurs limites absolues** [SID p.8] : Vdd −0,3…+17 V ; Vcc −0,3…+7 V ; entrée analogique −0,3…+17 V ; entrée numérique −0,3…+7 V ; fonctionnement 0…+70 °C ; stockage −55…+150 °C. Les colonnes chiffrées des caractéristiques électriques (p.8) et des chronogrammes lecture/écriture (p.9) **n'ont pas survécu à l'OCR** — seuls les intitulés (Tacc, Twh, etc.) sont lisibles ; ne pas citer de valeurs.

### 1.9 Annexe A — gamme tempérée complète (ø2 = 1,0 MHz, La4 = 440 Hz)

Fn = valeur 16 bits des registres de fréquence. † = colonnes décimal/hex incohérentes dans l'OCR. ⚠️ Pour ces lignes, la colonne hex n'est **pas fiable telle quelle** (certaines cellules reproduisent l'impression OCR, d'autres une reconstruction) : se fier au **décimal**, consulter le « détail des † » en fin de table et, au moindre doute, recalculer depuis la fréquence (Fn = Hz ÷ 0,0596). [SID p.10]

| # | Note | Hz | Fn déc | Fn hex | # | Note | Hz | Fn déc | Fn hex |
|---|---|---|---|---|---|---|---|---|---|
| 0 | C0 | 16,35 | 274 | `$0112` | 48 | C4 | 261,63 | 4389 | `$1125` |
| 1 | C0# | 17,32 | 291 | `$0123` | 49 | C4# | 277,18 | 4650 | `$122A` |
| 2 | D0 | 18,35 | 308 | `$0134` | 50 | D4 | 293,66 | 4927 | `$133F` |
| 3 | D0# | 19,44 | 326 | `$0146` | 51 | D4# | 311,13 | 5220 | `$1464` |
| 4 | E0 | 20,60 | 346 | `$015A` | 52 | E4 | 329,63 | 5530 | `$159A` |
| 5 | F0 | 21,83 | 366 | `$016E` | 53 | F4 | 349,23 | 5859 | `$16E3` |
| 6 | F0# | 23,12 | 388 | `$0184` | 54 | F4# | 370,00 | 6207 | `$183F` |
| 7 | G0 | 24,50 | 414† | `$018B`† | 55 | G4 | 392,00 | 6577 | `$19B1`† |
| 8 | G0# | 25,96 | 435 | `$01B3` | 56 | G4# | 415,30 | 6968 | `$1B38` |
| 9 | A0 | 27,50 | 461 | `$01CD` | 57 | A4 | 440,00 | 7382 | `$1CD6` |
| 10 | A0# | 29,14 | 489 | `$01E9` | 58 | A4# | 466,16 | 7821 | `$1E8D`† |
| 11 | B0 | 30,87 | 518 | `$0206` | 59 | B4 | 493,88 | 8286 | `$205E` |
| 12 | C1 | 32,70 | 549 | `$0225` | 60 | C5 | 523,25 | 8779 | `$224B` |
| 13 | C1# | 34,65 | 581 | `$0245` | 61 | C5# | 554,37 | 9301 | `$2455` |
| 14 | D1 | 36,71 | 616 | `$0268` | 62 | D5 | 587,33 | 9854 | `$267E` |
| 15 | D1# | 38,89 | 652 | `$028C` | 63 | D5# | 622,25 | 10440 | `$28C8` |
| 16 | E1 | 41,20 | 691 | `$02B3` | 64 | E5 | 659,25 | 11060 | `$2B34` |
| 17 | F1 | 43,65 | 732 | `$02DC` | 65 | F5 | 698,46 | 11718 | `$2DC6` |
| 18 | F1# | 46,25 | 776 | `$0308` | 66 | F5# | 740,00 | 12415 | `$307F` |
| 19 | G1 | 49,00 | 822 | `$0336` | 67 | G5 | 783,99 | 13153 | `$3361` |
| 20 | G1# | 51,91 | 871 | `$0367` | 68 | G5# | 830,61 | 13935 | `$366F` |
| 21 | A1 | 55,00 | 923 | `$039B` | 69 | A5 | 880,00 | 14764 | `$39AC` |
| 22 | A1# | 58,27 | 978 | `$03D2` | 70 | A5# | 932,33 | 15642 | `$3D1A` |
| 23 | B1 | 61,74 | 1036 | `$040C` | 71 | B5 | 987,77 | 16572 | `$40BC` |
| 24 | C2 | 65,41 | 1097 | `$0449` | 72 | C6 | 1046,50 | 17557 | `$4495` |
| 25 | C2# | 69,30 | 1163 | `$048B` | 73 | C6# | 1108,73 | 18601 | `$48A9` |
| 26 | D2 | 73,42 | 1232 | `$04D0` | 74 | D6 | 1174,66 | 19709 | `$4CFC`† |
| 27 | D2# | 77,18† | 1305 | `$0519` | 75 | D6# | 1244,51 | 20897 | `$518F`† |
| 28 | E2 | 82,41 | 1383 | `$0567` | 76 | E6 | 1318,51 | 22121 | `$5669` |
| 29 | F2 | 87,31 | 1465 | `$05B9` | 77 | F6 | 1396,91 | 23436 | `$5B8C` |
| 30 | F2# | 92,50 | 1552 | `$0610` | 78 | F6# | 1479,98 | 24830 | `$60FE` |
| 31 | G2 | 98,00 | 1644 | `$066C` | 79 | G6 | 1567,98 | 26306 | `$66C2`† |
| 32 | G2# | 103,83† | 1742 | `$06CE` | 80 | G6# | 1661,22 | 27871 | `$6CDF` |
| 33 | A2 | 110,00 | 1845 | `$0735` | 81 | A6 | 1760,00 | 29528 | `$7358` |
| 34 | A2# | 116,54 | 1955 | `$07A3` | 82 | A6# | 1864,65 | 31234† | `$7A34`† |
| 35 | B2 | 123,47 | 2071 | `$0817` | 83 | B6 | 1975,53 | 33144 | `$8178` |
| 36 | C3 | 130,81 | 2195 | `$0893` | 84 | C7 | 2093,00 | 35115 | `$892B` |
| 37 | C3# | 138,59 | 2325 | `$0915` | 85 | C7# | 2217,46 | 37203 | `$9153` |
| 38 | D3 | 146,83 | 2463 | `$099F` | 86 | D7 | 2349,32 | 39415 | `$99F7` |
| 39 | D3# | 155,56 | 2610 | `$0A32` | 87 | D7# | 2489,01 | 41759 | `$A31F` |
| 40 | E3 | 164,81 | 2765 | `$0ACD` | 88 | E7 | 2637,02 | 44242 | `$ACD2` |
| 41 | F3 | 174,61 | 2930 | `$0B72` | 89 | F7 | 2793,83 | 46873 | `$B719` |
| 42 | F3# | 185,00 | 3104 | `$0C20` | 90 | F7# | 2959,95 | 49660 | `$C1FC` |
| 43 | G3 | 196,00 | 3288 | `$0CD8`† | 91 | G7 | 3135,96 | 52613 | `$CD85`† |
| 44 | G3# | 207,65 | 3484 | `$0D9C` | 92 | G7# | 3322,44 | 55741 | `$D9BD`† |
| 45 | A3 | 220,00 | 3691 | `$0E6B` | 93 | A7 | 3520,00 | 59056 | `$E6B0` |
| 46 | A3# | 233,08 | 3910 | `$0F46` | 94 | A7# | 3729,31 | 62567 | `$F467` |
| 47 | B3 | 246,94 | 4143 | `$102F` | 95 | B7 | 3951,06 | \*66288 | \*`$102F0`† |

Détail des † : #7 déc/hex incohérents tels qu'imprimés (414 ≠ `$018B`) ; #27 « 77,18 » probablement 77,78 (D2#) ; #32 OCR « 403,83 » ; #43/55/58/74/79/91 hex OCR (« 0C08 », « 1981 », « 1E80 », « 4CFC », « 6602 », « CO85 ») incohérent avec le décimal ; #75 20897 = `$51A1` ≠ OCR `$518F` ; #82 déc. probable 31284 (= `$7A34` = 2×15642) ; #92 hex illisible (« 0980 ») ; #95 hex OCR « 1F2FO ». B7 (astérisque) **dépasse 16 bits** : hors plage des oscillateurs, mais à garder dans la table pour le calcul (le MSB exige un cas logiciel spécial, p. ex. génération dans la retenue avant décalage). Astuce mémoire [SID p.10-11] : ne stocker que les 12 notes de l'octave 8 (24 octets au lieu de 192) et diviser par 2 (décalage à droite) par octave d'écart ; encodage 1 octet = quartet bas (semitone 0–11) + quartet haut (nombre de décalages).

### 1.10 Notes d'utilisation

Usage type d'une voix : régler fréquence, effets (SYNC, RING MOD), taux d'enveloppe, puis positionner GATE quand le son est voulu ; maintien libre, fin par GATE = 0. Les voix peuvent jouer à l'unisson (léger désaccord = son riche et animé). [SID p.5]

---

## 2. CIA 6526 — le modèle logiciel de Wolfgang Lorenz

### 2.1 Portée du modèle — à savoir avant de citer

Le document décrit le fonctionnement **interne** du 6526 du point de vue d'un développeur d'émulateur, validé par des programmes de la C64 Emulator Test Suite. **TOD (horloge temps réel) et SDR (registre série) n'y sont PAS implémentés** (« haven't been implemented yet ») ; les ports d'E/S généraux A/B et leurs DDR ne sont pas traités non plus — seule la sortie timer sur PB6/PB7 est modélisée. Ce chapitre ne peut donc rien affirmer de sourcé sur TOD, SDR, PRA/PRB/DDRA/DDRB au-delà de ce qui suit. Seule mention du SDR : la sortie du flip-flop toggle « peut aussi servir au SDR — pas encore étudié ». [Lorenz §intro, §Fig.4]

### 2.2 Sources d'horloge des timers

- **Timer A** : compte soit les horloges système ø2, soit les fronts montants de la ligne CNT ; sélection par **bit 5 du Control Register A (CRA, offset `$0E`)** — masque `0x20` : `0x00` = ø2, `0x20` = CNT. En mode ø2, l'entrée vaut toujours 1 → décrément à chaque cycle. En mode CNT, le front est **synchronisé sur ø2 par un pipeline** : le front met à 1 le bit CountA0 de `dwDelay` ; à chaque cycle, `dwDelay` est décalé à gauche (rempli depuis `dwFeed`) ; le 1 traverse jusqu'à CountA3, qui décrémente alors le compteur. [Lorenz §Fig.1]
- **Timer B** : idem, plus le mode **cascadé** (compte les débordements du timer A) ; sélection par **bits 6–5 du CRB (offset `$0F`)** — masque `0x60` : `0x00` = ø2, `0x20` = CNT, `0x40` = débordements TA, `0x60` = TA **ET** CNT. [Lorenz §Fig.2]
- **CNT est haut par défaut** (testé en cascade avec CRB = `$61`). [Lorenz §CNTDEF]

### 2.3 Compteur, latch, démarrage, rechargement (subtilités de timing)

Chaque timer = compteur 16 bits + latch 16 bits. [Lorenz §Fig.3]
- **Démarrage** : le timer commence à compter **deux horloges après** l'écriture de 1 dans le bit 0 (start, `0x01`) du CRA.
- **Débordement** : arrivé à zéro, le compteur est rechargé depuis le latch **dès qu'une horloge attend dans le pipeline** — toujours vrai en mode ø2. D'où : **on ne lit jamais 0 en mode ø2** (séquence lue : 2-1-2), mais on lit des 0 en mode cascadé (2-2-2-1-1-1-0-0-2).
- **Rechargement** (par débordement ou par force load, bit 4 `0x10` du CRA) : **l'horloge suivante est retirée du pipeline** → en mode ø2 on lit deux fois la valeur rechargée (2-1-2-**2**-1-2).
- **Écriture du latch** [Lorenz §LOADTH] : écrire l'octet **haut** charge le compteur **seulement si le timer est arrêté** ; timer en marche → pas de chargement ; écrire l'octet **bas** ne charge jamais (arrêté ou non).
- **Commutation ø2↔CNT** : la bascule de source n'est reconnue qu'après un **délai de deux horloges**. [Lorenz §CNTO2]

### 2.4 Mode one-shot

Bit 3 (`0x08`) du CRx. Si, au débordement, le bit one-shot est à 1 **ou l'était à l'horloge précédente**, le bit start (b0) est effacé ; comme CountA2 a déjà été vidé par le débordement, le timer s'arrête immédiatement. [Lorenz l.60–63]
Cas limites mesurés (débordement à t) :
- **Basculer one-shot** [Lorenz §FLIPOS] : la mise à 1 prend effet dès t−1, la mise à 0 dès t−2 :

| instant d'écriture | set → | clear → |
|---|---|---|
| t−2 | stop | count |
| t−1 | stop | stop |
| t | count | stop |

- **Lecture du CRA autour du débordement** [Lorenz §ONESHOT] : à t−1 on lit `$09` (start encore 1), à t on lit `$08` (start déjà effacé).

### 2.5 Sortie timer sur PB6 (A) / PB7 (B)

- Activation par **bit 1** (`0x02`) du CRx (timer vs port). Sortie normale = **impulsion haute d'une horloge ø2** au débordement. Mode **toggle** : PBx bascule à chaque débordement — le texte de Lorenz imprime « bit 3 », mais sa propre figure 4 et ses programmes de test utilisent le **bit 2 (`0x04`)** (le bit 3 étant one-shot) : contradiction interne du document, la figure et les tests font foi. [Lorenz §Fig.4, §CIA1PB6-CIA2PB7]
- **Flip-flop toggle** : mis à 1 par un **front montant du bit start** (b0) du CRx, remis à zéro par le reset système. Résultats des tests [Lorenz §CIA1PB6-CIA2PB7] : le bit PBx résultant vaut 0 si le nouveau PBxToggle = 0, 1 si = 1, indéterminé si PBxOut = 0 ; **les anciennes valeurs, Start et Force Load n'influencent pas ce résultat**. PBx passe à 0 au premier débordement ; ni écrire CRx (hors bit 0) ni écrire Timer Hi/Lo ne le remet à 1 — **la seule source capable de remettre la ligne toggle à 1 est un front montant du bit start**. La ligne toggle est indépendante des bits PBxOut/PBxToggle (les changer n'empêche pas la bascule au débordement).

### 2.6 Interruptions : ICR/IMR — la lecture qui acquitte

[Lorenz §Fig.5, §ICR01, §IMR]
- Un débordement met à 1 le bit correspondant de l'**ICR** (`0x01` = TA, `0x02` = TB ; `0x80` = drapeau IR).
- Si le bit correspondant de l'**IMR** (masque) est aussi à 1, le CIA lève l'interruption **avec un retard d'une horloge ø2**.
- **L'interruption peut être empêchée en lisant l'ICR au moment exact du débordement.** Mesure [§ICR01] (débordement à t, CIA 2 → NMI) :

| lecture à | valeur ICR lue | NMI exécutée ? |
|---|---|---|
| t−1 | `$00` | oui |
| t | `$01` | **non** |
| t+1 | `$81` | oui |

- Une fois le flip-flop d'interruption armé, **modifier l'IMR est sans effet** : si une condition est vraie dans l'ICR, mettre à 1 le bit d'IMR correspondant déclenche aussi l'interruption ; effacer le bit d'IMR **ne l'efface pas**. **Seule la lecture de l'ICR l'efface** (et efface l'ICR, y compris le bit `$80`).

### 2.7 Cas limites chiffrés (programmes de test)

- **Écriture de CRB, cycles 1–3 après le `STA $DD0F`** [Lorenz §CIA1TB123/CIA2TB123] (mesuré en exécutant le STA en `$DD03` pour lire `$DD06` au cycle suivant ; #1 puis #2 = valeurs écrites dans `$DD0F`) :

| #1 | #2 | cycle 1 | cycle 2 | cycle 3 | (4) |
|---|---|---|---|---|---|
| 00 | 01 | keep | keep | count | count |
| 00 | 10 | keep | load | keep | keep |
| 00 | 11 | keep | load | keep | count |
| 01 | 11 | count | load | keep | count |
| 01 | 10 | count | load | keep | keep |
| 01 | 00 | count | count | keep | keep |

- **Mode cascadé complet** [Lorenz §CIA1TAB] : latches A et B à 2, TA sur ø2, TB sur débordements de TA, PB6 = impulsion TA, PB7 = toggle TB, IMR = `$02`. Séquence cycle par cycle attendue (toute divergence = échec du test) :

```
TA  01 02 02 01 02 02 01 02 02 01 02 02
TB  02 02 02 01 01 01 00 00 02 02 02 02
PB  80 C0 80 80 C0 80 80 C0 00 00 40 00
ICR 00 01 01 01 01 01 01 01 03 83 83 83
```

---

### Renvois croisés Arena64

Pour le jeu : GATE/ADSR et le volume `$D418` pilotent les effets (tirs, impacts) ; OSC3 noise (`$D41B`) est le générateur aléatoire matériel gratuit ; côté CIA, retenir surtout que **lire l'ICR acquitte tout** (un `LDA $DC0D` mal placé peut avaler une IRQ, et une lecture au cycle du débordement la supprime), que le start d'un timer a 2 cycles de latence, et que l'octet haut du latch ne recharge le compteur que timer arrêté. Rappel : sur le C64 Ultimate au turbo, toute valeur de timing dérivée du 1 MHz nominal est à re-mesurer sur le vrai matériel.

---

# Chapitre 5 — Le REU : DMA `$DF00`


Sources : `docs/REU-programming.txt` (texte de Richard Hable, zimmers.net `programming.reu`, base du `reu_xfer` d'Arena64) → ancre **[REU-prog]** ; `docs/REU-registers.txt` (zimmers.net `reu.registers`) → ancre **[REU-reg]** ; `docs/U64-firmware-memmap.txt` → ancre **[memmap]**.

## 5.1 Vue d'ensemble

Les REU Commodore (1700 = 128 Ko, 1764 = 256 Ko, 1750 = 512 Ko, extensibles à plusieurs Mo) fournissent de la RAM externe **non adressable directement** par le 6510 : le contrôleur intégré REC (*RAM Expansion Controller*) transfère les blocs entre la RAM C64 et la RAM d'expansion par DMA. Ses registres apparaissent mappés en I/O entre **`$DF00` et `$DF0A`** quand une REU est branchée sur le port d'expansion, et se lisent/écrivent comme des registres VIC ou SID. [REU-prog]

## 5.2 Table des registres `$DF00`–`$DF0A` (verbatim, [REU-reg])

```
Address	Bits	Function
0		Status register - read only
	7	Interrupt Pending (1=interrupt waiting to be serviced)
	6	End of Block (1=transfer complete)
	5	Fault (1=block verify error)
	4	Size (1=256 kB)
	3-0	Version number
	Note: Bits 7-5 are cleared when this register is read.

Other registers are R/W:

1		Command Register
	7	Execute (1=initiate transfer per current config)
	6	reserved (left 1 in an example program in the manual)
	5	Load (1=enable AUTOLOAD option)
	4	FF00 (1=disable FF00 decode)
	3-2	reserved (left 1)
	1-0	Transfer type:	00=C64->REU
				01=REU->C64
				10=swap
				11=verify

2	7-0	C64 start address (LSB)
3	7-0	C64 start address (MSB)
(address overflow is not detected; it will continue from $0000)
4	7-0	REU start address (LSB)
5	7-0	REU start address (More SB)
6	2-0	REU start address (most significant bits)

7	7-0	Transfer length (LSB) ($0000=64 kB)
8	7-0	Transfer length (MSB)

9		Interrupt Mask Register
	7	Interrupt enable (1=interrupts enabled)
	6	End of Block mask (1=interrupt on end of block)
	5	Verify error (1=interrupt on verify error)
	4-0	unused (left 0 in an example program)

A	7-6	Address Control Register
		00=increment both addresses
		01=fix expansion address
		10=fix C64 address
		11=fix both addresses
```

Précisions croisées [REU-prog] : dans `$DF00`, le bit 5 FAULT est posé si une différence C64/REU est trouvée pendant un *compare* ; le bit 4 SIZE est posé sur 1764/1750, effacé sur 1700 ; bits 3..0 = version (0 sur la REU de l'auteur). `$DF04`..`$DF06` = adresse REU sur trois octets (lo, hi, banque) ; normalement seuls les **bits 2..0 de la banque** sont valides (max 512 Ko), les autres bits lisent toujours 1. Labels d'assembleur suggérés : `status=$DF00, command=$DF01, c64base=$DF02, reubase=$DF04, translen=$DF07, irqmask=$DF09, control=$DF0A`.

## 5.3 Les quatre commandes (bits 1..0 de `$DF01`)

- **%00 stash (C64 → REU)** et **%01 fetch (REU → C64)** : poser les adresses de base, la longueur, puis écrire le registre de commande. Exemple canonique [REU-prog] : `lda #%10010000 / sta command` = C64→REU avec exécution immédiate ; `#%10010001` pour le retour REU→C64.
- **%10 swap (C64 ↔ REU)** : échange les deux zones ; même programmation que le transfert simple. **Deux fois plus lent** qu'un stash/fetch (deux accès mémoire C64 par octet, lecture + écriture). Sert à simuler du bank switching (ex. RAMDOS : 256 octets résidents, driver de 6 Ko swappé à la demande). [REU-prog]
- **%11 verify (compare)** : rien n'est transféré ; les octets sont comparés et le bit FAULT (`$DF00` bit 5) est posé à la première différence. **Lire `$DF00` avant de comparer** pour effacer un FAULT résiduel et obtenir une info valide. La comparaison s'arrête à la première différence trouvée ; le REC stoppe le DMA et les registres d'adresses + banque pointent alors **une position au-dessus** de l'adresse fautive — sauf si AUTOLOAD est activé, auquel cas cette adresse d'erreur est **perdue**. [REU-prog][REU-reg]

**Exécution immédiate vs `$FF00`** (`$DF01` bit 4) : bit 4 à 1 = la commande part **dès l'écriture** dans `$DF01` ; bit 4 à 0 = l'exécution est différée jusqu'à une **écriture quelconque à `$FF00`**. L'intérêt : la RAM C64 est vue par le REC dans la configuration mémoire **au moment de l'écriture du registre de commande** — or il faut l'I/O active pour écrire `$DF01`. Pour transférer la RAM sous `$D000`–`$DFFF` ou la ROM caractères, on arme la commande avec FF00=0, on bascule `$01` sur RAM 64 Ko, puis `lda $FF00 / sta $FF00` (relire d'abord pour ne pas altérer le contenu de `$FF00`) déclenche le DMA, avant de restaurer `$01`. [REU-prog] L'option FF00 est **auto-effacée à chaque usage**. [REU-reg]

**Autoload** (`$DF01` bit 5) : à 1, les registres d'adresse C64, d'adresse REU (banque incluse) et le compteur d'octets sont **rechargés automatiquement** en fin de transfert — utile pour répéter l'opération sur le même bloc. À 0 (fonctionnement normal), les deux pointeurs finissent sur **la première position hors de la plage transférée** (dernier octet + 1, banque comprise, sauf pointeur fixé), et le compteur d'octets **décrémente jusqu'à 1** (pas 0) : attention en testant la « fin de transfert » par le compteur, car une longueur de **0 = 64 Ko pleins**. [REU-prog][REU-reg]

**Adresses : wrap et fixation.** Longueur `$0000` = 64 Ko. Si C64 base + longueur dépasse 64 Ko, l'adresse C64 **wrappe et repart de `$0000`** (overflow non détecté) ; si REU base + longueur dépasse 512 Ko, l'adresse REU wrappe à 0. Le wrap se produit **dans tous les modes**. La « banque » `$DF06` est en réalité la partie haute de l'adresse : elle **s'incrémente** au franchissement d'une frontière de 64 Ko (2^19 = 0,5 Mo max sur silicium d'origine ; les bits hauts inutilisés permettraient 2^24 = 16 Mo à un clone — c'est exactement le cas de la REU 16 Mo de l'U64). `$DF0A` fige au choix l'adresse C64 (bit 7) et/ou REU (bit 6) : une adresse fixée fait porter tout le DMA sur **le même octet**. Applications citées : REU fixée = remplissage ultra-rapide d'une zone C64 avec un octet (ou détection de fin de zone d'octets égaux pour la compression) ; C64 fixée = sortie rapide vers un port I/O, « magic byte » VIC pour du bitmap dans les bordures, échantillonnage ~1 MHz. [REU-prog][REU-reg]

**IRQ (`$DF09`)** : bit 7 valide les interruptions, bit 6 = IRQ en fin de bloc, bit 5 = IRQ sur erreur de verify. Les deux docs concordent : c'est **inutile en pratique**, car le CPU est gelé pendant le DMA — le transfert est toujours terminé dès l'instruction suivant le `sta command` (ou le store à `$FF00`) ; l'IRQ tomberait juste après. Pas besoin non plus de scruter END OF BLOCK. [REU-prog][REU-reg]

**Vitesse** : CPU halté, 1 octet par cycle d'horloge (985 248/s en PAL) écran et sprites coupés ; un peu moins écran allumé (cycles volés par le VIC). Compare = même vitesse (arrêt à la première différence) ; swap = moitié. Copie C64→C64 via la REU (aller-retour, méthode GEOS) ≈ 5× plus rapide qu'une copie en langage machine. Le code en RAM externe ne s'exécute pas sur place : toujours le recopier (ou le swapper) en RAM C64. [REU-prog]

## 5.4 Pièges de programmation recensés dans les docs

1. **Lire `$DF00` efface les bits 7-5** (Interrupt Pending, End of Block, Fault) — lecture destructive. Corollaire : lire le statut **avant** un verify, et, si IRQ utilisées, lire `$DF00` au moins une fois **entre deux transferts** successifs. [REU-reg]
2. **Longueur 0 = 64 Ko**, pas « rien ». [REU-prog][REU-reg]
3. **Wrap silencieux** des adresses C64 (à 64 Ko) et REU (à 512 Ko), non détecté, dans tous les modes. [REU-prog][REU-reg]
4. **Compteur final = 1** (pas 0) en fin de transfert normal — prudence si on teste le compteur. [REU-reg]
5. **AUTOLOAD + verify = adresse d'erreur perdue** (les pointeurs sont rechargés au lieu de pointer après l'octet fautif). [REU-reg]
6. **Configuration mémoire figée à l'armement** : le DMA voit la carte mémoire du moment de l'écriture de `$DF01` ; passer par le déclenchement `$FF00` (avec `lda $FF00` avant `sta $FF00` pour préserver l'octet, et sous `sei`) pour atteindre la RAM sous I/O/ROM. [REU-prog]
7. **Bits réservés incohérents entre sources** : `$DF01` bits 6 et 3-2 « normalement 0 » selon [REU-prog], « laissés à 1 dans un exemple du manuel » selon [REU-reg] ; `$DF09` bits 4-0 « normalement tous à 1 » [REU-prog] vs « laissés à 0 » [REU-reg]. Les bits hauts de `$DF06` lisent toujours 1 sur une vraie REU ≤ 512 Ko.
8. **Détection de la REU** : écrire 1,2,3… dans `$DF02`..`$DF08` et relire (si ça ne reste pas → pas de REU, mais un autre module peut répondre à ces adresses) ; le bit SIZE ne dit que « ≥ 2 ou ≥ 4 banques », la taille réelle se sonde banque par banque en écriture+verify. [REU-prog]

## 5.5 Memmap firmware Ultimate-II/U64 en bref [memmap]

Côté firmware (adresses **internes** au SoC, pas côté C64) : 32 Mo de RAM à `00000000-01FFFFFF` (U2 ; le double sur U2+/U64 avec `02000000-03FFFFFF`), I/O à `04000000` (bloc commun `ultimate_logic_32`) et `A0000000` (spécifique U2+/U64). Ce qui est utile à Arena64 :

- **`01000000-01FFFFFF` = 16 Mo « REU / GeoRAM space »** : la REU émulée est un bloc dédié de 16 Mo dans la RAM du firmware — cohérent avec la remarque de [REU-reg] sur les clones adressant 2^24 octets, et avec la REU 16 Mo configurée pour le projet.
- **`02000000-02FFFFFF` = 16 Mo « RAM Disk (/temp) »** (U2+/U64) : le RAM-disk `/Temp` où s'accumulent les `tempNNNN` de chaque upload est un bloc fixe de 16 Mo — d'où sa saturation possible.
- Autour : `~14,6 Mo` d'espace application (code/tas/pile du firmware), espaces Kernal de remplacement, échantillons son et CPU des drives A/B, `00EF0000` = 64 Ko RAM cartouche, `00F00000` = 1 Mo ROM cartouche, `03000000` réservé au chargement de l'updater ; sur U64 seul, `08000000-0BFFFFFF` = 64 Mo réservés non implémentés. Sur U2 (sans le bloc dédié), le RAM Disk est pris sur le tas de l'application et limité à 3 Mo.

---

# Chapitre 6 — L'Ultimate 64 : services (REST, streams, turbo, UCI)

## Ultimate 64 : services (REST, flux de données, turbo, UCI)

Ce chapitre synthétise la documentation de référence embarquée dans `docs/` du projet. Ces textes décrivent le firmware Ultimate « amont » (Gideon) ; sur la machine réelle du projet (Commodore 64 Ultimate, fork réduit), chaque service doit être vérifié sur le matériel avant usage.

**Fichiers sources** (dans `/home/zam/Programmation/c64/Arena64/docs/`) : `U64-REST-api_calls.rst`, `U64-data-streams.rst`, `U64-turbo-mode.rst`, `U64-machine.rst`, `U64-UCI-architecture.rst`, `U64-UCI-dos-target.rst`, `U64-UCI-control-target.rst`.

---

## 1. Organisation de la documentation [U64-machine.rst]

`U64-machine.rst` est la page d'accueil (table des matières) de la doc Ultimate-64 : Getting Started, Power Button, User Interface, Configuration, Hardware, **Data Streams**, SID player, How-to. L'application qui gère l'Ultimate-64 est en essence la même que celle de la cartouche Ultimate-II+ (mêmes fonctions).

---

## 2. API REST [U64-REST-api_calls.rst]

Disponible à partir du firmware **3.11**. Format d'URL :

```
/v1/<route>/<path>:<command>?<arguments>
```

Verbes : **GET** = lecture sans changement d'état ; **PUT** = action avec informations dans l'URL (ou fichier référencé par l'URL) ; **POST** = action avec données attachées à la requête. La plupart des réponses sont en JSON (`Content-Type: application/json`) et contiennent toujours au moins le tableau `errors` (liste des erreurs, vide si succès).

**Mot de passe réseau** (firmware ≥ 3.12) : si un « Network Password » est configuré, toute requête doit inclure l'en-tête HTTP `X-Password: <mot-de-passe>` ; sinon `403 Forbidden`. L'en-tête est ignoré si aucun mot de passe n'est défini.

### 2.1 About

| Route | Params | Action / Réponse |
|---|---|---|
| `GET /v1/version` | — | Version de l'API REST : `{"version": "0.1", "errors": []}` |
| `GET /v1/info` | — | Infos machine : `product`, `firmware_version`, `fpga_version`, `core_version` (U64 uniquement), `hostname`, `unique_id` (sauf si désactivé dans Network Settings) |

### 2.2 Runners

| Route | Params | Action |
|---|---|---|
| `PUT /v1/runners:sidplay` | `file`, `[songnr]` | Joue un fichier SID présent sur le FS de l'Ultimate (chanson par défaut sauf `songnr`) ; cherche les durées dans le sous-dossier `SONGLENGTHS` |
| `POST /v1/runners:sidplay` | `[songnr]` | Joue le SID attaché à la requête ; 2ᵉ pièce jointe optionnelle = durées |
| `PUT /v1/runners:modplay` | `file` | Joue un MOD Amiga présent sur le FS |
| `POST /v1/runners:modplay` | — | Joue le MOD attaché |
| `PUT /v1/runners:load_prg` | `file` | Reset machine + charge le programme en mémoire par DMA. **Ne lance pas** le programme |
| `POST /v1/runners:load_prg` | — | Idem avec le programme attaché |
| `PUT /v1/runners:run_prg` | `file` | Reset + chargement DMA + **lance** le programme |
| `POST /v1/runners:run_prg` | — | Idem avec le programme attaché *(c'est la route utilisée par `make fli-run`)* |
| `PUT /v1/runners:run_crt` | `file` | Reset avec la cartouche indiquée active ; ne modifie pas la configuration |
| `POST /v1/runners:run_crt` | — | Idem avec le fichier `.crt` attaché |

### 2.3 Configuration

| Route | Params | Action |
|---|---|---|
| `GET /v1/configs` | — | Liste toutes les catégories de configuration (Audio Mixer, SID Sockets Configuration, U64 Specific Settings, Clock Settings, Network settings, Data Streams, Drive A/B Settings…) |
| `GET /v1/configs/<category>` | — | Tous les items d'une catégorie ; **jokers autorisés** ; profondeur 1. Ex. `GET /v1/configs/drive%20a*` |
| `GET /v1/configs/<category>/<item>` | — | Détail d'item(s) : `current`, `min`, `max`, `format`, `default`. Jokers autorisés ; profondeur 2 |
| `PUT /v1/configs/<category>/<item>` | `value` | Écrit une valeur. Ex. `PUT /v1/configs/drive%20a*/*bus*?value=9` |
| `POST /v1/configs` | corps JSON | Change plusieurs réglages d'un coup ; JSON à 2 niveaux : catégorie → item → valeur |
| `PUT /v1/configs:load_from_flash` | — | Recharge la configuration sauvée en mémoire non volatile |
| `PUT /v1/configs:save_to_flash` | — | Écrit la configuration courante en flash (chargée au boot) — ⚠️ interdit sur ce projet (bug écran noir, cf. CLAUDE.md) |
| `PUT /v1/configs:reset_to_default` | — | Réglages courants → défauts usine (ne touche pas la flash) — ⚠️ interdit sur ce projet |

### 2.4 Machine

| Route | Params | Action |
|---|---|---|
| `PUT /v1/machine:reset` | — | Reset de la machine, configuration inchangée |
| `PUT /v1/machine:reboot` | — | Redémarre : ré-initialise la configuration cartouche + reset |
| `PUT /v1/machine:pause` | — | Pause : ligne DMA tirée basse à un moment sûr (CPU stoppé, **timers non stoppés**) |
| `PUT /v1/machine:resume` | — | Relâche la ligne DMA, le CPU reprend |
| `PUT /v1/machine:poweroff` | — | **U64 uniquement** : éteint la machine (réponse probablement non reçue) |
| `PUT /v1/machine:menu_button` | — | Équivaut au bouton Menu (cartouche) / appui bref Multi Button (U64) : entre/sort du menu Ultimate |
| `PUT /v1/machine:writemem` | `address`, `data` | Écrit en mémoire C64 par DMA (map mémoire courante ; registres I/O du 6510 inaccessibles). `address` en hexa, `data` = chaîne d'octets hexa, **max 128 octets**. Ex. `?address=D020&data=0504` → `$05` dans `$D020`, `$04` dans `$D021` |
| `POST /v1/machine:writemem` | `address` | Idem avec données en pièce jointe binaire ; ne doit pas déborder `$FFFF` |
| `GET /v1/machine:readmem` | `address`, `[length]` | Lecture DMA sur le bus cartouche, résultat en binaire ; 256 octets par défaut |
| `GET /v1/machine:debugreg` | — | Lit le registre debug **`$D7FF`**, renvoie `value` en hexa (U64 uniquement) |
| `PUT /v1/machine:debugreg` | `value` | Écrit `value` (hexa) dans `$D7FF` puis le relit et renvoie `value` (U64 uniquement) |

### 2.5 Lecteurs de disquette

| Route | Params | Action |
|---|---|---|
| `GET /v1/drives` | — | État de tous les lecteurs IEC internes : `enabled`, `bus_id`, `type`, `rom`, `image_file`, `image_path` ; entrée `softiec` avec `last_error` et `partitions` |
| `PUT /v1/drives/<drive>:mount` | `image`, `[type]`, `[mode]` | Monte une image du FS de l'Ultimate. `type` : **d64**, **g64**, **d71**, **g71**, **d81** (défaut = extension). `mode` : **readwrite**, **readonly**, **unlinked** (écriture autorisée mais non répercutée dans l'image) |
| `POST /v1/drives/<drive>:mount` | `[type]`, `[mode]` | Idem avec l'image en pièce jointe (nom via Content-Deposition *(sic)*) |
| `PUT /v1/drives/<drive>:reset` | — | Reset du lecteur |
| `PUT /v1/drives/<drive>:remove` | — | Retire la disquette montée. *NB : la source liste `:remove` deux fois ; la seconde entrée décrit la rupture du lien image↔lecteur (écritures non répercutées ensuite)* |
| `PUT /v1/drives/<drive>:on` | — | Allume le lecteur (reset s'il était déjà allumé) |
| `PUT /v1/drives/<drive>:off` | — | Éteint le lecteur (disparaît du bus série) |
| `PUT /v1/drives/<drive>:load_rom` | `file` | Charge une ROM lecteur (16 K ou 32 K selon type) depuis le FS ; **temporaire** (perdue au changement de type ou reboot) |
| `POST /v1/drives/<drive>:load_rom` | — | Idem, ROM en pièce jointe |
| `PUT /v1/drives/<drive>:set_mode` | `mode` | Change le mode du lecteur : **1541**, **1571**, **1581** ; recharge la ROM par défaut |

### 2.6 Data Streams (U64 uniquement)

| Route | Params | Action |
|---|---|---|
| `PUT /v1/streams/<stream name>:start` | `ip` | Démarre un flux. Noms valides : **video**, **audio**, **debug**. Ports par défaut : **11000** (video), **11001** (audio), **11002** (debug). Port personnalisé après deux-points : `192.168.178.224:6789`. Démarrer la vidéo **coupe automatiquement** le flux debug |
| `PUT /v1/streams/<stream name>:stop` | — | Arrête le flux (**video**, **audio**, **debug**) |

### 2.7 Manipulation de fichiers (état V3.11 alpha, inachevé)

| Route | Params | Action |
|---|---|---|
| `GET /v1/files/<path>:info` | — | `fstat` du fichier (taille, extension). Jokers supportés. *Unfinished* |
| `PUT /v1/files/<path>:create_d64` | `[tracks]`, `[diskname]` | Crée un .d64 (chemin complet depuis la racine). 35 pistes par défaut, 40 possible ; `diskname` = nom d'en-tête (sinon nom de fichier) |
| `PUT /v1/files/<path>:create_d71` | `[diskname]` | Crée un .d71 (70 pistes fixes) |
| `PUT /v1/files/<path>:create_d81` | `[diskname]` | Crée un .d81 (160 pistes, 80 par face) |
| `PUT /v1/files/<path>:create_dnp` | `tracks`, `[diskname]` | Crée un .dnp ; `tracks` obligatoire, 256 secteurs/piste, max 255 pistes (≈16 Mo) |

---

## 3. Flux de données réseau [U64-data-streams.rst]

L'Ultimate-64 streame des données temps réel sur son port Ethernet, en **UDP** (sans connexion, pas de garantie de livraison). Trois modes d'adressage : **unicast** (une IP), **multicast** (224.0.0.0–239.255.255.255, le récepteur « joint » le groupe via IGMP ; nécessite un switch avec IGMP snooping, sinon comportement broadcast), **broadcast**. En multicast le tri se fait par adresse IP, pas par port UDP : utiliser des IP multicast différentes pour plusieurs flux.

### 3.1 Démarrage / arrêt

Trois moyens :

1. **Menu** : « action menu » (touche **F5**) → options start/stop ; l'IP par défaut vient de l'écran de config « Data Streams » (qui ne démarre rien par lui-même). Destination = IP ou nom DNS, port optionnel après `:` (ex. `192.168.0.119:11000`, `239.0.2.77:64738`).
2. **API REST** : `PUT /v1/streams/<nom>:start?ip=...` / `:stop` (cf. §2.6).
3. **Interface de commande TCP** (socket TCP « 64 ») :
   - Activer un flux : mot de commande **`FF2n`** ; désactiver : **`FF3n`** (`n` = numéro de flux).
   - Structure générique : `<mot de commande, little-endian>` `<longueur des paramètres, little-endian>` `<paramètres>`.
   - Paramètres d'activation (optionnels) : ① durée en ticks système de **5 ms** (0 = infini) ; ② destination (chaîne).
   - Exemples verbatim :
     - Activer le flux 0 pendant 1 s (200 ticks) vers la destination pré-configurée : `20 FF 02 00 00 C8`
     - Activer le flux 0 indéfiniment vers 192.168.0.119 : `20 FF 0F 00 00 00 192.168.0.119` (fin en ASCII ; longueur de commande = longueur de chaîne + 2)
     - Désactiver le flux 0 : `30 FF 00 00` (longueur de paramètres 0)

### 3.2 Flux vidéo VIC (ID 0)

Partie active de la sortie VIC. Chaque datagramme UDP = **en-tête 12 octets** + pixels :

| Champ | Taille | Valeur |
|---|---|---|
| Numéro de séquence | 16 bits LE | incrémental |
| Numéro de trame | 16 bits LE | |
| Numéro de ligne | 16 bits LE | **bit 15 mis = dernier paquet de la trame** |
| Pixels par ligne | 16 bits LE | toujours **384** |
| Lignes par paquet | 8 bits | toujours **4** |
| Bits par pixel | 8 bits | toujours **4** |
| Type d'encodage | 16 bits | toujours **0** (« 1 » réservé pour un futur RLE) |

Exemple de paquet (trame 3, lignes 100–103, début bleu foncé) :

```
A1 00 02 00 64 00 80 01 04 04 00 00 66 66 66 66 66 66 66 ...
seq #|frm #|line#|width|lp|bp|-enc-|data....................
```

Pixels : couleurs VIC 4 bits, **little-endian, nibble 3..0 en premier**. 4 lignes × 384 pixels = 768 octets ; datagramme total = **780 octets**. Pour capturer une trame : attendre un paquet avec bit 15 du numéro de ligne, puis capturer jusqu'au suivant → **68 paquets = 272 lignes**. Vidéo rognée à **384 × 272** (alignée sur les images de référence VICE ; sortie écran réelle 400 × 288 en PAL). En NTSC : flux **384 × 240** (écran 400 × 240).

### 3.3 Flux audio (ID 1)

Pris à la sortie du mixeur audio (identique au HDMI / codec analogique). En-tête = **2 octets** seulement : numéro de séquence. Suivent **192 échantillons stéréo** en **16 bits signé little-endian**, gauche/droite entrelacés, **gauche d'abord**. Paquet UDP total = **770 octets** (2 + 192 × 4) :

```
00 00 fe ff 02 00 ff ff 03 00 fd ff 00 00 ...
-seq- left--right-left--right-left--right-...
```

Fréquence d'échantillonnage ≈ 48 kHz, dépend du mode vidéo :
- **PAL** : (Fc × 16/9 × 15 / 77 / 32) = **47 983 Hz** (Fc = 4 433 618,75 Hz ; −356 ppm vs 48 kHz)
- **NTSC** : (Fc × 16/7 × 15 / 80 / 32) = **47 940 Hz** (Fc = 3 579 545,45 Hz ; −1243 ppm)

### 3.4 Flux debug (ID 2)

Fonction avancée (firmware ≥ 3.7 / V1.28) : trace **temps réel, au cycle près**, des accès bus du 6510, du VIC ou du CPU 1541. Modes : **6510 Only**, **VIC Only**, **6510 & VIC**, **1541 Only**, **6510 & 1541**. Chaque flux ≈ **32 Mbps** : incompatible avec le flux vidéo (port 100 Mbps), et les trois sources ne peuvent pas être combinées.

Paquet : premier mot 32 bits = numéro de séquence 16 bits + 16 bits réservés, puis **360 entrées de 32 bits** → charge utile **1444 octets** :

```
05 16 00 00 xx xx xx xx yy yy yy yy ...
-seq- resvd |- entry 0 -|- entry 1 -|
```

Format d'une entrée 32 bits :

| bit | 31 | 30 | 29 | 28 | 27 | 26 | 25 | 24 | 23..16 | 15..0 |
|---|---|---|---|---|---|---|---|---|---|---|
| **6510 / VIC** | PHI2 | GAME# | EXROM# | BA | IRQ# | ROM# | NMI# | R/W# | Data | Address |
| **1541** | '0' | ATN | DATA | CLOCK | SYNC | BYTE_READY | IRQ# | R/W# | Data | Address |

Les formats 6510 et VIC sont identiques ; la distinction CPU/VIC se fait sur AEC et PHI2 (le bit 31 reflète littéralement PHI2 pendant l'accès). Le flux 1541 inclut ATN/CLOCK/DATA du bus IEC. Outils : `grab_debug.py` (dépôt GideonZ/1541ultimate), `dump_bus_trace.c` → fichier VCD (GtkWave). Visionneuses vidéo : TSB U64 Streamer (Windows), u64view (Linux/Mac), scripts `grab.py` / `grab_audio.py`.

---

## 4. Mode turbo [U64-turbo-mode.rst]

### 4.1 Réglages menu

- **Turbo control** : `Off` (pas de turbo) ; `Manual` (réglages U64, **non** modifiables par registres) ; `U64 Turbo Registers` (modifiables par registres — c'est le mode requis par Arena64) ; `TurboEnable Bit` (modifiables par registres).
- **CPU Speed** : défaut **1 MHz (1×)** ; max **48 MHz (48×)** sur U64, **64 MHz (64×)** sur U64 Elite-II.
- **Badline Timing** : activer/désactiver le timing badline (désactiver = plus de cycles CPU) ; contrôlable par registre.
- **SuperCPU Detect (`$D0BC`)** : registre de détection compatible SuperCPU.

### 4.2 Registres de contrôle turbo

| Adresse | Registre | Détail |
|---|---|---|
| **53297 / `$D031`** | **U64 Turbo Control** | Disponible seulement si Turbo Mode = « U64 Turbo Registers » ou « Turbo Enable Bit », sinon lit `$FF`. **bits 0–3** : index de vitesse CPU ; **bit 7** : timing badline, 0 = activé, 1 = désactivé |
| **53296 / `$D030`** | **Turbo Enable Bit** | Disponible seulement en mode « Turbo Enable Bit », sinon lit `$FF`. **bit 0 en écriture** : 0 = 1 MHz + badlines, 1 = réglages du menu. **bit 0 en lecture** : 0 = turbo off, 1 = turbo on |
| **53370 / `$D07A`** | SuperCPU compatible | Écriture seule ; Software Speed Select – **Normal**. Disponible dans les deux modes registre |
| **53371 / `$D07B`** | SuperCPU compatible | Écriture seule ; Software Speed Select – **Turbo (20 MHz)** (`$079` *(sic)*). Disponible dans les deux modes registre |
| **53436 / `$D0BC`** | SuperCPU Detect | Lecture seule ; activé séparément dans la config |

Table des index de vitesse (`$D031` bits 0–3) :

| Index | U64 | U64E2 | | Index | U64 | U64E2 |
|---|---|---|---|---|---|---|
| 0 | 1 MHz | 1 MHz | | 8 | 12 MHz | 14 MHz |
| 1 | 2 MHz | 2 MHz | | 9 | 14 MHz | 16 MHz |
| 2 | 3 MHz | 3 MHz | | 10 | 16 MHz | 20 MHz |
| 3 | 4 MHz | 4 MHz | | 11 | 20 MHz | 24 MHz |
| 4 | 5 MHz | 6 MHz | | 12 | 24 MHz | 32 MHz |
| 5 | 6 MHz | 8 MHz | | 13 | 32 MHz | 40 MHz |
| 6 | 8 MHz | 10 MHz | | 14 | 40 MHz | 48 MHz |
| 7 | 10 MHz | 12 MHz | | 15 | 48 MHz | 64 MHz |

CPU et mémoire tournent en permanence à 48 MHz (U64) / 64 MHz (U64E2) ; l'index détermine combien de créneaux temporels sont attribués au CPU. Le VIC vole toujours des cycles quand il est actif ; le réglage badline n'affecte **pas** le signal BA du port cartouche (accès externes — dont les sockets SID — restent soumis aux limitations badline).

### 4.3 Badlines en turbo (notes)

Le VIC a toujours priorité, quel que soit le réglage badline (contrairement au C128 en 2 MHz, le VIC affiche correctement en turbo). Sur C64 classique : 2 créneaux par MHz (PHI2=0 pour le VIC, PHI2=1 pour le CPU), et le DMA VIC (sprites + lecture des 40 octets caractère toutes les 8 lignes) bloque le CPU ~43 µs — d'où « bad lines ». Quand le VIC réclame un cycle CPU, **BA** passe bas. Sur U64 : 48 créneaux par MHz (64 sur C64U). Tout accès **interne** peut se faire dans n'importe quel créneau ; un accès au bus externe passe par le pont cartouche, toujours à 1 MHz, et seulement quand BA=1. Le réglage badline fait une seule chose : badlines **activées** = CPU gelé pendant BA=0 (timing compatible C64) ; **désactivées** = le CPU continue pendant BA=0 si l'accès est interne. (S'applique à Ultimate 64 et Elite-II ; certains réglages requièrent firmware ≥ 1.33.)

---

## 5. UCI — Ultimate Command Interface [U64-UCI-architecture.rst]

Interface de commande programmable depuis le C64 vers l'application de gestion Ultimate, via les registres I/O du port cartouche. Les « cibles » (targets) incluent Ultimate DOS, Network, Module Control, SoftIEC Bypass, client HTTP (firmware 3.15).

### 5.1 Registres (`$DF1B`–`$DF1F`, masquent les 5 derniers registres du REU — formulation de la source qui suppose que l'émulation REU du U64 décode des MIROIRS au-delà de `$DF0A` [ch.5] ; non vérifié sur notre fork — ; mapping optionnel, à activer dans le menu « Command Interface »)

| Adresse | Accès | Rôle | Défaut |
|---|---|---|---|
| `$DF1B` | R | SoftwareIEC Bus ID | |
| `$DF1C` | W | Registre de contrôle | |
| `$DF1C` | R | Registre d'état | `$00` |
| `$DF1D` | W | Registre de données de commande | |
| `$DF1D` | R | Registre d'identification | **`$C9`** |
| `$DF1E` | R | Registre de données de réponse | |
| `$DF1F` | R | Registre de données d'état (status) | |

### 5.2 Registre de contrôle (`$DF1C` en écriture)

| Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
|---|---|---|---|---|---|---|---|
| DMA | TRIGGER | IRQ | réservé | CLR_ERR | ABORT | DATA_ACC | PUSH_CMD |

- **PUSH_CMD** : pousse la commande écrite dans `$DF1D` vers le logiciel Ultimate.
- **DATA_ACC** : signale que toutes les données ont été acceptées ; vide et réinitialise les files de réponse/status. Ignoré hors des états de données.
- **ABORT** : lève le drapeau abort (pollé par l'Ultimate, qui ramène la machine d'états à idle).
- **CLR_ERR** : efface le drapeau d'erreur d'état (commande poussée hors idle).
- **IRQ** (≥ V3.15) : active l'interruption de fin de commande ; auto-effacé à la lecture des files ou au DATA_ACC. IRQ actif → l'identification lit **`$49`** au lieu de `$C9` (bit 7 effacé).
- **TRIGGER** : si mis lors du push, l'Ultimate passe en mode DMA dès qu'une écriture sur **`$FF00`** survient ; relâché à la fin de la commande.
- **DMA** : si mis lors du push, mode DMA immédiat ; relâché à la fin de la commande.

### 5.3 Registre d'état (`$DF1C` en lecture)

| Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
|---|---|---|---|---|---|---|---|
| DATA_AV | STAT_AV | STATE | STATE | ERROR | ABORT_P | DATA_ACC | CMD_BUSY |

États (bits 5–4) : **00** = Idle ; **01** = Command Busy ; **10** = Data Last (dernier bloc) ; **11** = Data More (données restantes). `DATA_AV` = données disponibles dans `$DF1E` ; `STAT_AV` = status disponible dans `$DF1F` ; `ERROR` = commande envoyée hors idle ; `ABORT_P` = abort en attente de traitement ; `CMD_BUSY` = commande en attente.

### 5.4 Poignée de main (handshake), octet par octet

1. **État Idle** (bits STATE = 00 dans `$DF1C`) : écrire la commande **octet par octet** dans `$DF1D` (1ᵉʳ octet = numéro de cible).
2. Écrire ‘1’ sur **PUSH_CMD** (`$DF1C`) → transition vers **Command Busy**.
3. L'Ultimate prépare réponse et status, puis passe en **Data Last** ou **Data More**.
4. Lire les données dans **`$DF1E`** et le status dans **`$DF1F`** tant que **DATA_AV** / **STAT_AV** valent ‘1’ (ils passent à ‘0’ quand tout est lu).
5. Écrire ‘1’ sur **DATA_ACC** : si l'état était Data Last → retour **Idle** ; si Data More → retour **Command Busy** (bloc suivant), reprendre à l'étape 3.

Tailles de files (= taille max de transfert par commande) : **commande 896 octets (`$380`)**, **données de réponse 896 octets (`$380`)**, **status 256 octets (`$100`)**. Le premier octet de la commande désigne la cible (dispatcher léger) ; en firmware 2.6, seule cible : « Ultimate-DOS », en **deux instances aux cibles 1 et 2** (deux répertoires/fichiers ouverts simultanément possibles, un par cible).

---

## 6. Cible DOS (targets `$01` / `$02`) [U64-UCI-dos-target.rst]

Accès programmatique au système de fichiers de l'Ultimate. Premier octet de commande = **`$01`** ou **`$02`** (deux instances indépendantes, chacune son état). Exemples ci-dessous sur `$01`. Le status est une chaîne type CBM DOS (`00,OK`, etc.).

| Opcode | Commande | Format | Réponse (données) | Status possibles |
|---|---|---|---|---|
| **0x01** | IDENTIFY | `$01 $01` | Chaîne d'identification, ex. « ULTIMATE-II DOS V1.0 » | `00,OK` (ne peut échouer) |
| **0x02** | OPEN_FILE | `$01 $02 <attrib> <filename>` | aucune | `00,OK` ou erreur FS |
| **0x03** | CLOSE_FILE | `$01 $03` | aucune | `00,OK` ; `84,NO FILE TO CLOSE` |
| **0x04** | READ_DATA | `$01 $04 [len_lo] [len_hi]` | données du fichier, **par blocs de 512 octets max** (accepter chaque bloc via DATA_ACC), total max 65 535 octets | silence si OK ; `85,NO FILE OPEN` (+ paquet vide) |
| **0x05** | WRITE_DATA | `$01 $05 [dummy] [dummy] [data …]` | aucune (2 octets dummy = alignement long-word ; 512 octets/commande conseillé) | `85,NO FILE OPEN` ; `ACCESS DENIED` si pas ouvert en écriture |
| **0x06** | FILE_SEEK | `$01 $06 [posL] [posML] [posMH] [posH]` (32 bits LSB first) | aucune | `00,OK` ; `85,NO FILE OPEN` ; erreur FS |
| **0x07** | FILE_INFO | `$01 $07` | struct : `uint32 size ; uint16 date ; uint16 time ; char extension[3] ; uint8 attrib ; char filename[]` | `00,OK` ; `85,NO FILE OPEN` ; `88,NO INFORMATION AVAILABLE` |
| **0x08** | FILE_STAT | `$01 $08 <filename>` | même struct que 0x07 | `00,OK` ; `88,FILE NOT FOUND` |
| **0x09** | DELETE_FILE | `$01 $09 <filename>` | aucune | `00,OK` ou erreur FS (v1.1+) |
| **0x0A** | RENAME_FILE | `$01 $0a <filename> $00 <newname>` | aucune | `00,OK` ou erreur FS (v1.1+) |
| **0x0B** | COPY_FILE | `$01 $0b <source> $00 <destination>` | aucune | `00,OK` ou erreur FS (v1.1+) |
| **0x11** | CHANGE_DIR | `$01 $11 <directory name>` — `.` et `..` valides ; peut « entrer » dans un .D64 (sous-système de fichiers) | aucune | `00,OK` ; `83,NO SUCH DIRECTORY` |
| **0x12** | GET_PATH | `$01 $12` | chemin courant depuis la racine | `00,OK` (ne peut échouer) |
| **0x13** | OPEN_DIR | `$01 $13` | aucune | `00,OK` ; `01,DIRECTORY EMPTY` ; `86,CAN'T READ DIRECTORY` |
| **0x14** | READ_DIR | `$01 $14` | **un paquet de données par entrée** : 1 octet d'attribut + nom de fichier | (voir 0x13 pour l'ouverture) |
| **0x15** | COPY_UI_PATH | `$01 $15` | (déprécié depuis firmware 3.0) | `99,FUNCTION NOT IMPLEMENTED` |
| **0x16** | CREATE_DIR | `$01 $16 <dirname>` | aucune | `00,OK` ou erreur FS (v1.1+) |
| **0x17** | COPY_HOME_PATH | `$01 $17` | enchaîne sur GET_PATH (renvoie le chemin courant) | erreur FS si le home n'existe pas (v1.1+) |
| **0x21** | LOAD_REU | `$01 $21 [addrL] [addrML] [addrMH] [addrH] [lenL] [lenML] [lenMH] [lenH]` | chaîne détaillée, ex. « `$003000` BYTES LOADED TO REU `$126800` » | `00,OK` ; `02,REQUEST TRUNCATED` ; erreur FS |
| **0x22** | SAVE_REU | `$01 $22 [addrL] [addrML] [addrMH] [addrH] [lenL] [lenML] [lenMH] [lenH]` | chaîne, ex. « `$008000` BYTES SAVED FROM REU `$852000` » | `00,OK` ; `02,REQUEST TRUNCATED` ; erreur FS |
| **0x23** | MOUNT_DISK | `$01 $23 <id> <filename>` | aucune | `00,OK` ; `89,NOT A DISK IMAGE` ; `90,DRIVE NOT PRESENT` (v1.1+) |
| **0x24** | UMOUNT_DISK | `$01 $24 <id>` | aucune | `00,OK` (même sans disque monté) ; `90,DRIVE NOT PRESENT` (v1.1+) |
| **0x25** | SWAP_DISK | `$01 $25 <id>` *(la source écrit « `$0x25` », coquille)* — équivaut au menu-button > 1 s | aucune | `00,OK` ; `90,DRIVE NOT PRESENT` (v1.1+) |
| **0x26** | GET_TIME | `$01 $26 [fmt]` — fmt 0/absent : `yyyy/mm/dd hh:mm:ss` ; fmt 1 : `www yyyy/mm/dd hh:mm:ss` | date/heure | `00,OK` (v1.2+) |
| **0x27** | SET_TIME | `$01 $27 <Y> <M> <D> <h> <m> <s>` *(source : « `$0x27` », coquille)* — année − 1900 | aucune | `00,OK` ; `98,FUNCTION PROHIBITED` si désactivé (v1.2+) |
| **0xF0** | ECHO | `$01 $F0` | écho de la commande | `00,OK` (ne peut échouer) |

**Attributs OPEN_FILE (0x02)** : `FA_READ` = `$01` ; `FA_WRITE` = `$02` ; `FA_CREATE_NEW` = `$04` (tronque à 0 octet) ; `FA_CREATE_ALWAYS` = `$08` (peut écraser). Lecture seule = `$01` ; écriture sur fichier existant sans le vider = `$02` ; écriture avec écrasement systématique = **`$0E`**. Le nom de fichier n'est **pas** null-terminé (la longueur de commande fait foi).

**Octet d'attribut READ_DIR (0x14)** (repris du format FAT, réutilisé pour les FS non-FAT) :

| Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
|---|---|---|---|---|---|---|---|
| — | — | ARCHIVE | **DIR** | VOLUME | SYSTEM | HIDDEN | READONLY |

**LOAD_REU / SAVE_REU (0x21/0x22)** : opèrent sur le fichier **actuellement ouvert** ; deux paramètres 32 bits LSB first (adresse REU, longueur). Pas de wrap-around : transfert **tronqué** si adresse + longueur dépasse la fin du REU. Les octets hauts d'adresse et de longueur sont masqués (octets dummy en pratique). **Suppose une configuration REU de 16 Mo.**

---

## 7. Cible Control (target `$04`), en bref [U64-UCI-control-target.rst]

Interface bas niveau de gestion matérielle (exécution C64, alimentation des lecteurs émulés, utilitaires REU/disque). Premier octet de commande = **`$04`**.

| Opcode | Commande | Format / Essentiel |
|---|---|---|
| **0x01** | IDENTIFY | `$04 $01` → chaîne « CONTROL TARGET V1.1 » ; `00,OK` |
| **0x03** | FINISH_CAPTURE | `$04 $03` — clôt une capture cassette en cours et ferme le fichier |
| **0x05** | FREEZE | `$04 $05` — gel matériel (équivalent bouton) ; l'acquittement après le freeze reste problématique (à corriger, dixit la doc) |
| **0x06** | REBOOT | `$04 $06` — reboot complet du C64 + ré-init cartouche ; **aucune réponse** (l'UCI est resetée avec le C64) |
| **0x08 / 0x09** | LOAD_REU / SAVE_REU | `$04 $08 <FILENAME>` / `$04 $09 <FILENAME>` — charge/sauve une **image REU par nom de fichier** (contrairement à la version DOS 0x21/0x22 qui opère sur le fichier ouvert). Réponse : 4 octets LE = octets transférés (négatif = erreur). Status : `00,OK` ; `81,INVALID PARAMS` ; `84,REU NOT ENABLED` ; `85,REU FILE CANNOT BE OPENED.` |
| **0x0F** | U64_SAVEMEM | `$04 $0F <FILENAME>` — sauve **toute la RAM** (U64/Elite/Elite-II/C64U seulement) ; défaut `/temp/c64_memory.bin` ; `00,OK` ou `87,DISK ERR: <...>` |
| **0x11** | DECODE_TRACK | `$04 $11 <TRK> <MAX_SEC> <GCR_ADDR> <BIN_ADDR> <GCR_LEN>` — conversion GCR→binaire rapide via REU (adresses/longueur LSB first). Réponse : 1 octet (secteurs réels) + 2 octets de drapeaux d'erreur par secteur ; `00,OK` ou `82,ERRORS ON TRACK.` |
| **0x20** | EASYFLASH_ERASE | `$04 $20 $00 <BANK> <BASEADDR>` — émule l'effacement secteur EasyFlash : 64 KiB (8 banques de 8 KiB) mis à `$FF` ; BANK bits 3–5 = secteur ; BASEADDR = octet haut d'adresse C64 (Low `$8000`–`$9FFF` / High `$A000`–`$BFFF`) ; `00,OK` ou `81,INVALID PARAMS` |
| **0x28** | GET_HWINFO (**déprécié**) | `$04 $28 <SUB_CMD>` — `$00` : nom du modèle (ex. « ULTIMATE 64 » ; défaut sans sous-commande depuis 3.15) ; `$01` : config SID (1 octet = nb de trames, puis 5 octets/trame : base primaire 2 octets LSB first, base secondaire 2 octets MSB first, indicateur de type au sens flou) |
| **0x29** | GET_DRVINFO | `$04 $29 <EFFECTIVE_ADDR_FLAG>` — octet 0 = nombre de lecteurs, puis groupes de 3 octets [Type] [Adresse bus IEC] [État alim.]. Types : 1541=`$00`, 1571=`$01`, 1581=`$02`, Undecided=`$03`, Software IEC=`$0F`, Printer=`$50` ; alim `$00`/`$01` |
| **0x30–0x33** | ENABLE/DISABLE_DRIVE_A/B | `$04 $30` (A on), `$04 $31` (A off), `$04 $32` (B on), `$04 $33` (B off) ; `00,OK` |
| **0x34 / 0x35** | GET_DRIVE_A/B_POWER | `$04 $34` / `$04 $35` → réponse `on` ou `off` ; `00,OK` |
| **0x40** | GET_MP3_RAMDISKINFO | `$04 $40` — spécifique GEOS MegaPatch 3 : bloc de 8 octets (2/lecteur) ; 1ᵉʳ octet = type (`$41`, `$71`, `$81` ou `$DD` = Native) ; 2ᵉ = taille en blocs de 64 KiB pour les partitions natives, sinon 0 |

---

### Renvois internes au projet

- Le déploiement Arena64 utilise `POST /v1/runners:run_prg` (§2.2) via `tools/send.sh` ; les interdits projet (`save_to_flash`, `reset_to_default`, `reset`/`reboot`/`poweroff`) portent sur §2.3–2.4.
- La capture d'écran réelle (`tools/capture_stream.py`) consomme le flux VIC ID 0 (§3.2).
- Le turbo constant du moteur FLI repose sur `$D031` en mode « U64 Turbo Registers » (§4.2).
- Sur le firmware Commodore (fork), l'UCI cœur et le DMA REU sont confirmés fonctionnels, mais chaque service documenté ici doit être revalidé sur la machine réelle avant d'être considéré acquis.

---

# Chapitre 7 — La couche empirique Arena64


*Ce chapitre n'existe dans aucun autre livre : ce sont les comportements MESURÉS de notre
C64 Ultimate (firmware Commodore) là où ils précisent, confirment ou CONTREDISENT la théorie
des chapitres 1-6. Statut de chaque item : **[mesuré]** = reproduit sur le HW ; **[documenté]**
= consigné dans nos docs projet ; **[hypothèse]** = explication plausible non prouvée.
Ancres : dépôt git (commits), docs projet et journaux de session — certaines mesures fines
(poke/retry `$0348`, seuil ~330 uploads, 43 % de lectures manette polluées…) ne sont tracées
que dans les journaux de session, pas dans les docs du dépôt.*

## 7.1 Le turbo 64 MHz et ses murs
- **[mesuré]** `$D031 = $0F` (mode « C64U Turbo Registers » — ⚠️ divergence de NOM du fork Commodore : la doc Gideon [ch.6 §4.1] l'appelle « U64 Turbo Registers ») = 64 MHz constant. Inoffensif sur
  C64 stock (`$D031` = registre VIC inutilisé). [ch.6 §4.2 ; tools/send.sh]
- **[mesuré] ☠️ LA BASCULE turbo↔1 MHz EST INTERDITE** : changer `$D031` pendant qu'une écriture
  RAM est en vol **RESET le firmware U64** (écran noir). Cause exacte inconnue [hypothèse :
  hazard de domaine d'horloge FPGA]. Conséquence : tout au turbo constant, toujours. [CLAUDE.md ⚠️ ; CURRENT-FLI.md « bascule ABANDONNÉE »]
- **[mesuré sur nos bancs — CONCORDANT avec les ~43 µs de la doc turbo, ch.6 §4.3 (pas une mesure indépendante du chiffre)]** La **badline gèle le CPU MÊME à 64 MHz** : ~43 µs par badline (le FPGA fige le
  CPU rapide pendant que le VIC possède le bus). C'est ce qui limite le FLI à ~25 fps et
  sert de synchro ligne à ligne au displayer (`fli_turbo.s`).
- **[mesuré]** Conversion vol-de-cycles → délai logiciel au turbo : **1 cycle VIC volé ≈ 13
  itérations** de boucle `DEY/BNE` (5 cycles CPU à 64 MHz). Base de toute compensation calculée. [arithmétique : 64 MHz ÷ 5 cy/itération = 12,8 ; dérivé session 12 juil]
- **[mesuré]** Vitesses réelles : moteur 4-couleurs plein écran ~50 fps ; FLI 16 couleurs
  ~25 fps (2× le coût, à cause des 200 badlines forcées). [CURRENT-FLI.md ; mémoire projet « coût FLI mesuré »]

## 7.2 L'API REST et ses pièges (le fork Commodore)
- **[mesuré]** `readmem` = FIABLE, à tout moment (nos captures, mouchards, LED watcher). [CLAUDE.md §Déploiement]
  Chaque lecture vole un peu de bus [documenté : glitch bref possible sur le FLI].
- **[mesuré] ⚠️ `writemem` PENDANT l'exécution turbo = NON FIABLE** : octets perdus/corrompus.
  Un poke isolé avec relecture+retry passe (menu `$0348`) ; un flux de données NON. Paramètres
  de test → à la COMPILATION (`-D NOM=val`), jamais en poke. [CLAUDE.md §Déploiement, mesuré]
- **[mesuré]** `writemem` avant `run_prg` vers `$0200-$03FF` = EFFACÉ par le reset (RAMTAS —
  voir la désassemblée ROM). Le bloc projet `$0340-$035F` n'est PAS chargé par le .prg
  (buffer cassette) : valeur INDÉTERMINÉE au boot → toujours initialiser à 0 avant la boucle. [CLAUDE.md ; c64disasm RAMTAS ; src/main.c commentaires $0348/$034C]
- **[mesuré] ☠️ JAMAIS** `configs:save_to_flash`, `configs:reset_to_default`, `machine:reset/
  reboot/poweroff` : efface les réglages user / réveille le bug écran-noir #620. Récupération
  si écran noir persistant : maintenir RESTORE à l'allumage (clear flash config). [CLAUDE.md ☠️ ; mémoire « écran noir U64 = bug #620 »]
- **[mesuré]** Fuite firmware : chaque `run_prg` crée `/Temp/tempNNNN` jamais supprimé →
  « Cannot open file » vers ~330 uploads → purger par FTP (`DELE`), SANS reboot. [CLAUDE.md → docs/MIP-EXPERIMENT.md §3a]
- **[mesuré]** Fork Commodore vs docs Gideon : **UCI cœur + REU DMA + REST configs = OK ;
  sockets réseau UCI = BLOQUENT ; `$DF20` (audio Gideon) = RESET la machine.** Toute doc
  Gideon du ch. 6 est une BASE À VÉRIFIER sur ce firmware, jamais un acquis. [mémoire « firmware Commodore, pas Gideon » ; mesures projet]
- **[mesuré]** Stream vidéo VIC (ch. 6 / `U64-data-streams.rst`) : amorcer l'ARP (pings) avant
  `streams/video:start`, sinon « Resolve Error ». `run_prg` reset l'état stream → stop +
  re-set destination + start à chaque session de capture. UDP = paquets perdus : ne garder
  que les trames COMPLÈTES pour toute analyse. [tools/capture_stream.py, commentaires + session 26 juil]

## 7.3 Le displayer FLI au turbo (branche `engine-fli`)
- **[mesuré]** Servir le FLI par **polling `$D012`** au turbo constant marche (zéro switch).
  Écrire `$D018` puis `$D011` **après le cycle 14** (délai `DLYCNT=240` ≈ cycle 16-22 ; la plage
  180-320 n'a validé que la scène complète RC/VC, PAS la propreté du bord gauche —
  contrainte plus serrée, T≈19-21, voir SPRITE-DMA-SHEAR.md) sinon RC est remis à 0 → « bleu uni ». [Bauer §3.7.2 règle 2]
- **[mesuré]** `MATOFF=7` (rotation des 8 matrices) : SEULE valeur donnant un décalage
  vertical constant sur CE U64 (MATOFF=1 alterne +8/+16 = tirets sur les arêtes).
- **[mesuré]** Le FLI-bug (24 px, `$ff` sur les 3 premiers c-access) est irréductible
  [Bauer §3.14.3 : « there is no way around that »] — masqué par 2 sprites Y-expandés
  multiplexés (56 px, incluant la marge anti-peigne).
- **[mesuré] ⚠️ LE PIÈGE DU NIBBLE** : l'affichage FLI lit la matrice décalée de +4,5
  cellules — la cellule écran C affiche (nibble bas de C−5, nibble haut de C−4). Tout blit
  matrice direct doit émettre un flux de nibbles PRÉ-DÉCALÉ. Sonder avec hi≠lo (un contenu
  hi=lo masque le phénomène). [hypothèse de classe : VMLI shift-register, Bauer §3.7.2 —
  instable sur silicium selon révision/température ; déterministe sur le FPGA U64]
- **[mesuré : symptôme + isolation ; mécanisme causal = documenté + hypothèse forte] Vols DMA des sprites de jeu (« le peigne »)** — cohérent avec le diagramme
  Mäkelä (ch. 2) : slots 0-2 volent en FIN de ligne (cycles 58-63, absorbés par le poll) ;
  slots 3-7 volent en DÉBUT de ligne (cycles 1-10, PENDANT la boucle de délai → l'écriture
  `$D011` glisse → décalage type DMA-delay à droite). Compensations empiriques par scalaires =
  ÉCHEC sur vols multiples ; la table calculée par ligne (ch. 2 + conversion 13×) reste À
  FAIRE. Solution de contournement LIVRÉE : monstre + boule en billboards matrice (zéro
  sprite de jeu = zéro peigne) [commits 983f5ca/a771859, branche engine-fli] ; le pivot
  moteur 4-couleurs (branche arena-4color, docs/PORT-4COLOR-PLAN.md) élimine la classe
  entière. NB : CLAUDE.md et CURRENT-FLI.md décrivent l'ère FLI — EN RETARD sur le git.
- **[mesuré]** Compteur d'overrun `$0347` (fli_turbo) : n'attrape QUE l'arrivée tardive de
  `fli_show`, PAS les retards par-ligne. **Un banc STATIQUE ment** : calibrer EN MOUVEMENT
  (leçon VC1=40 : 0 overrun statique → injouable en mouvement, +18 % de fill déborde).
- **[mesuré]** Budget bordure : gros blit matrice = l'ÉTALER (≤ ~8 rangées/trame) ; overlays
  en ASM (draw_bb/draw_name, octet-identiques prouvés sim65) ; fast-paths fill (ciel/sol/mur
  pleins) → le fill plein écran (VIEWH=200) est ~gratuit, ce sont les OVERLAYS qui débordent.

## 7.4 Entrées, vidéo 4-couleurs, divers
- **[documenté]** Banking : le mode FLI/jeu tourne avec **`$01` = `$35`** (KERNAL+BASIC off,
  I/O on) — vecteurs RAM `$0314+` inutilisés (SEI + polling). [src/fli_turbo.s « KERNAL off »]
- **[mesuré]** Pile soft cc65 (`sp`, ZP `$02-$03`) : le crt0 la pose à la FIN de MAIN — à `$8C00`
  elle écrasait screen B (`$8800`) → carrés clignotants en bas d'écran. Fix : relocaliser `sp`
  à `$CFFF` dans main(). [src/main.c moteur 4-coul, commentaire « CORRECTIF MÉMOIRE CRITIQUE »]
- **[mesuré]** Manette fiable au turbo : COUPER le scan clavier KERNAL (`$DC0D`=`$7F` + lire ICR)
  et figer DDRA port 2 en entrées — sinon ~43 % des lectures `$DC00` polluées à 64 MHz. [src/main.c « MANETTE FIABLE AU TURBO »]
- **[mesuré]** Moteur 4-couleurs : double-buffer par flip banque VIC (`$DD00`) + `$D018` au
  raster 251 ; bitmap multicolore standard, zéro trick badline → aucun des pièges FLI ne
  s'applique. Sprites inutilisés à ce jour (fusil/visage = blits bitmap). [src/main.c game_main, branche arena-4color]
- **[mesuré]** PETSCII : cl65 -t c64 stocke les litéraux en PETSCII ('A'=`$C1`) ; sim65
  (-t sim6502) garde l'ASCII → un test sim65 NE VALIDE PAS un mapping de caractères. Mapping
  char→index en C, jamais en ASM avec des constantes ASCII. [commit c4199e7 ; mémoire « piège PETSCII vs sim65 »]
- **[mesuré]** REU sur U64 : DMA ponctuel fiable (`$DF01`=`$90`/`$91` immédiat) pour stash/fetch
  d'assets ; latence de setup ~60 µs/transfert → inadapté aux micro-transferts par trame
  (prescale texture abandonné). Piège .prg : un segment chargé à `$A000` (REUSTAGE) doit être
  stashé AVANT que video_init n'efface le bitmap B. [src/main.c game_main ; mémoire « REU = magasin d'assets »]
- **[documenté]** Capture d'écran : `capture.py` (reconstruction RAM — PAS les sprites, PAS
  les artefacts d'affichage) vs `capture_stream.py` (VRAI rendu VIC, tout compris). Pour
  juger un glitch d'affichage : STREAM uniquement, en rafale, trames complètes. [tools/capture.py vs tools/capture_stream.py, en-têtes]

---

# Chapitre 8 — Index des adresses du projet


*Les adresses que le CODE d'Arena64 touche réellement, avec leur rôle. Pour tout le reste :
`mapping-c64-…` (l'adresse), `c64disasm-…` (la routine ROM), `c64prg-…` (le manuel).*

## Zéropage & bas de mémoire
| Adresse | Rôle projet | Voir |
|---|---|---|
| `$01` | banking (=`$35` : KERNAL/BASIC off, I/O on — mode FLI) | mapping, ch.7.4 |
| `$02-$03` | pile soft cc65 `sp` (⚠️ relocalisée `$CFFF` — piège screen B) | ch.7.4 |
| `$A0-$BB` | ZP scratch des hot loops FLI (fill, overlays) | fli_fill.s |
| `$0314/15` | vecteur IRQ CINV → `$EA31` (le « POKE 788 ») | disasm `$EA31` |
| `$0340-$035F` | bloc d'état/debug projet (spawn, manette miroir, `$0347` overruns, `$0350` coups/LED) — RAM cassette NON chargée par .prg : init obligatoire | ch.7.2 |

## VIC-II (`$D000`-`$D02E`) — registres que le projet écrit
| Registre | Rôle projet |
|---|---|
| `$D011` | ctrl1 : DEN/RSEL/YSCROLL — cœur du FLI (badline forcée), écran off (screensaver) |
| `$D012` | raster : POLLING du displayer FLI + pacing 4-couleurs (ligne 251) |
| `$D015/$D017/$D01D` | enable/expand sprites (masques FLI, ex-monstre) |
| `$D016` | ctrl2 : MCM=1, CSEL=0 (masque PARTIEL du FLI-bug : 7 px gauche [ch.1 §4] — le vrai masque = 2 sprites, ch.7.3) |
| `$D018` | base matrice/bitmap : rotation FLI par ligne ; flip double-buffer 4-coul |
| `$D020/$D021` | bordure (flash rouge impact) / fond |
| `$D025-$D02E` | couleurs sprites (visage, MC) |
| `$D030/$D031` | ⚠️ registres TURBO U64 (64 MHz constant — JAMAIS re-basculer) |

## SID / CIA / REU / UCI
| Adresse | Rôle projet |
|---|---|
| `$D40E-$D414` | SID voix 3 : tous nos SFX (pas/tir/impact) — ch.4 |
| `$D418` | volume |
| `$DC00/$DC02` | CIA1 : manette port 2 (DDRA figé entrées) |
| `$DC0D` | CIA1 ICR : scan clavier COUPÉ au turbo (lecture = acquittement !) |
| `$DD00` | CIA2 : banque VIC (double-buffer 4-coul ; banque 1 en FLI) |
| `$DF00-$DF0A` | REU : reu_xfer (stash/fetch assets) — ch.5 |
| `$DF1C…` | UCI (File Destroyer réel, futur) — ch.6 |
| `$FF00` | déclencheur DMA REU différé (RAM sous I/O) — ch.5 |
