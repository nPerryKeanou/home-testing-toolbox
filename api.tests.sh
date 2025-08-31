#!/bin/bash

# ===================================
# CONFIG
# ===================================

export $(grep -v '^#' .env | xargs)

if [[ -z "$BASE_URL" || -z "$PASSWORD" || -z "$DB_NAME" || -z "$DB_USER" ]]; then
  echo "* Variable manquantes dans .env (BASE_URL, PASSWORD, DB_NAME, DB_USER sont obligatoires)"
  exit 1
fi


EMAIL="" #sera défini pour l'action en cours
USERNAME="user_$(date +%s)_$RANDOM"
ACCESS_TOKEN=""
REFRESH_TOKEN=""
EMAIL_HISTORY_FILE=".email.tmp"
touch "$EMAIL_HISTORY_FILE"


# =============================
# UTILS
# =============================
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

# =============================
# GÉNÉRATION EMAIL UNIQUE
# =============================
generate_email(){
  local timestamp=$(date +%s)
  local random=$RANDOM
  EMAIL="user_${timestamp}_${random}@example.com"
  echo "$EMAIL" >> "$EMAIL_HISTORY_FILE"
  echo "-> Email généré : $EMAIL"
}

#Sélection d'un email existant
choose_email(){
  local count=$(wc -l < "$EMAIL_HISTORY_FILE")
  if [[ $count -eq 0 ]]; then
    echo "* Aucun email enregistré. Création d'un nouveau."
    generate_email
  else
    echo "Emails disponible :"
    nl "$EMAIL_HISTORY_FILE"
    echo "0) Créer un nouvel email"
    read -p "Choisis un email ou 0 pour un nouveau " choice
    if [[ "$choice" == "0" ]]; then
      generate_email
    else
      EMAIL=$(sed -n "${choice}p" "$EMAIL_HISTORY_FILE")
      echo "-> Email choisi : $EMAIL"
    fi
  fi
}


# =============================
# ACTIONS API
# =============================
create_user(){
  generate_email
  echo "-> Création user avec username: $USERNAME et email: $EMAIL"
  local resp=$(curl -s -X POST "$BASE_URL/" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
  echo " ----------------------------------------------"
  echo "Payload envoyé : {\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"
  echo " ----------------------------------------------"
  echo "$resp"
  check_error "$resp" "Création user"
}

# Fonction pour login et récupération des tokens
login_user() {
    choose_email  # Ta fonction existante pour choisir un email
    echo "➡️ Connexion user..."

    # On envoie l'email et le mot de passe
    local resp=$(curl -s -X POST "$BASE_URL_AUTH/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

    echo "$resp"
    check_error "$resp" "Login"

    # Récupère les tokens du JSON
    ACCESS_TOKEN=$(echo "$resp" | jq -r '.accessToken')
    REFRESH_TOKEN=$(echo "$resp" | jq -r '.refreshToken')

    # Vérification simple
    if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
        echo "* Échec extraction accessToken !"
        return 1
    fi
    if [[ -z "$REFRESH_TOKEN" || "$REFRESH_TOKEN" == "null" ]]; then
        echo "* Échec extraction refreshToken !"
        return 1
    fi

    echo "Access token: $ACCESS_TOKEN"
    echo "Refresh token: $REFRESH_TOKEN"
}


refresh_token() {
    if [[ -z "$REFRESH_TOKEN" ]]; then
        echo "* Aucun refreshToken disponible. Connecte-toi d'abord."
        return
    fi

    echo "➡️ Refresh token..."
    echo "REFRESH_TOKEN=$REFRESH_TOKEN"

    # Construire le JSON de façon sécurisée avec jq pour éviter les problèmes de quotes
    local json_body
    json_body=$(jq -n --arg token "$REFRESH_TOKEN" '{refreshToken: $token}')

    # Appel API pour rafraîchir le token
    local resp
    resp=$(curl -s -X POST "$BASE_URL_AUTH/refresh" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    echo "$resp"
    check_error "$resp" "Refresh token"

    # Extraire le nouvel accessToken
    ACCESS_TOKEN=$(echo "$resp" | jq -r '.accessToken')
    if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
        echo "* Échec extraction accessToken !"
        return
    fi
    echo "Nouveau accessToken: $ACCESS_TOKEN"

    # Supprimer le fichier temporaire contenant les tokens si nécessaire
    if [[ -f "$TMP_TOKEN_FILE" ]]; then
        rm -f "$TMP_TOKEN_FILE"
        echo "* Fichier temporaire des tokens supprimé."
    fi
}

me_user(){
    if [[ -z "$ACCESS_TOKEN" ]]; then
        echo "* Aucun accessToken disponible. Connecte-toi d'abord."
        return
    fi
    echo "➡️ Vérification /users/me..."
    local resp=$(curl -s -X GET "$BASE_URL/me" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    echo "$resp"
    check_error "$resp" "/users/me"
}


expired_token(){
    echo "➡️ Simulation token expiré..."
    local resp http_code
    resp=$(curl -s -o /tmp/resp.txt -w "%{http_code}" -X GET "$BASE_URL/me" \
        -H "Authorization: Bearer FAUX_TOKEN_EXPIRE")
    http_code="$resp"

    if [[ "$http_code" -ge 400 ]]; then
        echo "✅ Le backend a bien rejeté le token invalide (code $http_code)"
        cat /tmp/resp.txt
    else
        echo "❌ Le backend n'a PAS rejeté le token invalide"
        cat /tmp/resp.txt
    fi
}

delete_user(){
    choose_email
    echo "➡️ Suppression user..."
    local resp=$(psql -d "$DB_NAME" -U "$DB_USER" -t -c "DELETE FROM users WHERE email='$EMAIL';")
    if [[ $? -eq 0 ]]; then
        echo "User supprimé de la DB"
    else
        echo "Erreur suppression user"
    fi
    sed -i '' "/^$EMAIL$/d" .email.tmp
    echo "Email supprimé du fichier tmp.emails"
}

clear_email_history(){
    > "$EMAIL_HISTORY_FILE"
    EMAIL=""
    echo "Historique des emails vidé, prêt pour de nouveaux tests."
}

# Fonction pour nettoyer le fichier de tokens
cleanup_tokens() {
    if [[ -f "$TOKEN_FILE" ]]; then
        rm "$TOKEN_FILE"
        echo "* Fichier de tokens supprimé."
    fi
}

# =============================
# TRAITEMENT DES ARGUMENTS
# =============================
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

# =============================
# MENU INTERACTIF
# =============================
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
