from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import requests
import time
import json
import os
from datetime import datetime
import logging
from functools import wraps

app = Flask(__name__)
app.secret_key = os.environ.get('SESSION_SECRET', 'dev-secret-key-zt-controller')
app.config['CONFIG_FILE'] = 'zt_config.json'

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.template_filter('timestamp_to_date')
def timestamp_to_date(ms):
    if not ms: return "Never"
    try:
        dt = datetime.fromtimestamp(ms / 1000)
        return dt.strftime('%Y-%m-%d %H:%M')
    except: return "Invalid date"

@app.context_processor
def inject_now():
    return {'now': datetime.now}

def load_config():
    if os.path.exists(app.config['CONFIG_FILE']):
        try:
            with open(app.config['CONFIG_FILE'], 'r') as f:
                return json.load(f)
        except: pass
    return {"api_token": None, "last_network": None}

def save_config(config):
    try:
        with open(app.config['CONFIG_FILE'], 'w') as f:
            json.dump(config, f, indent=2)
        return True
    except: return False

def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        config = load_config()
        if not config.get('api_token'):
            return redirect(url_for('setup'))
        return f(*args, **kwargs)
    return decorated_function

def time_ago(ms):
    if not ms: return "Never"
    now = int(time.time())
    seconds = now - int(ms / 1000)
    if seconds < 0: return "Online"
    if seconds < 60: return "Just now"
    if seconds < 3600: return f"{seconds // 60}m ago"
    if seconds < 86400: return f"{seconds // 3600}h ago"
    return f"{seconds // 86400}d ago"

def get_headers():
    config = load_config()
    token = config.get('api_token')
    return {"Authorization": f"Bearer {token}"} if token else None

def test_api_token(token):
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get("https://api.zerotier.com/api/v1/status", headers=headers, timeout=10)
        return response.status_code == 200
    except: return False

@app.route("/")
@app.route("/app4/")  # Add this line to handle the /app4/ path specifically
def root_redirect():
    config = load_config()
    if config.get('last_network'):
        return redirect(url_for('network_members', network_id=config['last_network']))
    return redirect(url_for('networks_page'))

@app.route("/app4/setup", methods=["GET", "POST"])
def setup():
    config = load_config()
    if request.method == "POST":
        token = request.form.get("api_token", "").strip()
        if test_api_token(token):
            config['api_token'] = token
            save_config(config)
            return redirect(url_for("networks_page"))
        flash("Invalid API token", "error")
    return render_template("setup.html", has_token=bool(config.get('api_token')))

@app.route("/app4/logout")
def logout():
    config = load_config()
    config['api_token'] = None
    config['last_network'] = None
    save_config(config)
    return redirect(url_for('setup'))

@app.route("/app4/networks")
@token_required
def networks_page():
    headers = get_headers()
    try:
        response = requests.get("https://api.zerotier.com/api/v1/network", headers=headers, timeout=10)
        networks_data = response.json()
        return render_template("networks.html", networks=networks_data)
    except Exception as e:
        return render_template('error.html', error=str(e))

@app.route("/app4/network/<network_id>")
@token_required
def network_members(network_id):
    headers = get_headers()
    sort_by = request.args.get('sort', 'last_seen')
    order = request.args.get('order', 'desc')
    
    config = load_config()
    config['last_network'] = network_id
    save_config(config)
    
    try:
        response = requests.get(f"https://api.zerotier.com/api/v1/network/{network_id}/member", headers=headers, timeout=10)
        members = response.json()
        parsed = []
        now_ms = int(time.time() * 1000)
        online_count = 0
        
        for m in members:
            last_seen = m.get("lastSeen", 0)
            is_online = (now_ms - last_seen) < 120000 if last_seen else False
            if is_online: online_count += 1
            
            ip_assignments = m.get("config", {}).get("ipAssignments", [])
            parsed.append({
                "id": m.get("id"),
                "name": m.get("name") or f"Node {m.get('nodeId', '')[:8]}",
                "ip": ip_assignments[0] if ip_assignments else "N/A",
                "last_seen_raw": last_seen,
                "last_seen": time_ago(last_seen),
                "online": is_online,
                "authorized": m.get("config", {}).get("authorized", False)
            })

        reverse = (order == 'desc')
        if sort_by == 'name': parsed.sort(key=lambda x: x['name'].lower(), reverse=reverse)
        elif sort_by == 'last_seen': parsed.sort(key=lambda x: x['last_seen_raw'] or 0, reverse=reverse)
        
        return render_template("members.html", 
                               network_id=network_id, 
                               members=parsed, 
                               online_count=online_count,
                               sort_by=sort_by, 
                               order=order)
    except Exception as e:
        return redirect(url_for('networks_page'))

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8004, debug=True)
