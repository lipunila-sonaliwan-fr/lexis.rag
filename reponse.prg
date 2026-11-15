&& CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2026
&& Veille documentaire : réponse aux questions (RAG).
&&
&&   1. récupération : les passages les plus pertinents (index Lucene) ;
&&   2. génération : sans modèle, réponse extractive (phrases des passages les
&&      plus proches de la question, document.extraits) ; avec un modèle GGUF
&&      local (paquet llm), réponse rédigée à partir des passages numérotés,
&&      affichée au fil de l'eau ;
&&   3. sources numérotées et concepts des passages surlignés sur la carte.

&& Modèle de langage : NIMLLM_MODEL, sinon le premier .gguf de models/ (dépôt)
&& ou du dossier de travail.
fonction TROUVER_MODELE()
  locale m = systeme.env("NIMLLM_MODEL")
  si m <> nul et fichier.existe(m)
    retourner m
  finsi
  
  pour chaque d dans { fichier.joindre(systeme.dossierprogramme(), "models"), fichier.joindre(systeme.dossierprogramme(), "..", "..", "..", "models"), DOSSIER}
    si fichier.estdossier(d)
      pour chaque n dans fichier.liste(d)
        si finitpar(minuscule(n), ".gguf")
          retourner fichier.joindre(d, n)
        finsi
      suivant
    finsi
  suivant
retourner ""

procedure MODELE_INIT
  si CHEMIN_MODELE = ""
    avecmodele.actif = faux
    NOTER("Aucun modèle .gguf (NIMLLM_MODEL ou models/) : réponses extractives.")
  sinon
    NOTER("Modèle de langage disponible : " + fichier.nom(CHEMIN_MODELE))
  finsi
retourner

procedure REPONDRE(ev)
  globale REPONSE_ENTETE, REPONSE_PIED
  locale q = rogner(question.valeur)
  si q = ""
    retourner
  finsi
  PAGE(1)
  locale t0 = systeme.horloge()
  locale res = CHERCHER_PASSAGES(q, 6)
  REMPLIR_PASSAGES(res, q)
  SURLIGNER_PASSAGES(res)
  si #res = 0
    reponse.valeur = "### " + q + NL + NL + "*Aucun passage du corpus ne correspond. Lancez une recherche sur Internet sur ce sujet, ou ajoutez des documents.*"
    retourner
  finsi
  && sources numérotées dans l'ordre de pertinence
  locale num = {}
  locale sources = {}
  pour chaque p dans res
    si num[p.source] = nul
      inserer(sources, p.source)
      num[p.source] = #sources
    finsi
  suivant
  locale pied = NL + NL + "**Sources**" + NL + NL
  pour i = 1 a #sources
    pied = pied + i + ". " + LIEN_DE(sources[i]) + NL
  suivant
  pied = pied + NL + "*" + #res + " passages retrouvés en " + arrondi((systeme.horloge() - t0) * 1000) + " ms" + ;
         sisinon(idx <> nul, " (Lucene)", " (en mémoire)") + " — onglet Passages.*"
  locale entete = "### " + q + NL + NL
  si avecmodele:coche(1) et CHEMIN_MODELE <> ""
    REDIGER(q, res, num, entete, pied)
    retourner
  finsi
  locale textes = {}
  pour chaque p dans res
    inserer(textes, {texte = p.texte, source = p.source})
  suivant
  locale ex = document.extraits(textes, q, 5)
  locale corps = "**Réponse extractive** (phrases des passages les plus proches de la question) :" + NL + NL
  pour chaque e dans ex
    corps = corps + "- " + e.phrase + " [" + num[e.source] + "]" + NL
  suivant
  reponse.valeur = entete + corps + pied
retourner

&& Réponse rédigée par le modèle local, à partir des passages numérotés.
procedure REDIGER(q, res, num, entete, pied)
  globale MODELE, REPONSE_ENTETE, REPONSE_TEXTE, REPONSE_PIED
  REPONSE_ENTETE = entete
  REPONSE_PIED = pied
  REPONSE_TEXTE = ""
  si MODELE = nul
    reponse.valeur = entete + "*Chargement du modèle " + fichier.nom(CHEMIN_MODELE) + "…*"
    MODELE = llm.charger(CHEMIN_MODELE)
  finsi
  locale conv = MODELE:conversation({systeme = "Tu es un assistant de recherche documentaire. " + ;
      "Réponds en français, en quelques phrases, uniquement à partir des extraits fournis, " + ;
      "et cite leurs numéros entre crochets, par exemple [2]. " + ;
      "Si les extraits ne contiennent pas la réponse, dis-le.", contexte = 4096, maxtokens = 400})
  locale extraits = ""
  pour chaque p dans res
    extraits = extraits + "[" + num[p.source] + "] " + p.titre + " :" + NL + gauche(p.texte, 1100) + NL + NL
  suivant
  reponse.valeur = entete + "*Rédaction…*"
  conv:demander("Extraits :" + NL + NL + extraits + "Question : " + q, @FLUX_REPONSE)
  reponse.valeur = REPONSE_ENTETE + REPONSE_TEXTE + REPONSE_PIED
retourner

fonction FLUX_REPONSE(morceau)
  globale REPONSE_TEXTE
  REPONSE_TEXTE = REPONSE_TEXTE + morceau
  reponse.valeur = REPONSE_ENTETE + REPONSE_TEXTE + " ▍" + REPONSE_PIED
retourner vrai

&&
&& onglet Passages
&&

procedure REMPLIR_PASSAGES(res, q)
  globale LISTE_PASSAGES, TERMES_PASSAGES
  LISTE_PASSAGES = res
  TERMES_PASSAGES = q ou ""
  tpassages:vider()
  pour chaque p dans res
    tpassages:ajouterligne(chaine(arrondi(p.score, 2)), p.titre, chaine(p.numero))
  suivant
  si #res > 0
    tpassages:selectionner(1)
    PASSAGE_CHOISI()
  sinon
    apercu.valeur = "*Aucun passage.*"
  finsi
retourner

procedure PASSAGE_CHOISI(ev)
  locale i = tpassages:selection()
  si i < 1 ou i > #LISTE_PASSAGES
    retourner
  finsi
  locale p = LISTE_PASSAGES[i]
  apercu.valeur = "### " + p.titre + " — passage " + p.numero + NL + NL + "Source : " + LIEN_DE(p.source) + ;
                  NL + NL + SURLIGNER_TEXTE(p.texte, TERMES_PASSAGES)
retourner

&& Met en gras les mots de la recherche (même forme) dans un passage.
fonction SURLIGNER_TEXTE(t, q)
  locale r = remplacertexte(remplacertexte(t, "*", "\\*"), "_", "\\_")
  pour chaque m dans document.mots(q)
    si longueur(m) > 3
      r = remplacertexte(r, m, "**" + m + "**")
      locale cap = majuscule(gauche(m, 1)) + souschaine(m, 2)
      r = remplacertexte(r, cap, "**" + cap + "**")
    finsi
  suivant
retourner r
