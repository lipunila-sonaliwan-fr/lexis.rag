# Les cartes de concepts

Une **carte de concepts** représente les notions d'un ensemble de documents et
leurs relations sous forme de graphe : chaque concept est un nœud, chaque lien
relie deux concepts associés. Elle donne une vue d'ensemble d'un corpus avant
même de le lire, et aide à formuler de meilleures questions.

## Extraire les concepts

Les concepts candidats sont les termes caractéristiques des documents : des
mots pleins (sans les mots vides) et des expressions de deux ou trois mots,
comme « index inversé » ou « modèle de langage ». Le score TF-IDF favorise les
termes fréquents dans quelques documents plutôt que ceux présents partout. Les
formes au singulier et au pluriel, avec ou sans accents, sont regroupées.

## Relier les concepts

Deux concepts sont reliés lorsqu'ils apparaissent souvent dans les mêmes
passages : c'est la **cooccurrence**. Le poids d'un lien se calcule par une
mesure de similarité, par exemple le cosinus entre les ensembles de passages
des deux concepts. On ne garde que les liens les plus forts de chaque concept
pour que la carte reste lisible.

## Disposer la carte

Un algorithme de disposition par forces place les nœuds : les liens agissent
comme des ressorts qui rapprochent les concepts associés, et tous les nœuds se
repoussent pour ne pas se chevaucher. Les groupes de concepts liés forment
alors des îlots visibles, qui correspondent aux grands thèmes du corpus. Quand
de nouveaux documents arrivent, la carte est recalculée à partir des positions
précédentes, ce qui la garde reconnaissable.

Une recherche dans la carte met en évidence les concepts correspondants et
leurs voisins ; un clic sur un concept retrouve, dans l'index plein texte, les
passages qui l'emploient.
