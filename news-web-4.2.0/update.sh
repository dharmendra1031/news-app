#!/bin/bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "→ Running PM2 processes:"
pm2 list

echo ""
read -p "Enter app name or id to update: " TARGET

# ─── SEO mode ─────────────────────────────────────────────────────────────────
SEO_MODE=$(node -e "require('@next/env').loadEnvConfig(process.cwd()); console.log(process.env.NEXT_PUBLIC_SEO || '')")
if [ "$SEO_MODE" = "false" ]; then
  echo "✗ NEXT_PUBLIC_SEO=\"false\" builds a static export (out/), not a Node server."
  echo "  Set NEXT_PUBLIC_SEO=\"true\" in .env, or run 'npm run export' for static hosting."
  exit 1
fi

# ─── Build (also generates sitemap, rss feed, robots.txt, manifest) ───────────
echo "→ Building..."
NODE_OPTIONS="--max-old-space-size=1536" GENERATE_SOURCEMAP=false npm run build

# ─── Copy static assets to standalone ────────────────────────────────────────
echo "→ Copying static assets to standalone..."
rm -rf .next/standalone/.next/static .next/standalone/public
cp -r .next/static .next/standalone/.next/static
cp -r public .next/standalone/public

# ─── Restart ──────────────────────────────────────────────────────────────────
echo "→ Restarting $TARGET..."
pm2 restart "$TARGET"

echo ""
echo "✓ Update complete → $TARGET"
