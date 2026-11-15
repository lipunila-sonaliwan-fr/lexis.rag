&& Formulaire « accueil » - généré par le concepteur de wdlexis+.
&& Régénéré à chaque modification dans le concepteur : modifiez le dessin là-bas, pas ce fichier.
&& FORMACCUEIL_OUVRIR() ouvre la fenêtre et renvoie ses contrôles, aussi rangés dans la
&& variable globale formaccueil (formaccueil.fenetre, formaccueil.cad1…).

fonction FORMACCUEIL_OUVRIR()
  globale formaccueil
  locale f = {}
  f.fenetre = interface.fenetre{titre = "", largeur = 640, hauteur = 316, disposition = "vertical"}
  f.cad1 = f.fenetre:ajouter(interface.cadre("", "horizontal"))
  f.cad1.fond = "#FFFFFF"
  f.img1 = f.cad1:ajouter(interface.image("ressources/logo.png"))
  f.img1.largeurfixe = 170
  f.img1.hauteurfixe = 46
  f.lbl1 = f.cad1:ajouter(interface.etiquette("Créez aujourd'hui les solutions de demain !", "centre"))
  f.lbl1.largeurfixe = 389
  f.lbl1.couleur = "#003973"
  f.mkd1 = f.fenetre:ajouter(interface.markdown("# RAG Lexis+\n\nTous droits réservés 2026 - Jean-Marc  QUÉRÉ\n\n⛶ https://sonaliwan.fr  ✉ metalab(at)sonaliwan.fr\n\nSIRET 13033319800013 - **L.P.C.S. - Lab'Oratoire - Projet magenta**"))
  f.mkd1.hauteurfixe = 151
  f.cnt1 = f.fenetre:ajouter(interface.conteneur("horizontal", 4))
  f.lblTempo = f.cnt1:ajouter(interface.etiquette("----9"))
  f.lblTempo.poids = 3
  f.btnOK = f.cnt1:ajouter(interface.bouton("OK", {defaut = vrai}))
  && événements (procédures du code : principal.prg)
  f.btnOK.surclic = @BTNOK_CLIC
  formaccueil = f
retourner f
finfonction

&& Dessin du formulaire (relu par le concepteur) : ne pas modifier.
&&§ {
&&§   "kind": "fenetre",
&&§   "name": "accueil",
&&§   "props": {
&&§     "titre": "",
&&§     "sombre": "false",
&&§     "largeur": "640",
&&§     "hauteur": "316"
&&§   },
&&§   "events": [],
&&§   "children": [
&&§     {
&&§       "kind": "cadre",
&&§       "name": "cad1",
&&§       "props": {
&&§         "disposition": "horizontal",
&&§         "fond": "#FFFFFF",
&&§         "titre": ""
&&§       },
&&§       "events": [],
&&§       "children": [
&&§         {
&&§           "kind": "image",
&&§           "name": "img1",
&&§           "props": {
&&§             "chemin": "ressources/logo.png",
&&§             "etat": "actif",
&&§             "largeurfixe": "170",
&&§             "hauteurfixe": "46"
&&§           },
&&§           "events": [],
&&§           "children": []
&&§         },
&&§         {
&&§           "kind": "etiquette",
&&§           "name": "lbl1",
&&§           "props": {
&&§             "libelle": "Créez aujourd'hui les solutions de demain !",
&&§             "alignement": "centre",
&&§             "largeurfixe": "389",
&&§             "couleur": "#003973"
&&§           },
&&§           "events": [],
&&§           "children": []
&&§         }
&&§       ]
&&§     },
&&§     {
&&§       "kind": "markdown",
&&§       "name": "mkd1",
&&§       "props": {
&&§         "hauteurfixe": "151",
&&§         "texte": "# RAG Lexis+ 1.0.1\n\nTous droits réservés 2026 - Jean-Marc  QUÉRÉ\n\n⛶ https://sonaliwan.fr  ✉ metalab(at)sonaliwan.fr\n\nSIRET 13033319800013 - **L.P.C.S. - Lab'Oratoire - Projet magenta**"
&&§       },
&&§       "events": [],
&&§       "children": []
&&§     },
&&§     {
&&§       "kind": "conteneur",
&&§       "name": "cnt1",
&&§       "props": {
&&§         "colonnes": "4",
&&§         "disposition": "horizontal"
&&§       },
&&§       "events": [],
&&§       "children": [
&&§         {
&&§           "kind": "etiquette",
&&§           "name": "lblTempo",
&&§           "props": {
&&§             "poids": "3",
&&§             "alignement": "gauche",
&&§             "libelle": "----5"
&&§           },
&&§           "events": [],
&&§           "children": []
&&§         },
&&§         {
&&§           "kind": "bouton",
&&§           "name": "btnOK",
&&§           "props": {
&&§             "libelle": "OK",
&&§             "defaut": "true"
&&§           },
&&§           "events": [
&&§             [
&&§               "surclic",
&&§               "BTNOK_CLIC"
&&§             ]
&&§           ],
&&§           "children": []
&&§         }
&&§       ]
&&§     }
&&§   ],
&&§   "code": "principal.prg"
&&§ }
