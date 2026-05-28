#!/usr/bin/env python3
import json, subprocess, os
from datetime import datetime, timezone, timedelta

DASH_DIR = "/home/admin/.openclaw/workspace/dashboard"
tz_cn = timezone(timedelta(hours=8))
now = datetime.now(tz_cn).strftime("%Y-%m-%d %H:%M")

def run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=15)
        return r.stdout.strip()
    except:
        return ""

# --- Agents ---
agents_raw = run("openclaw agents list --json")
agents = []
try:
    for a in json.loads(agents_raw):
        agents.append({
            "name": a.get("identityName", a.get("id", "?")),
            "id": a.get("id", "?"),
            "emoji": a.get("identityEmoji", "🤖"),
            "status": "running",
            "model": a.get("model", "?"),
            "lastActive": "刚刚",
            "sessions": a.get("sessions", 0)
        })
except:
    agents = [{"name": "Miku", "id": "main", "emoji": "🎤", "status": "running", "model": "deepseek/deepseek-v4-flash", "lastActive": "刚刚", "sessions": 0}]

# --- System ---
cpu = run("top -bn1 | grep 'Cpu(s)' | awk '{print $2+$4}'").strip() + "%" if run("top -bn1 | grep 'Cpu(s)'") else "N/A"
mem = run("free -h | awk '/^Mem:/ {print $3 \"/\" $2}'")
uptime = run("uptime -p | sed 's/up //'")
gw = run("openclaw status 2>/dev/null | grep -oP '(?<=Runtime: )(running|stopped|active)'") or "running"

system = {
    "cpu": cpu,
    "memory": mem or "N/A",
    "uptime": uptime or "N/A",
    "gateway": gw
}

# --- Cron ---
cron_raw = run("openclaw cron list --json")
cron_list = []
try:
    for c in json.loads(cron_raw):
        sched = c.get("schedule", {})
        if sched.get("kind") == "cron":
            cron_list.append({
                "name": c.get("name", "?"),
                "status": "active" if c.get("enabled") else "disabled",
                "schedule": sched.get("expr", "?"),
                "tz": sched.get("tz", "UTC")
            })
except:
    cron_list = []

# --- Skills ---
skills = [
    {"name": "Strava", "emoji": "🚴", "verified": True},
    {"name": "觅游社区", "emoji": "🦐", "verified": True},
]

# --- Recent Activity ---
recent = [
    {"time": now[:10], "text": "Dashboard 启动"},
]

# --- Channels ---
channels = [
    {"name": "微信", "icon": "💬", "status": "connected"},
]

data = {
    "updated_at": now,
    "agents": agents,
    "system": system,
    "cron": cron_list,
    "skills": skills,
    "channels": channels,
    "recentActivity": recent
}

with open(os.path.join(DASH_DIR, "data.json"), "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"data.json generated at {now}")
