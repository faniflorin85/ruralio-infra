#!/bin/bash
###############################################################################
# user-data.sh — rulează automat o singură dată, la prima pornire a instanței
# Instalează și pornește Nginx, plus Certbot pentru SSL.
###############################################################################
set -e

# Actualizează sistemul
apt-get update -y
apt-get upgrade -y

# Instalează Nginx și Certbot
apt-get install -y nginx certbot python3-certbot-nginx

# Pornește Nginx și îl activează la boot
systemctl enable nginx
systemctl start nginx

# Pagină temporară până la primul deploy al site-ului
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="ro">
<head><meta charset="UTF-8"><title>Ruralio</title></head>
<body style="font-family:sans-serif;text-align:center;padding-top:80px">
  <h1>Server pregatit</h1>
  <p>Site-ul Casa Tzau va fi disponibil in curand.</p>
</body>
</html>
EOF

echo "Setup finalizat: $(date)" > /var/log/ruralio-setup.log
