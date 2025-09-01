#Centralisations de fonctions utiles(par ex: choose_email, gestion de fichiers tmp, affichage menu,...)

check_error(){
  local response="$1"
  local step="$2"
  if echo "$response" | grep -qi "error"; then
    echo "* Erreur à l'étape $step: $response"
  else
    echo "* Étape $step réussie"
  fi
}


pause(){
  read -p "-> Appuie sur [Entrée] pour continuer..."
}