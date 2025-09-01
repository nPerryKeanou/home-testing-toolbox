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

#Fonction pour nettoyer le fichier email_history.
clear_email_history(){
    > "$EMAIL_HISTORY_FILE"
    EMAIL=""
    echo "Historique des emails vidé, prêt pour de nouveaux tests."
}

# # Fonction pour nettoyer le fichier de tokens
cleanup_tokens() {
    if [[ -f "$TOKEN_FILE" ]]; then
        rm "$TOKEN_FILE"
        echo "* Fichier de tokens supprimé."
    fi
}


# # =============================
# # TRAITEMENT DES ARGUMENTS
# # =============================
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    case "$arg" in
      create) create_user ;;
      login) login_user ;;
      me) me_user ;;
      refresh) refresh_token ;;
      expired) expired_token ;;
      delete) delete_user ;;
      clear_history) clear_email_history ;;
      cleanup_tokens) cleanup_tokens ;;
      *) echo "* Action inconnue: $arg";;
    esac
  done
  exit 0
fi

# # =============================
# # MENU INTERACTIF
# # =============================
while true; do
    clear
    echo "=============================="
    echo "      API TEST MENU"
    echo "=============================="
    echo "1) Créer un user"
    echo "2) Login"
    echo "3) Vérifier /users/me"
    echo "4) Refresh token"
    echo "5) Simulation token expiré"
    echo "6) Supprimer user"
    echo "7) Vider l’historique des emails"
    echo "8) Supprimer le fichiers tmp des tokens"
    echo "0) Quitter"
    echo "------------------------------"
    read -p "Choisis une option: " choice

    case $choice in
        1) create_user; pause ;;
        2) login_user; pause ;;
        3) me_user; pause ;;
        4) refresh_token; pause ;;
        5) expired_token; pause ;;
        6) delete_user; pause ;;
        7) clear_email_history; pause ;;
        8) cleanup_tokens; pause;;
        0) echo "Bye !"; exit 0 ;;
        *) echo "* Option invalide"; pause ;;
    esac
done
