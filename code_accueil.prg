&& accueil.prg : procédures utilisables depuis tout le projet
procedure ACCUEIL
  globale formaccueil
  FORMACCUEIL_OUVRIR()
  formaccueil.minuterie = interface.minuterie(200,@TEMPO)
finprocedure

procedure TEMPO()
  globale formaccueil
  locale tempo = formaccueil.lblTempo.valeur
  local valeur = nombre(gauche(tempo,1))
  si valeur!=null
    valeur = valeur - 1
    tempo = chaine(valeur) + tempo
  finsi
  si valeur == 0
    BTNOK_CLIC(nul)
  sinon
    formaccueil.lblTempo.valeur = droite(tempo,4) + gauche(tempo,1)
  finsi
finprocedure

procedure BTNOK_CLIC(ev)
  && surclic de btnOK (formulaire « 1 »)
  globale formaccueil
  si formaccueil.minuterie:actif()
    formaccueil.minuterie:arreter()
  finsi
  MENURAG()
  formaccueil.fenetre:fermer()
finprocedure
