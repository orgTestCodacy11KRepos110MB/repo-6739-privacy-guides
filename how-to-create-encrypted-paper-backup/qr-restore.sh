#! /bin/bash

bold=$(tput bold)
red=$(tput setaf 1)
normal=$(tput sgr0)

set -e

printf "%s\n" "Scan QR code…"

data=""

while read line; do
  if echo -n $line | grep -Eq "^QR-Code:"; then
    line=$(echo -n $line | sed 's/QR-Code://')
  fi
  data="$data$line"
  if [ "$line" = "-----END PGP MESSAGE-----" ]; then
    killall zbarcam --signal SIGINT
  else
    data="$data\n"
  fi
done < <(zbarcam --nodisplay --quiet)

encrypted_secret=$(echo -e $data)

encrypted_secret_hash=$(echo -n "$encrypted_secret" | openssl dgst -sha512 | sed 's/^.* //')
encrypted_secret_short_hash=$(echo -n "$encrypted_secret_hash" | head -c 8)

printf "%s\n" "$encrypted_secret"
printf "SHA512 hash: $bold%s$normal\n" "$encrypted_secret_hash"
printf "SHA512 short hash: $bold%s$normal\n" "$encrypted_secret_short_hash"

printf "$bold$red%s$normal\n" "Show secret? (y or n)? "

read -r answer
if [ "$answer" = "y" ]; then
  secret=$(echo -e "$encrypted_secret" | gpg --decrypt)
  gpg-connect-agent reloadagent /bye > /dev/null 2>&1
  printf "Secret: $bold%s$normal\n" "$secret"
fi

printf "%s\n" "Done"