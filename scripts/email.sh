#Tests liés aux emails.

# # =============================
# # GÉNÉRATION EMAIL UNIQUE
# # =============================
generate_email(){
  local timestamp=$(date +%s)
  local random=$RANDOM
  EMAIL="user_${timestamp}_${random}@example.com"
  echo "$EMAIL" >> "$EMAIL_HISTORY_FILE"
  echo "-> Email généré : $EMAIL"
}


# #Sélection d'un email existant
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