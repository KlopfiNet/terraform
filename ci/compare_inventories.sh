#!/bin/bash
# Compares cached inventories

set -e

for EXPECTED_FILE in "/cache/current-inventory" "/cache/inventory-cache"; do
    ls $EXPECTED_FILE || exit 1
done

diff=$(diff /cache/current-inventory /cache/inventory-cache | wc -l) || exit 1
echo "[i] Diff is: $diff"

if [ $diff -gt 0 ]; then
    echo "is_different"
else
    echo "::notice title=INV_IDENTICAL::Inventories are the same"
    echo "is_identical"
fi
