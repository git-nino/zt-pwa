#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Installing ZT-PWA (app4)..."

### VARIABLES
APP_NAME="app4"
REPO_URL="https://github.com/git-nino/zt-pwa.git"
BASE_DIR="$HOME/app_volumes"
APP_DIR="$BASE_DIR/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"
SERVICE_DIR="$PREFIX/var/service/$APP_NAME"
BIN_DIR="$PREFIX/bin"

### 1️⃣ Check Termux environment
if [[ -z "${PREFIX:-}" ]]; then
    echo "❌ This installer must be run inside Termux"
    exit 1
fi

### 2️⃣ Ensure storage access
termux-setup-storage >/dev/null 2>&1 || true

### 3️⃣ Update system packages
echo "📦 Updating packages..."
pkg update -y
pkg upgrade -y

### 4️⃣ Install dependencies
echo "🔧 Installing system dependencies..."
pkg install -y python git tsu termux-services

### 5️⃣ Create base directory
mkdir -p "$BASE_DIR"

### 6️⃣ Clone or update repo
if [[ -d "$APP_DIR/.git" ]]; then
    echo "🔄 Updating existing app..."
    cd "$APP_DIR"
    git pull
else
    echo "⬇️ Cloning repository..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

### 7️⃣ Create Python virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
    echo "🐍 Creating virtual environment..."
    python -m venv "$VENV_DIR"
fi

### 8️⃣ Install Python packages
echo "📚 Installing Python packages..."
"$PYTHON" -m pip install --upgrade pip
"$PYTHON" -m pip install -r requirements.txt

### 9️⃣ Create Termux service for auto-start
echo "🛠 Setting up Termux service..."
mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_DIR/run" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
APP_DIR="$HOME/app_volumes/app4"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"

cd "$APP_DIR"
# Activate virtual environment and run app.py
source "$VENV_DIR/bin/activate"
exec "$PYTHON" app.py
EOF

chmod +x "$SERVICE_DIR/run"
echo "✅ Service created at $SERVICE_DIR"
echo "ℹ️ Enable and start it with:"
echo "   sv enable $APP_NAME"
echo "   sv up $APP_NAME"

### 1️⃣0️⃣ Finished
echo
echo "✅ ZT-PWA (app4) installed successfully!"
echo "➡️ To run manually:"
echo "   cd $APP_DIR"
echo "   source venv/bin/activate"
echo "   python app.py"
