# Les modèles de langage

Un **modèle de langage** prédit la suite d'un texte. Entraîné sur de très grands
corpus, un grand modèle de langage apprend la grammaire, les faits fréquents et
des façons de raisonner. Il travaille sur des **tokens**, des morceaux de mots
produits par un tokeniseur ; une phrase française compte en moyenne un peu plus
de tokens que de mots.

## Le contexte

Le modèle ne voit qu'une fenêtre de texte limitée : le **contexte**, mesuré en
tokens. Tout ce qui doit servir à la réponse (consigne, historique de la
conversation, documents joints) doit y tenir. Un contexte de quelques milliers
de tokens accueille une dizaine de passages de documents, pas une bibliothèque
entière : il faut choisir les passages pertinents avant de les joindre.

## Les hallucinations

Un modèle de langage produit un texte plausible, pas nécessairement exact.
Interrogé sur un sujet absent de ses données d'entraînement ou trop récent, il
peut inventer une réponse avec assurance : c'est une **hallucination**. Donner
au modèle les documents qui contiennent la réponse, et lui demander de citer
ses sources, réduit fortement ce risque.

## Les embeddings

Un modèle peut aussi transformer un texte en un vecteur de nombres, un
**embedding**. Deux textes de sens proche ont des vecteurs proches, même s'ils
n'emploient pas les mêmes mots : c'est la recherche sémantique. Elle complète
la recherche lexicale de l'index plein texte, qui retrouve les termes exacts.
Les deux approches se combinent souvent dans une recherche hybride.

Les modèles au format GGUF (Llama, Mistral, Qwen) fonctionnent sur un simple
processeur, sans service distant : les documents restent sur la machine.
