# L'indexation plein texte

Un moteur de recherche plein texte ne parcourt pas les documents au moment de
la requête : il les a préparés à l'avance dans un **index inversé**. Pour chaque
terme, l'index inversé garde la liste des documents qui le contiennent, avec
le nombre d'occurrences et souvent leurs positions. Retrouver les documents
qui parlent de « batterie » revient alors à lire une seule liste, quelle que
soit la taille du corpus.

## L'analyse du texte

Avant d'entrer dans l'index, le texte passe par un **analyseur**. La
tokenisation découpe le texte en mots ; les mots vides (le, de, et, the, of)
sont écartés ; la racinisation ramène « recherches », « rechercher » et
« recherché » à une même racine. L'analyseur dépend de la langue : un analyseur
français ne traite pas les pluriels ni les accents comme un analyseur anglais.
La même analyse est appliquée aux requêtes, si bien qu'une requête au pluriel
retrouve un document au singulier.

## Le classement des résultats

Tous les documents trouvés ne se valent pas. Le score **TF-IDF** combine la
fréquence d'un terme dans le document (TF) et sa rareté dans le corpus (IDF) :
un terme rare et répété pèse beaucoup, un terme présent partout ne pèse
presque rien. Le modèle **BM25**, utilisé par la plupart des moteurs actuels,
affine ce calcul en tenant compte de la longueur des documents.

## Lucene

Apache Lucene est la bibliothèque d'indexation plein texte la plus répandue.
Elle fournit les analyseurs, l'index inversé, une syntaxe de requête riche
(phrases exactes, jokers, recherche floue, intervalles numériques) et le
classement des résultats. Lucene++ en est le portage en C++ ; Elasticsearch et
Solr sont des serveurs construits autour de Lucene. Un index Lucene se met à
jour au fil des ajouts : un nouveau document est cherchable dès qu'il a été
indexé, sans reconstruire l'index.

Dans une chaîne de génération augmentée par la recherche, l'index plein texte
sert à retrouver rapidement les passages pertinents pour une question : c'est
la recherche lexicale, précise sur les noms propres, les références et les
termes techniques.
