#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

DEFAULT_PORT="8004"
PORT="${PORT:-$DEFAULT_PORT}"

APP_NAME=$(node -e "const c=require('./ecosystem.config.js'); console.log(c.apps[0].name)" 2>/dev/null || echo "news-ts")

RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RED="\033[31m"

log()     { echo -e "${BLUE}i${RESET} $1"; }
success() { echo -e "${GREEN}ok${RESET} $1"; }
warn()    { echo -e "${YELLOW}warn${RESET} $1"; }
fail()    { echo -e "${RED}error${RESET} $1"; exit 1; }
step()    { echo ""; echo -e "${BOLD}${CYAN}$1${RESET}"; }
run()     { log "$1"; shift; "$@"; }

echo "--------------------------------------------------"
echo -e "${BOLD}News TS VPS standalone deployment${RESET}"
echo "--------------------------------------------------"
echo "App  : $APP_NAME"
echo "Port : $PORT"

if [[ -t 0 ]]; then
  read -r -p "Enter port, or press Enter to keep $PORT: " INPUT_PORT
  PORT="${INPUT_PORT:-$PORT}"
fi

step "Checking required commands"
command -v npm  >/dev/null 2>&1 || fail "npm is required."
command -v node >/dev/null 2>&1 || fail "node is required."
command -v pm2  >/dev/null 2>&1 || fail "pm2 is required."
success "Required commands available"

step "Cleaning old build"
rm -rf .next out dist
mkdir -p logs
success "Clean complete"

step "Installing dependencies"
run "Running npm install" npm install --legacy-peer-deps

step "Checking SEO mode"
# Resolve NEXT_PUBLIC_SEO exactly as `next build` will (.env, .env.production, ...).
SEO_MODE=$(node -e "require('@next/env').loadEnvConfig(process.cwd()); console.log(process.env.NEXT_PUBLIC_SEO || '')")
if [[ "$SEO_MODE" == "false" ]]; then
  fail "NEXT_PUBLIC_SEO=\"false\" builds a static export (out/), not a Node server. Set NEXT_PUBLIC_SEO=\"true\" in .env for VPS deployment, or run 'npm run export' for static hosting."
fi
success "NEXT_PUBLIC_SEO=\"${SEO_MODE}\" — standalone build"

step "Building standalone Next.js app"
export NODE_ENV="production"
export PORT
export NODE_OPTIONS="--max-old-space-size=1536"
export GENERATE_SOURCEMAP="false"

# Also generates sitemap.xml, rssfeed.xml, robots.txt and manifest.json (see scripts/generate-seo-files.mjs).
run "Running Next.js build" npm run build

[[ -d ".next/standalone" ]] || fail ".next/standalone was not generated."

run "Copying static assets to standalone" bash -c "cp -r .next/static .next/standalone/.next/static && cp -r public .next/standalone/public"

step "Generating Apache .htaccess"
log "Writing .htaccess for port $PORT"
cat > .htaccess << EOF
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /

    RewriteRule ^favicon\.ico$ - [L]

    RewriteRule ^.well-known/acme-challenge/(.*) /.well-known/acme-challenge/\$1 [L]

    RewriteRule ^_next/static/(.*) /.next/static/\$1 [L]

    RewriteRule ^_next/data/(.*) http://127.0.0.1:${PORT}/_next/data/\$1 [P,L]

    RewriteCond %{REQUEST_URI} \.(js|css|svg|jpg|jpeg|png|gif|ico|woff|woff2|ttf|eot|webp|mp4|webm)$
    RewriteRule ^ - [L]

    RewriteRule ^index.html http://127.0.0.1:${PORT}/\$1 [P]
    RewriteRule ^index.php  http://127.0.0.1:${PORT}/\$1 [P]
    RewriteRule ^/?(.*)$    http://127.0.0.1:${PORT}/\$1 [P]
</IfModule>
EOF
success ".htaccess generated for port $PORT"

step "Starting PM2"
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  run "Restarting $APP_NAME" env PORT="$PORT" pm2 restart ecosystem.config.js --update-env
else
  run "Starting $APP_NAME"   env PORT="$PORT" pm2 start ecosystem.config.js
fi

run "Saving PM2 process list" pm2 save

step "Apache reload"
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl reload apache2 2>/dev/null || sudo systemctl reload httpd 2>/dev/null || warn "Apache reload failed."
elif command -v service >/dev/null 2>&1; then
  sudo service apache2 reload 2>/dev/null || sudo service httpd reload 2>/dev/null || warn "Apache reload failed."
else
  warn "Apache reload skipped — systemctl/service not found."
fi

echo ""
echo "--------------------------------------------------"
echo -e "${GREEN}${BOLD}Deployment complete${RESET}"
echo "App  : $APP_NAME"
echo "Mode : Next.js standalone"
echo "Port : $PORT"
echo "URL  : http://127.0.0.1:$PORT"
echo "--------------------------------------------------"

pm2 ls
