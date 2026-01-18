#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Installing ZT-PWA (app4) on Termux..."

### VARIABLES
APP_NAME="app4"
REPO_URL="https://github.com/git-nino/zt-pwa.git"
APP_BASE="$HOME/app_volumes"
APP_DIR="$APP_BASE/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"
BIN_DIR="$PREFIX/bin"
SERVICE_DIR="$PREFIX/var/service/$APP_NAME"
RUNSVDIR="$PREFIX/var/run/service"

### 1️⃣ Verify Termux environment
if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then
  echo "❌ This installer must be run inside Termux"
  exit 1
fi

### 2️⃣ Storage permission (non-fatal)
echo "📂 Setting up storage access..."
termux-setup-storage >/dev/null 2>&1 || true

### 3️⃣ Update system
echo "🔄 Updating packages..."
pkg update -y && pkg upgrade -y

### 4️⃣ Install required packages
echo "📦 Installing dependencies..."
pkg install -y \
  python \
  git \
  termux-services

### 5️⃣ Clone or update app
echo "📥 Deploying application..."
mkdir -p "$APP_BASE"

if [[ -d "$APP_DIR/.git" ]]; then
  cd "$APP_DIR"
  git pull --rebase
else
  git clone "$REPO_URL" "$APP_DIR"
fi

### 6️⃣ Create venv (only if missing)
if [[ ! -d "$VENV_DIR" ]]; then
  echo "🐍 Creating Python virtual environment..."
  python -m venv "$VENV_DIR"
fi

### 7️⃣ Install Python dependencies
echo "📦 Installing Python dependencies..."
"$PYTHON" -m pip install --upgrade pip setuptools wheel

if [[ -f "$APP_DIR/requirements.txt" ]]; then
  "$PYTHON" -m pip install -r "$APP_DIR/requirements.txt"
else
  "$PYTHON" -m pip install flask requests
fi

### 8️⃣ Verify tools
echo "🔍 Verifying installation..."
"$PYTHON" - <<'EOF'
import importlib.metadata
print("Flask OK:", importlib.metadata.version("flask"))
import importlib.util
print("Requests OK:", importlib.util.find_spec("requests") is not None)
EOF

### 9️⃣ Create runit service
echo "⚙️ Creating runit service..."
mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
cd "$APP_DIR"
exec "$PYTHON" app.py
EOF

chmod +x "$SERVICE_DIR/run"

### 🔟 Enable and start service if runsvdir is running
if [[ -d "$RUNSVDIR" && -x "$PREFIX/bin/sv-enable" ]]; then
  echo "🔁 Enabling and starting service..."
  sv-enable "$APP_NAME" || true
  sv up "$APP_NAME" || true
  echo "✅ Service started"
else
  echo "ℹ️ Services not active yet (Termux restart required)"
fi

### ✅ Done
echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📌 NEXT STEP:"
echo "⚠️ Close Termux completely (swipe away) and reopen it."
echo "👉 After reopening, the service will start automatically."
echo ""
echo "📥 Commands available after restart:"
echo "   sv status $APP_NAME"
echo ""
