#!/bin/bash

# Pastikan perintah dijalankan di dalam folder repositori Git
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: Folder ini bukan repositori Git!"
    exit 1
fi

echo "🔄 [1/4] Pulling perubahan terbaru dari remote..."
git pull

echo "➕ [2/4] Staging semua file yang diubah..."
git add .

# Minta input pesan commit
read -p "💬 Masukkan pesan commit (kosongkan untuk default): " commit_msg

# Jika input kosong, gunakan timestamp sebagai pesan default
if [ -z "$commit_msg" ]; then
    commit_msg="update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "📝 [3/4] Creating commit..."
git commit -m "$commit_msg"

echo "🚀 [4/4] Pushing ke repository..."
git push

echo "✅ Selesai! Repositori berhasil diperbarui."
