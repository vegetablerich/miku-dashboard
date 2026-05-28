#!/bin/bash
# Collect data for Miku Dashboard
DASH_DIR="/home/admin/.openclaw/workspace/dashboard"

# Agent status
AGENTS_JSON=$(openclaw agents list --json 2>/dev/null)
GATEWAY_STATUS=$(openclaw status 2>/dev/null)

# System info
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}')
MEM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
UPTIME=$(uptime -p | sed 's/up //')
GATEWAY_STATE=$(echo "$GATEWAY_STATUS" | grep -oP 'running|active' | head -1)

# Cron jobs
CRON_LIST=$(openclaw cron list --json 2>/dev/null)

# Channel status
CHANNELS_JSON=$(openclaw channels status --json 2>/dev/null)

# Generate data.json
python3 << PYEOF
import json, subprocess, shlex
from datetime import datetime, timezone, timedelta

tz_cn = timezone(timedelta(hours=8))
now = datetime.now(tz_cn).strftime("%Y-%m-%d %H:%M")

# Agents
try:
    agents_raw = """$AGENTS_JSON"""
    agents_data = json.loads(agents_raw)
except:
    agents_data = []

agents = []
for a in agents_data:
    name = a.get("identityName", a.get("id", "?"))
    eid = a.get("id", "?")
    model = a.get("model", "?")
    sessions = a.get("sessions", 0)
    agents.append({
        "name": name,
        "id": eid,
        "emoji": a.get("identityEmoji", "🤖"),
        "status": "running",
        "model": model,
        "lastActive": "刚刚",
        "sessions": sessions
    })

# System
system = {
    "cpu": """$CPU""".strip() or "N/A",
    "memory": """$MEM""".strip() or "N/A",
    "uptime": """$UPTIME""".strip() or "N/A",
    "gateway": """$GATEWAY_STATE""".strip() or "unknown"
}

# Cron
cron_list = []
try:
    cron_raw = json.loads("""$CRON_LIST""") if """$CRON_LIST""" else []
    for c in (cron_raw if isinstance(cron_raw, list) else []):
        sched = c.get("schedule", {})
        if sched.get("kind") == "cron":
            cron_list.append({
                "name": c.get("name", "?"),
                "status": "active" if c.get("enabled") else "disabled",
                "schedule": sched.get("expr", "?")
            })
except:
    pass

# Skills
skills = [
    {"name": "Strava", "emoji": "🚴", "verified": True},
    {"name": "觅游社区", "emoji": "🦐", "verified": True},
]

# Channels
channels = [
    {"name": "微信", "icon": "💬", "status": "connected"},
]

# Recent activity
recent = [
    {"time": now[:10], "text": "Dashboard 已启动"},
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

with open("$DASH_DIR/data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("data.json generated at", now)
PYEOF
