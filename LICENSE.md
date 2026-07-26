# Licence

Ce dépôt contient trois natures de fichiers, et elles ne relèvent pas de la même licence.

---

## 1. Le livre — *Creative Commons BY-SA 4.0*

**Ce qui est concerné** : `20-MILLISECONDES.md`, `20-MILLISECONDES.pdf`, `README.md`,
`livre-pas-a-pas/*/chapitre.md`, l'annexe, et **toutes les captures d'écran** `*-hw.png`.

© 2026 Johnny Piette. Texte rédigé avec l'assistance d'une IA (Claude, Anthropic) sous la
direction de l'auteur ; captures produites sur son matériel.

Vous êtes libre de **partager** (copier, redistribuer, sur tout support) et d'**adapter**
(remixer, transformer, construire à partir du matériel), y compris commercialement, aux deux
conditions suivantes :

- **Attribution** — citer l'auteur, indiquer si des modifications ont été faites.
- **Partage dans les mêmes conditions** — toute œuvre dérivée doit être diffusée sous la
  même licence.

Texte complet : <https://creativecommons.org/licenses/by-sa/4.0/legalcode.fr>
Résumé lisible : <https://creativecommons.org/licenses/by-sa/4.0/deed.fr>

---

## 2. Les programmes et les outils — *licence MIT*

**Ce qui est concerné** : tous les fichiers `livre-pas-a-pas/*/*.a` (les programmes du
livre), `tools/*` (chaîne LaTeX, outils de capture et de vérification).

Le copyleft n'a pas sa place ici : un lecteur doit pouvoir reprendre un listing du livre
dans son propre programme sans que cela l'engage à quoi que ce soit.

```
Copyright (c) 2026 Johnny Piette

L'autorisation est accordée, gracieusement, à toute personne acquérant une copie de ces
fichiers et des fichiers de documentation associés (le « Logiciel »), d'utiliser le
Logiciel sans restriction, notamment les droits d'utiliser, copier, modifier, fusionner,
publier, distribuer, sous-licencier et/ou vendre des copies du Logiciel, ainsi que
d'autoriser les personnes auxquelles le Logiciel est fourni à le faire, sous réserve des
conditions suivantes :

La déclaration de copyright ci-dessus et la présente autorisation doivent être incluses
dans toutes copies ou parties substantielles du Logiciel.

LE LOGICIEL EST FOURNI « TEL QUEL », SANS GARANTIE D'AUCUNE SORTE, EXPLICITE OU IMPLICITE,
NOTAMMENT SANS GARANTIE DE QUALITÉ MARCHANDE, D'ADÉQUATION À UN USAGE PARTICULIER ET
D'ABSENCE DE CONTREFAÇON. EN AUCUN CAS LES AUTEURS OU TITULAIRES DU DROIT D'AUTEUR NE
SERONT RESPONSABLES DE TOUT DOMMAGE, RÉCLAMATION OU AUTRE RESPONSABILITÉ, QUE CE SOIT
DANS LE CADRE D'UN CONTRAT, D'UN DÉLIT OU AUTRE, EN PROVENANCE DE, CONSÉCUTIF À OU EN
RELATION AVEC LE LOGICIEL OU SON UTILISATION.
```

---

## 3. ⚠️ `reference/` — ce qui **ne nous appartient pas**

**Ce dossier n'est couvert par aucune des licences ci-dessus et ne doit pas être
redistribué publiquement.**

### `reference/sources/` — les documents d'origine

Quatorze documents de tiers, conservés ici comme **copie de travail** pour vérifier les faits
du livre. Leurs statuts diffèrent et plusieurs sont explicitement réservés :

- le *Commodore 64 Programmer's Reference Guide* porte « Copyright © 1982 Commodore Business
  Machines — All rights reserved. No part of this publication may be reproduced… without the
  prior written permission » ;
- *Mapping the Commodore 64* (Sheldon Leemon) est un ouvrage commercial, diffusé ici sous
  forme d'e-text par le projet de préservation **Project 64**, dont le préambule ne concède
  aucun droit : il décline toute garantie et renvoie explicitement à la licence du document
  d'origine (« Please refer to the warantee of the original document ») ;
- **les autres ne portent aucune mention de licence.** Vérifié fichier par fichier : les
  chronogrammes de Mäkelä (*pal.timing*), l'article d'Ojala (*Missing Cycles*, C=Hacking n°3)
  et la page d'Åkesson (*MISC*) ne contiennent **ni copyright, ni permission, ni condition**.
  Le *64doc* de West et Mäkelä, lui, renvoie à un fichier que nous n'avons pas : « This file
  is part of Commodore 64 emulator… **See README for copyright notice** ».

**Silence ne veut pas dire domaine public.** Sans mention explicite, une œuvre reste protégée
par défaut (convention de Berne). Ces documents circulent librement dans la communauté depuis
trente ans, et leurs auteurs les ont manifestement écrits pour être lus et utilisés — mais
c'est un **usage**, pas une licence. Reproduire un chronogramme entier ou une table complète
va au-delà de la courte citation ; s'en servir pour *établir un fait* et le réécrire avec ses
propres mots, non.

C'est exactement la ligne que suit « 20 millisecondes » : il prend les faits, il n'emprunte
pas une phrase. Si le volume de référence devait un jour être publié, deux chemins honnêtes
existent : **redessiner** les diagrammes à partir de nos propres mesures, ou **demander
l'autorisation** aux auteurs — ils sont joignables, et l'esprit de cette communauté est
généreux.

Les cinq courriels de demande sont prêts, en anglais, dans
[`autorisations/`](autorisations/) : un par auteur, chacun disant précisément ce qui est
repris chez lui et combien de mots.

### « Mais c'est vieux, non ? » — l'âge ne change rien

C'est le contresens le plus répandu, et il vaut la peine d'être levé : **ce n'est pas l'âge du
document qui compte, c'est la vie de son auteur.** La durée est de **70 ans après la mort de
l'auteur** (art. L123-1 du code de la propriété intellectuelle, et règle harmonisée dans toute
l'Union européenne).

- Les documents de **1992-1994** — Mäkelä, Ojala, Åkesson, Bauer — ont été écrits par des
  informaticiens de la génération démo, **aujourd'hui vivants**. S'ils vivent jusqu'en 2060,
  leurs textes seront protégés jusqu'en **2130**. Un article de trente ans est, en droit
  d'auteur, un texte tout neuf.
- Le manuel **Commodore de 1982** est une œuvre d'entreprise : 70 ans après publication dans
  l'UE (**2052**), 95 ans aux États-Unis (**2077**).

Et « abandonware » n'est pas une catégorie juridique : c'est une tolérance, pas un droit.

**Mais rien de tout cela ne nous gêne**, parce que ce dont un livre technique a besoin n'est
pas protégé et ne l'a jamais été : **les faits**. Une adresse de registre, un compte de cycles,
la règle des trois conditions de la Bad Line — ce sont des données et des méthodes, pas des
œuvres. Seule leur *expression* est protégée. On peut donc tout dire, à condition de le dire
avec ses propres mots : c'est précisément ce que le livre a fait, et c'est mesurable.

Et pour ce qui dépasse le fait — un chronogramme entier, une table complète —, le chemin est
plus court qu'un procès en domaine public : **un courriel**. Ces auteurs sont vivants,
joignables, et ils ont écrit ces textes pour qu'on s'en serve.

**En cas de publication du dépôt, retirez ce dossier** et remplacez-le par la liste des
adresses où chacun se télécharge — elles figurent déjà dans la section « Sources » du livre.

### `reference/AU-COEUR-DU-METAL*.md` — le volume compagnon

C'est une **synthèse** : il reproduit délibérément, en les attribuant, des tableaux, des
chronogrammes et des extraits de code issus des documents ci-dessus (la vérification
automatique en trouve plusieurs passages de plus de cent mots, jusqu'à 259). Ces emprunts
sont assumés — c'est le principe même d'un ouvrage de référence qui veut être vérifiable —
mais ils font que **ce volume ne peut pas être placé sous licence libre en l'état**.

---

## Une vérification, plutôt qu'une déclaration

La question « a-t-on écrit, ou recopié ? » a été mesurée, pas supposée. En comparant le livre
aux quatorze documents du corpus, séquence de huit mots par séquence de huit mots :

| | Passages identiques trouvés |
|---|---|
| **20 millisecondes** (26 773 mots) | **20** — et ce sont uniquement les **titres des ouvrages cités** dans la bibliographie |
| *Au cœur du métal* (30 001 mots), pour comparaison | 2 077 — surtout des tableaux, chronogrammes et listings reproduits en citation |

Autrement dit : **pas une phrase du livre « 20 millisecondes » ne vient d'ailleurs.** Les
faits, eux, viennent des sources — et c'est très bien ainsi : les faits n'appartiennent à
personne, seule leur expression est protégée.

Le contrôle est reproductible ; le script tient en quinze lignes de Python et compare les
n-grammes du livre à ceux du corpus.
