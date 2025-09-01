#Tests liés aux authentifiactions.
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

#Vérification du token access.
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

#Simulation du token d'access expiré.
expired_token(){
    echo "➡️ Simulation token expiré..."
    local resp http_code
    resp=$(curl -s -o /tmp/resp.txt -w "%{http_code}" -X GET "$BASE_URL/me" \
        -H "Authorization: Bearer FAUX_TOKEN_EXPIRE")
    http_code="$resp"

    if [[ "$http_code" -ge 400 ]]; then
        echo "Le backend a bien rejeté le token invalide (code $http_code)"
        cat /tmp/resp.txt
    else
        echo "Le backend n'a PAS rejeté le token invalide"
        cat /tmp/resp.txt
    fi
}