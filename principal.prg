&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Veille documentaire (RAG) : recherche automatisée sur Internet, indexation
&& Lucene, analyse des documents au fil de leurs ajouts et carte des concepts.
&&
&&   wdlexisrt exemples/rag/principal.prg [dossier_de_travail]
&&
&& Le dossier de travail (par défaut ~/rag_lexis) contient :
&&   corpus/      les documents : .txt, .md, .pdf, .html (déposez-y les vôtres) ;
&&   index/       l'index Lucene des passages ;
&&   etat.json    documents analysés, passages, positions de la carte.
&&
&& La chaîne :
&&   collecte.prg  recherche sur Internet (Wikipédia, DuckDuckGo, adresses) :
&&                 chaque page devient un fichier du corpus (Markdown ou PDF) ;
&&   analyse.prg   surveillance du dossier : chaque document ajouté ou modifié
&&                 est lu (paquet document : texte, Markdown, PDF, HTML),
&&                 découpé en passages, indexé (paquet lucene), puis la carte
&&                 des concepts est recalculée ;
&&   carte.prg     carte des concepts (toile en mode plateau) : taille = poids,
&&                 liens = cooccurrences ; filtre, recherche, clic sur un concept ;
&&   reponse.prg   question → passages (Lucene) → réponse extractive citée, ou
&&                 rédigée par un modèle de langage local (paquet llm) s'il y en a un.
&&
&& Sans la bibliothèque Lucene (voir exemples/lucene), la recherche se fait en
&& mémoire : l'exemple reste utilisable, en moins rapide.

os = paquet("systeme")
ui = paquet("interface")
NL = car(10)

&& dossiers
DOSSIER = fichier.joindre(fichier.dossierperso(), "rag_lexis")
si #systeme.args >= 1
  DOSSIER = fichier.absolu(systeme.args[1])
finsi
CORPUS = fichier.joindre(DOSSIER, "corpus")
FICHIER_ETAT = fichier.joindre(DOSSIER, "etat.json")
EXTENSIONS = {".txt", ".md", ".markdown", ".pdf", ".html", ".htm"}
premiere = non fichier.existe(CORPUS)
fichier.creerdossier(CORPUS)
si premiere
  && premier lancement : le corpus d'exemple sert d'amorce
  pour chaque n dans fichier.liste(fichier.joindre(systeme.dossierprogramme(), "corpus"))
    fichier.copier(fichier.joindre(systeme.dossierprogramme(), "corpus", n), fichier.joindre(CORPUS, n))
  suivant
finsi

&&
&& état
&&

DOCS = {}             && chemin -> {chemin, nom, titre, genre, adresse, taille, modifie, passages, mots, langue, motscles, ajoute, erreur}
PASSAGES = {}         && liste de {id, source, titre, numero, texte}
SOURCES_WEB = {}      && nom de fichier -> adresse d'origine (fichiers téléchargés)
VUS = {}              && chemin -> taille au dernier passage (fichier stable avant analyse)
FILE = {}             && chemins à analyser, dans l'ordre d'arrivée
COLLECTE = {}         && travaux de collecte : {genre, ...}
COLLECTE_TOTAL = 0
COLLECTE_FAITS = 0
ANALYSE_EN_COURS = faux
COLLECTE_EN_COURS = faux
CARTE_A_REFAIRE = faux
DERNIER_CALCUL = 0
NB_CONCEPTS = 40
idx = nul             && index Lucene (nul : recherche en mémoire)
&& carte (carte.prg)
LARGEUR_CARTE = 1600
HAUTEUR_CARTE = 1000
POS = {}              && clef de concept -> {x, y}
CONCEPTS_CARTE = nul  && résultat de document.concepts
PAR_CLE = {}          && clef -> concept
FORMES = {}           && clef -> vrai : concept dessiné
LIENS_DESSINES = {}
NOUVEAUX = {}         && concepts apparus avec le dernier calcul
CHOISI = ""
SURLIGNES = {}
FILTRE_TEXTE = ""
CARTE_AJUSTEE = faux
&& listes affichées
LISTE_PASSAGES = {}
TERMES_PASSAGES = ""
LISTE_DOCS = {}
&& collecte (collecte.prg)
AGENT = "LexisRAG/1.0 (exemple wdlexis+ ; https://sonaliwan.fr)"
DOMAINES_EXCLUS = {"youtube.com", "youtu.be", "facebook.com", "twitter.com", "x.com", "instagram.com", ;
                   "tiktok.com", "linkedin.com", "pinterest.", "amazon.", "duckduckgo.com"}
&& réponses (reponse.prg)
CHEMIN_MODELE = TROUVER_MODELE()
MODELE = nul
REPONSE_ENTETE = ""
REPONSE_TEXTE = ""
REPONSE_PIED = ""
CHARGER_ETAT()
OUVRIR_INDEX()

&&
&& accueil
&&

globale RACINE=fichier.dossier(os.args[0])
ACCUEIL()
ui.executer()

&&
&& fenêtre principale
&&

procedure MENURAG()

  fen = ui.fenetre{titre = "RAG Lexis+", largeur = 1440, hauteur = 900, disposition = "bordure"}
  fen.surfermeture = @FERMETURE

  && collecte sur Internet
  haut = fen:ajouter(ui.rangee())
  haut.ancrage = "haut"
  haut.marge = 8
  haut.espacement = 8
  haut:ajouter(ui.etiquette("Sujet :"))
  sujet = haut:ajouter(ui.saisie{indication = "un sujet (ex. : recherche d'information), ou des adresses http(s) séparées par des espaces"})
  sujet.poids = 1
  sujet.surtouchebas = @TOUCHE_SUJET
  source = haut:ajouter(ui.combo("Wikipédia", "Web (DuckDuckGo)", "Wikipédia et Web"))
  source:selectionner(1)
  source.largeurfixe = 170
  haut:ajouter(ui.etiquette("Pages :"))
  nbpages = haut:ajouter(ui.compteur())
  nbpages.min = 1
  nbpages.max = 20
  nbpages.num = 5
  nbpages.largeurfixe = 70
  brecherche = haut:ajouter(ui.bouton("Rechercher sur Internet"))
  brecherche.surclic = @RECHERCHER_WEB
  bajouter = haut:ajouter(ui.bouton("Ajouter des documents…"))
  bajouter.surclic = @AJOUTER_DOCUMENTS
  bdossier = haut:ajouter(ui.bouton("Dossier du corpus"))
  bdossier.surclic = @OUVRIR_DOSSIER

  && barre d'état et progression
  bas = fen:ajouter(ui.rangee())
  bas.ancrage = "bas"
  bas.marge = 8
  bas.espacement = 8
  etat = bas:ajouter(ui.etiquette(""))
  etat.poids = 1
  jauge = bas:ajouter(ui.jauge())
  jauge.largeurfixe = 220
  jauge.max = 1
  jauge.num = 0

  sep = fen:ajouter(ui.separateur{vertical = vrai, position = 0.6})
  sep.ancrage = "centre"

  && carte des concepts
  colcarte = sep:ajouter(ui.colonne())
  outils = colcarte:ajouter(ui.rangee())
  outils.marge = 6
  outils.espacement = 6
  outils:ajouter(ui.etiquette("Carte :"))
  filtre = outils:ajouter(ui.saisie{indication = "filtrer les concepts, Entrée : chercher les passages"})
  filtre.poids = 1
  filtre.surchangement = @FILTRER_CARTE
  filtre.surtouchebas = @TOUCHE_FILTRE
  outils:ajouter(ui.etiquette("Concepts :"))
  nbconcepts = outils:ajouter(ui.compteur())
  nbconcepts.min = 10
  nbconcepts.max = 120
  nbconcepts.num = NB_CONCEPTS
  nbconcepts.largeurfixe = 70
  nbconcepts.surchangement = @CHANGER_NB_CONCEPTS
  bmoins = outils:ajouter(ui.bouton("-"))
  bmoins.largeurfixe = 34
  bmoins.infobulle = "Zoom arrière (Ctrl+molette)"
  bmoins.surclic = @ZOOM_MOINS
  bplus = outils:ajouter(ui.bouton("+"))
  bplus.largeurfixe = 34
  bplus.infobulle = "Zoom avant (Ctrl+molette)"
  bplus.surclic = @ZOOM_PLUS
  bajuster = outils:ajouter(ui.bouton("Ajuster"))
  bajuster.surclic = @AJUSTER_CARTE
  bdisposer = outils:ajouter(ui.bouton("Redisposer"))
  bdisposer.surclic = @REDISPOSER
  toilecarte = colcarte:ajouter(ui.toile{mode = "plateau"})
  toilecarte.poids = 1
  toilecarte.surselection = @CONCEPT_CLIQUE
  toilecarte.surchangement = @CARTE_MODIFIEE
  legende = colcarte:ajouter(ui.etiquette("Taille : poids du concept · trait : concepts cités ensemble · orange : apparu avec le dernier document · glisser : déplacer · Ctrl+molette : zoom"))
  legende.couleur = "#8A8F98"
  PREPARER_CARTE()

  && panneaux de droite
  onglets = sep:ajouter(ui.onglets())
  pq = onglets:ajouterpage("Question")
  rq = pq:ajouter(ui.rangee())
  rq.espacement = 6
  question = rq:ajouter(ui.saisie{indication = "Posez une question sur le corpus…"})
  question.poids = 1
  question.surtouchebas = @TOUCHE_QUESTION
  brepondre = rq:ajouter(ui.bouton("Répondre"))
  brepondre.surclic = @REPONDRE
  avecmodele = pq:ajouter(ui.cases(sisinon(CHEMIN_MODELE = "", ;
    "Modèle de langage local absent (aucun .gguf trouvé : NIMLLM_MODEL ou models/)", 
    "Rédiger la réponse avec le modèle local " + fichier.nom(CHEMIN_MODELE))))
  reponse = pq:ajouter(ui.markdown("Posez une question : les passages les plus pertinents sont retrouvés dans l'index, puis la réponse est composée à partir d'eux, avec ses sources."))
  reponse.poids = 1
  reponse.surselection = @LIEN_CLIQUE

  pc = onglets:ajouterpage("Concept")
  ficheconcept = pc:ajouter(ui.markdown("Cliquez un concept de la carte."))
  ficheconcept.poids = 1
  ficheconcept.surselection = @LIEN_CLIQUE

  pp = onglets:ajouterpage("Passages")
  tpassages = pp:ajouter(ui.tableau())
  tpassages:ajoutercolonne("Score", 60, "droite")
  tpassages:ajoutercolonne("Document", 230)
  tpassages:ajoutercolonne("N°", 40, "droite")
  tpassages.hauteurfixe = 220
  tpassages.surselection = @PASSAGE_CHOISI
  apercu = pp:ajouter(ui.markdown(""))
  apercu.poids = 1
  apercu.surselection = @LIEN_CLIQUE

  pd = onglets:ajouterpage("Documents")
  tdocs = pd:ajouter(ui.tableau())
  tdocs:ajoutercolonne("Document", 230)
  tdocs:ajoutercolonne("Type", 76)
  tdocs:ajoutercolonne("Langue", 54)
  tdocs:ajoutercolonne("Passages", 66, "droite")
  tdocs:ajoutercolonne("Mots-clés", 300)
  tdocs.poids = 1
  tdocs.surselection = @DOCUMENT_CHOISI
  fichedoc = pd:ajouter(ui.markdown(""))
  fichedoc.hauteurfixe = 230
  fichedoc.surselection = @LIEN_CLIQUE

  pj = onglets:ajouterpage("Journal")
  journal = pj:ajouter(ui.liste())
  journal.poids = 1

  MODELE_INIT()
  REMPLIR_DOCUMENTS()
  CALCULER_CARTE()
  NOTER("Dossier de travail : " + DOSSIER)
  NOTER(sisinon(idx = nul, "Lucene indisponible (" + lucene.erreur() + ") : recherche en mémoire.", ;
                "Index : " + lucene.version() + ", " + idx:nombre() + " passage(s)."))
  MAJ_ETAT()
  ui.minuterie(1200, @SURVEILLER)
  ui.minuterie(300, @COLLECTER)
  question:focus()
retourner

&&
&& utilitaires
&&

procedure NOTER(msg)
  journal:ajouter(heure() + "  " + msg)
  journal:selectionner(journal:nombre())
retourner

procedure MAJ_ETAT
  locale s = chaine(nbelements(DOCS)) + " document(s), " + #PASSAGES + " passage(s)"
  si #FILE > 0
    s = s + " · " + #FILE + " à analyser"
  finsi
  si #COLLECTE > 0 ou COLLECTE_EN_COURS
    s = s + " · collecte : " + COLLECTE_FAITS + " / " + COLLECTE_TOTAL
  finsi
  etat.libelle = s
  si COLLECTE_TOTAL > 0
    jauge.max = COLLECTE_TOTAL
    jauge.num = COLLECTE_FAITS
  sinon
    jauge.max = 1
    jauge.num = 0
  finsi
retourner

&& Entrée (ou Entrée du pavé numérique) dans les champs de saisie.
fonction ENTREE(ev)
retourner ev.touche = 13 ou ev.touche = 1073741912

procedure TOUCHE_SUJET(ev)
  si ENTREE(ev)
    RECHERCHER_WEB()
  finsi
retourner

procedure TOUCHE_FILTRE(ev)
  si ENTREE(ev)
    CHERCHER_DEPUIS_CARTE()
  finsi
retourner

procedure TOUCHE_QUESTION(ev)
  si ENTREE(ev)
    REPONDRE()
  finsi
retourner

&& Page des onglets de droite : 1 Question, 2 Concept, 3 Passages, 4 Documents, 5 Journal.
procedure PAGE(i)
  onglets.valeur = chaine(i)
retourner

&& Titre court d'un document (chemin du corpus).
fonction TITRE_DE(chemin)
  locale d = DOCS[chemin]
  si d = nul
    retourner fichier.nom(chemin)
  finsi
retourner d.titre

&& Lien Markdown vers l'origine d'un document : son adresse web, sinon le fichier.
fonction LIEN_DE(chemin)
  locale d = DOCS[chemin]
  si d <> nul et d.adresse <> nul et d.adresse <> ""
    retourner "[" + d.titre + "](" + d.adresse + ")"
  finsi
retourner "[" + TITRE_DE(chemin) + "](fichier:" + url(fichier.nom(chemin)) + ")"

&& Lien cliqué dans une fiche : adresse web (navigateur), fichier du corpus
&& (fiche du document) ou concept de la carte.
procedure LIEN_CLIQUE(ev)
  locale cible = ev.texte
  si cible = nul ou cible = ""
    retourner
  finsi
  faire cas
  cas commencepar(cible, "concept:")
    CHOISIR_CONCEPT(http.decoder(souschaine(cible, 9)))
  cas commencepar(cible, "fichier:")
    MONTRER_DOCUMENT(fichier.joindre(CORPUS, http.decoder(souschaine(cible, 9))))
  autrement
    OUVRIR_EXTERNE(cible)
  fincas
retourner

procedure OUVRIR_EXTERNE(cible)
  locale p = systeme.plateforme()
  faire cas
  cas p = "windows"
    systeme.executer("start \"\" \"" + cible + "\"")
  cas p = "macosx"
    systeme.executer("open \"" + cible + "\"")
  autrement
    systeme.executer("xdg-open \"" + cible + "\" >/dev/null 2>&1 &")
  fincas
retourner

procedure OUVRIR_DOSSIER(ev)
  OUVRIR_EXTERNE(CORPUS)
retourner

&& Ajoute des fichiers au corpus : ils sont copiés, la surveillance fait le reste.
procedure AJOUTER_DOCUMENTS(ev)
  locale p = ui.ouvrirfichier{titre = "Ajouter un document au corpus", ;
                              filtre = "Documents|*.txt;*.md;*.markdown;*.pdf;*.html;*.htm|Tous les fichiers|*"}
  si p = nul
    retourner
  finsi
  locale dest = fichier.joindre(CORPUS, fichier.nom(p))
  fichier.copier(p, dest)
  NOTER("Ajouté au corpus : " + fichier.nom(p))
retourner

procedure FERMETURE(ev)
  ENREGISTRER_ETAT()
  si idx <> nul
    idx:fermer()
  finsi
retourner
