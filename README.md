```
   _._
 o|- -|o This file is licensed under CC BY-NC-SA 4.0 international license.
  ( l )  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
    =    Author: jean-marc "jihem" quere 2026
```

[![rag](ressources/rag.png)](https://lipunila.sonaliwan.fr)
# Veille documentaire (RAG) en Lexis+

Recherche automatisée sur Internet, indexation **Lucene**, analyse des documents
au fil de leurs ajouts (texte, Markdown, PDF, HTML) et **carte des concepts**
interrogeable, le tout en Lexis+.

```
wdlexisrt exemples/rag/principal.prg [dossier_de_travail]
```

Le dossier de travail (par défaut `~/rag_lexis`) contient le corpus
(`corpus/`), l'index Lucene des passages (`index/`) et l'état de l'application
(`etat.json` : documents analysés, passages, positions de la carte). Au premier
lancement, le corpus d'exemple (`corpus/` de ce dossier : quatre textes et un
PDF) y est copié.

## La chaîne

| Étape | Fichier | Paquets |
| --- | --- | --- |
| Recherche sur Internet : Wikipédia (API), DuckDuckGo (page HTML), ou des adresses http(s) collées dans le champ Sujet. Chaque page devient un fichier du corpus : Markdown (texte principal de la page, avec `Source : <adresse>`) ou PDF tel quel. Un travail à la fois, par une minuterie : l'interface reste réactive. | `collecte.prg` | `http`, `json`, `document` |
| Surveillance du dossier `corpus/` : tout fichier ajouté, modifié ou retiré (y compris à la main, ou par *Ajouter des documents…*) est pris en compte. | `analyse.prg` | `fichier` |
| Analyse de chaque document : texte (PDF en Nim pur, HTML, Markdown, texte), langue, mots-clés, découpage en passages qui se recouvrent, indexation des passages. | `analyse.prg` | `document`, `lucene` |
| Carte des concepts : termes caractéristiques des passages (mots et expressions), reliés quand ils apparaissent dans les mêmes passages ; la carte est recalculée après chaque document et garde ses positions. Les concepts apparus avec le dernier document sont cerclés d'orange. | `carte.prg` | `document`, `interface` (toile) |
| Question → passages les plus pertinents (Lucene) → réponse extractive citée (phrases des passages les plus proches de la question), ou rédigée par un modèle de langage local s'il y en a un. | `reponse.prg` | `lucene`, `document`, `llm` |

## Utilisation

- **Sujet** + *Rechercher sur Internet* (ou Entrée) : Wikipédia, Web, ou les
  deux ; *Pages* fixe le nombre de résultats retenus par moteur. Le journal
  suit la collecte et l'analyse.
- **Carte** : cliquer un concept affiche sa fiche (poids, concepts liés,
  documents, phrases en contexte) et met en évidence ses voisins ; glisser un
  concept le déplace (ses liens suivent, sa position est gardée) ; Ctrl+molette
  ou `-` / `+` : zoom ; *Redisposer* recalcule toute la disposition.
- **Filtre de la carte** : pendant la frappe, les concepts qui correspondent
  restent vifs ; Entrée cherche les passages (onglet Passages) et surligne sur
  la carte les concepts qu'ils contiennent.
- **Question** : la réponse cite ses sources `[n]` ; les liens ouvrent la page
  d'origine (navigateur) ou la fiche du document. Les concepts des passages
  retrouvés sont surlignés sur la carte.
- **Documents** : fiche de chaque document (source, langue, mots, passages,
  mots-clés cliquables) ; sa sélection surligne ses concepts.

## Modèle de langage (facultatif)

Sans modèle, les réponses sont extractives. Avec un modèle GGUF (Llama 3.2 1B
Instruct, Qwen, Mistral…), la case *Rédiger la réponse avec le modèle local*
fait rédiger la réponse à partir des passages numérotés, affichée au fil de
l'eau. Le modèle est cherché dans `NIMLLM_MODEL`, puis dans le dossier `models/`
du dépôt et dans le dossier de travail.

## Sans Lucene

Si la bibliothèque du paquet `lucene` n'est pas disponible (voir
`exemples/lucene`), l'exemple fonctionne quand même : la recherche des passages
se fait en mémoire (termes de la question pondérés par leur rareté), ce que le
journal signale au démarrage.

## Remarques

- Wikipédia est interrogée en français, puis en anglais si rien n'est trouvé ;
  les sections de fin (Notes, Références, Voir aussi…) sont retirées.
- Les adresses déjà collectées ne sont pas téléchargées deux fois ; les sites
  vidéo et réseaux sociaux sont ignorés (`DOMAINES_EXCLUS`).
- Les PDF scannés (images sans texte) et chiffrés sont signalés « illisibles ».
- Pour repartir de zéro : supprimer le dossier de travail.

## IMPORTANT
Le langage de programmation utilisé pour réaliser cette application est **Lexis+** (disponible pour Linux, macOS et Windows). Vous devez installer l'environnement de développement intégré (EDI / IDE) **[wdlexis+](https://github.com/lipunila-sonaliwan-fr/nim.wdlexis)** disponible sur GitHub pour pouvoir (re)compiler. Le dépôt de **wdlexis** comporte des versions prête à installer dans la section **[Releases](https://github.com/lipunila-sonaliwan-fr/nim.wdlexis/releases)**. La version minimale requise est **v1.9.4 wdlexis+ (complet)**.

## Licence

CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026

### Encore une chose !
Un p'tit geste qui peut - grandement - nous aider... \[La caféïne c'est important pour une équipe de neuro-atypiques : TSA, TDAH, TAG, HPI et/ou THPI (membres de **mensa.fr** et de **triplenine.org**).\]

[![Buy Me a Coffee](ressources/buymeacoffe-fre.png)](https://buymeacoffee.com/sonaliwan.fr)
