#Tests liés aux users.
# # =============================
# # ACTIONS API
# # =============================
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

# # Fonction pour login et récupération des tokens
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

#Suppression d'un user.
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