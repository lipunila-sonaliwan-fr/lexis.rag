&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Veille documentaire : recherche automatisée sur Internet.
&&
&& Un sujet devient une file de travaux, traités un par un par une minuterie
&& (l'interface reste réactive pendant les téléchargements) :
&&   wiki      recherche Wikipédia (API) → une page « wikipage » par résultat ;
&&   wikipage  texte de l'article (extrait brut) → corpus/wikipedia_<titre>.md ;
&&   web       recherche DuckDuckGo (page HTML) → une « page » par résultat ;
&&   page      téléchargement : HTML → texte principal → corpus/web_<titre>.md,
&&             PDF → corpus/web_<titre>.pdf, texte → .txt.
&& Les fichiers écrits dans le corpus sont ensuite analysés par la surveillance
&& (analyse.prg), comme ceux que l'on dépose à la main.

&& Bouton « Rechercher sur Internet » (ou Entrée dans le sujet).
procedure RECHERCHER_WEB(ev)
  locale q = rogner(sujet.valeur)
  si q = ""
    ui.alerte("Indiquez un sujet de recherche, ou des adresses http(s).", "info", "Veille documentaire")
    retourner
  finsi
  locale n = entier(nbpages.num)
  && des adresses : téléchargées directement
  si commencepar(q, "http://") ou commencepar(q, "https://")
    pour chaque a dans decouper(q, " ")
      si commencepar(a, "http")
        AJOUTER_TRAVAIL({genre = "page", adresse = a})
      finsi
    suivant
    retourner
  finsi
  locale s = source:selection()
  si s = 1 ou s = 3
    AJOUTER_TRAVAIL({genre = "wiki", sujet = q, n = n, langue = "fr"})
  finsi
  si s = 2 ou s = 3
    AJOUTER_TRAVAIL({genre = "web", sujet = q, n = n})
  finsi
  NOTER("Recherche lancée : « " + q + " » (" + source:element(s) + ", " + n + " page(s))")
retourner

procedure AJOUTER_TRAVAIL(t)
  globale COLLECTE_TOTAL
  inserer(COLLECTE, t)
  COLLECTE_TOTAL += 1
  MAJ_ETAT()
retourner

&& Minuterie : un travail à la fois.
procedure COLLECTER(ev)
  globale COLLECTE_EN_COURS, COLLECTE_FAITS, COLLECTE_TOTAL
  si COLLECTE_EN_COURS ou #COLLECTE = 0
    retourner
  finsi
  COLLECTE_EN_COURS = vrai
  locale t = retirer(COLLECTE, 1)
  essayer
    faire cas
    cas t.genre = "wiki"
      COLLECTER_WIKI(t)
    cas t.genre = "wikipage"
      COLLECTER_WIKIPAGE(t)
    cas t.genre = "web"
      COLLECTER_WEB(t)
    cas t.genre = "page"
      COLLECTER_PAGE(t)
    fincas
  capturer e
    NOTER("Collecte : " + e)
  finessayer
  COLLECTE_FAITS += 1
  si #COLLECTE = 0
    NOTER("Collecte terminée : " + COLLECTE_FAITS + " travau(x).")
    COLLECTE_TOTAL = 0
    COLLECTE_FAITS = 0
  finsi
  COLLECTE_EN_COURS = faux
  MAJ_ETAT()
retourner

&& GET avec un délai ; erreur si le serveur ne répond pas 2xx.
fonction OBTENIR(adresse)
  locale h = {}
  h["User-Agent"] = AGENT
  h["Accept-Language"] = "fr,en;q=0.8"
  locale r = http.requete{url = adresse, entetes = h, delai = 20}
  si r.statut < 200 ou r.statut >= 300
    erreur adresse + " : " + r.statut + " " + r.raison
  finsi
retourner r

&& Adresse déjà collectée (dans cette session ou une précédente) ?
fonction DEJA_COLLECTEE(adresse)
  pour chaque nom, a dans SOURCES_WEB
    si a = adresse
      retourner vrai
    finsi
  suivant
retourner faux

&& Nom de fichier lisible et sûr à partir d'un titre.
fonction NOM_FICHIER(prefixe, titre, ext)
  locale accents = {{"àâäá", "a"}, {"éèêë", "e"}, {"îïí", "i"}, {"ôöó", "o"}, {"ùûüú", "u"}, {"ç", "c"}, {"ÿ", "y"}, {"ñ", "n"}}
  locale mots = {}
  pour chaque m dans document.mots(titre, vrai)
    locale propre = ""
    pour i = 1 a longueur(m)
      locale c = souschaine(m, i, 1)
      pour chaque a dans accents
        si contient(a[1], c)
          c = a[2]
        finsi
      suivant
      si c = "œ"
        c = "oe"
      finsi
      si (c >= "a" et c <= "z") ou (c >= "0" et c <= "9") ou c = "oe"
        propre = propre + c
      finsi
    suivant
    si propre <> ""
      inserer(mots, propre)
    finsi
  suivant
  locale racine = gauche(joindre(mots, "_"), 60)
  si racine = ""
    racine = "page"
  finsi
  locale nom = prefixe + "_" + racine + ext
  locale i = 2
  tantque fichier.existe(fichier.joindre(CORPUS, nom))
    nom = prefixe + "_" + racine + "_" + i + ext
    i += 1
  fintantque
retourner nom

&& Écrit un document Markdown collecté dans le corpus.
procedure ECRIRE_DOCUMENT(prefixe, titre, adresse, corps)
  locale nom = NOM_FICHIER(prefixe, titre, ".md")
  SOURCES_WEB[nom] = adresse
  fichier.ecrire(fichier.joindre(CORPUS, nom), "# " + titre + NL + NL + "Source : " + adresse + NL + NL + corps + NL)
  NOTER("Collecté : " + titre + " → " + nom)
retourner

&&
&& Wikipédia
&&

procedure COLLECTER_WIKI(t)
  locale api = "https://" + t.langue + ".wikipedia.org/w/api.php?"
  locale r = OBTENIR(api + "action=query&list=search&format=json&utf8=1&srlimit=" + t.n + ;
                     "&srsearch=" + http.encoder(t.sujet))
  locale res = json.decoder(r.corps)
  locale trouves = res.query.search ou {}
  si #trouves = 0 et t.langue = "fr"
    && rien en français : on tente l'anglais
    AJOUTER_TRAVAIL({genre = "wiki", sujet = t.sujet, n = t.n, langue = "en"})
    retourner
  finsi
  NOTER("Wikipédia (" + t.langue + ") : " + #trouves + " article(s) pour « " + t.sujet + " »")
  pour chaque a dans trouves
    AJOUTER_TRAVAIL({genre = "wikipage", titre = a.title, langue = t.langue})
  suivant
retourner

procedure COLLECTER_WIKIPAGE(t)
  locale adresse = "https://" + t.langue + ".wikipedia.org/wiki/" + http.encoder(remplacertexte(t.titre, " ", "_"))
  si DEJA_COLLECTEE(adresse)
    NOTER("Déjà dans le corpus : " + t.titre)
    retourner
  finsi
  locale r = OBTENIR("https://" + t.langue + ".wikipedia.org/w/api.php?action=query&prop=extracts" + ;
                     "&explaintext=1&exsectionformat=wiki&redirects=1&format=json&utf8=1&titles=" + http.encoder(t.titre))
  locale res = json.decoder(r.corps)
  locale extrait = ""
  pour chaque id, pg dans res.query.pages ou {}
    extrait = pg.extract ou ""
  suivant
  si longueur(extrait) < 300
    NOTER("Article trop court, ignoré : " + t.titre)
    retourner
  finsi
  ECRIRE_DOCUMENT("wikipedia", t.titre, adresse, WIKI_VERS_MARKDOWN(extrait))
retourner

&& « == Section == » → « ## Section » ; sections vides de fin (Notes, Voir aussi…) retirées.
fonction WIKI_VERS_MARKDOWN(s)
  locale sortie = {}
  pour chaque l dans decouper(s, NL)
    locale x = rogner(l)
    si commencepar(x, "==") et finitpar(x, "==")
      locale niveau = 0
      tantque souschaine(x, niveau + 1, 1) = "="
        niveau += 1
      fintantque
      locale titre = rogner(remplacertexte(x, "=", ""))
      si contient({"Notes et références", "Notes", "Références", "Voir aussi", "Liens externes", ;
                   "Bibliographie", "Articles connexes", "See also", "References", "External links", ;
                   "Further reading", "Notes and references"}, titre)
        sortir
      finsi
      inserer(sortie, "")
      inserer(sortie, repliquer("#", min(niveau, 4)) + " " + titre)
      inserer(sortie, "")
    sinon
      inserer(sortie, l)
    finsi
  suivant
retourner joindre(sortie, NL)

&&
&& Web (DuckDuckGo, version HTML sans JavaScript)
&&

procedure COLLECTER_WEB(t)
  locale r = OBTENIR("https://html.duckduckgo.com/html/?kl=fr-fr&q=" + http.encoder(t.sujet))
  locale liens = LIENS_DUCKDUCKGO(r.corps)
  locale n = 0
  pour chaque a dans liens
    si n >= t.n
      sortir
    finsi
    si non EXCLUE(a) et non DEJA_COLLECTEE(a)
      AJOUTER_TRAVAIL({genre = "page", adresse = a})
      n += 1
    finsi
  suivant
  NOTER("Web : " + #liens + " résultat(s), " + n + " page(s) à télécharger pour « " + t.sujet + " »")
retourner

&& Les résultats pointent vers //duckduckgo.com/l/?uddg=<adresse encodée>&rut=…
fonction LIENS_DUCKDUCKGO(page)
  locale liens = {}
  locale reste = page
  locale p = position("uddg=", reste)
  tantque p > 0
    reste = souschaine(reste, p + 5)
    locale fin = longueur(reste) + 1
    pour chaque marque dans {"&", "\"", "'"}
      locale q = position(marque, reste)
      si q > 0 et q < fin
        fin = q
      finsi
    suivant
    locale a = http.decoder(gauche(reste, fin - 1))
    si commencepar(a, "http") et non contient(liens, a)
      inserer(liens, a)
    finsi
    p = position("uddg=", reste)
  fintantque
retourner liens

fonction EXCLUE(a)
  locale m = minuscule(a)
  pour chaque d dans DOMAINES_EXCLUS
    si contient(m, d)
      retourner vrai
    finsi
  suivant
retourner faux

&&
&& une page web : HTML, PDF ou texte
&&

procedure COLLECTER_PAGE(t)
  si DEJA_COLLECTEE(t.adresse)
    NOTER("Déjà dans le corpus : " + t.adresse)
    retourner
  finsi
  locale r = OBTENIR(t.adresse)
  locale ct = minuscule(r.entetes["content-type"] ou "")
  locale chemin = minuscule(decouper(t.adresse, "?")[1])
  faire cas
  cas contient(ct, "pdf") ou finitpar(chemin, ".pdf")
    locale titre = decouper(fichier.nom(chemin), ".")[1]
    locale nom = NOM_FICHIER("web", titre, ".pdf")
    SOURCES_WEB[nom] = t.adresse
    fichier.ecrireoctets(fichier.joindre(CORPUS, nom), r.corps)
    NOTER("Collecté (PDF, " + arrondi(longueur(r.corps) / 1024) + " Ko) : " + t.adresse + " → " + nom)
  cas contient(ct, "html") ou ct = ""
    locale h = document.html(r.corps, t.adresse)
    si longueur(h.texte) < 400
      NOTER("Page sans texte utile, ignorée : " + t.adresse)
      retourner
    finsi
    locale titre = rogner(h.titre ou "")
    si titre = ""
      titre = decouper(remplacertexte(remplacertexte(t.adresse, "https://", ""), "http://", ""), "/")[1]
    finsi
    ECRIRE_DOCUMENT("web", titre, t.adresse, h.texte)
  cas commencepar(ct, "text/")
    ECRIRE_DOCUMENT("web", fichier.nom(chemin), t.adresse, r.corps)
  autrement
    NOTER("Type non pris en charge (" + ct + ") : " + t.adresse)
  fincas
retourner
