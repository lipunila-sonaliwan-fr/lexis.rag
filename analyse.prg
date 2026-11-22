&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Veille documentaire : surveillance du corpus, analyse des documents au fil
&& de leurs ajouts, index des passages (Lucene, ou en mémoire), état sur disque.

&&
&& index
&&

procedure OUVRIR_INDEX
  globale idx
  si non lucene.disponible()
    idx = nul
    retourner
  finsi
  essayer
    idx = lucene.ouvrir(fichier.joindre(DOSSIER, "index"), ;
                        {analyseur = "francais", ;
                         schema = {id = "cle", source = "cle", numero = "entier", ;
                                   titre = "texte", texte = "texte"}})
  capturer e
    idx = nul
    retourner
  finessayer
  && index perdu ou désaccordé avec l'état : on le reconstruit depuis les passages
  si idx:nombre() <> #PASSAGES
    idx:vider()
    pour chaque p dans PASSAGES
      idx:ajouter({id = p.id, source = p.source, numero = p.numero, titre = p.titre, texte = p.texte})
    suivant
    idx:valider()
  finsi
retourner

&& Requête Lucene tolérante à partir d'un texte libre : les mots pleins,
&& reliés par OR (un passage n'a pas besoin de tous les contenir).
fonction REQUETE_LIBRE(q)
  locale mots = {}
  pour chaque m dans document.mots(q)
    m = remplacertexte(m, "-", " ")
    pour chaque c dans {"+", "!", "(", ")", "{", "}", "[", "]", "^", "\"", "~", "*", "?", ":", "\\", "/", "&", "|"}
      m = remplacertexte(m, c, " ")
    suivant
    pour chaque x dans decouper(m, " ")
      si longueur(x) > 1 et non contient(mots, x)
        inserer(mots, x)
      finsi
    suivant
  suivant
retourner joindre(mots, " OR ")

&& Passages les plus pertinents pour un texte : liste de {score, id, source, titre, numero, texte}.
&& exact = vrai : l'expression exacte (concept), avec repli sur les mots.
fonction CHERCHER_PASSAGES(q, n, exact)
  locale res = {}
  locale req = REQUETE_LIBRE(q)
  si exact et idx <> nul et contient(q, " ") et non contient(q, "\"")
    req = "\"" + q + "\" OR " + req
  finsi
  si req = ""
    retourner res
  finsi
  si idx <> nul
    locale r
    essayer
      r = idx:chercher(req, {max = n})
    capturer e
      NOTER("Requête refusée : " + e)
      retourner res
    finessayer
    pour chaque x dans r.resultats
      inserer(res, {score = x.score, id = x.document.id, source = x.document.source, ;
                    titre = x.document.titre, numero = x.document.numero, texte = x.document.texte})
    suivant
    retourner res
  finsi
  && en mémoire : termes de la question présents dans le passage, pondérés par leur rareté
  locale cles = {}
  pour chaque m dans document.mots(q)
    cles[document.cle(m)] = vrai
  suivant
  locale df = {}
  locale presents = {}
  pour i = 1 a #PASSAGES
    locale trouves = {}
    pour chaque m dans document.mots(PASSAGES[i].texte)
      locale k = document.cle(m)
      si cles[k] et non trouves[k]
        trouves[k] = vrai
        df[k] = (df[k] ou 0) + 1
      finsi
    suivant
    presents[i] = trouves
  suivant
  pour i = 1 a #PASSAGES
    locale sc = 0
    pour chaque k, v dans presents[i]
      sc = sc + log(1 + #PASSAGES / df[k])
    suivant
    si sc > 0
      locale p = PASSAGES[i]
      inserer(res, {score = sc, id = p.id, source = p.source, titre = p.titre, numero = p.numero, texte = p.texte})
    finsi
  suivant
  trier(res, @PLUS_PERTINENT)
  tantque #res > n
    retirer(res)
  fintantque
retourner res

fonction PLUS_PERTINENT(a, b)
retourner a.score > b.score

&&
&& surveillance du corpus
&&

&& Toutes les 1,2 s : fichiers nouveaux ou modifiés (taille stable entre deux
&& passages, pour ne pas lire un fichier en cours de copie), fichiers retirés,
&& puis analyse d'un document de la file.
procedure SURVEILLER(ev)
  globale ANALYSE_EN_COURS
  si ANALYSE_EN_COURS
    retourner
  finsi
  ANALYSE_EN_COURS = vrai
  essayer
    EXAMINER_CORPUS()
    si #FILE > 0
      ANALYSER(retirer(FILE, 1))
    sinonsi CARTE_A_REFAIRE
      CALCULER_CARTE()
    finsi
  capturer e
    NOTER("Erreur : " + e)
  finessayer
  ANALYSE_EN_COURS = faux
  MAJ_ETAT()
retourner

procedure EXAMINER_CORPUS
  locale presents = {}
  pour chaque n dans fichier.liste(CORPUS)
    si finitpar(n, "/") ou commencepar(n, ".")
      boucler
    finsi
    locale ext = minuscule(fichier.extension(n))
    si non commencepar(ext, ".")
      ext = "." + ext
    finsi
    si non contient(EXTENSIONS, ext)
      boucler
    finsi
    locale chemin = fichier.joindre(CORPUS, n)
    presents[chemin] = vrai
    locale inf = fichier.infos(chemin)
    si inf = nul
      boucler
    finsi
    locale d = DOCS[chemin]
    si d <> nul et d.taille = inf.taille et d.modifie = inf.modifie
      boucler
    finsi
    si VUS[chemin] = inf.taille et non contient(FILE, chemin)
      inserer(FILE, chemin)
    finsi
    VUS[chemin] = inf.taille
  suivant
  && documents retirés du dossier
  locale partis = {}
  pour chaque chemin, d dans DOCS
    si non presents[chemin]
      inserer(partis, chemin)
    finsi
  suivant
  pour chaque chemin dans partis
    RETIRER_PASSAGES(chemin)
    NOTER("Retiré : " + DOCS[chemin].titre)
    DOCS[chemin] = nul
    VUS[chemin] = nul
  suivant
  si #partis > 0
    INDEX_VALIDER()
    REMPLIR_DOCUMENTS()
    PLANIFIER_CARTE()
    ENREGISTRER_ETAT()
  finsi
retourner

procedure RETIRER_PASSAGES(chemin)
  globale PASSAGES
  locale garde = {}
  pour chaque p dans PASSAGES
    si p.source <> chemin
      inserer(garde, p)
    finsi
  suivant
  PASSAGES = garde
  si idx <> nul
    idx:supprimer("source", chemin)
  finsi
retourner

procedure INDEX_VALIDER
  si idx <> nul
    idx:valider()
  finsi
retourner

&& Analyse d'un document : texte, passages, index, mots-clés, carte.
procedure ANALYSER(chemin)
  locale t0 = systeme.horloge()
  locale inf = fichier.infos(chemin)
  si inf = nul
    retourner
  finsi
  locale nom = fichier.nom(chemin)
  locale d
  essayer
    d = document.lire(chemin)
  capturer e
    && document illisible (PDF scanné, chiffré…) : noté pour ne pas le relire
    DOCS[chemin] = {chemin = chemin, nom = nom, titre = nom, genre = "?", adresse = "", taille = inf.taille, ;
                    modifie = inf.modifie, passages = 0, mots = 0, langue = "", motscles = {}, ;
                    ajoute = entier(horodatage()), erreur = e}
    NOTER("Illisible : " + nom + " (" + e + ")")
    REMPLIR_DOCUMENTS()
    retourner
  finessayer
  locale titre = rogner(d.titre ou "")
  si titre = ""
    titre = nom
  finsi
  && adresse d'origine : téléchargement (collecte) ou ligne « Source : » en tête
  locale adresse = SOURCES_WEB[nom] ou ""
  locale p0 = position("Source : ", gauche(d.texte, 600))
  si adresse = "" et p0 > 0
    adresse = rogner(decouper(souschaine(d.texte, p0 + 9, 400), NL)[1])
  finsi
  RETIRER_PASSAGES(chemin)
  locale morceaux = document.decouper(d.texte, {taille = 900, chevauchement = 150})
  pour chaque m dans morceaux
    locale p = {id = chemin + "#" + m.numero, source = chemin, titre = titre, numero = m.numero, texte = m.texte}
    inserer(PASSAGES, p)
    si idx <> nul
      idx:ajouter({id = p.id, source = chemin, numero = m.numero, titre = titre, texte = m.texte})
    finsi
  suivant
  INDEX_VALIDER()
  locale kw = {}
  pour chaque k dans document.motscles(d.texte, 8)
    inserer(kw, k.terme)
  suivant
  locale neuf = DOCS[chemin] = nul
  DOCS[chemin] = {chemin = chemin, nom = nom, titre = titre, genre = d.type, adresse = adresse, ;
                  taille = inf.taille, modifie = inf.modifie, passages = #morceaux, mots = d.mots, ;
                  langue = d.langue, motscles = kw, ajoute = entier(horodatage()), erreur = ""}
  NOTER(sisinon(neuf, "Analysé : ", "Réanalysé : ") + titre + " (" + d.type + ", " + d.langue + ", " + ;
          #morceaux + " passages, " + arrondi((systeme.horloge() - t0) * 1000) + " ms) - " + joindre(kw, ", "))
  REMPLIR_DOCUMENTS()
  PLANIFIER_CARTE()
  ENREGISTRER_ETAT()
retourner

&& La carte suit les ajouts : recalculée après chaque document, au plus toutes
&& les 4 secondes pendant une collecte (et une fois la file vide).
procedure PLANIFIER_CARTE
  globale CARTE_A_REFAIRE
  si #FILE = 0 ou systeme.horloge() - DERNIER_CALCUL > 4
    CALCULER_CARTE()
  sinon
    CARTE_A_REFAIRE = vrai
  finsi
retourner

&&
&& tableau des documents
&&

fonction DOCS_ORDONNES()
  locale l = {}
  pour chaque chemin, d dans DOCS
    inserer(l, d)
  suivant
  trier(l, @PLUS_RECENT)
retourner l

fonction PLUS_RECENT(a, b)
retourner a.ajoute > b.ajoute

procedure REMPLIR_DOCUMENTS
  globale LISTE_DOCS
  LISTE_DOCS = DOCS_ORDONNES()
  tdocs:vider()
  pour chaque d dans LISTE_DOCS
    tdocs:ajouterligne(d.titre, d.genre, d.langue, chaine(d.passages), ;
                       sisinon(d.erreur <> "", "illisible : " + d.erreur, joindre(d.motscles, ", ")))
  suivant
retourner

procedure DOCUMENT_CHOISI(ev)
  locale i = tdocs:selection()
  si i < 1 ou i > #LISTE_DOCS
    retourner
  finsi
  MONTRER_DOCUMENT(LISTE_DOCS[i].chemin, faux)
retourner

procedure MONTRER_DOCUMENT(chemin, basculer)
  locale d = DOCS[chemin]
  si d = nul
    retourner
  finsi
  locale md = "### " + d.titre + NL + NL
  md = md + "- fichier : `" + d.nom + "` (" + d.genre + ", " + arrondi(d.taille / 1024, 1) + " Ko)" + NL
  si d.adresse <> ""
    md = md + "- source : [" + d.adresse + "](" + d.adresse + ")" + NL
  finsi
  md = md + "- langue : " + d.langue + ", " + d.mots + " mots, " + d.passages + " passages" + NL
  md = md + "- analysé le " + systeme.date("%d/%m/%Y à %H:%M", entier(d.ajoute)) + NL + NL
  si #d.motscles > 0
    md = md + "**Mots-clés :** "
    locale liens = {}
    pour chaque k dans d.motscles
      inserer(liens, "[" + k + "](concept:" + url(document.cle(k)) + ")")
    suivant
    md = md + joindre(liens, " · ") + NL + NL
  finsi
  && début du premier passage
  pour chaque p dans PASSAGES
    si p.source = chemin
      md = md + "> " + remplacertexte(gauche(p.texte, 600), NL, " ") + "…" + NL
      sortir
    finsi
  suivant
  fichedoc.valeur = md
  si basculer <> faux
    PAGE(4)
  finsi
  SURLIGNER_DOCUMENT(chemin)
retourner

&&
&& état sur disque
&&

procedure CHARGER_ETAT
  globale DOCS, PASSAGES, SOURCES_WEB, POS, NB_CONCEPTS
  POS = {}
  si non fichier.existe(FICHIER_ETAT)
    retourner
  finsi
  locale e
  essayer
    e = json.lire(FICHIER_ETAT, vrai)
  capturer err
    retourner
  finessayer
  pour chaque d dans e.documents ou {}
    DOCS[d.chemin] = {chemin = d.chemin, nom = d.nom, titre = d.titre, genre = d.genre, ;
                      adresse = d.adresse ou "", taille = d.taille, modifie = d.modifie, ;
                      passages = d.passages, mots = d.mots, langue = d.langue, ;
                      motscles = d.motscles ou {}, ajoute = d.ajoute, erreur = d.erreur ou ""}
  suivant
  pour chaque p dans e.passages ou {}
    inserer(PASSAGES, {id = p.id, source = p.source, titre = p.titre, numero = p.numero, texte = p.texte})
  suivant
  && clefs de données (noms de fichiers, concepts) : gardées telles quelles (json.lire exact)
  pour chaque k, v dans e.sources ou {}
    SOURCES_WEB[k] = v
  suivant
  pour chaque k, v dans e.positions ou {}
    POS[k] = {x = v.x, y = v.y}
  suivant
  NB_CONCEPTS = e.concepts ou NB_CONCEPTS
retourner

procedure ENREGISTRER_ETAT
  locale lignes = {}
  pour chaque chemin, d dans DOCS
    inserer(lignes, {chemin = d.chemin, nom = d.nom, titre = d.titre, genre = d.genre, adresse = d.adresse, ;
                   taille = d.taille, modifie = d.modifie, passages = d.passages, mots = d.mots, ;
                   langue = d.langue, motscles = d.motscles, ajoute = d.ajoute, erreur = d.erreur})
  suivant
  locale places = {}
  pour chaque k, v dans POS
    places[k] = {x = arrondi(v.x, 1), y = arrondi(v.y, 1)}
  suivant
  json.ecrire(FICHIER_ETAT, {documents = lignes, passages = PASSAGES, sources = SOURCES_WEB, ;
                             positions = places, concepts = NB_CONCEPTS}, faux)
retourner
