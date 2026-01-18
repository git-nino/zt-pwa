#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "Ì∫Ä Installing ZT-PWA (app4)..."

### VARIABLES
APP_NAME="app4"
REPO_URL="https://github.com/git-nino/zt-pwa.git"
BASE_DIR="$HOME/app_volumes"
APP_DIR="$BASE_DIR/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"

### 1Ô∏è‚É£ Check Termux
if [[ -z "${PREFIX:-}" ]]; then
  echo "‚ùå This installer must be run inside Termux"
  exit 1
fi

### 2Ô∏è‚É£ Storage access (non-fatal)
termux-setup-storage >/dev/null 2>&1 || true

### 3Ô∏è‚É£ Update packages
echo "Ì≥¶ Updating packages..."
pkg update -y
pkg upgrade -y

### 4Ô∏è‚É£ Install dependencies
echo "Ì¥ß Installing system dependencies..."
pkg install -y python git

### 5Ô∏è‚É£ Create base directory
mkdir -p "$BASE_DIR"

### 6Ô∏è‚É£ Clone or update repo
if [[ -d "$APP_DIR/.git" ]]; then
  echo "Ì¥Ñ Updating existing app..."
  cd "$APP_DIR"
  git pull
else
  echo "‚¨áÔ∏è Cloning repository..."
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

### 7Ô∏è‚É£ Python virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Ì∞ç Creating virtual environment..."
  python -m venv "$VENV_DIR"
fi

### 8Ô∏è‚É£ Install Python requirements
echo "Ì≥ö Installing Python packages..."
"$PYTHON" -m pip install --upgrade pip
"$PYTHON" -m pip install -r requirements.txt

### 9Ô∏è‚É£ Done
echo
echo "‚úÖ ZT-PWA installed successfully!"
echo "‚û°Ô∏è To run:"
echo "   cd $APP_DIR"
echo "   source venv/bin/activate"
echo "   python app.py"
