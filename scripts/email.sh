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