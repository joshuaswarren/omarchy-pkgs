#!/bin/bash
# Import GPG keys for package verification

echo "==> Importing GPG verification keys..."

# Read the gpg-keys.txt file for verification keys
if [[ -f /build/gpg-keys.txt ]]; then
  echo "  -> Importing verification keys..."
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    # Check if it's a URL (contains ://)
    if [[ "$line" == *"://"* ]]; then
      echo "    - Importing key from $line"
      curl -sS "$line" | gpg --import - || {
        echo "      Warning: Failed to import key from $line"
      }
    else
      # It's a key ID - receive from ubuntu first, keys.openpgp.org as fallback
      echo "    - Receiving key $line"
      gpg --receive-keys --keyserver hkps://keyserver.ubuntu.com "$line" \
        || gpg --receive-keys --keyserver hkps://keys.openpgp.org "$line" || {
        echo "      Warning: Failed to receive key $line"
      }
    fi
  done </build/gpg-keys.txt
  echo "  ✓ Verification key import complete"
else
  echo "  -> No gpg-keys.txt file found, skipping"
fi
