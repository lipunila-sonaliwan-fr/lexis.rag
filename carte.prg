&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Veille documentaire : la carte des concepts.
&&
&& document.concepts() extrait les termes caractéristiques des passages (mots
&& et expressions) et les relie quand ils apparaissent dans les mêmes passages ;
&& document.disposer() les place par forces, en gardant les positions connues :
&& la carte grandit au fil des documents sans être chamboulée.
&&
&& Dessin sur une toile en mode « plateau » : chaque concept est un groupe
&& (disque + libellé) que l'on clique ou que l'on fait glisser ; les liens sont
&& sur un calque en dessous. Les mises à jour sont incrémentales (formes
&& ajoutées, modifiées, retirées) : la vue (zoom, défilement) est conservée.

procedure PREPARER_CARTE
  toilecarte:dimensions(LARGEUR_CARTE, HAUTEUR_CARTE)
  toilecarte:fond("#FBFBFD")
  toilecarte:calque("liens")
  toilecarte:calque("concepts")
retourner

fonction RAYON(x)
retourner 9 + 24 * x.poids

fonction COULEUR(poids)
  locale palette = {"#BFDBFE", "#93C5FD", "#60A5FA", "#3B82F6", "#2563EB", "#1D4ED8"}
retourner palette[1 + entier(min(poids, 0.999) * #palette)]

fonction TAILLE_TEXTE(x)
retourner arrondi(11 + 7 * x.poids)

&& Calcule la carte à partir de tous les passages, puis la dessine.
procedure CALCULER_CARTE
  globale CONCEPTS_CARTE, CARTE_A_REFAIRE, DERNIER_CALCUL, NOUVEAUX, PAR_CLE
  CARTE_A_REFAIRE = faux
  DERNIER_CALCUL = systeme.horloge()
  si #PASSAGES = 0
    CONCEPTS_CARTE = {concepts = {}, liens = {}}
    PAR_CLE = {}
    DESSINER_CARTE()
    retourner
  finsi
  locale c = document.concepts(PASSAGES, {max = NB_CONCEPTS, liens = 4})
  && concepts apparus depuis la carte précédente (bord orange)
  NOUVEAUX = {}
  si nbelements(FORMES) > 0
    pour chaque x dans c.concepts
      si non FORMES[x.cle]
        NOUVEAUX[x.cle] = vrai
      finsi
    suivant
  finsi
  CONCEPTS_CARTE = c
  PAR_CLE = {}
  && disposition dans la zone utile de la planche (marges pour les disques et
  && les libellés) ; les positions connues sont gardées
  locale mx = 100, my = 45
  locale noeuds = {}
  pour chaque x dans c.concepts
    PAR_CLE[x.cle] = x
    locale n = {id = x.cle, taille = RAYON(x)}
    si POS[x.cle] <> nul
      n.x = POS[x.cle].x - mx
      n.y = POS[x.cle].y - my
    finsi
    inserer(noeuds, n)
  suivant
  locale places = document.disposer(noeuds, c.liens, {largeur = LARGEUR_CARTE - 2 * mx, hauteur = HAUTEUR_CARTE - my - 75})
  pour chaque k, v dans places
    POS[k] = {x = v.x + mx, y = v.y + my}
  suivant
  DESSINER_CARTE()
retourner

procedure DESSINER_CARTE
  globale LIENS_DESSINES, CARTE_AJUSTEE
  locale c = CONCEPTS_CARTE
  && concepts disparus
  locale partis = {}
  locale cles = clefs(FORMES)
  pour chaque k dans cles
    si PAR_CLE[k] = nul
      inserer(partis, "n:" + k)
      inserer(partis, "t:" + k)
      FORMES[k] = nul
    finsi
  suivant
  si #partis > 0
    toilecarte:supprimer(partis)
  finsi
  && liens : redessinés à chaque fois (ils changent avec les cooccurrences)
  si #LIENS_DESSINES > 0
    toilecarte:supprimer(LIENS_DESSINES)
  finsi
  LIENS_DESSINES = {}
  pour chaque l dans c.liens
    locale a = POS[l.a]
    locale b = POS[l.b]
    si a <> nul et b <> nul
      locale id = "l:" + l.a + "|" + l.b
      toilecarte:ajouter{genre = "ligne", id = id, x = a.x, y = a.y, largeur = b.x - a.x, hauteur = b.y - a.y, ;
                         contour = "#94A3B8", epaisseur = 0.6 + 3 * l.poids, opacite = 0.55, ;
                         calque = "liens", selectionner = faux}
      inserer(LIENS_DESSINES, id)
    finsi
  suivant
  pour chaque x dans c.concepts
    DESSINER_CONCEPT(x)
  suivant
  APPLIQUER_STYLES()
  si non CARTE_AJUSTEE et #c.concepts > 0
    toilecarte:ajuster()
    CARTE_AJUSTEE = vrai
  finsi
retourner

procedure DESSINER_CONCEPT(x)
  locale r = RAYON(x)
  locale p = POS[x.cle]
  si p = nul
    retourner
  finsi
  si FORMES[x.cle]
    toilecarte:modifier("n:" + x.cle, {x = p.x - r, y = p.y - r, largeur = 2 * r, hauteur = 2 * r, ;
                                       remplissage = COULEUR(x.poids)})
    toilecarte:modifier("t:" + x.cle, {x = p.x - 90, y = p.y + r + 2, taille = TAILLE_TEXTE(x), gras = x.poids > 0.5})
  sinon
    toilecarte:ajouter{genre = "ellipse", id = "n:" + x.cle, groupe = "c:" + x.cle, calque = "concepts", ;
                       x = p.x - r, y = p.y - r, largeur = 2 * r, hauteur = 2 * r, ;
                       remplissage = COULEUR(x.poids), contour = "#FFFFFF", epaisseur = 1.5, selectionner = faux}
    toilecarte:ajouter{genre = "texte", id = "t:" + x.cle, groupe = "c:" + x.cle, calque = "concepts", ;
                       texte = x.terme, x = p.x - 90, y = p.y + r + 2, largeur = 180, alignement = "centre", ;
                       taille = TAILLE_TEXTE(x), gras = x.poids > 0.5, remplissage = "#1F2937", selectionner = faux}
    FORMES[x.cle] = vrai
  finsi
retourner

&& Mise en évidence : concept choisi et ses voisins, sinon concepts surlignés
&& (recherche, question, document), sinon concepts du filtre ; le reste pâlit.
procedure APPLIQUER_STYLES
  locale c = CONCEPTS_CARTE
  si c = nul ou #c.concepts = 0
    retourner
  finsi
  locale vifs = nul
  si CHOISI <> "" et PAR_CLE[CHOISI] <> nul
    vifs = {}
    vifs[CHOISI] = vrai
    pour chaque l dans c.liens
      si l.a = CHOISI
        vifs[l.b] = vrai
      sinonsi l.b = CHOISI
        vifs[l.a] = vrai
      finsi
    suivant
  sinonsi nbelements(SURLIGNES) > 0
    vifs = SURLIGNES
  sinonsi FILTRE_TEXTE <> ""
    vifs = {}
    locale fk = document.cle(FILTRE_TEXTE)
    pour chaque x dans c.concepts
      si contient(minuscule(x.terme), FILTRE_TEXTE) ou contient(x.cle, fk)
        vifs[x.cle] = vrai
      finsi
    suivant
  finsi
  locale clairs = {}, pales = {}, neufs = {}, normaux = {}
  pour chaque x dans c.concepts
    si vifs = nul ou vifs[x.cle]
      inserer(clairs, "n:" + x.cle)
      inserer(clairs, "t:" + x.cle)
    sinon
      inserer(pales, "n:" + x.cle)
      inserer(pales, "t:" + x.cle)
    finsi
    si x.cle = CHOISI
      && traité à part
    sinonsi NOUVEAUX[x.cle]
      inserer(neufs, "n:" + x.cle)
    sinon
      inserer(normaux, "n:" + x.cle)
    finsi
  suivant
  locale lclairs = {}, lpales = {}
  pour chaque l dans c.liens
    si vifs = nul ou (vifs[l.a] et vifs[l.b])
      inserer(lclairs, "l:" + l.a + "|" + l.b)
    sinon
      inserer(lpales, "l:" + l.a + "|" + l.b)
    finsi
  suivant
  MODIFIER_SI(clairs, {opacite = 1})
  MODIFIER_SI(pales, {opacite = 0.15})
  MODIFIER_SI(lclairs, {opacite = 0.55})
  MODIFIER_SI(lpales, {opacite = 0.05})
  MODIFIER_SI(normaux, {contour = "#FFFFFF", epaisseur = 1.5})
  MODIFIER_SI(neufs, {contour = "#F97316", epaisseur = 3.5})
  si CHOISI <> "" et PAR_CLE[CHOISI] <> nul
    toilecarte:modifier("n:" + CHOISI, {contour = "#DC2626", epaisseur = 4})
  finsi
retourner

procedure MODIFIER_SI(ids, props)
  si #ids > 0
    toilecarte:modifier(ids, props)
  finsi
retourner

&&
&& interactions
&&

procedure CONCEPT_CLIQUE(ev)
  globale CHOISI
  locale s = ev.texte ou ""
  si commencepar(s, "c:")
    CHOISIR_CONCEPT(souschaine(s, 3))
  sinonsi s = ""
    CHOISI = ""
    APPLIQUER_STYLES()
  finsi
retourner

&& Un concept glissé : sa position est gardée, ses liens suivent.
procedure CARTE_MODIFIEE(ev)
  locale a = toilecarte:action()
  si a = nul ou non commencepar(a.action, "deplace")
    retourner
  finsi
  si commencepar(a.action, "deplace:c:")
    locale cle = souschaine(a.action, 11)
    locale f = toilecarte:forme("n:" + cle)
    si f <> nul
      POS[cle] = {x = f.x + f.largeur / 2, y = f.y + f.hauteur / 2}
    finsi
  finsi
  RELIER()
retourner

&& Replace les extrémités des liens sur les centres des concepts.
procedure RELIER
  si CONCEPTS_CARTE = nul
    retourner
  finsi
  pour chaque l dans CONCEPTS_CARTE.liens
    locale a = POS[l.a]
    locale b = POS[l.b]
    si a <> nul et b <> nul
      toilecarte:modifier("l:" + l.a + "|" + l.b, {x1 = a.x, y1 = a.y, x2 = b.x, y2 = b.y})
    finsi
  suivant
retourner

procedure CHOISIR_CONCEPT(cle)
  globale CHOISI, SURLIGNES
  locale x = PAR_CLE[cle]
  si x = nul
    && concept cité ailleurs (mot-clé d'un document) mais absent de la carte
    filtre.valeur = cle
    CHERCHER_DEPUIS_CARTE()
    retourner
  finsi
  CHOISI = cle
  SURLIGNES = {}
  toilecarte:selectionner("groupe:c:" + cle)
  APPLIQUER_STYLES()
  locale md = "### " + x.terme + NL + NL
  md = md + "Poids " + arrondi(x.poids, 2) + " · " + x.frequence + " occurrence(s) · " + x.passages + " passage(s)" + NL + NL
  && concepts liés, du plus fort au plus faible
  locale voisins = {}
  pour chaque l dans CONCEPTS_CARTE.liens
    si l.a = cle et PAR_CLE[l.b] <> nul
      inserer(voisins, {cle = l.b, poids = l.poids, nombre = l.nombre})
    sinonsi l.b = cle et PAR_CLE[l.a] <> nul
      inserer(voisins, {cle = l.a, poids = l.poids, nombre = l.nombre})
    finsi
  suivant
  trier(voisins, @LIEN_PLUS_FORT)
  si #voisins > 0
    locale vl = {}
    pour chaque v dans voisins
      inserer(vl, "[" + PAR_CLE[v.cle].terme + "](concept:" + url(v.cle) + ") (" + v.nombre + ")")
    suivant
    md = md + "**Concepts liés :** " + joindre(vl, " · ") + NL + NL
  finsi
  && documents qui le contiennent
  md = md + "**Documents :**" + NL + NL
  pour chaque s dans x.sources
    md = md + "- " + LIEN_DE(s) + NL
  suivant
  && passages : recherche de l'expression exacte dans l'index
  locale res = CHERCHER_PASSAGES(x.terme, 12, vrai)
  REMPLIR_PASSAGES(res, x.terme)
  locale textes = {}
  pour chaque p dans res
    inserer(textes, {texte = p.texte, source = p.source})
  suivant
  locale ex = document.extraits(textes, x.terme, 4)
  si #ex > 0
    md = md + NL + "**En contexte :**" + NL + NL
    pour chaque e dans ex
      md = md + "> " + e.phrase + NL + ">" + NL + "> — " + LIEN_DE(e.source) + NL + NL
    suivant
  finsi
  ficheconcept.valeur = md
  PAGE(2)
  etat.libelle = "Concept « " + x.terme + " » : " + #voisins + " concept(s) lié(s), " + #x.sources + " document(s)"
retourner

fonction LIEN_PLUS_FORT(a, b)
retourner a.poids > b.poids

&& Filtre pendant la frappe : les concepts qui correspondent restent vifs.
procedure FILTRER_CARTE(ev)
  globale FILTRE_TEXTE, CHOISI, SURLIGNES
  FILTRE_TEXTE = minuscule(rogner(filtre.valeur))
  CHOISI = ""
  SURLIGNES = {}
  toilecarte:selectionner()
  APPLIQUER_STYLES()
retourner

&& Entrée dans le filtre : recherche des passages, concepts de ces passages surlignés.
procedure CHERCHER_DEPUIS_CARTE(ev)
  locale q = rogner(filtre.valeur)
  si q = ""
    retourner
  finsi
  locale res = CHERCHER_PASSAGES(q, 30)
  REMPLIR_PASSAGES(res, q)
  SURLIGNER_PASSAGES(res)
  PAGE(3)
  etat.libelle = #res + " passage(s) pour « " + q + " »" + sisinon(idx <> nul, " (Lucene : " + idx:analyser(REQUETE_LIBRE(q)) + ")", "")
retourner

&& Concepts présents dans une liste de passages.
procedure SURLIGNER_PASSAGES(res)
  globale SURLIGNES, CHOISI
  SURLIGNES = {}
  CHOISI = ""
  toilecarte:selectionner()
  si CONCEPTS_CARTE = nul
    retourner
  finsi
  pour chaque p dans res
    locale tous = " " + CLES_TEXTE(document.mots(p.texte, vrai)) + " "
    locale pleins = " " + CLES_TEXTE(document.mots(p.texte)) + " "
    pour chaque x dans CONCEPTS_CARTE.concepts
      si contient(tous, " " + x.cle + " ") ou contient(pleins, " " + x.cle + " ")
        SURLIGNES[x.cle] = vrai
      finsi
    suivant
  suivant
  APPLIQUER_STYLES()
retourner

fonction CLES_TEXTE(mots)
  locale l = {}
  pour chaque m dans mots
    inserer(l, document.cle(m))
  suivant
retourner joindre(l, " ")

&& Concepts d'un document.
procedure SURLIGNER_DOCUMENT(chemin)
  globale SURLIGNES, CHOISI
  SURLIGNES = {}
  CHOISI = ""
  toilecarte:selectionner()
  si CONCEPTS_CARTE = nul
    retourner
  finsi
  pour chaque x dans CONCEPTS_CARTE.concepts
    si contient(x.sources, chemin)
      SURLIGNES[x.cle] = vrai
    finsi
  suivant
  APPLIQUER_STYLES()
retourner

procedure ZOOM_PLUS(ev)
  toilecarte:zoom(toilecarte:zoom() * 1.25)
retourner

procedure ZOOM_MOINS(ev)
  toilecarte:zoom(toilecarte:zoom() / 1.25)
retourner

procedure AJUSTER_CARTE(ev)
  toilecarte:ajuster()
retourner

&& Nouvelle disposition complète (les positions mémorisées sont oubliées).
procedure REDISPOSER(ev)
  globale POS
  POS = {}
  CALCULER_CARTE()
  toilecarte:ajuster()
retourner

procedure CHANGER_NB_CONCEPTS(ev)
  globale NB_CONCEPTS
  locale n = entier(nbconcepts.num)
  si n = NB_CONCEPTS
    retourner
  finsi
  NB_CONCEPTS = n
  CALCULER_CARTE()
retourner
