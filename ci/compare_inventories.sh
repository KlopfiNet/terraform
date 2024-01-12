#!/bin/bash
# Compares cached inventories

set -e

for EXPECTED_FILE in "/cache/current-inventory" "/cache/inventory-cache"; do
    ls $EXPECTED_FILE || exit 1
done

diff=$(diff /cache/current-inventory /cache/inventory-cache | wc -l) || exit 1
echo "[i] Diff is: $diff"

if [ $diff -gt 0 ]; then
    echo "::warning title=INV_DIFFER::Inventories are different"
    verdict="is_different"
else
    echo "::notice title=INV_IDENTICAL::Inventories are the same"
    verdict="is_identical"
fi

echo "VERDICT=$verdict" >> "$GITHUB_OUTPUT"