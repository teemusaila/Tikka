#!/bin/sh
# This code was generated with AI (Claude by Anthropic). MIT License, see LICENSE and README.
# scoreboard-install.sh: Tikka, a darts scoreboard and game manager served by the Autodarts Pi.
#
# Run as root:   sh scoreboard-install.sh
#
# Installs a single web page to /data/scoreboard and serves it on port 8080 with
# Busybox httpd. Open http://<pi-address>:8080 on any tablet, phone, laptop or TV browser.
# The page reads detected darts from the board service (port 3180) and runs the games
# itself: X01, Cricket (standard, cut-throat, no points), Tactics, Mickey Mouse, Around the
# Clock, Shanghai, Baseball, Golf, Count-Up, Fives, Halve-It, Bob's 27, a checkout drill, Killer,
# Follow the Leader and Scram, with legs and sets, checkout routes, a live dartboard of
# the round's hits, corrections, a Fix scores list for earlier visits, undo and a spoken
# score caller.
# Sign-in: add users with "scoreboard-user add NAME" (until the first user exists the page is open).
# Starting a game locks the board to that user until the match ends or they end it; other users
# then see the game read-only. Admins can force-unlock; a lock idle for 3 hours is dropped.
# The player list is shared by all devices (kept in /data/scoreboard/data). Games in progress are
# stored in the browser of the device you use. Re-running this script updates the page
# and keeps the player list.

set -e
DIR=/data/scoreboard
AUTH=/data/scoreboard-auth   # users, admins and the lock helper; outside the web root
PORT=${SCOREBOARD_PORT:-8080}

[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
grep -q ' /data ' /proc/mounts || { echo "/data is not mounted."; exit 1; }

echo "== Installing the web server"
apk add -q busybox-extras
apk cache -q sync 2>/dev/null || true   # packages come back from this cache at boot
HTTPD=$(command -v httpd) || { echo "httpd not found after installing busybox-extras."; exit 1; }

echo "== Writing the scoreboard to $DIR"
mkdir -p "$DIR"
cat > "$DIR/app.html" <<'EOF_OCHE'
<!doctype html>
<html lang="en">
<!-- Tikka, a darts scoreboard for Autodarts boards. This code was generated with AI (Claude by Anthropic). MIT License. -->
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#07090e">
<link rel="icon" href="data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20viewBox=%220%200%2062%2014%22%20shape-rendering=%22crispEdges%22%3E%3Crect%20x=%2238%22%20y=%220%22%20width=%223%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2238%22%20y=%221%22%20width=%229%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2239%22%20y=%222%22%20width=%2210%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2240%22%20y=%223%22%20width=%229%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2249%22%20y=%223%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%224%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2239%22%20y=%224%22%20width=%222%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2241%22%20y=%224%22%20width=%2210%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%222%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2238%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2239%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2241%22%20y=%225%22%20width=%226%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2248%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23000000%22/%3E%3Crect%20x=%2249%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2250%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%226%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%223%22%20y=%226%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2219%22%20y=%226%22%20width=%2216%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2238%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2240%22%20y=%226%22%20width=%227%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%226%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2248%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23000000%22/%3E%3Crect%20x=%2250%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%226%22%20width=%225%22%20height=%221%22%20fill=%22%23d0d0d0%22/%3E%3Crect%20x=%220%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%222%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%224%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2215%22%20y=%227%22%20width=%225%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2220%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2222%22%20y=%227%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2225%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2226%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2230%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2231%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2235%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2236%22%20y=%227%22%20width=%2216%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%227%22%20width=%229%22%20height=%221%22%20fill=%22%23d0d0d0%22/%3E%3Crect%20x=%2261%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%238a8a8a%22/%3E%3Crect%20x=%222%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%224%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%226%22%20y=%228%22%20width=%2211%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2217%22%20y=%228%22%20width=%223%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2220%22%20y=%228%22%20width=%226%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2226%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2227%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2231%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2232%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2236%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2237%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2239%22%20y=%228%22%20width=%229%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2248%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%238a8a8a%22/%3E%3Crect%20x=%222%22%20y=%229%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%224%22%20y=%229%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%226%22%20y=%229%22%20width=%226%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2212%22%20y=%229%22%20width=%223%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2215%22%20y=%229%22%20width=%2224%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2239%22%20y=%229%22%20width=%229%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2248%22%20y=%229%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%222%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%224%22%20y=%2210%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2212%22%20y=%2210%22%20width=%223%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2215%22%20y=%2210%22%20width=%2225%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2240%22%20y=%2210%22%20width=%227%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2211%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%2211%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%223%22%20y=%2211%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2214%22%20y=%2211%22%20width=%222%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2216%22%20y=%2211%22%20width=%2225%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2241%22%20y=%2211%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2212%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%2212%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%222%22%20y=%2212%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2218%22%20y=%2212%22%20width=%2221%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%220%22%20y=%2213%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3C/svg%3E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Chakra+Petch:wght@400;500;600;700&family=Orbitron:wght@500;700;900&family=Press+Start+2P&family=VT323&display=swap">
<title>Tikka</title>
<style>
:root {
  --z: 1;                  /* page scale, set by the script in <head> */
  /* HUD theme: cold charcoal steel with electric cyan and molten orange */
  --cabinet: #131a26;      /* panels */
  --cabinet-deep: #07090e; /* canvas */
  --surface: #0e131d;
  --elevated: #1a2332;
  --sisal: #e8f1f8;        /* main text, cool white */
  --sisal-ink: #07090e;
  --wire: #8497b3;         /* secondary text */
  --glow: #00e5ff;         /* electric cyan: active player, focus */
  --orange: #ff7a00;       /* molten orange: second accent, hover, multipliers */
  --red: #ff5a36;          /* hot orange-red: bust */
  --green: #a4ff3a;        /* neon lime: checkout, closed */
  --metal-dark: #222c3d;
  --metal-light: #52637a;
  --line: rgba(227, 32, 47, .2);
  --halo: 0 0 6px rgba(227, 32, 47, .9), 0 0 22px rgba(227, 32, 47, .55), 0 0 48px rgba(227, 32, 47, .3);
  --font-hud: "Orbitron", "Russo One", "Rajdhani", "Bahnschrift", system-ui, sans-serif;
  --font: "Chakra Petch", "JetBrains Mono", "Bahnschrift", "DIN Alternate", "Roboto Condensed", system-ui, sans-serif;
}
* { box-sizing: border-box; }
html, body { margin: 0; height: 100%; }
body {
  background: radial-gradient(120% 80% at 50% -10%, #0b1a33 0%, var(--cabinet-deep) 60%) fixed, var(--cabinet-deep);
  color: var(--sisal);
  font-family: var(--font);
  font-variant-numeric: tabular-nums;
  -webkit-tap-highlight-color: transparent;
  overflow: hidden;
}
button {
  font: inherit; color: inherit; background: none; border: 0; cursor: pointer;
  touch-action: manipulation;
}
button:focus-visible, input:focus-visible { outline: 3px solid var(--glow); outline-offset: 3px; }
.screen { display: none; height: calc(100dvh / var(--z)); }
.screen.on { display: flex; flex-direction: column; }

/* ---------- setup ---------- */
#setup { overflow-y: auto; padding: 32px max(20px, calc(6vw / var(--z))) 40px; gap: 28px; background: transparent; }
#setup h1 { color: var(--glow); text-shadow: var(--halo); }
#setup h1 { margin: 0; font-size: clamp(40px, calc(7vw / var(--z)), 72px); font-weight: 700; letter-spacing: -.01em; line-height: 1; }
#setup h2 { margin: 0 0 12px; font-size: 20px; font-weight: 600; color: var(--wire); }
#settings { overflow-y: auto; padding: 20px max(16px, calc(4vw / var(--z))) 32px; gap: 18px; }
#settings .shead { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
#settings h1 { margin: 0; font-size: 34px; color: var(--glow); text-shadow: var(--halo); }
#settings h2 { margin: 0 0 8px; font-size: 18px; font-weight: 600; color: var(--wire); }
.sgroup { padding: 14px 16px; border: 1px solid var(--line); border-radius: 14px; background: rgba(22, 19, 18, .7); max-width: 900px; }
.smsg { margin: 0; min-height: 1.3em; font-size: 15px; color: var(--green); }
.smsg.err { color: var(--red); }
.ulist { list-style: none; margin: 0 0 10px; padding: 0; display: grid; gap: 6px; }
.ulist li { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.ulist .uname { min-width: 9em; font-size: 17px; }
.ulist .badge { font-size: 12px; padding: 2px 8px; border: 1px solid currentColor; border-radius: 999px; color: var(--glow); }
.ulist button, .ulist input { font: inherit; font-size: 14px; }
.ulist button { padding: 5px 10px; border: 1px solid var(--line); border-radius: 8px; }
.ulist button.del { color: var(--red); border-color: rgba(255, 61, 187, .4); }
.sform { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 10px 14px; margin-top: 8px; }
.sform label { display: flex; flex-direction: column; gap: 4px; font-size: 13px; color: var(--wire); }
.sform label.check { flex-direction: row; align-items: center; gap: 6px; font-size: 15px; color: var(--sisal); padding-bottom: 10px; }
.sform input, .sform select, .ulist input { font: inherit; font-size: 16px; padding: 8px 10px; border-radius: 10px; border: 1px solid var(--line); background: var(--cabinet-deep); color: var(--sisal); min-width: 0; }
.sform input[type="number"] { width: 6em; }
.sform input[name="device_id"], .sform input[name="local_key"] { width: 15em; }
.sform input[type="checkbox"] { width: 18px; height: 18px; padding: 0; }
.row { display: flex; flex-wrap: wrap; gap: 10px; }
.chip {
  padding: 12px 18px; border-radius: 999px; border: 2px solid var(--line);
  font-size: 20px; min-height: 52px;
}
.chip[aria-pressed="true"] { background: rgba(46, 242, 255, .1); color: var(--glow); border-color: var(--glow); box-shadow: 0 0 14px rgba(46, 242, 255, .45), inset 0 0 10px rgba(46, 242, 255, .2); text-shadow: 0 0 8px rgba(46, 242, 255, .7); }
.chip .order { font-size: 14px; opacity: .7; margin-left: 6px; }
.add { display: flex; gap: 10px; margin-top: 12px; max-width: 520px; }
.add input {
  flex: 1; min-width: 0; font: inherit; font-size: 20px; padding: 12px 16px; border-radius: 12px;
  border: 2px solid var(--line); background: var(--cabinet-deep); color: var(--sisal);
}
.hint { color: var(--wire); font-size: 16px; margin: 8px 0 0; }
.start {
  align-self: flex-start; padding: 18px 40px; border-radius: 14px; font-size: 26px; font-weight: 700;
  background: var(--glow); color: var(--sisal-ink); box-shadow: 0 0 18px rgba(46, 242, 255, .7), 0 0 50px rgba(46, 242, 255, .35);
}
.start:disabled { opacity: .3; box-shadow: none; cursor: not-allowed; }
.link { color: var(--wire); text-decoration: underline; font-size: 16px; padding: 6px 0; }

/* ---------- game ---------- */
#game { background: transparent; }
.bar {
  display: flex; align-items: center; gap: 14px; padding: 10px 18px;
  border-bottom: 1px solid var(--line); color: var(--wire); font-size: 17px; min-height: 52px;
}
.bar .grow { flex: 1; }
.dot { width: 12px; height: 12px; border-radius: 50%; background: var(--wire); flex: none; }
.dot.ok { background: var(--green); box-shadow: 0 0 10px var(--green); }
.dot.wait { background: #ffc23d; box-shadow: 0 0 10px #ffc23d; }
.dot.off { background: var(--red); box-shadow: 0 0 10px var(--red); }
.bar button { padding: 8px 14px; border-radius: 10px; border: 1px solid var(--line); color: var(--sisal); }

.players { flex: 1; display: grid; grid-auto-flow: column; grid-auto-columns: 1fr; min-height: 0; }
.player {
  display: flex; flex-direction: column; justify-content: center; align-items: center; gap: 6px;
  padding: 16px; border-right: 1px solid var(--line); text-align: center; min-width: 0;
  transition: background-color .25s, color .25s;
}
.player:last-child { border-right: 0; }
.player .name { font-size: clamp(22px, calc(3.2vw / var(--z)), 40px); font-weight: 600; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.player .legs { font-size: clamp(15px, calc(1.8vw / var(--z)), 20px); color: var(--wire); }
.player { container-type: inline-size; }
.player .score { font-size: clamp(56px, 40cqi, 220px); font-weight: 700; line-height: .9; letter-spacing: -.03em; }
.player .route { font-size: clamp(18px, calc(2.4vw / var(--z)), 30px); min-height: 1.3em; color: var(--green); font-weight: 600; text-shadow: 0 0 10px rgba(164, 255, 58, .7); }
.player .recent { display: flex; justify-content: center; flex-wrap: wrap; gap: 4px 10px; min-height: 1.4em; font-size: clamp(14px, calc(1.7vw / var(--z)), 20px); color: var(--wire); }
.player .recent .new { color: var(--sisal); font-weight: 700; }
.player .stats { font-size: clamp(14px, calc(1.6vw / var(--z)), 18px); color: var(--wire); }
.player .score { text-shadow: 0 0 18px rgba(230, 247, 255, .18); }
.player.active { background: linear-gradient(180deg, rgba(46, 242, 255, .09), rgba(46, 242, 255, .02)); box-shadow: inset 0 0 0 2px var(--glow), inset 0 0 60px rgba(46, 242, 255, .18), 0 0 30px rgba(46, 242, 255, .25); }
.player.active .name { color: var(--glow); text-shadow: 0 0 10px rgba(46, 242, 255, .6); }
.player.active .score { color: var(--glow); text-shadow: var(--halo); }
.player.active.bust { background: linear-gradient(180deg, rgba(255, 61, 187, .12), rgba(255, 61, 187, .03)); box-shadow: inset 0 0 0 2px var(--red), inset 0 0 60px rgba(255, 61, 187, .22), 0 0 30px rgba(255, 61, 187, .3); }
.player.active.bust .name, .player.active.bust .route { color: var(--red); text-shadow: 0 0 10px rgba(255, 61, 187, .7); }
.player.active.bust .score { color: var(--red); text-shadow: 0 0 6px rgba(255, 61, 187, .9), 0 0 24px rgba(255, 61, 187, .6), 0 0 50px rgba(255, 61, 187, .35); }

.visit {
  display: grid; grid-template-columns: repeat(3, 1fr) auto; gap: 12px;
  padding: 14px 18px calc(14px + env(safe-area-inset-bottom)); border-top: 1px solid var(--line);
  background: rgba(22, 19, 18, .85);
}
.dart {
  min-height: 84px; border-radius: 14px; border: 2px dashed var(--line);
  font-size: clamp(28px, calc(4.5vw / var(--z)), 48px); font-weight: 700;
}
.dart.hit { border-style: solid; border-color: var(--glow); color: var(--glow); box-shadow: 0 0 14px rgba(46, 242, 255, .45), inset 0 0 14px rgba(46, 242, 255, .15); text-shadow: 0 0 10px rgba(46, 242, 255, .7); }
.dart.edited { border-color: var(--green); color: var(--green); box-shadow: 0 0 14px rgba(164, 255, 58, .45); text-shadow: 0 0 10px rgba(164, 255, 58, .7); }
.total { min-width: 120px; display: flex; flex-direction: column; justify-content: center; align-items: flex-end; padding-right: 6px; }
.total b { font-size: clamp(36px, calc(6vw / var(--z)), 64px); line-height: 1; }
.total b { color: var(--glow); text-shadow: var(--halo); }
.total span { font-size: 16px; color: var(--wire); }

.banner {
  position: fixed; inset: 0; display: none; place-items: center; text-align: center;
  background: rgba(12, 10, 9, .9); backdrop-filter: blur(4px); z-index: 5; padding: 24px;
}
.banner.on { display: grid; }
.banner h2 { margin: 0 0 8px; font-size: clamp(44px, calc(9vw / var(--z)), 110px); line-height: 1; }
.banner h2 { color: var(--glow); text-shadow: var(--halo); }
.banner p { margin: 0 0 24px; font-size: 22px; color: var(--wire); }
.banner .row { justify-content: center; }

/* ---------- keypad ---------- */
.pad { position: fixed; inset: 0; display: none; background: rgba(0,0,0,.6); z-index: 6; align-items: flex-end; justify-content: center; }
.pad.on { display: flex; }
.pad .sheet { background: var(--cabinet); box-shadow: 0 -10px 40px rgba(46, 242, 255, .2); border-top: 1px solid var(--glow); width: min(760px, 100%); border-radius: 18px 18px 0 0; padding: 18px 18px calc(18px + env(safe-area-inset-bottom)); }
.pad .mult { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 10px; }
.pad .nums { display: grid; grid-template-columns: repeat(7, 1fr); gap: 8px; }
.pad button { min-height: 56px; border-radius: 10px; border: 1px solid var(--line); font-size: 22px; font-weight: 600; }
.pad .mult button[aria-pressed="true"] { color: var(--glow); border-color: var(--glow); box-shadow: 0 0 12px rgba(46, 242, 255, .5); }
.pad .foot { display: flex; justify-content: space-between; margin-top: 12px; }
#pad { z-index: 7; }
/* passive display */
#passive { background: transparent; }
.pbar { display: flex; align-items: center; gap: 14px; padding: 8px 18px; color: var(--wire); font-size: 17px; border-bottom: 1px solid var(--line); }
.pbar .grow { flex: 1; }
#p-lock { color: var(--red); font-weight: 600; }
.pbar button { padding: 8px 14px; border-radius: 10px; border: 1px solid var(--line); color: var(--sisal); opacity: .6; }
.pmain { flex: 1; display: flex; min-height: 0; }
.pboard { width: min(calc(88vh / var(--z)), calc(50vw / var(--z))); flex: none; display: flex; flex-direction: column; justify-content: center; gap: 10px; padding: 14px; border-right: 1px solid var(--line); }
.pboard svg { width: 100%; height: auto; display: block; }
.pcap { font-size: clamp(16px, calc(2vw / var(--z)), 24px); color: var(--wire); text-align: center; }
.phits { display: flex; flex-wrap: wrap; justify-content: center; gap: 8px; min-height: 2.2em; }
.phits span { padding: 4px 12px; border-radius: 999px; border: 2px solid; font-size: clamp(18px, calc(2.4vw / var(--z)), 32px); font-weight: 700; }
.pplayers { flex: 1; display: flex; flex-direction: column; min-width: 0; overflow-y: auto; }
.pp { flex: 1; min-height: 120px; display: grid; grid-template-columns: 1fr auto; align-items: center; gap: 4px 16px; padding: 12px 22px; border-bottom: 1px solid var(--line); }
.pp .nm { font-size: clamp(20px, calc(3vw / var(--z)), 40px); font-weight: 600; }
.pp .nm small { margin-left: 12px; font-size: .55em; color: var(--wire); font-weight: 400; }
.pp .big { grid-row: span 2; font-size: clamp(56px, calc(11vw / var(--z)), 150px); font-weight: 700; line-height: 1; text-align: right; }
.pp .sub { font-size: clamp(14px, calc(1.8vw / var(--z)), 22px); color: var(--green); }
.pp .rec { grid-column: 1 / -1; display: flex; flex-wrap: wrap; gap: 4px 14px; font-size: clamp(16px, calc(2.2vw / var(--z)), 30px); color: var(--wire); min-height: 1.4em; }
.pp .rec .new { color: var(--sisal); font-weight: 700; }
.pp.active { background: linear-gradient(90deg, rgba(46, 242, 255, .09), rgba(46, 242, 255, .02)); box-shadow: inset 4px 0 0 var(--glow); }
.pp.active .nm, .pp.active .big { color: var(--glow); text-shadow: var(--halo); }
.pp.active.bust .nm, .pp.active.bust .big { color: var(--red); text-shadow: 0 0 24px rgba(255, 61, 187, .6); }
.pp.out { opacity: .45; }
@media (max-width: 900px) { .pmain { flex-direction: column; overflow-y: auto; } .pboard { width: 100%; border-right: 0; border-bottom: 1px solid var(--line); } .pboard svg { width: min(calc(70vw / var(--z)), calc(60vh / var(--z))); margin: 0 auto; } }
#fix .sheet { max-height: calc(80dvh / var(--z)); display: flex; flex-direction: column; }
#fix h3 { margin: 0 0 4px; font-size: 24px; color: var(--glow); text-shadow: 0 0 10px rgba(46, 242, 255, .6); }
#fix p { margin: 0 0 12px; color: var(--wire); font-size: 16px; }
#fix-list { overflow-y: auto; display: flex; flex-direction: column; gap: 8px; }
.frow { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border: 1px solid var(--line); border-radius: 12px; }
.frow .who { flex: 1; min-width: 0; font-size: 18px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.frow .who small { display: block; font-size: 13px; color: var(--wire); }
.frow .pts { min-width: 44px; text-align: right; font-size: 22px; font-weight: 700; color: var(--sisal); }
.frow button { min-width: 64px; min-height: 52px; padding: 0 10px; border-radius: 10px; border: 1px solid var(--glow); color: var(--glow); font-size: 22px; font-weight: 700; }
.frow button.add { border-style: dashed; border-color: var(--line); color: var(--wire); }
.frow.fixed { box-shadow: inset 0 0 0 2px var(--green); }

.raw { position: fixed; right: 12px; bottom: 120px; max-width: min(520px, calc(90vw / var(--z))); max-height: calc(40vh / var(--z)); overflow: auto;
  background: #000; color: var(--green); font: 13px/1.4 ui-monospace, monospace; padding: 10px; border-radius: 8px; display: none; z-index: 4; white-space: pre-wrap; }
.raw.on { display: block; }

@media (max-width: 700px) {
  .bar { flex-wrap: wrap; gap: 8px; padding: 8px 12px; font-size: 15px; }
  .bar #match-text { display: none; }
  .bar #conn-text { flex: 1; }
  .bar button { padding: 6px 10px; font-size: 15px; }
  .player .stats, .player .route, .player .recent { flex-basis: 100%; justify-content: flex-start; }
  .players { grid-auto-flow: row; grid-auto-rows: 1fr; grid-auto-columns: auto; }
  .player { border-right: 0; border-bottom: 1px solid var(--line); flex-direction: row; flex-wrap: wrap; justify-content: space-between; text-align: left; padding: 10px 16px; }
  .player .score { font-size: clamp(56px, calc(18vw / var(--z)), 96px); }
  .visit { grid-template-columns: repeat(3, 1fr); }
  .total { grid-column: 1 / -1; flex-direction: row; justify-content: space-between; align-items: baseline; }
}
@media (prefers-reduced-motion: reduce) { .player { transition: none; } }

/* ---------- additions for all games ---------- */
.manage { margin-top: 14px; padding: 16px; border: 1px solid var(--line); border-radius: 14px; max-width: 640px; background: rgba(22, 19, 18, .7); }
.manage ul { list-style: none; margin: 0 0 6px; padding: 0; display: grid; gap: 8px; }
.manage li { display: flex; gap: 8px; align-items: center; }
.manage li input { flex: 1; min-width: 0; font: inherit; font-size: 19px; padding: 9px 12px; border-radius: 10px; border: 1px solid var(--line); background: var(--cabinet-deep); color: var(--sisal); }
.manage li button { min-width: 46px; min-height: 46px; border-radius: 10px; border: 1px solid var(--line); font-size: 18px; }
.manage li button:disabled { opacity: .25; cursor: default; }
.manage li button.del { color: var(--red); border-color: rgba(255, 61, 187, .4); padding: 0 12px; }
.manage li .count { font-size: 14px; color: var(--wire); min-width: 4.5em; text-align: right; }
.rule { color: var(--wire); font-size: 17px; margin: 10px 0 0; max-width: 62ch; line-height: 1.4; }
.opt-group { margin-top: 16px; }
.who .link { margin-left: 10px; font-size: inherit; padding: 0; }
.rules { margin-top: 10px; max-width: 90ch; color: var(--wire); font-size: 16px; line-height: 1.4; }
.rules summary { display: inline-block; cursor: pointer; padding: 5px 14px; border: 1px solid var(--line); border-radius: 999px; color: var(--sisal); font-size: 15px; list-style: none; }
.rules summary::-webkit-details-marker { display: none; }
.rules summary::after { content: ' ▾'; color: var(--wire); }
.rules[open] summary::after { content: ' ▴'; }
.rules[open] summary { color: var(--glow); border-color: var(--glow); }
.rules ul { margin: 8px 0 0; padding-left: 1.2em; }
.rules li { margin: 2px 0; }
.rules li b { color: var(--sisal); font-weight: 600; }
.rules h3 { margin: 10px 0 0; font-size: 14px; font-weight: 600; color: var(--wire); }
.opt-group h3 { margin: 0 0 8px; font-size: 16px; font-weight: 600; color: var(--wire); }
/* Compact menu on tablets, laptops and TVs: the whole setup fits about 1200x900 without scrolling. */
@media (min-width: 701px) {
  #setup { padding: 20px max(20px, calc(4vw / var(--z))) 24px; gap: 16px; }
  #setup h1 { font-size: clamp(34px, calc(4.5vw / var(--z)), 52px); }
  #setup h2 { margin: 0 0 8px; font-size: 17px; }
  .row { gap: 8px; }
  .chip { padding: 8px 15px; font-size: 18px; min-height: 44px; }
  .hint { font-size: 14px; margin-top: 6px; }
  .rule { font-size: 15px; margin-top: 6px; max-width: 90ch; }
  #game-opts { display: flex; flex-wrap: wrap; gap: 0 28px; }
  .opt-group { margin-top: 10px; }
  .opt-group h3 { margin: 0 0 6px; font-size: 14px; }
  .start { padding: 13px 34px; font-size: 22px; }
  .add { margin-top: 0; }
}
.marks { display: grid; grid-template-columns: auto auto; gap: 2px 14px; margin-top: 6px; font-size: clamp(16px, calc(2vw / var(--z)), 24px); }
.marks .mk { display: contents; }
.marks .t { text-align: right; color: inherit; opacity: .75; }
.marks .m { text-align: left; font-weight: 700; min-width: 1.6em; letter-spacing: .05em; }
.marks.many { grid-template-columns: repeat(4, auto); }
.marks .m.closed { color: var(--green); text-shadow: 0 0 8px rgba(164, 255, 58, .8); }
.player.out { opacity: .4; }
.player .tag { font-size: clamp(14px, calc(1.6vw / var(--z)), 18px); padding: 2px 10px; border-radius: 999px; border: 1px solid currentColor; }
.arena { flex: 1; display: flex; min-height: 0; }
.arena .players { flex: 1; }
.boardview { width: min(calc(46vh / var(--z)), calc(36vw / var(--z))); flex: none; display: flex; flex-direction: column; justify-content: center; gap: 10px; padding: 14px; border-left: 1px solid var(--line); }
.boardview svg { width: 100%; height: auto; display: block; }
.boardview .cap { font-size: 16px; color: var(--wire); text-align: center; }
.legend { display: flex; flex-wrap: wrap; justify-content: center; gap: 6px 14px; font-size: 16px; }
.legend i { display: inline-block; width: 12px; height: 12px; border-radius: 50%; margin-right: 6px; vertical-align: -1px; }
.bar .reset { color: var(--wire); }
@media (max-width: 700px) {
  .arena { flex-direction: column; }
  .boardview { width: 100%; border-left: 0; border-top: 1px solid var(--line); flex-direction: row; align-items: center; padding: 8px 12px; }
  .boardview svg { width: calc(34vw / var(--z)); }
  .boardview .side { flex: 1; }
}
@media (max-width: 700px) {
  .marks { display: flex; flex-wrap: wrap; gap: 4px 14px; flex-basis: 100%; }
  .marks .mk { display: inline-flex; gap: 4px; }
  .marks .m { min-width: 1em; }
  .arena { overflow-y: auto; }
  .arena .players { flex: none; grid-auto-rows: auto; }
  .player .score { font-size: clamp(48px, calc(18vw / var(--z)), 96px); }
}

/* ---------- compact phone layout (menu and game) ---------- */
@media (max-width: 700px) {
  /* menu */
  #setup { padding: 16px 16px 24px; gap: 14px; }
  #setup h1 { font-size: 32px; }
  #setup h2 { margin: 0 0 6px; font-size: 15px; }
  .row { gap: 6px; }
  .chip { padding: 7px 12px; font-size: 15px; min-height: 40px; border-width: 1.5px; }
  .hint { font-size: 13px; margin-top: 4px; }
  .rule { font-size: 13px; margin-top: 4px; line-height: 1.35; }
  #game-opts { display: flex; flex-wrap: wrap; gap: 0 16px; }
  .opt-group { margin-top: 8px; }
  .opt-group h3 { margin: 0 0 4px; font-size: 13px; }
  .start { padding: 11px 24px; font-size: 19px; border-radius: 12px; }
  .link { font-size: 14px; padding: 4px 0; }
  .add { margin-top: 0; }
  .add input { font-size: 15px; padding: 8px 10px; }
  .rules { font-size: 13px; margin-top: 6px; }
  .rules summary { font-size: 13px; padding: 4px 12px; }

  /* game: top bar in two short rows */
  .bar { gap: 6px; padding: 6px 10px; min-height: 0; font-size: 13px; }
  .bar button { padding: 5px 8px; font-size: 13px; border-radius: 8px; }
  .bar #conn-text { flex: 1 1 auto; }

  /* players: one compact row each, score on the right */
  .player {
    display: grid; grid-template-columns: minmax(0, 1fr) auto; column-gap: 12px; row-gap: 1px;
    align-items: center; justify-items: start; text-align: left; padding: 6px 14px;
  }
  .player > * { grid-column: 1; }
  .player .name { font-size: 19px; }
  .player .legs { font-size: 12px; }
  .player .score { grid-column: 2; grid-row: 1 / span 4; justify-self: end; font-size: 48px; line-height: 1; }
  .player .route { font-size: 14px; min-height: 0; }
  .player .route:empty { display: none; }
  .player .stats, .player .recent { font-size: 12px; min-height: 0; gap: 2px 8px; flex-basis: auto; }
  .player .recent:empty { display: none; }
  .marks { font-size: 13px; margin-top: 2px; }

  /* board: smaller, legend beside it */
  .boardview { padding: 4px 12px; gap: 10px; }
  .boardview svg { width: min(52vw, 30vh); flex: none; }
  .boardview .cap, .legend { font-size: 12px; }

  /* this visit: three darts and the total on one row */
  .visit { grid-template-columns: repeat(3, 1fr) auto; gap: 8px; padding: 8px 10px calc(8px + env(safe-area-inset-bottom)); }
  .dart { min-height: 52px; font-size: 24px; border-radius: 10px; }
  .total { grid-column: auto; flex-direction: column; justify-content: center; align-items: flex-end; min-width: 58px; padding-right: 2px; }
  .total b { font-size: 32px; }
  .total span { font-size: 11px; }
}

/* ---------- HUD look: steel panels, cyan/orange corner lights, telemetry type ---------- */
body {
  background:
    linear-gradient(to right, rgba(227, 32, 47, .05) 1px, transparent 1px) 0 0 / 24px 24px,
    linear-gradient(to bottom, rgba(227, 32, 47, .05) 1px, transparent 1px) 0 0 / 24px 24px,
    radial-gradient(120% 80% at 50% -10%, #101a2b 0%, var(--cabinet-deep) 62%) fixed, var(--cabinet-deep);
}
/* Metallic chrome titles */
#setup h1, #settings h1, #fix h3, .banner h2 {
  font-family: var(--font-hud); text-transform: uppercase; font-style: italic; font-weight: 900; letter-spacing: .02em;
  background: linear-gradient(180deg, #ffffff 0%, #cbd5e1 45%, #475569 50%, #94a3b8 100%);
  -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; color: transparent;
  text-shadow: none; filter: drop-shadow(0 2px 4px rgba(0, 0, 0, .9));
}
/* A dart in front of the main title (also the page icon) */
#setup h1::before {
  content: ''; display: inline-block; width: .95em; height: .95em; margin-right: .3em; vertical-align: -.12em;
  background: url("data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20viewBox=%220%200%2064%2064%22%3E%3Cg%20stroke-linecap=%22round%22%20stroke-linejoin=%22round%22%3E%3Cpath%20d=%22M5%2059%20L15%2049%22%20stroke=%22%23e2e8f0%22%20stroke-width=%223%22/%3E%3Cpath%20d=%22M15%2049%20L30%2034%22%20stroke=%22%2394a3b8%22%20stroke-width=%227%22/%3E%3Cpath%20d=%22M19%2045%20L26%2038%22%20stroke=%22%23475569%22%20stroke-width=%222%22/%3E%3Cpath%20d=%22M30%2034%20L42%2022%22%20stroke=%22%2300e5ff%22%20stroke-width=%223%22/%3E%3Cpath%20d=%22M40%2024%20L43%2011%20L57%207%20L53%2021%20Z%22%20fill=%22%2300e5ff%22%20stroke=%22%2300e5ff%22%20stroke-width=%221%22/%3E%3Cpath%20d=%22M40%2024%20L53%2021%20L57%207%20L47%2015%20Z%22%20fill=%22%23ff7a00%22%20stroke=%22%23ff7a00%22%20stroke-width=%221%22/%3E%3C/g%3E%3C/svg%3E") center / contain no-repeat;
  filter: drop-shadow(0 0 6px rgba(227, 32, 47, .6));
}
#setup h2, #settings h2, .opt-group h3 { font-family: var(--font-hud); font-size: .8em; font-weight: 700; text-transform: uppercase; letter-spacing: .14em; color: var(--wire); }
#setup h2::before, .opt-group h3::before { content: '◢ '; color: var(--orange); font-size: .8em; }
.rules h3 { font-family: var(--font-hud); }

/* Panels get the HUD frame: metal border, cyan light top-left, orange light bottom-right */
.sgroup, .manage, .pad .sheet, .boardview, .pboard, .frow, .rules[open] {
  position: relative; background: var(--surface); border-color: var(--metal-dark); border-radius: 4px;
  box-shadow: 0 0 0 1px var(--metal-dark), 0 12px 30px rgba(0, 0, 0, .7);
}
.sgroup::before, .manage::before, .boardview::before, .pboard::before, .pad .sheet::before,
.sgroup::after, .manage::after, .boardview::after, .pboard::after, .pad .sheet::after { content: ''; position: absolute; height: 2px; pointer-events: none; }
.sgroup::before, .boardview::before, .pboard::before, .pad .sheet::before { top: 0; left: 0; right: 50%; background: linear-gradient(90deg, var(--glow), transparent); }
.sgroup::after, .boardview::after, .pboard::after, .pad .sheet::after { bottom: 0; left: 50%; right: 0; background: linear-gradient(90deg, transparent, var(--orange)); }
.pad .sheet { border-top: 0; border-radius: 4px 4px 0 0; }
.boardview, .pboard { background: var(--surface) linear-gradient(to right, rgba(227, 32, 47, .05) 1px, transparent 1px) 0 0 / 24px 24px, linear-gradient(to bottom, rgba(227, 32, 47, .05) 1px, transparent 1px) 0 0 / 24px 24px; }
/* glowing rim round the live board */
.boardview svg, .pboard svg { filter: drop-shadow(0 0 10px rgba(227, 32, 47, .45)) drop-shadow(0 0 3px rgba(255, 122, 0, .5)); }

/* Player cards */
.player { position: relative; }
.player::before, .player::after { content: ''; position: absolute; height: 2px; pointer-events: none; opacity: .35; }
.player::before { top: 0; left: 0; right: 50%; background: linear-gradient(90deg, var(--glow), transparent); }
.player::after { bottom: 0; left: 50%; right: 0; background: linear-gradient(90deg, transparent, var(--orange)); }
.player.active::before, .player.active::after { opacity: 1; height: 3px; }
.player .name, .pp .nm { font-family: var(--font-hud); font-weight: 700; text-transform: uppercase; letter-spacing: .06em; }
.player .score, .pp .big, .total b { font-family: var(--font-hud); font-weight: 900; }
.player .score, .pp .big { letter-spacing: 0; }
@media (min-width: 701px) { .player .score { font-size: clamp(52px, 30cqi, 190px); } }
.player.active { background: linear-gradient(180deg, rgba(227, 32, 47, .1), rgba(227, 32, 47, .02)); box-shadow: inset 0 0 0 1px var(--glow), inset 0 0 60px rgba(227, 32, 47, .16), 0 0 30px rgba(227, 32, 47, .2); }
.player.active.bust, .pp.active.bust { background: linear-gradient(180deg, rgba(255, 90, 54, .14), rgba(255, 90, 54, .03)); box-shadow: inset 0 0 0 1px var(--red), inset 0 0 60px rgba(255, 90, 54, .22), 0 0 30px rgba(255, 90, 54, .3); }
.player.active.bust .name, .player.active.bust .route { color: var(--red); text-shadow: 0 0 10px rgba(255, 90, 54, .7); }
.player.active.bust .score { color: var(--red); text-shadow: 0 0 6px rgba(255, 90, 54, .9), 0 0 24px rgba(255, 90, 54, .6), 0 0 50px rgba(255, 90, 54, .35); }
.pp.active.bust .nm, .pp.active.bust .big { color: var(--red); text-shadow: 0 0 24px rgba(255, 90, 54, .6); }
.pp.active { box-shadow: inset 4px 0 0 var(--glow), inset 0 -2px 0 -1px var(--orange); }
.player .stats, .player .recent, .player .legs, .marks, .pp .rec, .pp .sub { font-family: var(--font); font-weight: 500; }

/* Telemetry tags: chamfered corners, monospaced numerals */
.player .tag, .ulist .badge {
  border: 0; border-radius: 0; padding: 3px 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .08em;
  background: rgba(227, 32, 47, .14); color: var(--glow);
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
}
.phits span { border-radius: 0; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); border-width: 2px; font-family: var(--font); }

/* Chips and buttons: beveled, uppercase; cyan = selected/primary, orange = hover on secondary */
.chip { border-radius: 0; clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%); border-color: var(--metal-light); background: var(--surface); text-transform: uppercase; letter-spacing: .05em; font-weight: 600; transition: border-color .15s, box-shadow .15s, color .15s; }
.chip:hover { border-color: var(--orange); color: var(--orange); }
.chip[aria-pressed="true"] { background: rgba(227, 32, 47, .12); color: var(--glow); border-color: var(--glow); box-shadow: inset 0 0 12px rgba(227, 32, 47, .25); }
.chip[aria-pressed="true"]:hover { color: var(--glow); border-color: var(--glow); }
.start {
  border-radius: 0; clip-path: polygon(16px 0, 100% 0, calc(100% - 16px) 100%, 0 100%);
  background: var(--elevated); color: var(--glow); border: 2px solid var(--glow);
  font-family: var(--font-hud); font-style: italic; font-weight: 900; text-transform: uppercase; letter-spacing: .08em;
  box-shadow: inset 0 0 18px rgba(227, 32, 47, .25); transition: box-shadow .15s, background .15s;
}
.start:hover:not(:disabled) { background: rgba(227, 32, 47, .16); box-shadow: inset 0 0 28px rgba(227, 32, 47, .45), 0 0 18px rgba(227, 32, 47, .6); }
.start:disabled { border-color: var(--metal-light); color: var(--wire); box-shadow: none; }
.bar { background: linear-gradient(180deg, var(--surface), rgba(22, 19, 18, .6)); border-bottom: 1px solid var(--metal-dark); font-family: var(--font); letter-spacing: .03em; }
.bar button, .pbar button, .ulist button, .pad button, .manage li button, .frow button.add {
  border-radius: 2px; border: 1px solid var(--metal-light); color: var(--wire); background: transparent; text-transform: uppercase; letter-spacing: .06em; font-weight: 600; transition: border-color .15s, color .15s, box-shadow .15s;
}
.bar button:hover, .pbar button:hover, .ulist button:hover, .pad button:hover, .manage li button:hover:not(:disabled), .frow button.add:hover, .link:hover {
  border-color: var(--orange); color: var(--orange); box-shadow: 0 0 12px rgba(255, 122, 0, .4);
}
.bar button#btn-next, .pad .foot button.primary { border-color: var(--glow); color: var(--glow); }
.link { color: var(--wire); text-transform: uppercase; letter-spacing: .06em; font-size: 14px; }
.ulist button.del, .manage li button.del { color: var(--red); border-color: rgba(255, 90, 54, .5); }
.dot { background: transparent; border: 2px solid var(--wire); width: 14px; height: 14px; position: relative; }
.dot::after { content: ''; position: absolute; inset: 2px; border-radius: 50%; background: currentColor; opacity: 0; }
.dot.ok { border-color: var(--glow); background: transparent; box-shadow: 0 0 10px var(--glow), inset 0 0 6px var(--glow); }
.dot.wait { border-color: var(--orange); background: transparent; box-shadow: 0 0 10px var(--orange); }
.dot.off { border-color: var(--red); background: transparent; box-shadow: 0 0 10px var(--red); }
.sform input, .sform select, .ulist input, .add input, .manage li input { border-radius: 2px; border-color: var(--metal-light); background: var(--cabinet-deep); font-family: var(--font); }
.sform input:focus, .sform select:focus, .ulist input:focus, .add input:focus, .manage li input:focus { border-color: var(--glow); box-shadow: 0 0 12px rgba(227, 32, 47, .35); outline: none; }

/* Visit darts: cyan reticle slots, orange when corrected by hand */
.visit { background: linear-gradient(0deg, var(--surface), rgba(22, 19, 18, .7)); border-top: 1px solid var(--metal-dark); }
.dart { border-radius: 2px; border: 2px dashed var(--metal-light); font-family: var(--font-hud); font-weight: 700; }
.dart.hit { border-color: var(--glow); color: var(--glow); }
.dart.edited { border-color: var(--orange); color: var(--orange); box-shadow: 0 0 14px rgba(255, 122, 0, .45), inset 0 0 14px rgba(255, 122, 0, .15); text-shadow: 0 0 10px rgba(255, 122, 0, .7); }
.total b { text-shadow: var(--halo); }
.total span { font-family: var(--font); text-transform: uppercase; letter-spacing: .1em; }
.marks .m.closed, .frow.fixed { }
.frow.fixed { box-shadow: inset 0 0 0 2px var(--orange); }
.frow button { border-radius: 2px; border-color: var(--glow); }
.pad .mult button[aria-pressed="true"] { border-color: var(--glow); color: var(--glow); }
.rules summary { border-radius: 0; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); border-color: var(--metal-light); text-transform: uppercase; letter-spacing: .06em; }
.rules summary:hover { border-color: var(--orange); }
.banner { background: radial-gradient(60% 60% at 50% 45%, rgba(227, 32, 47, .12), rgba(12, 10, 9, .94)); }
/* ---------- clearer sections: every block of the menu is its own framed panel ---------- */
:root { --panel-border: #3d4e69; }
.panel, .sgroup, .manage {
  background: linear-gradient(180deg, rgba(40, 34, 32, .85), rgba(22, 19, 18, .92));
  border: 1px solid var(--panel-border); border-left: 3px solid var(--glow); border-radius: 4px;
  padding: 14px 18px 16px; box-shadow: 0 0 0 1px rgba(0, 0, 0, .6), 0 10px 26px rgba(0, 0, 0, .55);
  position: relative;
}
.panel::before, .panel::after { content: ''; position: absolute; height: 2px; pointer-events: none; }
.panel::before { top: -1px; left: 0; right: 50%; background: linear-gradient(90deg, var(--glow), transparent); }
.panel::after { bottom: -1px; left: 50%; right: 0; background: linear-gradient(90deg, transparent, var(--orange)); }
.panel > h2, .sgroup > h2 {
  display: flex; align-items: center; margin: 0 0 12px; padding-bottom: 9px; border-bottom: 1px solid var(--panel-border);
  color: var(--sisal); font-size: 15px; letter-spacing: .16em;
}
.panel > h2::before, .sgroup > h2::before { content: '◢'; color: var(--orange); margin-right: .6em; font-size: .85em; }
.panel.actions { padding: 14px 18px; }
.split { display: flex; flex-wrap: wrap; gap: 14px 40px; }
.split h3 { margin: 0 0 8px; font-family: var(--font-hud); font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .14em; color: var(--wire); }
.rules { border-top: 1px dashed var(--panel-border); padding-top: 10px; }
#game-opts { margin-top: 12px; padding-top: 6px; border-top: 1px dashed var(--panel-border); }
.opt-group h3::before { content: ''; margin: 0; }
.sgroup, .manage { max-width: 900px; }
.manage { margin-top: 12px; border-left-color: var(--orange); background: rgba(12, 10, 9, .55); }
@media (max-width: 700px) {
  .panel, .sgroup, .manage { padding: 10px 12px 12px; }
  .panel > h2, .sgroup > h2 { margin-bottom: 8px; padding-bottom: 6px; font-size: 13px; }
  .split { gap: 8px 24px; }
}
/* ---------- last three turns, end screen ---------- */
.history { display: flex; flex-wrap: wrap; align-items: center; gap: 6px 10px; padding: 8px 18px; border-top: 1px solid var(--panel-border); background: rgba(12, 10, 9, .6); font-family: var(--font); min-height: 44px; }
.history:empty { display: none; }
.history::before { content: 'Last turns'; font-family: var(--font-hud); font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .14em; color: var(--wire); margin-right: 4px; }
.turn { display: inline-flex; align-items: baseline; gap: 8px; padding: 4px 12px; border: 1px solid var(--c, var(--metal-light)); border-left-width: 4px; background: rgba(40, 34, 32, .7); font-size: 17px; opacity: .75; }
.turn b { color: var(--c, var(--sisal)); font-weight: 700; text-transform: uppercase; letter-spacing: .05em; font-size: .9em; }
.turn i { font-style: normal; letter-spacing: .04em; }
.turn em { font-style: normal; font-weight: 700; color: var(--glow); }
.turn.new { opacity: 1; box-shadow: 0 0 12px rgba(227, 32, 47, .25); }
.phist { padding: 6px 4px; border: 0; background: none; justify-content: center; }
.phist .turn { font-size: clamp(14px, calc(1.7vw / var(--z)), 22px); }
.chip.danger:hover { border-color: var(--red); color: var(--red); }
.player .tag.finish { color: var(--green); border-color: var(--green); box-shadow: 0 0 10px rgba(164, 255, 58, .35); }
.dart.unsure { border-style: dashed; border-color: var(--orange); color: var(--orange); box-shadow: 0 0 14px rgba(255, 122, 0, .35); }
.dart.unsure::after { content: ' ?'; font-size: .6em; vertical-align: super; }
.evidence { margin: 0 0 12px; text-align: center; }
.evidence img { max-width: 100%; max-height: calc(38vh / var(--z)); border: 1px solid var(--panel-border); cursor: pointer; display: block; margin: 0 auto; }
.evidence .hint { margin: 4px 0 0; }
.bar #btn-end:hover { border-color: var(--red); color: var(--red); box-shadow: 0 0 12px rgba(255, 90, 54, .4); }
.endscreen { z-index: 9; }
.endcard h2 { font-size: clamp(34px, calc(6vw / var(--z)), 72px); }
/* the top bar of the game has many buttons: keep each on one line, wrap the bar if it must */
.bar { flex-wrap: wrap; row-gap: 6px; }
.bar button { white-space: nowrap; font-size: 14px; padding: 8px 11px; letter-spacing: .04em; }
.bar #conn-text, .bar .grow { white-space: nowrap; }
.bar .grow { overflow: hidden; text-overflow: ellipsis; min-width: 0; }
.endcard { width: min(720px, 100%); }
.endcard .kicker { margin: 0 0 6px; font-family: var(--font-hud); font-size: 14px; letter-spacing: .3em; text-transform: uppercase; color: var(--orange); }
.endcard h2 { margin-bottom: 4px; }
.endcard #end-sub { margin: 0 0 18px; }
#end-table { display: grid; gap: 6px; margin: 0 0 16px; text-align: left; }
.er { display: grid; grid-template-columns: 2em 1fr auto auto; align-items: center; gap: 12px; padding: 10px 16px; border: 1px solid var(--panel-border); border-left: 3px solid var(--metal-light); background: rgba(40, 34, 32, .8); font-size: 20px; }
.er .pos { font-family: var(--font-hud); color: var(--wire); }
.er .nm { font-family: var(--font-hud); text-transform: uppercase; letter-spacing: .06em; font-weight: 700; }
.er .lg { color: var(--wire); font-size: .8em; }
.er .bg { font-family: var(--font-hud); font-weight: 900; min-width: 2.5em; text-align: right; }
.er.win { border-color: var(--glow); border-left-color: var(--orange); box-shadow: 0 0 22px rgba(227, 32, 47, .3), inset 0 0 20px rgba(227, 32, 47, .12); }
.er.win .nm, .er.win .bg { color: var(--glow); text-shadow: var(--halo); }
.endnote { margin: 0 0 18px !important; font-size: 16px !important; color: var(--green) !important; min-height: 1.3em; }
@media (max-width: 700px) {
  .history { padding: 6px 10px; gap: 4px 6px; min-height: 0; }
  .turn { font-size: 13px; padding: 3px 8px; gap: 5px; }
  .er { font-size: 16px; padding: 8px 10px; gap: 8px; }
}
@media (prefers-reduced-motion: reduce) { .chip, .start, .bar button { transition: none; } }

/* ================= phones: thumb-first layout =================
   Portrait phones (up to 700 px wide). The design rules: the one main action sits at the bottom where the thumb is,
   every tap target is at least 44 px, nothing scrolls sideways except the games row, and text fields use 16 px so
   iPhones do not zoom when they are tapped. */
#btn-more { display: none; }
.pad .grab { display: none; }
@media (max-width: 700px) {
  html, body { overscroll-behavior: none; }
  button, .chip, input, select { touch-action: manipulation; }

  /* ---- menu */
  #setup { padding: 12px 14px calc(96px + env(safe-area-inset-bottom)); gap: 12px; }
  #setup > *, #settings > * { flex-shrink: 0; }      /* the menu scrolls; its parts must not be squeezed */
  #setup h1 { font-size: 26px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; padding: 2px 0; }
  #setup h1::before { width: 1em; height: 1em; }
  .panel, .sgroup, .manage { padding: 10px 12px 12px; }
  .panel > h2, .sgroup > h2 { font-size: 12px; margin-bottom: 8px; padding-bottom: 6px; }
  .chip { min-height: 44px; padding: 8px 14px; font-size: 15px; }
  #roster .chip { min-width: 72px; justify-content: center; }
  /* the sixteen games: one row that scrolls sideways, with a hint of the next chip at the edge */
  #opt-game { flex-wrap: nowrap; overflow-x: auto; scroll-snap-type: x proximity; -webkit-overflow-scrolling: touch;
              margin: 0 -12px; padding: 2px 12px 8px; scrollbar-width: none;
              mask-image: linear-gradient(90deg, transparent 0, #000 12px, #000 calc(100% - 24px), transparent 100%);
              -webkit-mask-image: linear-gradient(90deg, transparent 0, #000 12px, #000 calc(100% - 24px), transparent 100%); }
  #opt-game::-webkit-scrollbar { display: none; }
  #opt-game .chip { flex: none; scroll-snap-align: center; }
  .split { gap: 10px 18px; }
  #game-opts { gap: 0 14px; }
  /* Start sticks to the bottom of the screen, full width, where the thumb is */
  #start-row { position: fixed; left: 0; right: 0; bottom: 0; z-index: 3; margin: 0; border-radius: 0; border-left: 0;
               padding: 10px 14px calc(10px + env(safe-area-inset-bottom)); gap: 6px 14px;
               background: rgba(12, 10, 9, .94); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
               box-shadow: 0 -10px 30px rgba(0, 0, 0, .6); }
  #start-row::before, #start-row::after { display: none; }
  #start-row .start { flex: 1 1 100%; width: 100%; min-height: 52px; padding: 12px; font-size: 18px; text-align: center; }
  #start-row .link { font-size: 12px; min-height: 32px; }
  #open-passive { display: none; }            /* a TV page is opened on the TV, not from the phone */
  .add input, .manage li input, .sform input, .sform select, .ulist input { font-size: 16px; }

  /* ---- settings */
  #settings { padding: 12px 14px calc(24px + env(safe-area-inset-bottom)); }
  #settings h1 { font-size: 26px; }
  .sform { flex-direction: column; align-items: stretch; }
  .sform label { width: 100%; }
  .sform input:not([type="checkbox"]), .sform select { width: 100% !important; min-height: 44px; }
  .sform input[type="checkbox"] { width: 22px; height: 22px; }
  .sform label.check { flex-direction: row; padding: 4px 0; }
  .sform .chip, #engine-tools .chip { width: 100%; justify-content: center; }
  #engine-tools { flex-direction: column; }

  /* ---- game: a slim bar with Undo, Next and More */
  .bar { flex-wrap: nowrap; gap: 6px; padding: 6px 8px; min-height: 52px; padding-top: calc(6px + env(safe-area-inset-top)); }
  .bar .secondary { display: none !important; }
  #btn-more { display: inline-flex; align-items: center; justify-content: center; }
  .bar button { min-height: 40px; padding: 6px 10px; font-size: 13px; }
  .bar #conn-text { flex: 1 1 auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 13px; }
  .bar #match-text { display: none; }
  #btn-next { font-weight: 700; }
  /* players stay compact; the board fills what is left instead of leaving a gap */
  .arena { display: flex; flex-direction: column; min-height: 0; overflow-y: auto; }
  .arena .players { flex: none; }
  .boardview { flex: 1 1 auto; min-height: 150px; padding: 6px 12px; flex-direction: row; align-items: center; justify-content: center; gap: 12px; }
  .boardview svg { height: 100%; max-height: min(44vh, 64vw); width: auto; aspect-ratio: 1; flex: none; }
  .boardview .side { flex: 0 1 auto; }
  .player { min-height: 64px; }
  .player .score { font-size: 46px; }
  .history { padding: 6px 10px; }
  .visit { gap: 8px; padding: 8px 10px calc(8px + env(safe-area-inset-bottom)); }
  .dart { min-height: 56px; font-size: 22px; }

  /* ---- sheets (correct a dart, fix scores, more) come up from the bottom */
  .pad .sheet { width: 100%; max-height: 88dvh; overflow-y: auto; padding: 6px 12px calc(12px + env(safe-area-inset-bottom));
                border-radius: 16px 16px 0 0; }
  .pad .grab { display: block; width: 44px; height: 5px; border-radius: 3px; background: var(--metal-light); margin: 4px auto 10px; }
  .pad .mult { gap: 6px; margin-bottom: 8px; }
  .pad .nums { grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 6px; }
  .pad button { min-height: 48px; font-size: 18px; padding: 0 2px; letter-spacing: 0; min-width: 0; }
  .pad .foot { gap: 8px; }
  .pad .foot button { flex: 1; min-height: 48px; font-size: 14px; }
  .evidence img { max-height: 30dvh; }
  .more-list { display: grid; gap: 8px; }
  .more-list button { min-height: 52px; font-size: 16px; text-align: left; padding: 0 16px; border: 1px solid var(--metal-light);
                      border-radius: 4px; background: var(--surface); color: var(--sisal); text-transform: uppercase; letter-spacing: .05em; }
  .more-list button.danger { color: var(--red); border-color: rgba(255, 90, 54, .5); }

  /* ---- end screen and win banner fit a phone */
  .endcard h2, .banner h2 { font-size: 34px; }
  .er { grid-template-columns: 1.6em 1fr auto; font-size: 15px; padding: 8px 10px; }
  .er .lg { display: none; }
}
/* phones on their side: the game screen keeps everything in one view */
@media (max-height: 500px) and (orientation: landscape) {
  .bar { min-height: 40px; padding: 4px 8px; }
  .bar button { padding: 4px 9px; font-size: 12px; }
  .bar .secondary { display: none !important; }
  #btn-more { display: inline-flex; }
  .player .score { font-size: clamp(34px, 12vh, 72px); }
  .visit { padding: 6px 10px calc(6px + env(safe-area-inset-bottom)); }
  .dart { min-height: 46px; }
  #setup { padding-bottom: 24px; }
}

/* ================= ARCADE: an 80s game-console coat over the same layout =================
   Press Start 2P for titles, scores and buttons, VT323 (a terminal font) where text has to be read, neon on black,
   pixel-notched corners and a light CRT scanline. Same as the Pi's login screen. Colours of the Tikka woodpecker
   ("tikka" is Finnish for a dart and a woodpecker): crest red for what matters now (start, the player at the board,
   totals), plumage white for what is chosen, warm black and bark grey for the rest. */
:root {
  --font-hud: "Press Start 2P", "Orbitron", system-ui, monospace;
  --font-crt: "VT323", "Chakra Petch", ui-monospace, monospace;
  --cabinet-deep: #0c0a09; --surface: #161312; --elevated: #221d1b; --panel-border: #3e3633; --metal-light: #6e6460; --metal-dark: #2a2422;
  --glow: #f4efe6; --orange: #ff8f3a; --red: #e3202f; --red-deep: #7a0d16; --green: #5fd35f; --yellow: #e3202f; --magenta: #e3202f;
  --line: rgba(244, 239, 230, .14); --halo: 0 0 6px rgba(227, 32, 47, .7), 0 0 20px rgba(227, 32, 47, .35);
  --buff: #e2c08d; --wire: #c9bfb4; --text: #f4efe6; --muted: #a39890;
  --pix: polygon(0 3px, 3px 3px, 3px 0, calc(100% - 3px) 0, calc(100% - 3px) 3px, 100% 3px, 100% calc(100% - 3px), calc(100% - 3px) calc(100% - 3px), calc(100% - 3px) 100%, 3px 100%, 3px calc(100% - 3px), 0 calc(100% - 3px));
  --pix-s: polygon(0 3px, 3px 3px, 3px 0, calc(100% - 3px) 0, calc(100% - 3px) 3px, 100% 3px, 100% calc(100% - 3px), calc(100% - 3px) calc(100% - 3px), calc(100% - 3px) 100%, 3px 100%, 3px calc(100% - 3px), 0 calc(100% - 3px));
}
body {
  background:
    linear-gradient(to right, rgba(244, 239, 230, .03) 1px, transparent 1px) 0 0 / 32px 32px,
    linear-gradient(to bottom, rgba(244, 239, 230, .03) 1px, transparent 1px) 0 0 / 32px 32px,
    radial-gradient(120% 70% at 50% -10%, #2a1312 0%, var(--cabinet-deep) 60%) fixed, var(--cabinet-deep);
}
body::after {                                    /* CRT: scanlines and a dark rim, never in the way of a tap */
  content: ''; position: fixed; inset: 0; pointer-events: none; z-index: 60;
  background: repeating-linear-gradient(to bottom, transparent 0 2px, rgba(0, 0, 0, .16) 2px 3px),
              radial-gradient(130% 110% at 50% 50%, transparent 60%, rgba(0, 0, 0, .45) 100%);
}
::selection { background: var(--red); color: #fff; }

/* titles: crest red, lit from above, with a hard pixel shadow */
#setup h1, #settings h1, #fix h3, .banner h2 {
  font-family: var(--font-hud); font-style: normal; font-weight: 400; letter-spacing: 0; text-transform: uppercase;
  background: linear-gradient(180deg, #ff7a7a 0%, #ff3b3b 30%, #e3202f 60%, #b5121f 100%);
  -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; color: transparent;
  filter: drop-shadow(3px 3px 0 #000) drop-shadow(1px 1px 0 var(--red-deep));
}
#setup h1 { font-size: clamp(22px, calc(3.2vw / var(--z)), 38px); line-height: 1.25; }
#setup h1::before { display: none; }
#settings h1 { font-size: 26px; }
.banner h2 { font-size: clamp(26px, calc(5vw / var(--z)), 60px); line-height: 1.3; }
.logo-tikka { height: clamp(34px, calc(4.4vw / var(--z)), 60px); aspect-ratio: 62 / 14; image-rendering: pixelated;
             background: url("data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20viewBox=%220%200%2062%2014%22%20shape-rendering=%22crispEdges%22%3E%3Crect%20x=%2238%22%20y=%220%22%20width=%223%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2238%22%20y=%221%22%20width=%229%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2239%22%20y=%222%22%20width=%2210%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2240%22%20y=%223%22%20width=%229%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2249%22%20y=%223%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%224%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2239%22%20y=%224%22%20width=%222%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2241%22%20y=%224%22%20width=%2210%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%222%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2238%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23ff0000%22/%3E%3Crect%20x=%2239%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2241%22%20y=%225%22%20width=%226%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2248%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23000000%22/%3E%3Crect%20x=%2249%22%20y=%225%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2250%22%20y=%225%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%226%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%223%22%20y=%226%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2219%22%20y=%226%22%20width=%2216%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2238%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2240%22%20y=%226%22%20width=%227%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%226%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2248%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23000000%22/%3E%3Crect%20x=%2250%22%20y=%226%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%226%22%20width=%225%22%20height=%221%22%20fill=%22%23d0d0d0%22/%3E%3Crect%20x=%220%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%222%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%224%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2215%22%20y=%227%22%20width=%225%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2220%22%20y=%227%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2222%22%20y=%227%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2225%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2226%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2230%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2231%22%20y=%227%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2235%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2236%22%20y=%227%22%20width=%2216%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%227%22%20width=%229%22%20height=%221%22%20fill=%22%23d0d0d0%22/%3E%3Crect%20x=%2261%22%20y=%227%22%20width=%221%22%20height=%221%22%20fill=%22%238a8a8a%22/%3E%3Crect%20x=%222%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%224%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%226%22%20y=%228%22%20width=%2211%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2217%22%20y=%228%22%20width=%223%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2220%22%20y=%228%22%20width=%226%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2226%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2227%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2231%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2232%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2236%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2237%22%20y=%228%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2239%22%20y=%228%22%20width=%229%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2248%22%20y=%228%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2252%22%20y=%228%22%20width=%221%22%20height=%221%22%20fill=%22%238a8a8a%22/%3E%3Crect%20x=%222%22%20y=%229%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%224%22%20y=%229%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%226%22%20y=%229%22%20width=%226%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2212%22%20y=%229%22%20width=%223%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2215%22%20y=%229%22%20width=%2224%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2239%22%20y=%229%22%20width=%229%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2248%22%20y=%229%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%222%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%224%22%20y=%2210%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2212%22%20y=%2210%22%20width=%223%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2215%22%20y=%2210%22%20width=%2225%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2240%22%20y=%2210%22%20width=%227%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%2247%22%20y=%2210%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2211%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%2211%22%20width=%222%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%223%22%20y=%2211%22%20width=%223%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2214%22%20y=%2211%22%20width=%222%22%20height=%221%22%20fill=%22%23d70000%22/%3E%3Crect%20x=%2216%22%20y=%2211%22%20width=%2225%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%2241%22%20y=%2211%22%20width=%224%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%220%22%20y=%2212%22%20width=%221%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%221%22%20y=%2212%22%20width=%221%22%20height=%221%22%20fill=%22%23eeeeee%22/%3E%3Crect%20x=%222%22%20y=%2212%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3Crect%20x=%2218%22%20y=%2212%22%20width=%2221%22%20height=%221%22%20fill=%22%23bcbcbc%22/%3E%3Crect%20x=%220%22%20y=%2213%22%20width=%222%22%20height=%221%22%20fill=%22%23444444%22/%3E%3C/svg%3E") left center / contain no-repeat; margin: -4px 0 2px; }

/* panels: pixel corners, a bright edge, the heading as a console label */
.panel, .sgroup, .manage { clip-path: var(--pix); border: 3px solid var(--panel-border); border-radius: 0; box-shadow: none;
  background: linear-gradient(180deg, rgba(34, 29, 27, .94), rgba(16, 13, 12, .96)); }
.panel::before, .panel::after, .sgroup::before, .sgroup::after, .manage::before, .manage::after { display: none; }
.panel > h2, .sgroup > h2, .split h3, .opt-group h3, #setup h2 { font-family: var(--font-hud); font-size: 11px; letter-spacing: 1px; color: var(--glow); border-bottom-color: var(--panel-border); }
.panel > h2::before, .sgroup > h2::before { content: '\25B6'; color: var(--magenta); margin-right: .7em; font-size: .9em; }
#setup h2::before, .opt-group h3::before { content: ''; }

/* readable text in the terminal font */
.hint, .rule, .rules, .smsg, .sform label, .player .stats, .player .legs, .player .recent, .history, .pp .rec, .pp .sub, .pcap, .legend,
.boardview .cap, .bar, #conn-text, .endcard p, .banner p, .frow .who, .manage li .count, .total span {
  font-family: var(--font-crt); letter-spacing: .02em; }
.hint { font-size: 19px; } .rule { font-size: 20px; } .rules { font-size: 19px; }
.player .stats, .player .recent { font-size: clamp(18px, calc(2vw / var(--z)), 24px); }
.player .legs { font-size: clamp(18px, calc(2vw / var(--z)), 24px); }
.bar { font-size: 20px; } .total span { font-size: 18px; } .history { font-size: 19px; }

/* chips and buttons: console buttons with pixel corners; the chosen one lights up */
.chip { font-family: var(--font-hud); font-size: 11px; letter-spacing: 0; text-transform: uppercase; font-weight: 400;
        clip-path: var(--pix-s); border-radius: 0; border: 3px solid var(--metal-light); background: var(--surface); line-height: 1.5; }
.chip:hover { border-color: var(--magenta); color: var(--magenta); }
.chip[aria-pressed="true"] { background: var(--glow); color: #120f0e; border-color: var(--glow); box-shadow: inset 0 -3px 0 #c9bfb4; text-shadow: none; }
.chip[aria-pressed="true"]:hover { color: #000; }
.chip .order { color: inherit; opacity: .8; }
.chip.danger:hover { border-color: var(--red); color: var(--red); }
.start { font-family: var(--font-hud); font-style: normal; font-weight: 400; font-size: 14px; letter-spacing: 1px; line-height: 1.5;
         clip-path: var(--pix); border: 3px solid var(--red); background: var(--red); color: #fff; box-shadow: inset 0 -4px 0 var(--red-deep); text-shadow: 2px 2px 0 var(--red-deep); }
.start:not(:disabled)::before { content: '\25B6\00a0'; animation: blink 1s steps(1) infinite; }
.start:hover:not(:disabled) { background: #ff3443; border-color: #ff3443; color: #fff; }
.start:disabled { border-color: #3e3633; color: #6e6460; background: var(--surface); box-shadow: none; text-shadow: none; }
@keyframes blink { 50% { opacity: 0; } }
.bar button, .pbar button, .ulist button, .pad button, .manage li button, .frow button, .more-list button, .rules summary, .link {
  font-family: var(--font-crt); font-size: 19px; letter-spacing: .04em; clip-path: var(--pix-s); border-radius: 0; }
.bar button { border-width: 2px; }
.bar button:hover, .pbar button:hover, .ulist button:hover, .pad button:hover, .manage li button:hover:not(:disabled), .link:hover {
  border-color: var(--magenta); color: var(--magenta); box-shadow: none; }
.bar button#btn-next { border-color: var(--red); background: var(--red); color: #fff; }
.sform input, .sform select, .ulist input, .add input, .manage li input, #api { font-family: var(--font-crt); font-size: 20px; border: 2px solid var(--metal-light); border-radius: 0; }

/* the game: names and scores in the console font, the player at the board in a blinking cursor box */
.player .name, .pp .nm { font-family: var(--font-hud); font-size: clamp(14px, calc(1.8vw / var(--z)), 24px); letter-spacing: 1px; font-weight: 400; }
.player .score, .pp .big, .total b { font-family: var(--font-hud); font-weight: 400; letter-spacing: 0; }
@media (min-width: 701px) { .player .score { font-size: clamp(40px, 22cqi, 150px); } }
.player .score { text-shadow: 4px 4px 0 rgba(0, 0, 0, .6); }
.player.active { background: linear-gradient(180deg, rgba(227, 32, 47, .16), rgba(227, 32, 47, .03)); box-shadow: inset 0 0 0 3px var(--red); }
.player.active .name::before { content: '\25B6\00a0'; color: var(--red); animation: blink 1s steps(1) infinite; }
.player.active .score { color: var(--glow); text-shadow: 4px 4px 0 var(--red-deep), 0 0 18px rgba(227, 32, 47, .45); }
.player.active.bust .score { color: var(--orange); text-shadow: 4px 4px 0 #4a1a00; }
.player .route { font-family: var(--font-crt); font-size: clamp(20px, calc(2.6vw / var(--z)), 32px); color: var(--green); text-shadow: 0 0 8px rgba(95, 211, 95, .45); }
.player::before, .player::after { display: none; }
.dart { font-family: var(--font-hud); font-size: clamp(16px, calc(2.6vw / var(--z)), 30px); clip-path: var(--pix); border: 3px dashed var(--metal-light); border-radius: 0; }
.dart.hit { border-style: solid; border-color: var(--glow); color: var(--glow); }
.dart.edited { border-color: var(--buff); color: var(--buff); }
.dart.unsure { border-color: var(--orange); color: var(--orange); }
.total b { color: var(--red); text-shadow: 4px 4px 0 #000; }
.turn { clip-path: var(--pix-s); border-radius: 0; font-family: var(--font-crt); font-size: 19px; }
.turn b { font-family: var(--font-crt); }
.player .tag, .ulist .badge { font-family: var(--font-hud); font-size: 9px; clip-path: var(--pix-s); }
.player .tag.finish { color: #000; background: var(--green); border-color: var(--green); }
.marks .t, .marks .m { font-family: var(--font-crt); font-size: 1.15em; }
.boardview, .pboard { border-color: var(--panel-border); }
.boardview svg, .pboard svg { filter: drop-shadow(0 0 10px rgba(227, 32, 47, .25)); }

/* sheets, banners, the end screen */
.pad .sheet { border-top: 3px solid var(--red); clip-path: none; }
.pad .mult button[aria-pressed="true"] { background: var(--glow); color: #120f0e; border-color: var(--glow); }
.pad .nums button { font-family: var(--font-hud); font-size: 13px; }
.endcard .kicker { font-family: var(--font-hud); font-size: 12px; color: var(--magenta); letter-spacing: 2px; animation: blink 1.2s steps(1) infinite; }
.er { clip-path: var(--pix-s); border-radius: 0; font-family: var(--font-crt); font-size: 22px; }
.er .nm, .er .bg, .er .pos { font-family: var(--font-hud); font-size: 13px; }
.er.win { border-color: var(--red); box-shadow: inset 0 0 0 2px var(--red); }
.er.win .nm, .er.win .bg { color: var(--glow); text-shadow: 3px 3px 0 var(--red-deep); }

@media (max-width: 700px) {
  #setup h1 { font-size: 18px; }
  .logo-tikka { height: 32px; }
  .chip { font-size: 10px; min-height: 44px; }
  #start-row .start { font-size: 12px; }
  .player .name { font-size: 13px; }
  .player .score { font-size: 30px; }
  .player .stats, .player .recent, .player .legs { font-size: 17px; }
  .dart { font-size: 15px; }
  .total b { font-size: 22px; }
  .bar button { font-size: 18px; padding: 4px 9px; }
  .hint, .rule { font-size: 17px; }
  .er .nm, .er .bg, .er .pos { font-size: 11px; }
}
@media (prefers-reduced-motion: reduce) {
  .start:not(:disabled)::before, .player.active .name::before, .endcard .kicker { animation: none; }
}
</style>
<script>
// Scale the whole page with the screen: the layout is designed for 1200x900 and zoomed to fill larger or
// smaller screens in proportion (TVs, 4K, small laptops). Phones keep their own layout. Viewport units in
// the CSS are divided by --z so they are not scaled twice.
(function () {
  function scale() {
    const w = innerWidth, h = innerHeight;
    const z = w <= 700 ? 1 : Math.min(4, Math.max(0.8, Math.min(w / 1200, h / 900)));
    document.documentElement.style.setProperty('--z', String(z));
    document.documentElement.style.zoom = String(z);
  }
  scale();
  addEventListener('resize', scale);
})();
</script>
</head>
<body>

<!-- Setup -->
<section id="setup" class="screen on" aria-labelledby="setup-title">
  <h1 id="setup-title">Tikka</h1>
  <div class="logo-tikka" role="img" aria-label="The Tikka woodpecker: a dart with a woodpecker's head"></div>
  <p class="hint who" id="who-line" hidden><span id="who"></span> <button class="link" id="btn-logout">Sign out</button></p>

  <div class="panel">
    <h2>Players</h2>
    <div class="row" id="roster"></div>
    <p class="hint" id="roster-hint">Tap names in throwing order.</p>
    <div class="row" style="margin-top:12px">
      <button class="chip" id="btn-last" hidden>Same players as last game</button>
      <button class="chip" id="btn-clear" hidden>Clear selection</button>
      <button class="chip" id="btn-manage" aria-expanded="false" aria-controls="manage">Manage list</button>
    </div>
    <div id="manage" class="manage" hidden>
      <ul id="manage-list"></ul>
      <form class="add" id="add-form">
        <input id="add-name" maxlength="16" placeholder="New player name" autocomplete="off" aria-label="New player name">
        <button class="chip" type="submit">Add player</button>
      </form>
      <p class="hint" id="sync-note"></p>
    </div>
  </div>

  <div class="panel">
    <h2>Game</h2>
    <div class="row" id="opt-game"></div>
    <p class="rule" id="game-rule"></p>
    <details class="rules" id="rules">
      <summary>Rules</summary>
      <ul id="rules-list"></ul>
      <h3>In every game</h3>
      <ul>
        <li>Players throw in the order you picked; the first thrower moves on by one each leg.</li>
        <li>A visit is three darts and ends when the darts are pulled out, or with Next player.</li>
        <li>Tap a dart to correct it, or use Fix scores to change an earlier visit.</li>
        <li>Win the leg count you chose (First to) to win the match.</li>
      </ul>
    </details>
    <div id="game-opts"></div>
  </div>

  <div class="panel">
    <h2>Match</h2>
    <div class="split">
      <div><h3>First to</h3><div class="row" id="opt-legs"></div></div>
      <div><h3>Sets</h3><div class="row" id="opt-sets"></div></div>
    </div>
  </div>

  <div class="panel actions row" id="start-row" style="align-items:center; gap:24px">
    <button class="start" id="start" disabled>Start game</button>
    <button class="link" id="resume" hidden>Resume last game</button>
    <button class="link" id="open-passive">Open passive display (for a TV: shows the game running on another device)</button>
  </div>

  <div class="panel">
    <h2>Options</h2>
    <div class="row">
      <button class="chip" id="opt-voice" aria-pressed="true">Score caller on</button>
      <button class="chip" id="opt-voice-test">Test voice</button>
      <button class="chip" id="opt-dartcalls" aria-pressed="false">Call each dart: off</button>
      <button class="chip" id="opt-finishcalls" aria-pressed="false">Call the finish: off</button>
      <button class="chip" id="opt-tips" aria-pressed="true">Throw tips on</button>
      <button class="chip" id="opt-awake" aria-pressed="true">Keep screen on</button>
      <button class="chip" id="opt-lights" hidden>Lights: auto</button>
      <button class="chip" id="btn-settings">Settings: board, users, lights, game lock</button>
      <button class="chip danger" id="end-session">End session: lights off</button>
    </div>

  </div>
</section>

<!-- Settings (admins; anyone while sign-in is off) -->
<section id="settings" class="screen" aria-labelledby="settings-title">
  <div class="shead"><h1 id="settings-title">Settings</h1><button class="chip" id="settings-close">Done</button></div>
  <p class="smsg" id="settings-msg" role="status"></p>

  <div class="sgroup" id="board-group">
    <h2>Board</h2>
    <form class="sform" id="api-form">
      <label>Address <input id="api" autocomplete="off" inputmode="url" style="width:22em"></label>
      <button class="chip" type="submit">Save</button>
    </form>
    <p class="hint">Address of the board service. Leave it at the Pi's own address and the page follows the
      board program that is switched on (below). Saved on this device only.</p>
    <p class="hint" id="engine-note"></p>
    <div class="row" id="engine-tools" hidden>
      <button class="chip" id="cal-auto" type="button">Calibrate cameras (empty, lit board)</button>
      <button class="chip" id="cal-orient" type="button">Set orientation: I threw a dart at the 20</button>
    </div>
  </div>

  <div class="sgroup" data-admin>
    <h2>Users</h2>
    <p class="hint" id="users-note"></p>
    <ul class="ulist" id="users-list"></ul>
    <form class="sform" id="user-add">
      <label>Name <input name="uname" maxlength="24" autocomplete="off" required></label>
      <label>Password <input name="password" type="password" minlength="6" autocomplete="new-password" required></label>
      <label class="check"><input name="admin" type="checkbox"> Admin</label>
      <button class="chip" type="submit">Add user</button>
    </form>
  </div>

  <div class="sgroup" id="lights-group" data-admin>
    <h2>Lights</h2>
    <p class="hint" id="lights-note"></p>
    <div class="row" id="lights-mode"></div>
    <form class="sform" id="lights-form">
      <label>Device ID <input name="device_id" autocomplete="off" required></label>
      <label>Plug IP address <input name="ip" inputmode="decimal" autocomplete="off" required></label>
      <label>Local key <input name="local_key" type="password" maxlength="16" autocomplete="off"></label>
      <label>Protocol <select name="version"><option>3.1</option><option>3.2</option><option>3.3</option><option>3.4</option><option>3.5</option></select></label>
      <label>Off after no board activity, min <input name="idle_minutes" type="number" min="1" max="240" required></label>
      <label>Off after no new score, min <input name="no_score_minutes" type="number" min="1" max="240" required></label>
      <button class="chip" type="submit">Save lights</button>
    </form>
  </div>

  <div class="sgroup" data-admin>
    <h2>Secure address (HTTPS)</h2>
    <p class="hint">When set, devices that open the home address are sent here, so sign-in and the
      keep-screen-on feature use HTTPS. Empty: no redirect. If the internet is down, open the home
      address with <b>?local</b> at the end.</p>
    <form class="sform" id="secure-form">
      <label>Address <input name="url" type="url" placeholder="https://name.tailnet.ts.net/play/" style="width:22em"></label>
      <button class="chip" type="submit">Save</button>
    </form>
  </div>

  <div class="sgroup" data-admin>
    <h2>Game lock</h2>
    <form class="sform" id="lock-form">
      <label>Release an unused lock after, hours <input name="hours" type="number" min="1" max="48" required></label>
      <button class="chip" type="submit">Save</button>
    </form>
  </div>
</section>

<!-- Game -->
<section id="game" class="screen" aria-label="Scoreboard">
  <div class="bar">
    <span class="dot" id="conn-dot" aria-hidden="true"></span>
    <span id="conn-text">Connecting to board</span>
    <span class="grow" id="match-text"></span>
    <button id="btn-reset" class="reset secondary">Reset board</button>
    <button id="btn-lights" class="secondary" hidden>Lights: auto</button>
    <button id="btn-passive" class="secondary">Passive view</button>
    <button id="btn-fix" class="secondary">Fix scores</button>
    <button id="btn-undo">Undo visit</button>
    <button id="btn-next">Next player</button>
    <button id="btn-menu" class="secondary">End game</button>
    <button id="btn-end" class="secondary">End session</button>
    <button id="btn-more" aria-haspopup="dialog" aria-controls="more">More</button>
  </div>
  <div class="arena">
    <div class="players" id="players"></div>
    <aside class="boardview" aria-label="Hits this round">
      <svg id="board" viewBox="-112 -112 224 224" role="img" aria-label="Dartboard with this round's hits"></svg>
      <div class="side">
        <div class="cap" id="board-cap">This round</div>
        <div class="legend" id="legend"></div>
      </div>
    </aside>
  </div>
  <div class="history" id="history" aria-label="Last three turns"></div>
  <div class="visit">
    <button class="dart" data-i="0" aria-label="Dart 1, tap to correct">–</button>
    <button class="dart" data-i="1" aria-label="Dart 2, tap to correct">–</button>
    <button class="dart" data-i="2" aria-label="Dart 3, tap to correct">–</button>
    <div class="total"><b id="visit-total">0</b><span id="visit-note">this visit</span></div>
  </div>
</section>

<!-- Passive display: board, hits and recent scores only -->
<section id="passive" class="screen" aria-label="Passive scoreboard">
  <div class="pbar"><span id="p-title">Waiting for a game</span><span class="grow"></span><span id="p-lock"></span><span id="p-stamp"></span><button id="p-unlock" hidden>Force unlock</button><button id="p-exit">Exit</button></div>
  <div class="pmain">
    <div class="pboard">
      <svg id="p-board" viewBox="-112 -112 224 224" role="img" aria-label="Dartboard with this round's hits"></svg>
      <div class="pcap" id="p-cap"></div>
      <div class="phits" id="p-hits"></div>
      <div class="history" id="p-hist" aria-label="Last three turns"></div>
    </div>
    <div class="pplayers" id="p-players"></div>
  </div>
</section>

<div class="banner" id="banner" role="dialog" aria-modal="true" aria-labelledby="banner-title">
  <div>
    <h2 id="banner-title"></h2>
    <p id="banner-text"></p>
    <div class="row" id="banner-actions"></div>
  </div>
</div>

<div class="banner endscreen" id="end" role="dialog" aria-modal="true" aria-labelledby="end-title">
  <div class="endcard">
    <p class="kicker">Session ended</p>
    <h2 id="end-title"></h2>
    <p id="end-sub"></p>
    <div id="end-table"></div>
    <p class="endnote" id="end-note"></p>
    <div class="row"><button class="chip" id="end-menu">Back to menu</button></div>
  </div>
</div>

<div class="pad" id="pad" role="dialog" aria-modal="true" aria-label="Correct dart">
  <div class="sheet">
    <div class="grab" aria-hidden="true"></div>
    <div class="evidence" id="pad-evidence" hidden>
      <img id="pad-img" alt="Camera picture of this dart with the detected tip marked">
      <p class="hint" id="pad-img-cap"></p>
    </div>
    <div class="mult" id="pad-mult"></div>
    <div class="nums" id="pad-nums"></div>
    <div class="foot">
      <button id="pad-clear" style="padding:0 18px">Use detected dart</button>
      <button id="pad-close" style="padding:0 18px">Cancel</button>
    </div>
  </div>
</div>

<div class="pad" id="fix" role="dialog" aria-modal="true" aria-label="Fix scores">
  <div class="sheet">
    <div class="grab" aria-hidden="true"></div>
    <h3>Fix scores</h3>
    <p>Tap a dart to change it. Everything after it is recalculated.</p>
    <div id="fix-list"></div>
    <div class="foot"><button id="fix-close" style="padding:0 18px">Close</button></div>
  </div>
</div>

<!-- Phones: the game bar keeps Undo and Next; the rest is here -->
<div class="pad" id="more" role="dialog" aria-modal="true" aria-label="More actions">
  <div class="sheet">
    <div class="grab" aria-hidden="true"></div>
    <div class="more-list" id="more-list"></div>
    <div class="foot"><button id="more-close">Close</button></div>
  </div>
</div>

<pre class="raw" id="raw" aria-live="off"></pre>

<script>
'use strict';
// Served under a path (the internet link's /play): keep a trailing slash so relative URLs stay below it.
if (!/\/$|\.html$/.test(location.pathname)) location.replace(location.pathname + '/' + location.search + location.hash);
// ================= storage & helpers =================
const store = {
  get(k, d) { try { const v = localStorage.getItem('hdarts.' + k); return v == null ? d : JSON.parse(v); } catch { return d; } },
  set(k, v) { try { localStorage.setItem('hdarts.' + k, JSON.stringify(v)); } catch {} },
  del(k) { try { localStorage.removeItem('hdarts.' + k); } catch {} },
};
const $ = (id) => document.getElementById(id);
const clone = (o) => JSON.parse(JSON.stringify(o));
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ================= darts maths =================
function seg(n, m) {
  if (!m || !n) return { n: 0, m: 0, name: 'Miss' };
  if (n === 25) return { n, m, name: m === 2 ? 'Bull' : '25' };
  return { n, m, name: (m === 3 ? 'T' : m === 2 ? 'D' : 'S') + n };
}
function fromApi(t) {
  const s = t && t.segment;
  if (!s || t.bouncer) return seg(0, 0);
  const d = seg(Number(s.number) || 0, Number(s.multiplier) || 0);
  if (t.coords && isFinite(t.coords.x) && isFinite(t.coords.y)) { d.x = t.coords.x; d.y = t.coords.y; }
  // Tikka Vision extras: the cameras disagreed about this dart, and which pictures show it.
  if (t.uncertain) d.unsure = true;
  if (t.id) { d.id = t.id; d.cams = Array.isArray(t.cameras) ? t.cameras.slice(0, 4) : []; }
  return d;
}
// Board geometry, in units of the outer double radius (170 mm), y pointing up.
const ORDER = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5];
const R = { bull: 6.35 / 170, outerBull: 15.9 / 170, trebleIn: 99 / 170, trebleOut: 107 / 170, doubleIn: 162 / 170, doubleOut: 1 };
function dartPos(d) {
  if (isFinite(d.x) && isFinite(d.y)) return { x: d.x, y: d.y, exact: true };
  if (!d.m || !d.n) return null;
  if (d.n === 25) return { x: 0, y: d.m === 2 ? 0 : -(R.bull + R.outerBull) / 2 };
  const r = d.m === 3 ? (R.trebleIn + R.trebleOut) / 2 : d.m === 2 ? (R.doubleIn + R.doubleOut) / 2 : (R.trebleOut + R.doubleIn) / 2;
  const a = (90 - ORDER.indexOf(d.n) * 18) * Math.PI / 180;
  return { x: r * Math.cos(a), y: r * Math.sin(a) };
}
const value = (d) => d.n * d.m;

const FINISH = [20, 16, 18, 12, 10, 8, 19, 17, 15, 14, 13, 11, 9, 7, 6, 5, 4, 3, 2, 1].map((n) => seg(n, 2)).concat([seg(25, 2)]);
const SETUP = [];
for (let n = 20; n >= 1; n--) SETUP.push(seg(n, 3));
SETUP.push(seg(25, 1), seg(25, 2));
for (let n = 20; n >= 1; n--) SETUP.push(seg(n, 1));
const oneDart = (r) => FINISH.find((d) => value(d) === r) || null;
function twoDarts(r) {
  for (const f of FINISH) {
    const need = r - value(f);
    if (need <= 0) continue;
    const a = SETUP.find((d) => value(d) === need);
    if (a) return [a, f];
  }
  return null;
}
function checkout(r, dartsLeft) {
  if (r > 170 || r < 2) return null;
  if (dartsLeft >= 1 && oneDart(r)) return [oneDart(r)];
  if (dartsLeft >= 2) { const two = twoDarts(r); if (two) return two; }
  if (dartsLeft >= 3) {
    for (const a of SETUP) {
      const rest = r - value(a);
      if (rest < 2) continue;
      const tail = oneDart(rest) ? [oneDart(rest)] : twoDarts(rest);
      if (tail) return [a, ...tail];
    }
  }
  return null;
}
const argmax = (arr) => { let best = -Infinity, idx = [], i = 0; for (const v of arr) { if (v > best) { best = v; idx = [i]; } else if (v === best) idx.push(i); i++; } return idx; };
const argmin = (arr) => argmax(arr.map((v) => -v));

// ================= throw tips =================
// Suggestions for the player at the board, shown under their score. Per device: menu "Throw tips".
const tipsOn = () => store.get('tips', true);
const GOOD_LEAVES = [40, 32, 36, 16, 24, 20, 8, 12, 28, 50];   // leaves that finish on a favourite double
const BOGEY = new Set([169, 168, 166, 165, 163, 162, 159]);    // no three-dart finish
const SINGLES = [...Array.from({ length: 20 }, (_, k) => seg(20 - k, 1)), seg(25, 1)];
const TREBLES_FIRST = [seg(20, 3), seg(19, 3), seg(18, 3), seg(17, 3), ...SINGLES];
// X01 when no finish is possible with the darts left: score, or set up a good finish.
// Tips are recalculated after every dart, so they only plan the next dart.
const TREBLES = Array.from({ length: 20 }, (_, k) => seg(20 - k, 3));
function x01Tip(r, dartsLeft) {
  if (r > 170) {
    // Score heavily, but don't leave a number that has no finish.
    for (const t of [20, 19, 18]) { const leave = r - 3 * t; if (leave > 170 || !BOGEY.has(leave)) return `Aim T${t}`; }
    return 'Aim T20';
  }
  const leaveWith = (darts, n) => darts.find((a) => value(a) === r - n);
  const doubles = GOOD_LEAVES.filter((n) => n !== 50);
  let a = null, left = 0;
  // 1. a single that leaves a favourite double, 2. a treble that does, 3. any single that leaves a
  // one-dart finish (biggest double first), 4. a two-dart finish, 5. just not a dead number.
  for (const list of [SINGLES, TREBLES]) {
    for (const n of doubles) { const d = leaveWith(list, n); if (d) { a = d; left = n; break; } }
    if (a) break;
  }
  if (!a) for (const d of [...SINGLES].reverse()) { const n = r - value(d); if (n >= 2 && oneDart(n)) { a = d; left = n; break; } }
  if (!a) for (const d of TREBLES_FIRST) { const n = r - value(d); if (n >= 2 && n <= 110 && twoDarts(n)) { a = d; left = n; break; } }
  if (!a) for (const d of TREBLES_FIRST) { const n = r - value(d); if (n >= 2 && !BOGEY.has(n)) { a = d; left = n; break; } }
  if (!a) return 'Aim T20';
  const d = oneDart(left);
  return `Set up ${a.name}, leaves ${left}${d ? ' (' + d.name + ')' : ''}`;
}
// X01 straight out: any dart that reaches zero, else score.
function straightOutTip(r) {
  const all = [seg(25, 2), seg(25, 1), ...[3, 2, 1].flatMap((m) => Array.from({ length: 20 }, (_, k) => seg(20 - k, m)))];
  const one = all.find((d) => value(d) === r);
  return one ? `Finish ${one.name}` : r > 60 ? 'Aim T20' : `Aim ${r > 40 ? 'T' + Math.min(20, Math.floor(r / 3)) : 'S' + Math.min(20, r)}`;
}
// Cricket: score when it helps, close what opponents score on, else close the highest open number.
function cricketTip(s, i) {
  const me = s.p[i], others = s.p.filter((p, j) => j !== i), mode = s.o.mode, nums = s.nums || CRICKET;
  const open = (p, t) => p.marks[t] < 3;
  const aim = (t, why) => `Aim ${t === 25 ? 'Bull' : 'T' + t} · ${why}`;
  if (mode !== 'none' && others.length) {
    const pts = others.map((p) => p.pts);
    const needPoints = mode === 'standard' ? me.pts <= Math.max(...pts) : me.pts >= Math.min(...pts);
    const scoreOn = nums.find((t) => !open(me, t) && others.some((p) => open(p, t)));
    if (needPoints && scoreOn) return aim(scoreOn, mode === 'standard' ? 'score' : 'points to opponents');
    const defend = nums.find((t) => open(me, t) && others.some((p) => !open(p, t)));
    if (defend) return aim(defend, 'close it');
  }
  const next = nums.find((t) => open(me, t));
  return next ? aim(next, 'close it') : '';
}
// Killer: become a killer, then go after the weakest opponent.
function killerTip(s, i) {
  const me = s.p[i];
  if (me.lives <= 0) return '';
  if (!me.killer) return `Aim D${me.num} to become a killer`;
  const foes = s.p.map((p, j) => ({ p, j })).filter(({ p, j }) => j !== i && p.lives > 0)
    .sort((a, b) => a.p.lives - b.p.lives || Number(b.p.killer) - Number(a.p.killer));
  if (!foes.length) return '';
  const name = G && G.cfg.players[foes[0].j] ? ` (${G.cfg.players[foes[0].j]})` : '';
  return `Aim D${foes[0].p.num}${name}`;
}

// ================= games =================
// Each game:  create(opts, n, prev) -> state
//             play(state, i, darts, ctx) -> { s, stop, won, winner, bust, scored, call }
//               ctx = { round, final }  (final = the visit is being committed)
//             view(state, i, ctx) -> { big, hint, extra, stats, tag }
//             roundEnd(state, round) -> winner index or null    (optional)
//             isOut(state, i) -> bool                           (optional)
const GAMES = {};

// ---------- X01 ----------
// ================= can this turn win? (the "Call the finish" option) =================
// A game may define finish(state, i, ctx) -> { say, show } | null: what player i needs to win with the darts left
// this turn (ctx.dartsLeft). Only games where one turn can end the leg have it.
const ONE_DART = new Set([0, 25, 50, ...Array.from({ length: 20 }, (_, k) => [k + 1, 2 * (k + 1), 3 * (k + 1)]).flat()]);
const REACH = [new Set([0])];                      // REACH[n]: totals n darts can make (a miss counts 0)
for (let n = 1; n <= 3; n++) {
  const s = new Set();
  for (const a of REACH[n - 1]) for (const b of ONE_DART) s.add(a + b);
  REACH.push(s);
}
const sayTarget = (t) => (t === 25 ? 'bull' : String(t));

GAMES.x01 = {
  name: 'X01',
  rule: 'Count down to exactly zero. With double out the last dart must be a double.',
  options: [
    { key: 'start', label: 'Start', choices: [['301', 301], ['501', 501], ['701', 701]], def: 501 },
    { key: 'in', label: 'Start with', choices: [['Straight in', 'straight'], ['Double in', 'double']], def: 'straight' },
    { key: 'out', label: 'Finish', choices: [['Double out', 'double'], ['Straight out', 'straight']], def: 'double' },
  ],
  title: (o) => `${o.start}${o.in === 'double' ? ' double in' : ''}${o.out === 'double' ? '' : ' straight out'}`,
  create(o, n, prev) {
    return { o, p: Array.from({ length: n }, (_, i) => ({
      rem: o.start, open: o.in !== 'double', legDarts: 0,
      pts: prev ? prev.p[i].pts : 0, darts: prev ? prev.p[i].darts : 0,
      best: prev ? prev.p[i].best : 0, maxes: prev ? prev.p[i].maxes : 0,
    })) };
  },
  play(s, i, darts) {
    const p = s.p[i], dout = s.o.out === 'double';
    const start = p.rem;
    let rem = start, open = p.open, used = 0;
    for (const d of darts) {
      used++;
      if (!open) { if (d.m === 2) open = true; else continue; }
      const r = rem - value(d);
      if (r < 0 || (dout && r === 1) || (r === 0 && dout && d.m !== 2)) {
        return { s, stop: true, bust: true, scored: 0, call: 'Bust', commitDarts: 3 };
      }
      rem = r;
      if (rem === 0) {
        const scored = start;
        Object.assign(p, { rem: 0, open, legDarts: p.legDarts + used, pts: p.pts + scored, darts: p.darts + used, best: Math.max(p.best, scored) });
        return { s, stop: true, won: true, scored, call: 'Game shot' };
      }
    }
    const scored = start - rem;
    Object.assign(p, { rem, open, legDarts: p.legDarts + 3, pts: p.pts + scored, darts: p.darts + 3, best: Math.max(p.best, scored), maxes: p.maxes + (scored === 180 ? 1 : 0) });
    return { s, scored, call: scored === 0 ? 'No score' : scored === 180 ? 'One hundred and eighty!' : String(scored) };
  },
  view(s, i, ctx) {
    const p = s.p[i];
    const dl = ctx.active ? ctx.dartsLeft : 3;
    const route = s.o.out === 'double' && p.open && !ctx.bust ? checkout(p.rem, dl) : null;
    const tip = ctx.active && !ctx.bust && tipsOn() && dl > 0
      ? (!p.open ? ' · aim D20' : route ? '' : s.o.out === 'double' ? x01Tip(p.rem, dl) : straightOutTip(p.rem)) : '';
    return {
      big: p.rem,
      hint: ctx.bust ? 'Bust' : !p.open ? 'Needs a double to start' + tip : route ? route.map((d) => d.name).join(' ') : tip,
      stats: `Avg ${p.darts ? (p.pts / p.darts * 3).toFixed(1) : '–'} · Darts ${p.legDarts}${p.maxes ? ' · 180s ' + p.maxes : ''}`,
    };
  },
  finish(s, i, ctx) {
    const p = s.p[i], dl = ctx.dartsLeft;
    if (!p.open || dl < 1 || p.rem < 2 && s.o.out === 'double') return null;
    if (s.o.out === 'double') {
      const route = checkout(p.rem, dl);
      return route ? { say: `you require ${p.rem}`, show: route.map((d) => d.name).join(' ') } : null;
    }
    return REACH[dl].has(p.rem) ? { say: `you require ${p.rem}`, show: `${p.rem} to finish` } : null;
  },
};

// ---------- Cricket ----------
const CRICKET = [20, 19, 18, 17, 16, 15, 25];
const markGlyph = (m) => ['', '/', 'X', 'Ⓧ'][Math.min(m, 3)];
// Cricket and its relatives differ only in which numbers are in play.
function cricketGame({ name, nums, rule, titles }) {
  return {
    name, rule,
    options: [
      { key: 'mode', label: 'Scoring', choices: [['Standard', 'standard'], ['Cut-throat', 'cut'], ['No points', 'none']], def: 'standard' },
    ],
    title: (o) => ({ standard: titles[0], cut: titles[1], none: titles[2] }[o.mode]),
    create(o, n, prev) {
      return { o, nums, p: Array.from({ length: n }, (_, i) => ({
        marks: Object.fromEntries(nums.map((t) => [t, 0])), pts: 0,
        totalMarks: prev ? prev.p[i].totalMarks : 0, rounds: prev ? prev.p[i].rounds : 0,
      })) };
    },
    play(s, i, darts) {
      const me = s.p[i], mode = s.o.mode, list = s.nums || CRICKET;
      let marks = 0;
      const closedAll = (p) => list.every((t) => p.marks[t] >= 3);
      for (const d of darts) {
        if (!list.includes(d.n) || !d.m) continue;
        for (let k = 0; k < d.m; k++) {
          marks++;
          if (me.marks[d.n] < 3) { me.marks[d.n]++; continue; }
          const val = d.n;
          const open = s.p.filter((p, j) => j !== i && p.marks[d.n] < 3);
          if (!open.length || mode === 'none') continue;
          if (mode === 'standard') me.pts += val;
          else open.forEach((p) => { p.pts += val; });
        }
        if (closedAll(me)) {
          const others = s.p.filter((p, j) => j !== i).map((p) => p.pts);
          const ok = mode === 'none' || !others.length ||
            (mode === 'standard' ? me.pts >= Math.max(...others) : me.pts <= Math.min(...others));
          if (ok) { me.totalMarks += marks; me.rounds++; return { s, stop: true, won: true, scored: marks, call: 'Game shot' }; }
        }
      }
      me.totalMarks += marks; me.rounds++;
      return { s, scored: marks, call: marks ? `${marks} mark${marks > 1 ? 's' : ''}` : 'No score' };
    },
    view(s, i, ctx) {
      const p = s.p[i], list = s.nums || CRICKET;
      const rows = list.map((t) => `<span class="mk"><span class="t">${t === 25 ? 'Bull' : t}</span><span class="m${p.marks[t] >= 3 ? ' closed' : ''}">${markGlyph(p.marks[t])}</span></span>`).join('');
      return {
        big: s.o.mode === 'none' ? list.filter((t) => p.marks[t] >= 3).length + '/' + list.length : p.pts,
        hint: ctx && ctx.active && tipsOn() ? cricketTip(s, i) : '',
        extra: `<div class="marks${list.length > 8 ? ' many' : ''}">${rows}</div>`,
        stats: `Marks per round ${p.rounds ? (p.totalMarks / p.rounds).toFixed(2) : '–'}`,
      };
    },
    finish(s, i, ctx) {
      const me = s.p[i], list = s.nums || CRICKET, mode = s.o.mode;
      const others = s.p.filter((p, j) => j !== i).map((p) => p.pts);
      // Closing the last numbers wins only when the points already allow it (they cannot be counted on to change).
      if (mode !== 'none' && others.length && !(mode === 'standard' ? me.pts >= Math.max(...others) : me.pts <= Math.min(...others))) return null;
      const open = list.filter((t) => me.marks[t] < 3);
      if (!open.length) return null;
      const darts = open.reduce((a, t) => a + Math.ceil((3 - me.marks[t]) / (t === 25 ? 2 : 3)), 0);
      if (darts > ctx.dartsLeft) return null;
      const names = open.map(sayTarget);
      return { say: `to win: ${names.join(' and ')}`, show: `To win: ${names.join(', ')}` };
    },
  };
}
GAMES.cricket = cricketGame({
  name: 'Cricket', nums: CRICKET,
  rule: 'Close 15 to 20 and the bull with three marks each. Score on numbers you have closed and others have not. Close everything with the most points to win.',
  titles: ['Cricket', 'Cut-throat cricket', 'Cricket, no points'],
});
const TACTICS = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 25];
GAMES.tactics = cricketGame({
  name: 'Tactics', nums: TACTICS,
  rule: 'Cricket with more numbers: close 10 to 20 and the bull with three marks each. Score on numbers you have closed and others have not. Close everything with the most points to win.',
  titles: ['Tactics', 'Cut-throat tactics', 'Tactics, no points'],
});
const MICKEY = [20, 19, 18, 17, 16, 15, 14, 13, 12, 25];
GAMES.mickey = cricketGame({
  name: 'Mickey Mouse', nums: MICKEY,
  rule: 'Cricket on 12 to 20 and the bull. Three marks close a number. Score on numbers you have closed and others have not. Close everything with the most points to win.',
  titles: ['Mickey Mouse', 'Cut-throat Mickey Mouse', 'Mickey Mouse, no points'],
});

// ---------- Around the Clock ----------
const CLOCK = [...Array.from({ length: 20 }, (_, k) => k + 1), 25];
GAMES.clock = {
  name: 'Around the Clock',
  rule: 'Hit 1 to 20 in order, then the bull. First to hit the bull wins.',
  options: [
    { key: 'hit', label: 'Counts as a hit', choices: [['Any segment', 'any'], ['Doubles only', 'double'], ['Trebles only', 'treble']], def: 'any' },
    { key: 'skip', label: 'Doubles and trebles', choices: [['Advance one', false], ['Skip ahead', true]], def: false },
  ],
  title: (o) => 'Around the Clock' + (o.hit === 'any' ? '' : o.hit === 'double' ? ', doubles' : ', trebles'),
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ k: 0, darts: 0 })) }; },
  finish(s, i, ctx) {
    const p = s.p[i], left = CLOCK.slice(p.k);                       // the numbers still to hit, the bull last
    // With "skip ahead" one treble moves three numbers; the bull always takes its own dart.
    const darts = s.o.skip && s.o.hit !== 'double' ? Math.ceil((left.length - 1) / 3) + 1 : left.length;
    if (!left.length || darts > ctx.dartsLeft) return null;
    return { say: `to win: ${left.map(sayTarget).join(', ')}`, show: `To win: ${left.map(sayTarget).join(' ')}` };
  },
  play(s, i, darts) {
    const p = s.p[i], o = s.o;
    let adv = 0, used = 0;
    for (const d of darts) {
      used++;
      const target = CLOCK[p.k];
      if (d.n !== target || !d.m) continue;
      const ok = target === 25 ? (o.hit !== 'double' || d.m === 2) : o.hit === 'any' || (o.hit === 'double' && d.m === 2) || (o.hit === 'treble' && d.m === 3);
      if (!ok) continue;
      const step = o.skip && target !== 25 ? d.m : 1;
      p.k = Math.min(p.k + step, 20);
      adv += step;
      if (target === 25) { p.darts += used; return { s, stop: true, won: true, scored: adv, call: 'Game shot' }; }
    }
    p.darts += 3;
    return { s, scored: adv, call: adv ? `${adv} hit${adv > 1 ? 's' : ''}` : 'No score' };
  },
  view(s, i, ctx) {
    const p = s.p[i], o = s.o;
    const t = CLOCK[p.k];
    let tip = '';
    if (ctx && ctx.active && tipsOn()) {
      tip = t === 25 ? (o.hit === 'double' ? 'Aim Bull (inner)' : 'Aim Bull')
        : o.hit === 'double' ? `Aim D${t}` : o.hit === 'treble' ? `Aim T${t}`
        : o.skip ? `Aim T${t} (moves 3)` : `Aim ${t} (big single)`;
    }
    return { big: t === 25 ? 'Bull' : t, hint: tip ? `${tip} · ${p.k} of 21 done` : `${p.k} of 21 done`, stats: `Darts ${p.darts}` };
  },
};

// ---------- Shanghai ----------
GAMES.shanghai = {
  name: 'Shanghai',
  rule: 'Round 1 aims at 1, round 2 at 2, and so on. Only the round\'s number scores. A single, double and treble of it in one visit is a Shanghai and wins at once.',
  options: [{ key: 'rounds', label: 'Rounds', choices: [['7 rounds', 7], ['10 rounds', 10], ['20 rounds', 20]], def: 7 }],
  title: (o) => `Shanghai, ${o.rounds} rounds`,
  rounds: (o) => o.rounds,
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: 0 })) }; },
  target: (round) => ((round - 1) % 20) + 1,
  play(s, i, darts, ctx) {
    const t = this.target(ctx.round);
    const p = s.p[i];
    let scored = 0; const kinds = new Set();
    for (const d of darts) if (d.n === t) { scored += value(d); kinds.add(d.m); }
    p.pts += scored;
    if (kinds.size === 3) return { s, stop: true, won: true, scored, call: 'Shanghai!' };
    return { s, scored, call: scored ? String(scored) : 'No score' };
  },
  view(s, i, ctx) {
    const t = this.target(ctx.round);
    return { big: s.p[i].pts, hint: ctx.active ? (tipsOn() ? `Aim T${t} · S, D and T of ${t} = Shanghai` : `Aim at ${t}`) : '', stats: '' };
  },
  roundEnd(s, round) {
    if (round < s.o.rounds) return null;
    const w = argmax(s.p.map((p) => p.pts));
    return w.length === 1 ? w[0] : null; // tie: keep playing extra rounds
  },
};

// ---------- Count-Up ----------
GAMES.countup = {
  name: 'Count-Up',
  rule: 'Score as many points as you can in a set number of rounds. Highest total wins.',
  options: [{ key: 'rounds', label: 'Rounds', choices: [['7 rounds', 7], ['8 rounds', 8], ['10 rounds', 10]], def: 8 }],
  title: (o) => `Count-Up, ${o.rounds} rounds`,
  rounds: (o) => o.rounds,
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: 0, darts: 0 })) }; },
  play(s, i, darts) {
    const scored = darts.reduce((a, d) => a + value(d), 0);
    s.p[i].pts += scored; s.p[i].darts += 3;
    return { s, scored, call: scored === 180 ? 'One hundred and eighty!' : scored ? String(scored) : 'No score' };
  },
  view(s, i, ctx) {
    const p = s.p[i];
    return { big: p.pts, hint: ctx && ctx.active && tipsOn() ? 'Aim T20' : '', stats: `Avg ${p.darts ? (p.pts / p.darts * 3).toFixed(1) : '–'}` };
  },
  roundEnd(s, round) {
    if (round < s.o.rounds) return null;
    const w = argmax(s.p.map((p) => p.pts));
    return w.length === 1 ? w[0] : null;
  },
};

// ---------- Halve-It ----------
const HALVE = [
  { label: '20', hit: (d) => d.n === 20 }, { label: '19', hit: (d) => d.n === 19 },
  { label: 'Any double', hit: (d) => d.m === 2 }, { label: '18', hit: (d) => d.n === 18 },
  { label: '17', hit: (d) => d.n === 17 }, { label: 'Any treble', hit: (d) => d.m === 3 },
  { label: '16', hit: (d) => d.n === 16 }, { label: '15', hit: (d) => d.n === 15 },
  { label: 'Bull', hit: (d) => d.n === 25 },
];
GAMES.halve = {
  name: 'Halve-It',
  rule: 'Each round has a target. Hits score their value. Miss the target with all three darts and your total is halved. Highest total after nine rounds wins.',
  options: [{ key: 'startPts', label: 'Starting points', choices: [['40', 40], ['0', 0]], def: 40 }],
  title: () => 'Halve-It',
  rounds: () => HALVE.length,
  target: (round) => HALVE[Math.min(round, HALVE.length) - 1],
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: o.startPts })) }; },
  play(s, i, darts, ctx) {
    const t = this.target(ctx.round), p = s.p[i];
    const scored = darts.filter((d) => d.m && t.hit(d)).reduce((a, d) => a + value(d), 0);
    if (scored) { p.pts += scored; return { s, scored, call: String(scored) }; }
    if (ctx.final) { p.pts = Math.floor(p.pts / 2); return { s, scored: 0, call: 'Halved' }; }
    return { s, scored: 0 };
  },
  view(s, i, ctx) {
    const t = this.target(ctx.round);
    const best = { 'Any double': 'D20', 'Any treble': 'T20', Bull: 'Bull' }[t.label] || 'T' + t.label;
    return { big: s.p[i].pts, hint: ctx.active ? (tipsOn() ? `${t.label}: aim ${best} · a miss halves` : `Aim at ${t.label}`) : '' };
  },
  roundEnd(s, round) {
    if (round < HALVE.length) return null;
    const w = argmax(s.p.map((p) => p.pts));
    return w.length === 1 ? w[0] : null;
  },
};

// ---------- Bob's 27 ----------
const BOBS = [...Array.from({ length: 20 }, (_, k) => k + 1), 25];
GAMES.bobs = {
  name: "Bob's 27",
  rule: 'Doubles practice. Start on 27 and aim at D1, D2 … D20, then the bull. Each hit adds the double. Miss all three and you lose it. Drop to zero or below and you are out.',
  options: [],
  title: () => "Bob's 27",
  rounds: () => BOBS.length,
  target: (round) => BOBS[Math.min(round, BOBS.length) - 1],
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: 27, out: false })) }; },
  play(s, i, darts, ctx) {
    const t = this.target(ctx.round), p = s.p[i];
    const hits = darts.filter((d) => d.n === t && d.m === 2).length;
    if (hits) { p.pts += hits * 2 * t; return { s, scored: hits * 2 * t, call: `${hits} hit${hits > 1 ? 's' : ''}` }; }
    if (ctx.final) { p.pts -= 2 * t; if (p.pts <= 0) p.out = true; return { s, scored: -2 * t, call: p.out ? 'Out' : 'Missed' }; }
    return { s, scored: 0 };
  },
  isOut: (s, i) => s.p[i].out,
  view(s, i, ctx) {
    const t = this.target(ctx.round);
    return { big: s.p[i].pts, hint: ctx.active ? `Aim at ${t === 25 ? 'Bull' : 'D' + t}` : '', tag: s.p[i].out ? 'Out' : '' };
  },
  roundEnd(s, round) {
    const alive = s.p.map((p, i) => i).filter((i) => !s.p[i].out);
    if (round < BOBS.length && alive.length > (s.p.length > 1 ? 1 : 0)) return null;
    const w = argmax(s.p.map((p) => p.pts));
    return w[0];
  },
};

// ---------- Killer ----------
GAMES.killer = {
  name: 'Killer',
  rule: 'Everyone gets a number. Hit your own double to become a killer, then hit other players\' doubles to take their lives. Hitting your own double as a killer costs you a life. Last player standing wins.',
  options: [
    { key: 'lives', label: 'Lives', choices: [['3 lives', 3], ['5 lives', 5]], def: 3 },
    { key: 'zone', label: 'Counts as a hit', choices: [['Doubles', 'double'], ['Any segment', 'any']], def: 'double' },
  ],
  title: (o) => `Killer, ${o.lives} lives`,
  minPlayers: 2,
  create(o, n) {
    const nums = Array.from({ length: 20 }, (_, k) => k + 1).sort(() => Math.random() - 0.5).slice(0, n);
    return { o, p: nums.map((num) => ({ num, lives: o.lives, killer: false })) };
  },
  play(s, i, darts) {
    const me = s.p[i];
    let call = '';
    for (const d of darts) {
      if (!d.m || (s.o.zone === 'double' && d.m !== 2)) continue;
      const owner = s.p.findIndex((p) => p.num === d.n && p.lives > 0);
      if (owner < 0) continue;
      if (owner === i) {
        if (!me.killer) { me.killer = true; call = 'Killer!'; } else { me.lives--; call = 'Ouch'; }
      } else if (me.killer) { s.p[owner].lives--; call = s.p[owner].lives <= 0 ? 'Killed' : 'Hit'; }
      const alive = s.p.map((p, k) => k).filter((k) => s.p[k].lives > 0);
      if (alive.length <= 1) return { s, stop: true, won: true, winner: alive[0] ?? i, scored: 0, call: 'Game shot' };
      if (me.lives <= 0) return { s, stop: true, scored: 0, call: 'Out' };
    }
    return { s, scored: 0, call: call || 'No score' };
  },
  isOut: (s, i) => s.p[i].lives <= 0,
  finish(s, i, ctx) {
    const me = s.p[i];
    const foes = s.p.filter((p, j) => j !== i && p.lives > 0);
    if (!me.killer || foes.length !== 1 || foes[0].lives > ctx.dartsLeft) return null;
    const f = foes[0], dbl = s.o.zone === 'double' ? 'D' : '';
    return { say: `to win: ${f.lives === 1 ? '' : f.lives + ' times '}${dbl ? 'double ' : ''}${f.num}`, show: `To win: ${dbl}${f.num}${f.lives > 1 ? ' x' + f.lives : ''}` };
  },
  view(s, i, ctx) {
    const p = s.p[i];
    const tip = ctx && ctx.active && tipsOn() ? killerTip(s, i) : '';
    return { big: p.num, hint: '●'.repeat(Math.max(p.lives, 0)) + '○'.repeat(Math.max(s.o.lives - Math.max(p.lives, 0), 0)) + (tip ? ' · ' + tip : ''), tag: p.lives <= 0 ? 'Out' : p.killer ? 'Killer' : '', stats: `Lives ${Math.max(p.lives, 0)}` };
  },
};

// ---------- Baseball ----------
GAMES.baseball = {
  name: 'Baseball',
  rule: 'Inning 1 aims at 1, inning 2 at 2, and so on. Each dart on the inning\'s number scores runs: single 1, double 2, treble 3. Most runs after the last inning wins.',
  options: [{ key: 'rounds', label: 'Innings', choices: [['5 innings', 5], ['9 innings', 9]], def: 9 }],
  title: (o) => `Baseball, ${o.rounds} innings`,
  rounds: (o) => o.rounds,
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: 0 })) }; },
  target: (round) => ((round - 1) % 20) + 1,
  play(s, i, darts, ctx) {
    const t = this.target(ctx.round);
    const runs = darts.filter((d) => d.n === t && d.m).reduce((a, d) => a + d.m, 0);
    s.p[i].pts += runs;
    return { s, scored: runs, call: runs ? `${runs} run${runs > 1 ? 's' : ''}` : 'No score' };
  },
  view(s, i, ctx) {
    const t = this.target(ctx.round);
    return { big: s.p[i].pts, hint: ctx.active ? (tipsOn() ? `Aim T${t} · 3 runs` : `Aim at ${t}`) : '', stats: '' };
  },
  roundEnd(s, round) {
    if (round < s.o.rounds) return null;
    const w = argmax(s.p.map((p) => p.pts));
    return w.length === 1 ? w[0] : null; // tie: extra innings
  },
};

// ---------- Golf ----------
GAMES.golf = {
  name: 'Golf',
  rule: 'Hole 1 aims at 1, hole 2 at 2, and so on. The first dart that hits the hole\'s number ends it: treble 1 stroke, double 2, single 3. No hit is 4. Fewest strokes wins.',
  options: [{ key: 'rounds', label: 'Holes', choices: [['9 holes', 9], ['18 holes', 18]], def: 9 }],
  title: (o) => `Golf, ${o.rounds} holes`,
  rounds: (o) => o.rounds,
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ strokes: 0, card: [] })) }; },
  target: (round) => ((round - 1) % 18) + 1,
  play(s, i, darts, ctx) {
    const t = this.target(ctx.round), p = s.p[i];
    const hit = darts.find((d) => d.n === t && d.m);
    let strokes = 0;
    if (hit) strokes = 4 - hit.m;
    else if (ctx.final || darts.length >= 3) strokes = 4;
    else return { s, scored: 0 };
    p.strokes += strokes; p.card.push(strokes);
    return { s, stop: !!hit, scored: strokes, call: ['', 'Eagle', 'Birdie', 'Par', 'Bogey'][strokes] };
  },
  view(s, i, ctx) {
    const t = this.target(ctx.round), p = s.p[i];
    return { big: p.strokes, hint: ctx.active ? (tipsOn() ? `Hole ${t}: aim T${t} · treble 1, double 2, single 3` : `Aim at ${t}`) : '', stats: p.card.length ? 'Holes ' + p.card.slice(-9).join(' ') : '' };
  },
  roundEnd(s, round) {
    if (round < s.o.rounds) return null;
    const w = argmin(s.p.map((p) => p.strokes));
    return w.length === 1 ? w[0] : null; // tie: extra holes
  },
};

// ---------- Fives ----------
GAMES.fives = {
  name: 'Fives',
  rule: 'Add up the three darts. If the total is a multiple of 5, you score the total divided by 5. Otherwise nothing. First to the target wins.',
  options: [{ key: 'target', label: 'First to', choices: [['50 points', 50], ['100 points', 100], ['150 points', 150]], def: 100 }],
  title: (o) => `Fives, first to ${o.target}`,
  finish(s, i, ctx) {
    const need = s.o.target - s.p[i].pts;
    // A full visit can be worth up to 36 (three treble 20s); only the start of a visit is judged.
    if (ctx.dartsLeft < 3 || need < 1 || need > 36) return null;
    return { say: `needs ${need}`, show: `${need} to win` };
  },
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ pts: 0, visits: 0 })) }; },
  play(s, i, darts, ctx) {
    const p = s.p[i], done = ctx.final || darts.length >= 3;
    const total = darts.reduce((a, d) => a + value(d), 0);
    if (!done) return { s, scored: 0 };
    const scored = total > 0 && total % 5 === 0 ? total / 5 : 0;
    p.pts += scored; p.visits++;
    if (p.pts >= s.o.target) return { s, stop: true, won: true, scored, call: 'Game shot' };
    return { s, scored, call: scored ? String(scored) : 'No score' };
  },
  view(s, i, ctx) {
    const p = s.p[i];
    return { big: p.pts, hint: ctx && ctx.active ? `${Math.max(s.o.target - p.pts, 0)} to go${tipsOn() ? ' · total must end in 0 or 5' : ''}` : '', stats: `Per visit ${p.visits ? (p.pts / p.visits).toFixed(1) : '–'}` };
  },
};

// ---------- Follow the Leader ----------
GAMES.leader = {
  name: 'Follow the Leader',
  rule: 'Beat the previous visit\'s total or lose a life. The first player only has to score. At zero lives you are out. Last player standing wins.',
  options: [{ key: 'lives', label: 'Lives', choices: [['3 lives', 3], ['5 lives', 5], ['9 lives', 9]], def: 3 }],
  title: (o) => `Follow the Leader, ${o.lives} lives`,
  minPlayers: 2,
  create(o, n) { return { o, last: 0, p: Array.from({ length: n }, () => ({ lives: o.lives })) }; },
  play(s, i, darts, ctx) {
    const me = s.p[i], total = darts.reduce((a, d) => a + value(d), 0);
    if (!(ctx.final || darts.length >= 3)) return { s, scored: total };
    let call = String(total);
    if (total <= s.last) { me.lives--; call = me.lives <= 0 ? 'Out' : 'Lost a life'; }
    s.last = total;
    const alive = s.p.map((p, k) => k).filter((k) => s.p[k].lives > 0);
    if (alive.length <= 1) return { s, stop: true, won: true, winner: alive[0] ?? i, scored: total, call: 'Game shot' };
    return { s, stop: me.lives <= 0, scored: total, call };
  },
  isOut: (s, i) => s.p[i].lives <= 0,
  view(s, i, ctx) {
    const p = s.p[i];
    const hearts = '●'.repeat(Math.max(p.lives, 0)) + '○'.repeat(Math.max(s.o.lives - Math.max(p.lives, 0), 0));
    const beat = ctx && ctx.active && ctx.dartsLeft > 0 ? `Beat ${s.last}${tipsOn() && s.last < 180 ? ' · aim T20' : ''}` : '';
    return { big: p.lives, hint: beat || hearts, tag: p.lives <= 0 ? 'Out' : '', stats: `Lives ${Math.max(p.lives, 0)}` };
  },
};

// ---------- Scram ----------
const SCRAM = [20, 19, 18, 17, 16, 15, 25];
const scramMarks = () => Object.fromEntries(SCRAM.map((t) => [t, 0]));
GAMES.scram = {
  name: 'Scram',
  rule: 'For two players. One scores, the other closes. The scorer earns points on numbers the closer has not yet closed. The closer needs three marks on each of 15 to 20 and the bull. Then the roles swap. Most points wins.',
  options: [],
  title: () => 'Scram',
  minPlayers: 2,
  maxPlayers: 2,
  scorer: (s) => (s.phase % 2 === 1 ? 0 : 1),
  create(o) { return { o, phase: 1, marks: scramMarks(), p: [{ pts: 0 }, { pts: 0 }] }; },
  play(s, i, darts) {
    const scorer = this.scorer(s);
    let scored = 0, marks = 0;
    for (const d of darts) {
      if (!SCRAM.includes(d.n) || !d.m) continue;
      if (i === scorer) {
        if (s.marks[d.n] < 3) { s.p[i].pts += value(d); scored += value(d); }
        continue;
      }
      const add = Math.min(d.m, 3 - s.marks[d.n]);
      if (!add) continue;
      s.marks[d.n] += add; marks += add;
      if (!SCRAM.every((t) => s.marks[t] >= 3)) continue;
      const a = s.p[0].pts, b = s.p[1].pts;
      if (s.phase % 2 === 0 && a !== b) return { s, stop: true, won: true, winner: a > b ? 0 : 1, scored: marks, call: 'Game shot' };
      const level = s.phase % 2 === 0;
      s.phase++; s.marks = scramMarks();
      return { s, stop: true, scored: marks, call: level ? 'Level, play on' : 'All closed, change over' };
    }
    const n = i === scorer ? scored : marks;
    return { s, scored: n, call: n ? String(n) : 'No score' };
  },
  view(s, i, ctx) {
    const scoring = this.scorer(s) === i;
    const open = SCRAM.find((t) => s.marks[t] < 3);
    const rows = SCRAM.map((t) => `<span class="mk"><span class="t">${t === 25 ? 'Bull' : t}</span><span class="m${s.marks[t] >= 3 ? ' closed' : ''}">${markGlyph(s.marks[t])}</span></span>`).join('');
    const tip = ctx && ctx.active && tipsOn() && open ? `Aim ${open === 25 ? 'Bull' : 'T' + open}${scoring ? ' · score' : ' · close it'}` : '';
    return { big: s.p[i].pts, hint: tip, tag: scoring ? 'Scoring' : 'Closing', extra: `<div class="marks">${rows}</div>`, stats: `Half ${((s.phase - 1) % 2) + 1} of 2` };
  },
};

// ---------- Checkout drill ----------
GAMES.checkout = {
  name: 'Checkout drill',
  rule: 'Check out the target in one visit with a double out. Success moves the target up by one, otherwise you get another try, and after the last try the target goes back to the start. Highest target checked out wins.',
  options: [
    { key: 'start', label: 'Start at', choices: [['81', 81], ['101', 101], ['121', 121]], def: 121 },
    { key: 'tries', label: 'Visits per target', choices: [['1 visit', 1], ['3 visits', 3]], def: 3 },
    { key: 'rounds', label: 'Visits', choices: [['12 visits', 12], ['21 visits', 21], ['30 visits', 30]], def: 21 },
  ],
  title: (o) => `Checkout drill from ${o.start}`,
  rounds: (o) => o.rounds,
  create(o, n) { return { o, p: Array.from({ length: n }, () => ({ target: o.start, rem: o.start, tries: 0, best: 0 })) }; },
  play(s, i, darts, ctx) {
    const p = s.p[i], target = p.target;
    let rem = target, bust = false;
    for (const d of darts) {
      const r = rem - value(d);
      if (r < 0 || r === 1 || (r === 0 && d.m !== 2)) { bust = true; break; }
      rem = r;
      if (rem === 0) break;
    }
    const out = !bust && rem === 0;
    p.rem = bust ? target : rem;
    if (ctx.final) {
      p.rem = target;
      if (out) {
        p.best = Math.max(p.best, target); p.tries = 0;
        let next = target + 1;
        while (BOGEY.has(next)) next++;
        p.target = p.rem = Math.min(next, 170);
      } else if (++p.tries >= s.o.tries) { p.tries = 0; p.target = p.rem = s.o.start; }
    }
    if (bust) return { s, stop: true, bust: true, scored: 0, call: 'Bust' };
    if (out) return { s, stop: true, scored: target, call: 'Checked out' };
    const scored = target - rem;
    return { s, scored, call: scored ? String(scored) : 'No score' };
  },
  view(s, i, ctx) {
    const p = s.p[i];
    const dl = ctx.active ? ctx.dartsLeft : 3;
    const route = ctx.active && !ctx.bust && p.rem > 1 ? checkout(p.rem, dl) : null;
    return {
      big: p.rem,
      hint: ctx.bust ? 'Bust' : route ? route.map((d) => d.name).join(' ') : `Target ${p.target} · try ${p.tries + 1} of ${s.o.tries}`,
      stats: `Best ${p.best || '–'}`,
    };
  },
  roundEnd(s, round) {
    if (round < s.o.rounds) return null;
    const w = argmax(s.p.map((p) => p.best));
    return w.length === 1 ? w[0] : null;
  },
};

// Short rules shown in the menu's Rules section. Keep in step with the play() functions above.
const RULES = {
  x01: [
    'Everyone starts from <b>301, 501 or 701</b> and subtracts the score of every dart.',
    'Finish on <b>exactly zero</b>. With <b>Double out</b> the last dart must be a double; the bull\'s-eye counts as one.',
    '<b>Bust</b>: going below zero, leaving 1, or reaching zero without a double (double out). The whole visit scores nothing.',
    '<b>Double in</b>: your darts only start counting after you hit a double.',
    'When a finish is possible the suggested checkout is shown under your score.',
  ],
  cricket: [
    'Numbers <b>15 to 20 and the bull</b>. A single is 1 mark, a double 2, a treble 3. Three marks close a number.',
    '<b>Standard</b>: once you have closed a number, hits on it score its value while any opponent still has it open.',
    '<b>Cut-throat</b>: those points go to the opponents who still have it open, and the <b>lowest</b> score wins.',
    '<b>No points</b>: just close all seven first.',
    'Close all seven while level or ahead on points (behind in cut-throat) to win the leg.',
  ],
  clock: [
    'Hit <b>1, 2, 3 … 20</b> in order, then the <b>bull</b>. First to hit the bull wins the leg.',
    '<b>Counts as a hit</b>: any segment of the number, doubles only, or trebles only (doubles only needs the bull\'s-eye at the end).',
    '<b>Skip ahead</b>: a double moves you on two numbers and a treble three. With Advance one every hit moves one.',
  ],
  shanghai: [
    'Round 1 aims at <b>1</b>, round 2 at <b>2</b>, and so on, for 7, 10 or 20 rounds.',
    'Only the round\'s number scores: single ×1, double ×2, treble ×3.',
    'A <b>single, double and treble</b> of the number in one visit is a <b>Shanghai</b> and wins at once.',
    'Otherwise the highest total after the last round wins. A tie plays extra rounds.',
  ],
  countup: [
    'Every dart scores its full value. Play <b>7, 8 or 10 rounds</b>.',
    'Highest total wins. A tie plays extra rounds.',
  ],
  halve: [
    'Nine rounds with a target each: <b>20, 19, any double, 18, 17, any treble, 16, 15, bull</b>.',
    'Darts that hit the target score their value.',
    'Miss the target with all three darts and your total is <b>halved</b> (rounded down).',
    'Start on <b>40 or 0</b> points. Highest total wins; a tie plays extra rounds on the bull.',
  ],
  bobs: [
    'Doubles practice. Start on <b>27</b> and aim at <b>D1, D2 … D20</b>, then the bull\'s-eye.',
    'Every hit on the round\'s double adds its value (D5 adds 10).',
    'Miss all three and that double\'s value is taken off.',
    'At <b>zero or below</b> you are out. Highest score at the end, or the last player left, wins.',
  ],
  tactics: [
    'Cricket with more numbers: <b>10 to 20 and the bull</b>. Three marks close a number.',
    'Scoring works as in Cricket: standard, cut-throat (lowest score wins) or no points.',
    'Close all twelve while level or ahead on points (behind in cut-throat) to win the leg.',
  ],
  mickey: [
    'Cricket on <b>12 to 20 and the bull</b>. A single is 1 mark, a double 2, a treble 3. Three marks close a number.',
    'Scoring works as in Cricket: standard, cut-throat (lowest score wins) or no points.',
    'Close all ten while level or ahead on points (behind in cut-throat) to win the leg.',
  ],
  baseball: [
    'Inning 1 aims at <b>1</b>, inning 2 at <b>2</b>, and so on, for 5 or 9 innings.',
    'Each dart on the inning\'s number is worth <b>runs</b>: single 1, double 2, treble 3.',
    'Most runs after the last inning wins. A tie plays extra innings.',
  ],
  golf: [
    'Hole 1 aims at <b>1</b>, hole 2 at <b>2</b>, and so on, for 9 or 18 holes.',
    'The <b>first dart</b> that hits the hole\'s number ends the hole: treble = 1 stroke, double = 2, single = 3. Miss with all three darts and it is 4.',
    '<b>Fewest strokes</b> wins. A tie plays extra holes.',
  ],
  fives: [
    'Add up your three darts. If the total is a <b>multiple of 5</b> you score the total <b>divided by 5</b>.',
    'Any other total scores nothing.',
    'First to <b>50, 100 or 150</b> wins.',
  ],
  leader: [
    'Your visit must <b>beat the total of the previous visit</b>. The first player only has to score something.',
    'Fail and you lose a <b>life</b>. At zero you are out.',
    'Start with 3, 5 or 9 lives. <b>Last player standing</b> wins.',
  ],
  scram: [
    'Two players. One is the <b>scorer</b>, the other the <b>closer</b>.',
    'The scorer earns the value of every dart on <b>15 to 20 and the bull</b> that the closer has not closed yet.',
    'The closer needs three marks on each of the seven numbers. When all are closed the roles swap and the numbers open again.',
    'After both halves the higher score wins. A tie plays another pair of halves.',
  ],
  checkout: [
    'The target starts at <b>81, 101 or 121</b>. Check it out in one visit with a double out.',
    'Success moves the target up one (skipping numbers with no finish). With 3 visits per target, a failed try is repeated.',
    'After the last try the target <b>goes back to the start</b>.',
    'After the set number of visits, the player who checked out the highest target wins.',
  ],
  killer: [
    'Every player gets a <b>random number</b>, shown as their big number.',
    'Hit <b>your own double</b> to become a <b>Killer</b> (any segment of it, if Counts as a hit is Any segment).',
    'As a Killer, hits on other players\' doubles take one of their <b>lives</b>. Hitting your own double costs you a life.',
    'Everyone starts with 3 or 5 lives. At zero you are out. <b>Last player standing</b> wins.',
  ],
};

const GAME_ORDER = ['x01', 'cricket', 'tactics', 'mickey', 'clock', 'shanghai', 'baseball', 'golf', 'countup', 'fives', 'halve', 'bobs', 'checkout', 'killer', 'leader', 'scram'];

// ================= engine =================
let G = null;
let api = { darts: [], status: '', lastSeen: 0, raw: null };
let ignoreUntilClear = false;
let saidForVisit = false;
let dartsCalled = 0;                    // darts of this visit already called out ("Call each dart")
let quiet = false, pendingWin = null;   // set while Fix scores replays visits
const mod = () => GAMES[G.cfg.game];
const setsLabel = (n) => (G && (G.cfg.setsToWin || 1) > 1 ? `Sets ${n || 0} · ` : '');
const matchGoal = (legsTo, setsTo) => ((setsTo || 1) > 1 ? `first to ${setsTo} sets of ${legsTo}` : `first to ${legsTo}`);
const emptyVisit = () => { dartsCalled = 0; return { overrides: {}, extra: [], seen: [] }; };

function newGame(cfg) {
  const g = { v: 2, hits: [], lastHits: [], cfg, legs: cfg.players.map(() => 0), sets: cfg.players.map(() => 0), cur: 0, legStarter: 0, leg: 1, round: 1, visit: emptyVisit(), history: [], over: false, winner: null };
  g.s = GAMES[cfg.game].create(cfg.opts, cfg.players.length, null);
  return g;
}
const isOut = (i) => !!(mod().isOut && mod().isOut(G.s, i));
const snapshot = () => clone(Object.assign({}, G, { history: [] }));

function detectedDarts() {
  if (ignoreUntilClear) return [];
  return (api.darts.length ? api.darts : (G.visit.seen || [])).slice(0, 3);
}
function visitDarts() {
  const all = detectedDarts().concat(G.visit.extra).slice(0, 3);
  for (const k of Object.keys(G.visit.overrides)) if (Number(k) < 3) all[Number(k)] = G.visit.overrides[k];
  return all.filter(Boolean);
}
function recentScores(i, n) {
  return G.history.filter((e) => e.fixScore != null && e.cur === i && e.leg === G.leg).slice(-n).map((e) => e.fixScore);
}
// The darts of the last three committed turns of this leg, shown while the next player throws.
function lastTurns() {
  return G.history.filter((e) => e.fixDarts && e.leg === G.leg).slice(-3)
    .map((e) => ({ p: e.cur, name: G.cfg.players[e.cur] || '', darts: e.fixDarts.map((d) => d.name), score: e.fixScore, bust: !!e.fixBust }));
}
const turnsHtml = (list) => (list || []).map((t, k) =>
  `<span class="turn${k === list.length - 1 ? ' new' : ''}" style="--c:${PCOL[t.p % PCOL.length]}"><b>${esc(t.name)}</b><i>${t.darts.length ? t.darts.map(esc).join(' ') : '–'}</i><em>${t.bust ? 'Bust' : esc(t.score)}</em></span>`).join('');
function preview(final) {
  const darts = visitDarts();
  const r = mod().play(clone(G.s), G.cur, darts, { round: G.round, final });
  r.darts = darts;
  return r;
}

function commitVisit() {
  if (!G || G.over) return;
  const r = preview(true);
  const snap = snapshot();
  snap.fixDarts = clone(r.darts);   // what this visit scored, for Fix scores
  snap.fixScore = r.bust ? 0 : (r.scored || 0);
  snap.fixBust = !!r.bust;
  G.history.push(snap);
  if (G.history.length > 300) G.history.shift();
  G.s = r.s;
  G.hits = (G.hits || []).concat([{ p: G.cur, darts: r.darts }]);
  if (!saidForVisit && r.call) speak(r.call);
  saidForVisit = false;
  ignoreUntilClear = api.darts.length > 0;
  G.visit = emptyVisit();

  if (r.won) return legWon(r.winner ?? G.cur);

  // next player still in the game
  const n = G.cfg.players.length;
  const pos = (i) => (i - G.legStarter + n) % n;
  let next = G.cur, wrapped = false;
  for (let k = 0; k < n; k++) {
    const cand = (next + 1) % n;
    if (pos(cand) <= pos(next)) wrapped = true;
    next = cand;
    if (!isOut(next)) break;
  }
  if (wrapped) {
    if (mod().roundEnd) {
      const w = mod().roundEnd(G.s, G.round);
      if (w != null) return legWon(w);
    }
    G.round++;
    G.lastHits = G.hits; G.hits = [];
  }
  if (isOut(next) && mod().roundEnd) { const w = mod().roundEnd(G.s, Infinity); return legWon(w); }
  G.cur = next;
  save(); render();
  announceFinish();
}

function legWon(w) {
  G.legs[w]++;
  const name = G.cfg.players[w];
  const setsTo = G.cfg.setsToWin || 1;
  let setWon = false;
  if (G.legs[w] >= G.cfg.legsToWin) {
    if (setsTo > 1) { G.sets = G.sets || G.legs.map(() => 0); G.sets[w]++; setWon = true; }
    if (setsTo <= 1 || G.sets[w] >= setsTo) {
      G.over = true; G.winner = w;
      speak(`Game shot, and the match, ${name}`);
      save(); render();
      if (quiet) pendingWin = [true, name]; else showWin(true, name);
      releaseBoard();   // the match is over: others may play
      return;
    }
    G.legs = G.legs.map(() => 0);
  }
  speak(setWon ? `Game shot, and the set, ${name}` : `Game shot, ${name}`);
  if (quiet) pendingWin = [false, name]; else showWin(false, name);
  G.leg++;
  G.legStarter = (G.legStarter + 1) % G.cfg.players.length;
  G.cur = G.legStarter; G.round = 1;
  G.lastHits = []; G.hits = [];
  G.s = mod().create(G.cfg.opts, G.cfg.players.length, G.s);
  G.visit = emptyVisit();
  save(); render();
  announceFinish();
}

function undo() {
  if (!G || !G.history.length) return;
  const hist = G.history;
  G = Object.assign(G.history.pop(), { history: hist });
  delete G.fixDarts; delete G.fixScore;
  const restored = (G.visit.seen || []).slice(0, 3).concat(G.visit.extra).slice(0, 3);
  Object.keys(G.visit.overrides).forEach((k) => { if (restored[k]) restored[k] = G.visit.overrides[k]; });
  G.visit = { overrides: {}, extra: restored, seen: [] };
  ignoreUntilClear = api.darts.length > 0;
  hideBanner(); save(); render();
}

// ================= board polling =================
let engine = { name: 'autodarts', port: 3180 };   // which program reads the cameras, told by the Pi (cgi-bin/lock)
function apiBase() { return store.get('api', `http://${location.hostname || 'localhost'}:${engine.port}`); }
// A board address saved earlier that is just this Pi with a board program's port pins the page to that program:
// forget it, so the page follows whichever one (Autodarts 3180, Tikka Vision 3181) the Pi has switched on.
try {
  const pinned = store.get('api', null);
  if (pinned && new RegExp('^http://' + (location.hostname || '').replace(/[.]/g, '\\.') + ':318[01]/?$').test(pinned)) store.del('api');
} catch {}
// On an HTTPS page (the internet link) browsers block plain-http requests, so the board is read
// through the Pi (cgi-bin/board), which also checks the game lock before a reset.
// Tikka Vision listens only inside the Pi, so its board is always reached through the Pi's signed-in CGI.
const viaPi = () => location.protocol === 'https:' || engine.name === 'tikka-vision';
async function poll() {
  try {
    const res = await fetch(viaPi() ? 'cgi-bin/board' : apiBase() + '/api/state', { cache: 'no-store' });
    const s = await res.json();
    api.raw = s;
    api.status = String(s.status || s.event || '');
    api.lastSeen = Date.now();
    const darts = Array.isArray(s.throws) ? s.throws.map(fromApi) : [];
    const changed = darts.length !== api.darts.length || darts.some((d, i) => d.name !== api.darts[i].name);
    api.darts = darts;
    if (darts.length === 0 && ignoreUntilClear) ignoreUntilClear = false;
    // Only the game on screen takes darts, and only for the user holding the board.
    const playing = $('game').classList.contains('on') || passiveMode === 'local';
    const mine = G && !G.over && !lockedByOther() && playing && !ended;
    if (mine && s.running === false && /stopped/i.test(api.status) && Date.now() - lastStartTry > 10000) startBoard();
    if (mine && !ignoreUntilClear && darts.length) G.visit.seen = darts.slice(0, 3);
    if (mine) onBoard(changed);
  } catch (e) {
    api.status = 'offline';
  }
  renderConn();
  if ($('raw').classList.contains('on')) $('raw').textContent = JSON.stringify(api.raw, null, 2);
}
function onBoard(changed) {
  const r = preview(false);
  if (r.won) { commitVisit(); return; }
  // The visit ends when the darts are pulled: the board clears its throws after takeout.
  if (!ignoreUntilClear && api.darts.length === 0 && (G.visit.seen || []).length) { commitVisit(); return; }
  // Each dart as it lands ("Treble 20"), when that option is on. The visit's own call follows in the same
  // sentence, since starting a new one would cut the dart's call off.
  const said = [];
  const detected = detectedDarts();
  if (dartCallsOn() && detected.length > dartsCalled) {
    for (let k = dartsCalled; k < detected.length && k < 3; k++) said.push(dartWords(detected[k]));
    // ... and, between darts, what is still needed to win now ("You require 32").
    if (finishCallsOn() && detected.length < 3 && !r.stop) {
      const f = finishNow();
      if (f) said.push(f.say.charAt(0).toUpperCase() + f.say.slice(1));
    }
  }
  dartsCalled = Math.max(dartsCalled, detected.length);
  if ((r.stop || r.darts.length === 3) && !saidForVisit) {
    const fin = preview(true);
    if (fin.call) said.push(fin.call);
    saidForVisit = true;
  }
  if (said.length) speak(said.join('. '));
  if (changed) render();
}
// Per device, like the score caller: menu "Call each dart".
const dartCallsOn = () => store.get('dartCalls', false);
const finishCallsOn = () => store.get('finishCalls', false);
// What the player at the board needs to win this turn, given the darts already thrown in it; null if it cannot be won.
function finishNow() {
  if (!G || G.over || !mod().finish) return null;
  const r = preview(false);
  if (r.bust || r.stop) return null;
  try { return mod().finish(r.s, G.cur, { dartsLeft: 3 - r.darts.length }) || null; } catch { return null; }
}
// At the start of each turn: "Peetu, you require 40".
function announceFinish() {
  if (!finishCallsOn() || quiet) return;
  const f = finishNow();
  if (f) setTimeout(() => speak(`${G.cfg.players[G.cur]}, ${f.say}`), 900);   // after the visit's own call has ended
}
function dartWords(d) {
  if (!d || !d.m || !d.n) return 'Miss';
  if (d.n === 25) return d.m === 2 ? 'Bull' : 'Twenty five';
  return (d.m === 3 ? 'Treble ' : d.m === 2 ? 'Double ' : '') + d.n;
}

// ================= caller =================
// iPhones and iPads only speak after speech was started from a tap; later calls from timers (darts
// detected) are then allowed. So the first tap anywhere speaks a silent word, and cancel() is never
// followed straight away by speak(), which iOS drops.
let speechUnlocked = false;
function unlockSpeech() {
  if (speechUnlocked || !('speechSynthesis' in window)) return;
  try { const u = new SpeechSynthesisUtterance(' '); u.volume = 0; speechSynthesis.speak(u); speechUnlocked = true; } catch {}
}
document.addEventListener('click', unlockSpeech, true);
document.addEventListener('touchend', unlockSpeech, true);
let speechVoice = null;
function pickVoice() {
  try {
    const vs = speechSynthesis.getVoices();
    speechVoice = vs.find((v) => /^en[-_]GB/i.test(v.lang)) || vs.find((v) => /^en/i.test(v.lang)) || null;
  } catch {}
}
if ('speechSynthesis' in window) { pickVoice(); speechSynthesis.onvoiceschanged = pickVoice; }
function speak(text, force) {
  if ((quiet && !force) || !text || !('speechSynthesis' in window) || (!force && !store.get('voice', true))) return;
  try {
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 0.95; u.lang = speechVoice ? speechVoice.lang : 'en-GB';
    if (speechVoice) u.voice = speechVoice;
    if (speechSynthesis.speaking || speechSynthesis.pending) {
      speechSynthesis.cancel();
      setTimeout(() => speechSynthesis.speak(u), 80);
    } else speechSynthesis.speak(u);
    speechSynthesis.resume();   // Safari sometimes leaves speech paused after the page was in the background
  } catch {}
}

// ================= rendering =================
function render() {
  if (!G) return;
  const r = preview(false);
  const shown = r.s;   // live state including the current visit
  const darts = r.darts;
  const wrap = $('players');
  wrap.innerHTML = '';
  const fin = finishCallsOn() ? finishNow() : null;     // shown on the card of the player at the board
  G.cfg.players.forEach((name, i) => {
    const active = i === G.cur && !G.over;
    const v = mod().view(shown, i, { active, dartsLeft: 3 - darts.length, bust: active && r.bust, round: G.round });
    const el = document.createElement('div');
    el.className = 'player' + (active ? ' active' : '') + (active && r.bust ? ' bust' : '') + (isOut(i) && !active ? ' out' : '');
    el.innerHTML = `
      <div class="name">${esc(name)}</div>
      <div class="legs">${setsLabel(G.sets && G.sets[i])}Legs ${G.legs[i]}${v.tag ? ` <span class="tag">${esc(v.tag)}</span>` : ''}${fin && active ? ` <span class="tag finish" title="${esc(fin.show || '')}">Can win</span>` : ''}</div>
      <div class="score">${esc(v.big)}</div>
      <div class="route">${esc(v.hint || '')}</div>
      ${v.extra || ''}
      <div class="stats">${esc(v.stats || '')}</div>
      <div class="recent" aria-label="Last five visits">${recentScores(i, 5).map((n, k, a) => `<span${k === a.length - 1 ? ' class="new"' : ''}>${n}</span>`).join('')}</div>`;
    if (active) el.setAttribute('aria-current', 'true');
    wrap.appendChild(el);
  });
  const detected = detectedDarts().length;
  document.querySelectorAll('.dart').forEach((b) => {
    const i = Number(b.dataset.i), d = darts[i];
    b.textContent = d ? d.name : '–';
    b.classList.toggle('hit', !!d);
    b.classList.toggle('edited', !!d && (G.visit.overrides[i] != null || i >= detected));
    const unsure = !!d && !!d.unsure && G.visit.overrides[i] == null && i < detected;
    b.classList.toggle('unsure', unsure);
    b.title = unsure ? 'The cameras disagreed about this dart. Tap to check the picture and correct it.' : '';
  });
  $('visit-total').textContent = r.bust ? 0 : (r.scored || 0);
  $('visit-note').textContent = r.bust ? 'bust, pull the darts' : darts.length === 3 || r.stop ? 'pull the darts' : 'this visit';
  const rounds = mod().rounds ? mod().rounds(G.cfg.opts) : null;
  $('match-text').textContent = `${mod().title(G.cfg.opts)} · leg ${G.leg} · ${rounds ? `round ${G.round}/${rounds} · ` : ''}${matchGoal(G.cfg.legsToWin, G.cfg.setsToWin)}`;
  $('btn-undo').disabled = !G.history.length;
  $('btn-fix').disabled = !G.history.some((e) => e.fixDarts);
  $('history').innerHTML = turnsHtml(lastTurns());
  renderBoard(darts);
  if (passiveMode === 'local') paintPassive(buildPayload());
  publish();
}

const PCOL = ['#00e5ff', '#ff7a00', '#a4ff3a', '#ffd23d', '#b58cff', '#ffffff', '#ff4d6d', '#3d8bff'];
// The board is drawn in units of 1/100 of its radius (viewBox -112..112). The geometry is computed on a radius of 1
// and scaled up in one group; the numbers and dart dots are placed in the large units directly. Safari (WebKit)
// mis-sizes and mis-places SVG text with a font size below 1 and blurs badly at tiny filter sizes, so nothing
// here is drawn in fractions of a unit. Each board has its own filter id: with two boards in the page, WebKit
// would resolve a shared id to the first one, and a filter inside a hidden board draws nothing.
const BS = 100;
const boardBase = {};
function boardSvg(id = 'board') {
  if (boardBase[id]) return boardBase[id];
  const pt = (r, deg) => { const a = deg * Math.PI / 180; return `${(r * Math.cos(a)).toFixed(4)},${(-r * Math.sin(a)).toFixed(4)}`; };
  const wedge = (r1, r2, a1, a2, fill) => `<path d="M${pt(r1, a1)} L${pt(r2, a1)} A${r2},${r2} 0 0 1 ${pt(r2, a2)} L${pt(r1, a2)} A${r1},${r1} 0 0 0 ${pt(r1, a1)}Z" fill="${fill}"/>`;
  let out = `<defs><filter id="glow-${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><g transform="scale(${BS})"><circle r="1.1" fill="#111111" stroke="#2a2a2a" stroke-width="0.006"/>`;
  let rings = '', labels = '';
  ORDER.forEach((n, k) => {
    // wedge centred on 90 - k*18 degrees; outer arc runs clockwise on screen (sweep 1), inner arc back (sweep 0)
    const c = 90 - k * 18, a1 = c + 9, a2 = c - 9;
    const dark = k % 2 === 0;
    const single = dark ? '#151515' : '#f2e4bd', ring = dark ? '#d9242b' : '#1b8a3d';   // regular board colours
    out += wedge(R.outerBull, R.trebleIn, a1, a2, single) + wedge(R.trebleOut, R.doubleIn, a1, a2, single);
    rings += wedge(R.trebleIn, R.trebleOut, a1, a2, ring) + wedge(R.doubleIn, R.doubleOut, a1, a2, ring);
    const a = c * Math.PI / 180, lx = (106 * Math.cos(a)).toFixed(2), ly = (-106 * Math.sin(a) + 3).toFixed(2);   // +3: optical centre, no dominant-baseline (WebKit applies it unevenly)
    labels += `<text x="${lx}" y="${ly}" font-size="8.5" fill="#f2f2f2" text-anchor="middle" font-family="-apple-system, system-ui, sans-serif">${n}</text>`;
  });
  out += `<g>${rings}<circle r="${R.outerBull}" fill="#1b8a3d"/><circle r="${R.bull}" fill="#d9242b"/></g></g>${labels}`;
  return (boardBase[id] = out);
}
function dotsFor(sets, showLast, id = 'board') {
  let dots = '';
  sets.forEach((v) => {
    v.darts.forEach((d) => {
      const pos = dartPos(d);
      if (!pos) return;
      const col = PCOL[v.p % PCOL.length];
      const r = v.live ? 5 : 3.8, x = (pos.x * BS).toFixed(2), y = (-pos.y * BS).toFixed(2);
      dots += `<circle cx="${x}" cy="${y}" r="${r}" fill="${col}" stroke="#0c0a09" stroke-width="1.2" filter="url(#glow-${id})" opacity="${showLast ? 0.5 : 1}"/>`;
      if (v.live) dots += `<circle cx="${x}" cy="${y}" r="8" fill="none" stroke="${col}" stroke-width="1.2"/>`;
    });
  });
  return dots;
}
function hitSets(live) {
  const committed = (G.hits || []).length ? G.hits : null;
  const showLast = !committed && !live.length && (G.lastHits || []).length;
  const sets = (committed || (showLast ? G.lastHits : [])).slice();
  if (!G.over && live.length) sets.push({ p: G.cur, darts: live, live: true });
  return { sets, showLast };
}
function renderBoard(live) {
  const { sets, showLast } = hitSets(live);
  $('board').innerHTML = boardSvg() + dotsFor(sets, showLast);
  $('board-cap').textContent = showLast ? 'Last round' : `Round ${G.round} hits`;
  $('legend').innerHTML = G.cfg.players.map((n, i) => `<span><i style="background:${PCOL[i % PCOL.length]}"></i>${esc(n)}</span>`).join('');
}
function renderConn() {
  const dot = $('conn-dot'), txt = $('conn-text');
  if (!api.lastSeen || Date.now() - api.lastSeen > 4000) { dot.className = 'dot off'; txt.textContent = 'Board offline'; return; }
  const s = api.status;
  dot.className = 'dot ' + (/throw/i.test(s) ? 'ok' : 'wait');
  txt.textContent = /throw/i.test(s) ? 'Ready to throw' : /takeout/i.test(s) ? 'Pulling darts' : s || 'Connected';
}

// ================= end session =================
// Ends the evening: the lights go off right away, the board stops, the board is handed back and an
// end screen shows how the game stood. A game that was not finished stays resumable from the menu.
let ended = false;   // set while the session is over, so the poll does not restart the board
async function stopBoard() {
  try {
    if (viaPi()) await fetch('cgi-bin/board', { method: 'POST', body: 'stop' });
    else await fetch(apiBase() + '/api/stop', { method: 'PUT' });
  } catch {}
}
function showEnd() {
  let title = 'Session ended', sub = 'See you next time', rows = '';
  if (G) {
    const setsTo = G.cfg.setsToWin || 1, names = G.cfg.players, sets = G.sets || [];
    const order = names.map((n, i) => i).sort((a, b) => (sets[b] || 0) - (sets[a] || 0) || G.legs[b] - G.legs[a] || a - b);
    const big = (i) => { try { return mod().view(G.s, i, { active: false, dartsLeft: 3, bust: false, round: G.round }).big; } catch { return ''; } };
    title = G.over && G.winner != null ? `${names[G.winner]} wins` : 'Game stopped';
    sub = `${mod().title(G.cfg.opts)} · ${G.over ? 'final result' : `leg ${G.leg}, not finished`}`;
    rows = order.map((i, k) => `<div class="er${G.over && i === G.winner ? ' win' : ''}"><span class="pos">${k + 1}</span><span class="nm">${esc(names[i])}</span><span class="lg">${setsTo > 1 ? `Sets ${sets[i] || 0} · ` : ''}Legs ${G.legs[i]}</span><span class="bg">${esc(big(i))}</span></div>`).join('');
  }
  $('end-title').textContent = title; $('end-sub').textContent = sub;
  $('end-table').innerHTML = rows;
  $('end-note').textContent = 'Switching the lights off…';
  $('end').classList.add('on');
}
async function endSession() {
  if (lockedByOther()) { alert(`${me.owner} is playing. Only they, or an admin who unlocks the board, can end the session.`); return; }
  if (G && !G.over && $('game').classList.contains('on') && !confirm('End the session? The lights go off and the board stops. You can resume this game from the menu.')) return;
  ended = true;
  hideBanner(); $('pad').classList.remove('on'); $('fix').classList.remove('on');
  showEnd();
  // Lights first, so they go off at once; the board stops alongside.
  const lights = fetch('cgi-bin/lights', { method: 'POST', body: 'end' }).then((r) => r.json()).catch(() => null);
  const board = stopBoard();
  const l = await lights; await board;
  $('end-note').textContent = l && l.ok === false ? l.error : l ? 'Lights off · board stopped' : 'Board stopped';
  toSetup();   // hands the board back and clears the live game on the passive displays
}
$('btn-end').onclick = endSession;
// Phones: the less used game actions live in a sheet ("More"); each one simply presses the real button.
function openMore() {
  const list = $('more-list'); list.innerHTML = '';
  for (const id of ['btn-fix', 'btn-reset', 'btn-lights', 'btn-passive', 'btn-menu', 'btn-end']) {
    const src = $(id);
    if (!src || src.hidden) continue;
    const b = document.createElement('button');
    b.textContent = src.textContent; b.disabled = src.disabled;
    if (id === 'btn-end') b.className = 'danger';
    b.onclick = () => { $('more').classList.remove('on'); src.click(); };
    list.appendChild(b);
  }
  $('more').classList.add('on');
}
$('btn-more').onclick = openMore;
$('more-close').onclick = () => $('more').classList.remove('on');
// A tap on the dimmed area outside a sheet closes it, as on any phone.
for (const id of ['more', 'pad', 'fix']) {
  $(id).addEventListener('click', (e) => { if (e.target === $(id)) $(id).classList.remove('on'); });
}
$('end-session').onclick = endSession;
$('end-menu').onclick = () => { $('end').classList.remove('on'); renderSetup(); };

// ================= banners =================
function showWin(match, name) {
  $('banner-title').textContent = match ? `${name} wins` : `Game shot, ${name}`;
  $('banner-text').textContent = match
    ? G.cfg.players.map((n, i) => `${n}: ${(G.cfg.setsToWin || 1) > 1 ? `${(G.sets || [])[i] || 0} sets` : `${G.legs[i]} leg${G.legs[i] === 1 ? '' : 's'}`}`).join('  |  ')
    : 'Next leg is ready. Pull the darts.';
  const acts = $('banner-actions'); acts.innerHTML = '';
  const add = (label, fn) => { const b = document.createElement('button'); b.className = 'chip'; b.textContent = label; b.onclick = fn; acts.appendChild(b); };
  if (match) {
    add('Rematch', async () => { if (!(await takeBoard())) return; G = newGame(G.cfg); ignoreUntilClear = api.darts.length > 0; startBoard().then(resetBoard); pingLights(); hideBanner(); save(); render(); });
    add('New game', () => { hideBanner(); toSetup(); });
    add('End session', endSession);
    add('Undo last visit', undoOwned);
  } else {
    add('Continue', hideBanner);
    add('Undo last visit', undo);
    setTimeout(() => { if (G && !G.over) hideBanner(); }, 4000);
  }
  $('banner').classList.add('on');
}
function hideBanner() { $('banner').classList.remove('on'); }

// ================= keypad =================
let padIndex = 0, padMult = 1, padFix = null;   // padFix: { idx, k } when editing an earlier visit
// The camera picture a dart was found in (Tikka Vision keeps them for the last throws); tap it for the next camera.
let padCam = 0;
function showEvidence(d) {
  const box = $('pad-evidence');
  if (!d || !d.id || !d.cams || !d.cams.length || engine.name !== 'tikka-vision') { box.hidden = true; return; }
  const cam = d.cams[padCam % d.cams.length];
  $('pad-img').src = `cgi-bin/boardimg?throw=${encodeURIComponent(d.id)}&cam=${encodeURIComponent(cam)}`;
  $('pad-img-cap').textContent = `${d.name} as ${cam} saw it${d.unsure ? ' · the cameras disagreed' : ''}${d.cams.length > 1 ? ' · tap the picture for the next camera' : ''}`;
  $('pad-img').onclick = () => { padCam++; showEvidence(d); };
  $('pad-img').onerror = () => { box.hidden = true; };
  box.hidden = false;
}
function openPad(i, fix) {
  padIndex = i; padMult = 1; padFix = fix || null;
  padCam = 0; showEvidence(fix ? null : detectedDarts()[i]);
  $('pad-clear').textContent = padFix ? 'Remove dart' : 'Use detected dart';
  $('pad-clear').hidden = !!padFix && padFix.k >= G.history[padFix.idx].fixDarts.length;
  const mult = $('pad-mult'); mult.innerHTML = '';
  [['Single', 1], ['Double', 2], ['Treble', 3]].forEach(([label, m]) => {
    const b = document.createElement('button'); b.textContent = label; b.setAttribute('aria-pressed', String(m === padMult));
    b.onclick = () => { padMult = m; mult.querySelectorAll('button').forEach((x, k) => x.setAttribute('aria-pressed', String(k + 1 === m))); };
    mult.appendChild(b);
  });
  const nums = $('pad-nums'); nums.innerHTML = '';
  const pick = (d) => {
    if (padFix) {
      const darts = G.history[padFix.idx].fixDarts.slice();
      darts[padFix.k] = d;
      $('pad').classList.remove('on');
      fixVisit(padFix.idx, darts);
      return;
    }
    const detected = detectedDarts().length;
    if (padIndex < detected) G.visit.overrides[padIndex] = d;
    else {
      const k = padIndex - detected;
      if (k < G.visit.extra.length) G.visit.extra[k] = d; else G.visit.extra.push(d);
    }
    saidForVisit = false;
    $('pad').classList.remove('on'); save(); render();
    if (preview(false).won) commitVisit();
  };
  for (let n = 1; n <= 20; n++) { const b = document.createElement('button'); b.textContent = n; b.onclick = () => pick(seg(n, padMult)); nums.appendChild(b); }
  const bull = document.createElement('button'); bull.textContent = 'Bull'; bull.onclick = () => pick(seg(25, padMult === 1 ? 1 : 2)); nums.appendChild(bull);
  const miss = document.createElement('button'); miss.textContent = 'Miss'; miss.onclick = () => pick(seg(0, 0)); nums.appendChild(miss);
  $('pad').classList.add('on');
}
$('pad-close').onclick = () => $('pad').classList.remove('on');
$('pad-clear').onclick = () => {
  if (padFix) {
    const darts = G.history[padFix.idx].fixDarts.slice();
    darts.splice(padFix.k, 1);
    $('pad').classList.remove('on');
    fixVisit(padFix.idx, darts);
    return;
  }
  delete G.visit.overrides[padIndex]; $('pad').classList.remove('on'); render(); };
// ================= fix scores =================
// Every committed visit keeps the darts it scored (history[i].fixDarts) and the game state
// before it. Fixing a dart restores that state and replays the visit and all later ones.
function fixVisit(idx, newDarts) {
  const h = G.history, backup = G, ig = ignoreUntilClear, live = G.visit;
  const keep = h.slice(0, idx);
  G = Object.assign(clone(h[idx]), { history: keep });
  delete G.fixDarts; delete G.fixScore;
  quiet = true; pendingWin = null;
  let ok = true;
  for (let k = 0; idx + k < h.length; k++) {
    const e = h[idx + k];
    if (k > 0 && (G.over || G.leg !== e.leg || G.cur !== e.cur)) { ok = false; break; }
    G.visit = { overrides: {}, extra: clone(k === 0 ? newDarts : e.fixDarts), seen: [] };
    ignoreUntilClear = true;
    commitVisit();
  }
  quiet = false;
  const win = pendingWin; pendingWin = null;
  if (!ok) {
    G = backup; ignoreUntilClear = ig;
    alert('That change would alter who wins a leg or whose turn it is later on, so it was not applied. Use Undo visit to step back further.');
    render(); return;
  }
  ignoreUntilClear = ig;
  saidForVisit = false;
  hideBanner();
  if (win) { $('fix').classList.remove('on'); showWin(win[0], win[1]); } else if (!G.over) G.visit = live;
  save(); render(); renderFix(idx);
}
function renderFix(flash) {
  const list = $('fix-list'); list.innerHTML = '';
  const rows = [];
  G.history.forEach((e, i) => { if (e.fixDarts) rows.push(i); });
  rows.reverse().slice(0, 30).forEach((i) => {
    const e = G.history[i];
    const row = document.createElement('div');
    row.className = 'frow' + (i === flash ? ' fixed' : '');
    const who = document.createElement('div'); who.className = 'who';
    who.innerHTML = `${esc(G.cfg.players[e.cur])}<small>Leg ${e.leg} · round ${e.round}</small>`;
    row.appendChild(who);
    if (e.fixScore != null) { const t = document.createElement('div'); t.className = 'pts'; t.textContent = e.fixScore; row.appendChild(t); }
    e.fixDarts.forEach((d, k) => {
      const b = document.createElement('button'); b.textContent = d.name; b.setAttribute('aria-label', `Dart ${k + 1}, ${d.name}, tap to change`);
      b.onclick = () => openPad(0, { idx: i, k });
      row.appendChild(b);
    });
    if (e.fixDarts.length < 3) {
      const b = document.createElement('button'); b.className = 'add'; b.textContent = '+'; b.setAttribute('aria-label', 'Add a dart');
      b.onclick = () => openPad(0, { idx: i, k: e.fixDarts.length });
      row.appendChild(b);
    }
    list.appendChild(row);
  });
  if (!rows.length) list.innerHTML = '<p>No visits yet.</p>';
}
$('btn-fix').onclick = async () => { if (!G) return; if (G.over && !(await takeBoard())) return; renderFix(); $('fix').classList.add('on'); };
$('fix-close').onclick = () => $('fix').classList.remove('on');
document.querySelectorAll('.dart').forEach((b) => b.onclick = () => G && !G.over && openPad(Number(b.dataset.i)));

// ================= passive display =================
// A display-only view: dartboard, this round's hits and the last 10 scores of each player.
// The device that scores publishes the game to the Pi (cgi-bin/game); a TV opened in passive mode
// (#passive) reads it from there. The "Passive view" button shows the local game the same way.
let passiveMode = null;       // null | 'local' | 'remote'
let passiveTimer = null;
let lastPublished = '', publishTimer = 0, publishedAt = 0;

function buildPayload() {
  const r = preview(false), darts = r.darts;
  const { sets, showLast } = hitSets(darts);
  return {
    turns: lastTurns(), title: mod().title(G.cfg.opts), leg: G.leg, legsToWin: G.cfg.legsToWin, setsToWin: G.cfg.setsToWin || 1, round: G.round, over: G.over,
    winner: G.winner != null ? G.cfg.players[G.winner] : null, sets, showLast,
    players: G.cfg.players.map((name, i) => {
      const active = i === G.cur && !G.over;
      const v = mod().view(r.s, i, { active, dartsLeft: 3 - darts.length, bust: active && r.bust, round: G.round });
      return { name, legs: G.legs[i], sets: (G.cfg.setsToWin || 1) > 1 ? (G.sets || [])[i] || 0 : null, big: v.big, hint: v.hint || '', tag: v.tag || '', active, bust: active && !!r.bust, out: isOut(i) && !active, recent: recentScores(i, 10) };
    }),
  };
}
function publish(force) {
  if (!G || passiveMode === 'remote' || lockedByOther()) return;
  const body = JSON.stringify(buildPayload());
  if (!force && body === lastPublished) return;
  const wait = 400 - (Date.now() - publishedAt);
  if (wait > 0 && !force) { if (!publishTimer) publishTimer = setTimeout(() => { publishTimer = 0; publish(); }, wait); return; }
  lastPublished = body; publishedAt = Date.now();
  try { fetch('cgi-bin/game', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(Object.assign(JSON.parse(body), { t: Date.now() })) }).catch(() => {}); } catch {}
}
function paintPassive(d) {
  if (!d || d.none || !d.players) {
    $('p-title').textContent = 'Waiting for a game'; $('p-players').innerHTML = ''; $('p-hits').innerHTML = '';
    $('p-board').innerHTML = boardSvg('p'); $('p-cap').textContent = ''; $('p-hist').innerHTML = ''; return;
  }
  $('p-title').textContent = `${d.title} · leg ${d.leg} · ${matchGoal(d.legsToWin, d.setsToWin)}${d.over && d.winner ? ' · ' + d.winner + ' wins' : ''}`;
  $('p-stamp').textContent = d.t && passiveMode === 'remote' ? 'Updated ' + new Date(d.t).toLocaleTimeString() : '';
  $('p-board').innerHTML = boardSvg('p') + dotsFor(d.sets || [], d.showLast, 'p');
  $('p-cap').textContent = d.showLast ? 'Last round' : `Round ${d.round} hits`;
  $('p-hist').innerHTML = turnsHtml(d.turns);
  $('p-hits').innerHTML = (d.sets || []).map((v) => {
    const c = PCOL[v.p % PCOL.length], who = d.players[v.p] ? d.players[v.p].name : '';
    return v.darts.length ? `<span style="color:${c};border-color:${c}" ${d.showLast ? 'class="old"' : ''}>${esc(who)} ${v.darts.map((x) => esc(x.name)).join(' ')}</span>` : '';
  }).join('');
  $('p-players').innerHTML = d.players.map((p, i) => `
    <div class="pp${p.active ? ' active' : ''}${p.bust ? ' bust' : ''}${p.out ? ' out' : ''}">
      <div class="nm"><i style="display:inline-block;width:.5em;height:.5em;border-radius:50%;margin-right:.4em;background:${PCOL[i % PCOL.length]}"></i>${esc(p.name)}<small>${p.sets != null ? 'Sets ' + esc(p.sets) + ' · ' : ''}Legs ${esc(p.legs)}${p.tag ? ' · ' + esc(p.tag) : ''}</small></div>
      <div class="big">${esc(p.big)}</div>
      <div class="sub">${esc(p.hint)}</div>
      <div class="rec" aria-label="Last 10 scores">${(p.recent || []).map((n, k, a) => `<span${k === a.length - 1 ? ' class="new"' : ''}>${esc(n)}</span>`).join('')}</div>
    </div>`).join('');
}
async function pollPassive() {
  try {
    const res = await fetch('cgi-bin/game', { cache: 'no-store' });
    paintPassive(await res.json());
  } catch { $('p-stamp').textContent = 'Connection lost'; }
}
function showPassive(mode) {
  passiveMode = mode;
  $('p-exit').hidden = !!window.PUBLIC_VIEW || forcedView;
  $('setup').classList.remove('on'); $('game').classList.remove('on'); $('passive').classList.add('on');
  clearInterval(passiveTimer);
  if (mode === 'remote') { pollPassive(); passiveTimer = setInterval(pollPassive, 700); }
  else paintPassive(buildPayload());
  screenOn(true);
}
function exitPassive() {
  if (window.PUBLIC_VIEW) return;
  clearInterval(passiveTimer);
  const was = passiveMode; passiveMode = null;
  $('passive').classList.remove('on');
  if (location.hash === '#passive') history.replaceState(null, '', location.pathname + location.search);
  if (was === 'local' && G) toGame(); else toSetup(true);
}
$('btn-passive').onclick = () => { if (G) showPassive('local'); };
$('open-passive').onclick = () => { location.hash = '#passive'; showPassive('remote'); };
$('p-exit').onclick = exitPassive;

// ================= sign-in and game lock =================
// The Pi knows who signed in (browser sign-in). Starting a game locks the board to that user until the
// match ends or they end the game; everyone else gets the live game read-only. Without sign-in
// (no users set up) there is no owner and nothing is locked.
let me = { user: '', owner: '', admin: false };
let forcedView = false;
const lockedByOther = () => !!me.owner && me.owner !== me.user;
async function lockCall(action) {
  try {
    const res = await fetch('cgi-bin/lock', action ? { method: 'POST', body: action } : { cache: 'no-store' });
    if (res.status === 401) { goSignIn(); return false; }
    if (!res.ok) return true;              // older Pi without the lock: behave as before
    const d = await res.json();
    me = { user: d.me || '', owner: d.owner || '', admin: !!d.admin };
    if (d.engine) engine = { name: d.engine, port: d.port || (d.engine === 'tikka-vision' ? 3181 : 3180) };
    return d.ok !== false;
  } catch { return true; }
}
function applyLock() {
  if (window.PUBLIC_VIEW) return;
  if (lockedByOther()) {
    if (!forcedView) { forcedView = true; hideBanner(); $('pad').classList.remove('on'); $('fix').classList.remove('on'); showPassive('remote'); }
    $('p-lock').textContent = `${me.owner} is playing · view only`;
    $('p-unlock').hidden = !me.admin;
  } else {
    $('p-lock').textContent = ''; $('p-unlock').hidden = true;
    if (forcedView) { forcedView = false; exitPassive(); }
  }
  const w = $('who');
  $('who-line').hidden = !me.user;
  w.textContent = me.user ? `Signed in as ${me.user}${me.admin ? ' (admin)' : ''}${me.owner === me.user ? ' · the board is yours until the game ends' : ''}` : '';
}
async function lockWatch() { await lockCall(); applyLock(); }
// The page loads without a password; the data needs one. The browser asks for it when a page under
// cgi-bin/ is opened, so go there once and come back (keeping e.g. #passive).
let signingIn = false;
function goSignIn() {
  if (signingIn || window.PUBLIC_VIEW) return;
  signingIn = true;
  try { sessionStorage.setItem('afterLogin', location.hash); } catch {}
  // While the browser's sign-in box is open this page stays alive. Its timers must not keep calling
  // the Pi: every 401 makes the browser redraw the box, which looked like the login screen blinking
  // (Android Chrome). So cover the page and let no request out until the sign-in is done.
  const cover = document.createElement('div');
  cover.className = 'banner on'; cover.style.zIndex = '20';
  cover.innerHTML = '<div><h2>Sign in</h2><p>Waiting for your name and password…</p><div class="row"><button class="chip" id="signin-retry">Open sign-in</button></div></div>';
  document.body.appendChild(cover);
  cover.querySelector('button').onclick = () => { location.href = 'cgi-bin/login'; };
  location.href = 'cgi-bin/login';
}
// Every call to the Pi's CGIs goes through here: the first 401 starts the sign-in, after that no
// further call is sent until the page is loaded again.
const pageFetch = window.fetch.bind(window);
window.fetch = async function (url, opts) {
  const own = typeof url === 'string' && url.startsWith('cgi-bin/') && !url.startsWith('cgi-bin/login');
  if (own && signingIn) throw new Error('signing in');
  const res = await pageFetch(url, opts);
  if (own && res.status === 401) goSignIn();
  return res;
};
// Sign out. Browsers keep a sign-in until the tab is closed and offer no way to drop it, so the page
// signs in once more with a name that doesn't exist: the browser replaces the saved sign-in with it
// and asks for a name and password on the next load.
async function signOut() {
  if (me.owner && me.owner === me.user && G && !G.over && !confirm('Sign out? Your game stays locked to you until it ends or an admin unlocks it.')) return;
  screenOn(false);
  await new Promise((done) => {
    const x = new XMLHttpRequest();
    x.open('GET', 'cgi-bin/lock?signout=' + Date.now(), true, 'signed-out', 'x' + Date.now());
    x.onloadend = done; x.send();
  });
  goSignIn();
}
// Takes the board for this user; false (and the view-only screen) if someone else has it.
async function takeBoard() {
  const ok = await lockCall('acquire');
  if (ok) ended = false;
  applyLock();
  if (!ok && !lockedByOther()) alert('The board is in use by someone else.');
  return ok;
}
function releaseBoard() { lockCall('release').then(applyLock); }
$('btn-logout').onclick = signOut;
$('p-unlock').onclick = async () => {
  if (!confirm(`Take the board from ${me.owner}? Their game stops updating here.`)) return;
  await lockCall('force'); applyLock();
};

// ================= settings page =================
// Users, lights and the game lock, stored on the Pi (cgi-bin/settings). Admins only; while sign-in is
// off anyone on the home network may open it, so the first user can be created here.
function smsg(text, err) { $('settings-msg').textContent = text || ''; $('settings-msg').classList.toggle('err', !!err); }
async function settingsCall(params) {
  const opts = params
    ? { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: Object.entries(params).map(([k, v]) => k + '=' + encodeURIComponent(v)).join('&') }
    : { cache: 'no-store' };
  try {
    const res = await fetch('cgi-bin/settings', opts);
    const d = await res.json();
    if (d.ok === false) { smsg(d.error || 'Not saved.', true); return null; }
    return d;
  } catch { smsg('The Pi could not be reached.', true); return null; }
}
function renderSettings(d) {
  const list = $('users-list'); list.innerHTML = '';
  $('users-note').textContent = d.users.length
    ? 'Everyone signs in with these names. Admins can open this page and force-unlock a game.'
    : 'Sign-in is off: anyone on your network can use the scoreboard. Add a user to turn it on (the first user is admin).';
  $('secure-form').closest('.sgroup').hidden = !d.users.length && !d.secure_url;
  d.users.forEach((u) => {
    const li = document.createElement('li');
    const self = u.name === d.me;
    li.innerHTML = `<span class="uname">${esc(u.name)}</span>${u.admin ? '<span class="badge">admin</span>' : ''}${self ? '<span class="hint" style="margin:0">you</span>' : ''}
      <span class="grow" style="flex:1"></span>
      <input type="password" placeholder="New password" autocomplete="new-password" hidden>
      <button data-a="pw">Change password</button>
      <button data-a="admin">${u.admin ? 'Remove admin' : 'Make admin'}</button>
      <button data-a="del" class="del">Remove</button>`;
    const inp = li.querySelector('input');
    li.querySelector('[data-a="pw"]').onclick = async (e) => {
      if (inp.hidden) { inp.hidden = false; e.target.textContent = 'Save password'; inp.focus(); return; }
      const r = await settingsCall({ action: 'user_pw', name: u.name, password: inp.value });
      if (r) { renderSettings(r); smsg(self ? 'Password changed. Your browser will ask you to sign in again.' : `Password changed for ${u.name}.`); }
    };
    li.querySelector('[data-a="admin"]').onclick = async () => {
      const r = await settingsCall({ action: 'user_admin', name: u.name, on: u.admin ? 0 : 1 });
      if (r) { renderSettings(r); smsg(`${u.name} ${u.admin ? 'is no longer admin' : 'is now admin'}.`); }
    };
    li.querySelector('[data-a="del"]').onclick = async () => {
      if (!confirm(`Remove ${u.name}?`)) return;
      const r = await settingsCall({ action: 'user_del', name: u.name });
      if (r) { renderSettings(r); smsg(`${u.name} removed.`); }
    };
    list.appendChild(li);
  });
  const L = d.lights, f = $('lights-form');
  $('lights-form').hidden = $('lights-mode').hidden = !L.installed;
  $('lights-note').textContent = L.installed
    ? 'A Tuya / Smart Life Wi-Fi plug. Changes apply within a few seconds.'
    : 'Not installed. Install it with INSTALL_LIGHTS=yes (see README).';
  if (L.installed) {
    f.device_id.value = L.device_id; f.ip.value = L.ip; f.version.value = L.version;
    f.idle_minutes.value = L.idle_minutes; f.no_score_minutes.value = L.no_score_minutes;
    f.local_key.value = ''; f.local_key.placeholder = L.key_set ? 'Saved (leave empty to keep)' : '16 characters';
    f.local_key.required = !L.key_set;
    chips($('lights-mode'), [['Automatic', 'auto'], ['Always on', 'on'], ['Always off', 'off']], L.mode, async (m) => {
      const r = await settingsCall({ action: 'lights_mode', mode: m });
      if (r) { renderSettings(r); smsg('Lights: ' + { auto: 'automatic', on: 'always on', off: 'always off' }[m] + '.'); }
    });
  }
  $('lock-form').hours.value = d.lock_hours;
  $('secure-form').url.value = d.secure_url || '';
}
async function openSettings() {
  smsg('');
  $('setup').classList.remove('on'); $('settings').classList.add('on');
  $('api').value = apiBase();
  $('engine-note').textContent = engine.name === 'tikka-vision'
    ? `Board program: Tikka Vision (port ${engine.port}). Switch back on the Pi with: board-engine autodarts`
    : `Board program: Autodarts (port ${engine.port}). Switch on the Pi with: board-engine tikka-vision`;
  $('engine-tools').hidden = engine.name !== 'tikka-vision' || (!!me.user && !me.admin);     // calibrating is for admins
  if (api.raw && api.raw.needsOrientation) $('engine-note').textContent += ' · The cameras still need to know which way the board is turned: throw one dart at the 20 and press Set orientation.';
  // Everyone can set this device's board address; users, lights and the lock are for admins.
  const admin = !me.user || me.admin;
  document.querySelectorAll('#settings [data-admin]').forEach((el) => { el.hidden = !admin; });
  if (!admin) return;
  const d = await settingsCall();
  if (d) renderSettings(d);
}
$('btn-settings').onclick = openSettings;
$('settings-close').onclick = () => { $('settings').classList.remove('on'); lockWatch(); toSetup(true); };
$('user-add').onsubmit = async (e) => {
  e.preventDefault();
  const f = e.target, first = !$('users-list').children.length;
  const name = f.uname.value.trim();
  const r = await settingsCall({ action: 'user_add', name, password: f.password.value, admin: f.admin.checked ? 1 : 0 });
  if (!r) return;
  renderSettings(r); smsg(first ? `${name} added as admin. Sign-in is now on: your browser will ask for it.` : `${name} added.`);
  f.reset();
};
$('lights-form').onsubmit = async (e) => {
  e.preventDefault();
  const f = e.target;
  const r = await settingsCall({ action: 'lights_save', device_id: f.device_id.value, ip: f.ip.value, local_key: f.local_key.value,
    version: f.version.value, idle_minutes: f.idle_minutes.value, no_score_minutes: f.no_score_minutes.value });
  if (r) { renderSettings(r); smsg('Lights saved.'); }
};
$('secure-form').onsubmit = async (e) => {
  e.preventDefault();
  const r = await settingsCall({ action: 'secure_url', url: e.target.url.value.trim() });
  if (r) { renderSettings(r); smsg(r.secure_url ? 'Secure address saved. Devices on the home network are now sent there.' : 'Secure address removed.'); }
};
$('lock-form').onsubmit = async (e) => {
  e.preventDefault();
  const r = await settingsCall({ action: 'lock_hours', hours: e.target.hours.value });
  if (r) { renderSettings(r); smsg('Game lock saved.'); }
};

// ================= keep the screen on =================
// While a game is open the phone or tablet shouldn't go to sleep. HTTPS pages use the Wake Lock API.
// Plain-http pages (the home address) can't, so a tiny muted looping video plays out of sight instead,
// which keeps most phones awake. Per device: menu "Keep screen on".
const AWAKE_VIDEO = 'data:video/mp4;base64,AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAAW/bW9vdgAAAGxtdmhkAAAAAAAAAAAAAAAAAAAfQAAAPoAAAQAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAll0cmFrAAAAXHRraGQAAAADAAAAAAAAAAAAAAABAAAAAAAAPoAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAABAAAAAABAAAAAQAAAAAAAkZWR0cwAAABxlbHN0AAAAAAAAAAEAAD6AAAAAAAABAAAAAAHRbWRpYQAAACBtZGhkAAAAAAAAAAAAAAAAAABAAAAAgABVxAAAAAAALWhkbHIAAAAAAAAAAHZpZGUAAAAAAAAAAAAAAABWaWRlb0hhbmRsZXIAAAABfG1pbmYAAAAUdm1oZAAAAAEAAAAAAAAAAAAAACRkaW5mAAAAHGRyZWYAAAAAAAAAAQAAAAx1cmwgAAAAAQAAATxzdGJsAAAAuHN0c2QAAAAAAAAAAQAAAKhhdmMxAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAABAAEABIAAAASAAAAAAAAAABFExhdmM2My4xLjEwMiBsaWJ4MjY0AAAAAAAAAAAAAAAAGP//AAAALmF2Y0MBQsAe/+EAFmdCwB7ZHsBEAAADAAQAAAMACDxYuSABAAVoy4PEyAAAABBwYXNwAAAAAQAAAAEAAAAUYnRydAAAAAAAAApQAAAAAAAAABhzdHRzAAAAAAAAAAEAAAACAABAAAAAABRzdHNzAAAAAAAAAAEAAAABAAAAHHN0c2MAAAAAAAAAAQAAAAEAAAABAAAAAQAAABxzdHN6AAAAAAAAAAAAAAACAAACiQAAAAsAAAAYc3RjbwAAAAAAAAACAAAGAgAACKsAAAKRdHJhawAAAFx0a2hkAAAAAwAAAAAAAAAAAAAAAgAAAAAAAD6AAAAAAAAAAAAAAAABAQAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAJGVkdHMAAAAcZWxzdAAAAAAAAAABAAA+gAAABAAAAQAAAAACCW1kaWEAAAAgbWRoZAAAAAAAAAAAAAAAAAAAH0AAAEKAVcQAAAAAAC1oZGxyAAAAAAAAAABzb3VuAAAAAAAAAAAAAAAAU291bmRIYW5kbGVyAAAAAbRtaW5mAAAAEHNtaGQAAAAAAAAAAAAAACRkaW5mAAAAHGRyZWYAAAAAAAAAAQAAAAx1cmwgAAAAAQAAAXhzdGJsAAAAfnN0c2QAAAAAAAAAAQAAAG5tcDRhAAAAAAAAAAEAAAAAAAAAAAABABAAAAAAH0AAAAAAADZlc2RzAAAAAAOAgIAlAAIABICAgBdAFQAAAAAAH0AAAAE4BYCAgAUViFblAAaAgIABAgAAABRidHJ0AAAAAAAAH0AAAAE4AAAAIHN0dHMAAAAAAAAAAgAAABAAAAQAAAAAAQAAAoAAAAAoc3RzYwAAAAAAAAACAAAAAQAAAAEAAAABAAAAAgAAAAgAAAABAAAAWHN0c3oAAAAAAAAAAAAAABEAAAATAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAABxzdGNvAAAAAAAAAAMAAAXvAAAIiwAACLYAAAAac2dwZAEAAAByb2xsAAAAAgAAAAH//wAAABxzYmdwAAAAAHJvbGwAAAABAAAAEQAAAAEAAABhdWR0YQAAAFltZXRhAAAAAAAAACFoZGxyAAAAAAAAAABtZGlyYXBwbAAAAAAAAAAAAAAAACxpbHN0AAAAJKl0b28AAAAcZGF0YQAAAAEAAAAATGF2ZjYzLjEuMTAyAAAACGZyZWUAAALvbWRhdNwATGF2YzYzLjEuMTAyAAIwQA4AAAJyBgX//27cRem95tlIt5Ys2CDZI+7veDI2NCAtIGNvcmUgMTY1IHIzMjIyIGIzNTYwNWEgLSBILjI2NC9NUEVHLTQgQVZDIGNvZGVjIC0gQ29weWxlZnQgMjAwMy0yMDI1IC0gaHR0cDovL3d3dy52aWRlb2xhbi5vcmcveDI2NC5odG1sIC0gb3B0aW9uczogY2FiYWM9MCByZWY9MyBkZWJsb2NrPTE6LTM6LTMgYW5hbHlzZT0weDE6MHgxMTEgbWU9aGV4IHN1Ym1lPTcgcHN5PTEgcHN5X3JkPTIuMDA6MC43MCBtaXhlZF9yZWY9MSBtZV9yYW5nZT0xNiBjaHJvbWFfbWU9MSB0cmVsbGlzPTEgOHg4ZGN0PTAgY3FtPTAgZGVhZHpvbmU9MjEsMTEgZmFzdF9wc2tpcD0xIGNocm9tYV9xcF9vZmZzZXQ9LTQgdGhyZWFkcz0xIGxvb2thaGVhZF90aHJlYWRzPTEgc2xpY2VkX3RocmVhZHM9MCBucj0wIGRlY2ltYXRlPTEgaW50ZXJsYWNlZD0wIGJsdXJheV9jb21wYXQ9MCBjb25zdHJhaW5lZF9pbnRyYT0wIGJmcmFtZXM9MCB3ZWlnaHRwPTAga2V5aW50PTI1MCBrZXlpbnRfbWluPTEgc2NlbmVjdXQ9NDAgaW50cmFfcmVmcmVzaD0wIHJjX2xvb2thaGVhZD00MCByYz1jcmYgbWJ0cmVlPTEgY3JmPTIzLjAgcWNvbXA9MC42MCBxcG1pbj0wIHFwbWF4PTY5IHFwc3RlcD00IGlwX3JhdGlvPTEuNDAgYXE9MToxLjIwAIAAAAAPZYiEBfOf//8PRQABV5+AARggBwEYIAcBGCAHARggBwEYIAcBGCAHARggBwEYIAcAAAAHQZo4C+c6gAEYIAcBGCAHARggBwEYIAcBGCAHARggBwEYIAcBGCAH';
let wakeSentinel = null, wakeVideo = null, screenWanted = false;
const awakeOn = () => store.get('awake', true);
async function screenOn(on) {
  screenWanted = on && awakeOn();
  if (!screenWanted) {
    try { if (wakeSentinel) await wakeSentinel.release(); } catch {}
    wakeSentinel = null;
    if (wakeVideo) wakeVideo.pause();
    return;
  }
  if ('wakeLock' in navigator && window.isSecureContext) {
    try {
      if (!wakeSentinel) {
        wakeSentinel = await navigator.wakeLock.request('screen');
        wakeSentinel.addEventListener('release', () => { wakeSentinel = null; });
      }
      return;
    } catch {}
  }
  if (!wakeVideo) {
    wakeVideo = document.createElement('video');
    Object.assign(wakeVideo, { muted: true, loop: true, playsInline: true, src: AWAKE_VIDEO });
    wakeVideo.setAttribute('playsinline', ''); wakeVideo.setAttribute('muted', ''); wakeVideo.setAttribute('aria-hidden', 'true');
    wakeVideo.style.cssText = 'position:fixed;left:0;bottom:0;width:1px;height:1px;opacity:0.01;pointer-events:none';
    document.body.appendChild(wakeVideo);
  }
  try { await wakeVideo.play(); } catch {}   // needs a tap on some phones; retried on the next one
}
// The browser drops the lock when the page is hidden, and some phones only play after a tap.
document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible' && screenWanted) screenOn(true); });
document.addEventListener('pointerdown', () => {
  if (screenWanted && !wakeSentinel && (!wakeVideo || wakeVideo.paused)) screenOn(true);
}, true);

// ================= updates =================
// The installer stamps BUILD into the page and writes the same value to the file "build". An open page
// checks it every minute and reloads when a new version is installed, but never in the middle of a game.
const BUILD = '__SCOREBOARD_BUILD__';
let updateReady = false;
const canReload = () => window.PUBLIC_VIEW || !($('game').classList.contains('on') || $('settings').classList.contains('on')
  || $('pad').classList.contains('on') || (passiveMode === 'local'));
async function checkUpdate() {
  try {
    const b = (await (await fetch('build', { cache: 'no-store' })).text()).trim();
    if (/^[0-9a-f]{12}$/.test(b) && b !== BUILD) updateReady = true;
  } catch {}
  if (updateReady && canReload()) location.reload();
}
setInterval(checkUpdate, 60000);
document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') checkUpdate(); });

// ================= setup screen =================
// Players list: shared on the Pi (cgi-bin/players), cached in this browser.
let roster = store.get('roster', []);          // [{ name, games }]
roster = roster.map((r) => typeof r === 'string' ? { name: r, games: 0 } : r);
let lastLineup = store.get('lastLineup', []);
let picked = [];
let shared = false;
async function loadPlayers() {
  try {
    const res = await fetch('cgi-bin/players', { cache: 'no-store' });
    if (!res.ok) throw new Error(res.status);
    const data = await res.json();
    if (Array.isArray(data.players)) roster = data.players.map((r) => typeof r === 'string' ? { name: r, games: 0 } : r);
    if (Array.isArray(data.last)) lastLineup = data.last;
    shared = true;
  } catch { shared = false; }
  store.set('roster', roster); store.set('lastLineup', lastLineup);
  picked = picked.filter((n) => roster.some((r) => r.name === n));
  renderSetup();
}
async function savePlayers() {
  store.set('roster', roster); store.set('lastLineup', lastLineup);
  if (!shared) return;
  try {
    await fetch('cgi-bin/players', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ players: roster, last: lastLineup }) });
  } catch {}
}
function renderManage() {
  const ul = $('manage-list'); ul.innerHTML = '';
  roster.forEach((r, i) => {
    const li = document.createElement('li');
    li.innerHTML = `<input maxlength="16" aria-label="Name"><span class="count"></span>
      <button aria-label="Move up">↑</button><button aria-label="Move down">↓</button><button class="del">Remove</button>`;
    const [inp] = li.getElementsByTagName('input');
    const [up, down, del] = li.getElementsByTagName('button');
    inp.value = r.name;
    li.querySelector('.count').textContent = r.games ? `${r.games} game${r.games > 1 ? 's' : ''}` : '';
    inp.onchange = () => {
      const v = inp.value.trim();
      if (!v || roster.some((x, k) => k !== i && x.name === v)) { inp.value = r.name; return; }
      picked = picked.map((n) => n === r.name ? v : n);
      lastLineup = lastLineup.map((n) => n === r.name ? v : n);
      r.name = v; savePlayers(); renderSetup();
    };
    up.disabled = i === 0; down.disabled = i === roster.length - 1;
    up.onclick = () => { [roster[i - 1], roster[i]] = [roster[i], roster[i - 1]]; savePlayers(); renderSetup(); };
    down.onclick = () => { [roster[i + 1], roster[i]] = [roster[i], roster[i + 1]]; savePlayers(); renderSetup(); };
    del.onclick = () => {
      if (!confirm(`Remove ${r.name} from the list?`)) return;
      roster.splice(i, 1);
      picked = picked.filter((n) => n !== r.name);
      lastLineup = lastLineup.filter((n) => n !== r.name);
      savePlayers(); renderSetup();
    };
    ul.appendChild(li);
  });
  $('sync-note').textContent = shared
    ? 'The list is saved on the board computer and shared by every device.'
    : 'The board computer could not be reached, so the list is saved in this browser only.';
}
let cfg = Object.assign({ game: 'x01', legsToWin: 3, setsToWin: 1, opts: {} }, store.get('cfg', {}));
if (!GAMES[cfg.game]) cfg.game = 'x01';

function gameOpts(id) {
  const saved = store.get('opts.' + id, {});
  const o = {};
  for (const op of GAMES[id].options) o[op.key] = op.key in saved ? saved[op.key] : op.def;
  return o;
}
function chips(el, options, current, onPick) {
  el.innerHTML = '';
  options.forEach(([label, v]) => {
    const b = document.createElement('button'); b.className = 'chip'; b.textContent = label;
    b.setAttribute('aria-pressed', String(v === current));
    b.onclick = () => { onPick(v); renderSetup(); };
    el.appendChild(b);
  });
}
function renderSetup() {
  const el = $('roster'); el.innerHTML = '';
  roster.forEach(({ name }) => {
    const b = document.createElement('button'); b.className = 'chip';
    const pos = picked.indexOf(name);
    b.setAttribute('aria-pressed', String(pos >= 0));
    b.textContent = name;
    if (pos >= 0) { const o = document.createElement('span'); o.className = 'order'; o.textContent = pos + 1; b.appendChild(o); }
    b.onclick = () => { pos >= 0 ? picked.splice(pos, 1) : picked.push(name); renderSetup(); };
    el.appendChild(b);
  });
  $('roster-hint').textContent = roster.length ? 'Tap names in throwing order.' : 'No players yet. Open Manage list to add them.';
  const lastOk = lastLineup.length && lastLineup.every((n) => roster.some((r) => r.name === n));
  $('btn-last').hidden = !lastOk;
  $('btn-last').textContent = lastOk ? `Same players as last game: ${lastLineup.join(', ')}` : '';
  $('btn-clear').hidden = !picked.length;
  if (!$('manage').hidden) renderManage();

  chips($('opt-game'), GAME_ORDER.map((id) => [GAMES[id].name, id]), cfg.game, (v) => { cfg.game = v; store.set('cfg', cfg); });
  // On a phone the games are one sideways-scrolling row: keep the chosen one in view.
  const chosen = $('opt-game').querySelector('[aria-pressed="true"]');
  if (chosen && $('opt-game').scrollWidth > $('opt-game').clientWidth + 4) {
    const box = $('opt-game');
    box.scrollLeft = Math.max(0, chosen.offsetLeft - box.clientWidth / 2 + chosen.offsetWidth / 2);
  }
  const g = GAMES[cfg.game];
  $('game-rule').textContent = g.rule;
  $('rules-list').innerHTML = (RULES[cfg.game] || []).map((r) => `<li>${r}</li>`).join('');
  const opts = gameOpts(cfg.game);
  const box = $('game-opts'); box.innerHTML = '';
  for (const op of g.options) {
    const grp = document.createElement('div'); grp.className = 'opt-group';
    grp.innerHTML = `<h3>${esc(op.label)}</h3><div class="row"></div>`;
    chips(grp.querySelector('.row'), op.choices, opts[op.key], (v) => { opts[op.key] = v; store.set('opts.' + cfg.game, opts); });
    box.appendChild(grp);
  }
  chips($('opt-legs'), [['1 leg', 1], ['2 legs', 2], ['3 legs', 3], ['5 legs', 5]], cfg.legsToWin, (v) => { cfg.legsToWin = v; store.set('cfg', cfg); });
  chips($('opt-sets'), [['No sets', 1], ['2 sets', 2], ['3 sets', 3], ['5 sets', 5]], cfg.setsToWin, (v) => { cfg.setsToWin = v; store.set('cfg', cfg); });

  const need = g.minPlayers || 1, most = g.maxPlayers || Infinity;
  $('start').disabled = picked.length < need || picked.length > most;
  $('start').textContent = picked.length > most ? `${g.name} is for ${most} players`
    : picked.length < need
    ? (need > 1 ? `${g.name} needs ${need} players` : 'Start game')
    : `Start ${g.name} with ${picked.length} player${picked.length > 1 ? 's' : ''}`;
  const saved = store.get('game', null);
  $('resume').hidden = !(saved && saved.v === 2 && !saved.over && GAMES[saved.cfg.game]);
  $('api').value = apiBase();
  $('opt-voice').setAttribute('aria-pressed', String(store.get('voice', true)));
  $('opt-voice').textContent = store.get('voice', true) ? 'Score caller on' : 'Score caller off';
  $('opt-dartcalls').setAttribute('aria-pressed', String(dartCallsOn()));
  $('opt-dartcalls').textContent = dartCallsOn() ? 'Call each dart: on' : 'Call each dart: off';
  $('opt-dartcalls').disabled = !store.get('voice', true);
  $('opt-finishcalls').setAttribute('aria-pressed', String(finishCallsOn()));
  $('opt-finishcalls').textContent = finishCallsOn() ? 'Call the finish: on' : 'Call the finish: off';
  $('opt-tips').setAttribute('aria-pressed', String(tipsOn()));
  $('opt-tips').textContent = tipsOn() ? 'Throw tips on' : 'Throw tips off';
  $('opt-awake').setAttribute('aria-pressed', String(awakeOn()));
  $('opt-awake').textContent = awakeOn() ? 'Keep screen on' : 'Screen may sleep';
}
$('add-form').onsubmit = (e) => {
  e.preventDefault();
  const name = $('add-name').value.trim();
  if (name && !roster.some((r) => r.name === name)) { roster.push({ name, games: 0 }); picked.push(name); savePlayers(); }
  $('add-name').value = ''; renderSetup();
};
$('rules').open = !!store.get('rulesOpen', false);
$('rules').ontoggle = () => store.set('rulesOpen', $('rules').open);
$('btn-last').onclick = () => { picked = lastLineup.slice(); renderSetup(); };
$('btn-clear').onclick = () => { picked = []; renderSetup(); };
$('btn-manage').onclick = () => {
  const open = $('manage').hidden;
  $('manage').hidden = !open;
  $('btn-manage').setAttribute('aria-expanded', String(open));
  $('btn-manage').textContent = open ? 'Done' : 'Manage list';
  renderSetup();
  if (open && !roster.length) $('add-name').focus();
};
$('api-form').onsubmit = (e) => {
  e.preventDefault();
  const v = $('api').value.trim().replace(/\/$/, '');
  // The Pi's own address with the board program's port is the default: don't pin it, so switching
  // between Autodarts and Tikka Vision on the Pi needs nothing on this device.
  if (!v || new RegExp('^http://' + location.hostname.replace(/[.]/g, '\\.') + ':318[01]$').test(v)) store.del('api'); else store.set('api', v);
  $('api').value = apiBase();
  smsg('Board address saved.'); poll();
};
// Tikka Vision only: calibrate the cameras and settle the board's turn from one dart at the 20.
async function visionCall(action) {
  smsg('Working…');
  try {
    // Through the Pi's CGI: it switches the LEDs on for a calibration and off again afterwards.
    const res = await fetch('cgi-bin/board', { method: 'POST', body: action });
    const d = await res.json();
    if (d.ok) smsg(d.needs_orientation ? 'Calibrated. Now throw ONE dart at the 20 and press Set orientation.' : action === 'orient' ? 'Orientation set.' : 'Cameras calibrated.');
    else smsg(d.message || (d.cameras && Object.values(d.cameras).map((c) => c.message).filter((m) => m && m !== 'ok')[0]) || 'Not done.', true);
  } catch { smsg('The board service could not be reached.', true); }
}
$('cal-auto').onclick = () => visionCall('autocal');
$('cal-orient').onclick = () => visionCall('orient');
$('opt-voice').onclick = () => { store.set('voice', !store.get('voice', true)); renderSetup(); if (store.get('voice', true)) speak('Score caller on', true); };
$('opt-voice-test').onclick = () => speak('One hundred and eighty!', true);
$('opt-dartcalls').onclick = () => { store.set('dartCalls', !dartCallsOn()); renderSetup(); if (dartCallsOn()) speak('Treble 20', true); };
$('opt-finishcalls').onclick = () => { store.set('finishCalls', !finishCallsOn()); renderSetup(); if (finishCallsOn()) speak('You require 40', true); };
$('opt-tips').onclick = () => { store.set('tips', !tipsOn()); renderSetup(); };
$('opt-awake').onclick = () => { store.set('awake', !awakeOn()); renderSetup(); };
$('start').onclick = async () => {
  screenOn(true);
  if (!(await takeBoard())) { screenOn(false); return; }
  G = newGame({ game: cfg.game, opts: gameOpts(cfg.game), legsToWin: cfg.legsToWin, setsToWin: cfg.setsToWin, players: picked.slice() });
  lastLineup = picked.slice();
  roster.forEach((r) => { if (picked.includes(r.name)) r.games = (r.games || 0) + 1; });
  savePlayers();
  ignoreUntilClear = api.darts.length > 0; saidForVisit = false;
  startBoard().then(resetBoard); pingLights();
  save(); toGame();
};
$('resume').onclick = async () => { screenOn(true); if (!(await takeBoard())) { screenOn(false); return; } pingLights(); startBoard(); G = store.get('game', null); ignoreUntilClear = api.darts.length > 0; toGame(); };
$('btn-undo').onclick = undoOwned;
// Undo after the match ended reopens the game, so the board must be taken back first.
async function undoOwned() { if (G && G.over && !(await takeBoard())) return; undo(); }
// Asks the board service to reset (clears the current throws). Best effort: older or newer
// board versions may use a different endpoint; the scoreboard works without it.
// Starts the board's detection. Autodarts stays stopped until something starts it (autodarts.io
// does this for its own games) and stops again after its standby time without throws.
let lastStartTry = 0;
async function startBoard() {
  lastStartTry = Date.now();
  try {
    if (viaPi()) await fetch('cgi-bin/board', { method: 'POST', body: 'start' });
    else await fetch(apiBase() + '/api/start', { method: 'PUT' });
  } catch {}
}
async function resetBoard() {
  try { await fetch(viaPi() ? 'cgi-bin/board' : apiBase() + '/api/reset', { method: 'POST' }); } catch {}
}
$('btn-reset').onclick = resetBoard;
$('btn-next').onclick = () => commitVisit();
$('btn-menu').onclick = () => { if (G.over || confirm('End this game? You can resume it from the setup screen.')) toSetup(); };
$('conn-text').ondblclick = () => $('raw').classList.toggle('on');

function save() { if (G) store.set('game', G); }
// Tells the Pi a game has started, so the lights come on even before the first dart. A plain request: Safari
// handles "keepalive" requests on a separate path that may not carry the sign-in. Starting the board through the
// Pi (cgi-bin/board) signals the lights as well, so this is the second way, not the only one.
function pingLights() { try { fetch('cgi-bin/lights', { method: 'POST', body: 'start' }).catch(() => {}); } catch {} }
// Lights (LEDs): Automatic -> On -> Off. Shown when the lights service is installed.
const LIGHT_LABEL = { auto: 'Lights: auto', on: 'Lights: on', off: 'Lights: off' };
let lightsMode = null;
function showLights() {
  for (const id of ['btn-lights', 'opt-lights']) {
    const b = $(id);
    b.hidden = !lightsMode;
    if (lightsMode) { b.textContent = LIGHT_LABEL[lightsMode] || 'Lights'; b.setAttribute('aria-pressed', String(lightsMode !== 'off')); }
  }
}
async function lightsCall(mode) {
  try {
    const res = await fetch('cgi-bin/lights', mode ? { method: 'POST', body: mode } : { cache: 'no-store' });
    if (!res.ok) return;
    const d = await res.json();
    if (d.ok === false && d.error) alert(d.error);
    if (d.installed !== undefined) lightsMode = d.installed ? (d.mode || 'auto') : null;
    showLights();
  } catch {}
}
function nextLights() { lightsCall({ auto: 'on', on: 'off', off: 'auto' }[lightsMode] || 'auto'); }
$('btn-lights').onclick = nextLights;
$('opt-lights').onclick = nextLights;
function toGame() { $('setup').classList.remove('on'); $('game').classList.add('on'); render(); screenOn(true); }
function toSetup(viewerOnly) {
  if (updateReady) setTimeout(() => location.reload(), 300);   // a newer version was installed meanwhile
  screenOn(false);
  $('game').classList.remove('on'); $('passive').classList.remove('on'); $('setup').classList.add('on'); renderSetup();
  if (viewerOnly) return;   // a display leaving passive mode must not clear the game it was showing
  if (lockedByOther()) return;
  try {
    fetch('cgi-bin/game', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"none":true}' })
      .catch(() => {}).finally(releaseBoard);
  } catch { releaseBoard(); }
  lastPublished = '';
}

renderSetup();
// PUBLIC_VIEW is set only in the read-only public copy (public-view-install.sh): passive display, no controls.
if (window.PUBLIC_VIEW) showPassive('remote');
else (async () => {
  await lockWatch();   // one request first: if it needs a sign-in, nothing else is sent meanwhile
  if (signingIn) return;
  loadPlayers();
  if (location.hash === '#passive') showPassive('remote');
  setInterval(lockWatch, 3000);
  lightsCall();
  setInterval(() => lightsCall(), 30000);
  poll();
  setInterval(poll, 300);
})();
setInterval(renderConn, 1000);
</script>
</body>
</html>
EOF_OCHE
# Served by cgi-bin/index.cgi with "Cache-Control: no-cache", so browsers always get the current
# version (a plain file is cached for hours). The build stamp lets open pages notice an update.
BUILD=$(md5sum "$DIR/app.html" | cut -c1-12)
sed -i "s/__SCOREBOARD_BUILD__/$BUILD/" "$DIR/app.html"
echo "$BUILD" > "$DIR/build"
rm -f "$DIR/index.html"
mkdir -p "$DIR/cgi-bin"
cat > "$DIR/cgi-bin/index.cgi" <<'EOF_INDEX'
#!/bin/sh
# The page. When a secure address is set (Settings), visitors on the home network are sent there;
# requests through Tailscale arrive from the Pi itself and get the page. "?local" stays here, for
# when the internet is down.
SECURE=$(sed -n 's/^SECURE_URL=//p' /data/scoreboard/data/settings 2>/dev/null | head -1)
case "$REMOTE_ADDR" in *127.0.0.1*|*'::1'*) SECURE= ;; esac
case "&$QUERY_STRING&" in *'&local&'*|*'&local='*) SECURE= ;; esac
if [ -n "$SECURE" ]; then
  # Go to the secure address only if it answers (it needs the internet and Tailscale); otherwise stay
  # here with ?local, so the scoreboard always opens.
  printf 'Content-Type: text/html; charset=utf-8\r\nCache-Control: no-cache\r\n\r\n'
  cat <<EOF_GO
<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Darts</title><body style="margin:0;padding:32px;background:#0c0a09;color:#a39890;font:18px system-ui,sans-serif">Connecting…
<script>
var secure = '$SECURE', hash = location.hash, gone = false;
function go(ok) { if (gone) return; gone = true; location.replace(ok ? secure + hash : location.pathname + '?local' + hash); }
setTimeout(function () { go(false); }, 4000);
fetch(secure + 'build?' + Date.now(), { mode: 'no-cors', cache: 'no-store' }).then(function () { go(true); }, function () { go(false); });
</script>
EOF_GO
  exit 0
fi
printf 'Content-Type: text/html; charset=utf-8\r\nCache-Control: no-cache\r\n\r\n'
cat ../app.html
EOF_INDEX
# Sign-in page: the browser asks for name and password here (it is under /cgi-bin), then goes back.
cat > "$DIR/cgi-bin/login" <<'EOF_LOGIN'
#!/bin/sh
printf 'Content-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\n\r\n'
echo '<!doctype html><meta charset="utf-8"><title>Signed in</title><script>location.replace("../" + (sessionStorage.getItem("afterLogin") || ""))</script><a href="../">Continue</a>'
EOF_LOGIN
chmod 755 "$DIR" "$DIR/cgi-bin" "$DIR/cgi-bin/index.cgi" "$DIR/cgi-bin/login"; chmod 644 "$DIR/app.html" "$DIR/build"

echo "== Shared player list"
mkdir -p "$DIR/cgi-bin" "$DIR/data"
cat > "$DIR/cgi-bin/players" <<'EOF_CGI'
#!/bin/sh
# Shared player list for Tikka. GET returns it, POST replaces it.
F=/data/scoreboard/data/players.json
. /data/scoreboard-auth/lock.sh
csrf_check
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
if [ "$REQUEST_METHOD" = POST ]; then
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  if [ "$len" -gt 0 ] && [ "$len" -le 65536 ]; then
    body=$(head -c "$len")
    case "$body" in
      '{'*'}') printf '%s' "$body" > "$F.tmp" && mv "$F.tmp" "$F" && echo '{"ok":true}' && exit 0 ;;
    esac
  fi
  echo '{"ok":false}'
  exit 0
fi
if [ -f "$F" ]; then cat "$F"; else echo '{"players":[],"last":[]}'; fi
EOF_CGI
cat > "$DIR/cgi-bin/lights" <<'EOF_LIGHTS'
#!/bin/sh
# Lights (LEDs) on the Wi-Fi plug. GET: {"installed","mode"}. POST "auto" | "on" | "off" sets the mode
# (the player holding the board, or anyone while no game is locked); any other POST is a game-start
# ping, which the lights service treats as activity; "end" switches the lights off right away.
. /data/scoreboard-auth/lock.sh
csrf_check
M=/data/lights/mode
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
if [ "$REQUEST_METHOD" = POST ]; then
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  [ "$len" -le 8 ] || len=8
  act=$(head -c "$len")
  case "$act" in
    auto|on|off)
      [ -w "$M" ] || { echo '{"ok":false,"error":"Lights are not installed."}'; exit 0; }
      lock_mutex
      may_write || { echo '{"ok":false,"error":"Someone else is playing."}'; exit 0; }
      echo "$act" > "$M" ;;
    end)   # the session is over: the lights service switches the plug off right away
      lock_mutex
      may_write || { echo '{"ok":false,"error":"Someone else is playing."}'; exit 0; }
      [ -d /data/lights ] && touch /data/lights/end 2>/dev/null ;;
    *) touch /data/lights/ping 2>/dev/null ;;
  esac
fi
if [ -w "$M" ]; then printf '{"ok":true,"installed":true,"mode":"%s"}\n' "$(cat "$M" 2>/dev/null || echo auto)"
else echo '{"ok":true,"installed":false}'; fi
EOF_LIGHTS
cat > "$DIR/cgi-bin/game" <<'EOF_GAME'
#!/bin/sh
# Live view of the running game for the passive display. The scoring device POSTs it, displays GET it.
# Kept in RAM (/tmp): it is only needed while a game is on. Only the user holding the game lock may post.
F=/tmp/scoreboard-game.json
. /data/scoreboard-auth/lock.sh
csrf_check
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
if [ "$REQUEST_METHOD" = POST ]; then
  lock_mutex
  may_write || { echo '{"ok":false,"locked":true}'; exit 0; }
  touch "$SEEN"
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  if [ "$len" -gt 0 ] && [ "$len" -le 131072 ]; then
    body=$(head -c "$len")
    case "$body" in
      '{'*'}') printf '%s' "$body" > "$F.tmp" && mv "$F.tmp" "$F" && echo '{"ok":true}' && exit 0 ;;
    esac
  fi
  echo '{"ok":false}'
  exit 0
fi
if [ -f "$F" ]; then cat "$F"; else echo '{"none":true}'; fi
EOF_GAME
cat > "$DIR/cgi-bin/board" <<'EOF_BOARD'
#!/bin/sh
# Board access for pages opened over HTTPS (the internet link): state (GET); POST "start" starts
# the board, "stop" stops it, "autocal" and "orient" calibrate the Tikka Vision cameras, any other POST resets it.
# They are allowed only for the game lock holder. The board program is Autodarts (port 3180) or Tikka Vision
# (3181), whichever "board-engine" last switched to.
. /data/scoreboard-auth/lock.sh
csrf_check
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
if [ "$REQUEST_METHOD" = POST ]; then
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  [ "$len" -le 16 ] || len=16
  act=$(head -c "$len")
  lock_mutex
  may_write || { echo '{"ok":false,"locked":true}'; exit 0; }
  flock -u 9      # a calibration takes seconds: do not hold up the other pages' lock checks meanwhile
  case "$act" in
    start|stop)
      # A game took the board: count it as activity for the lights here on the Pi, so the LEDs come on
      # whatever the browser does with its own lights ping (Safari on iPhone may not deliver it).
      [ "$act" = start ] && touch /data/lights/ping 2>/dev/null
      # The board API starts and stops on PUT, which busybox wget can't send.
      printf 'PUT /api/%s HTTP/1.0\r\nHost: 127.0.0.1\r\nContent-Length: 0\r\n\r\n' "$act" | nc -w 5 127.0.0.1 "$BOARD_PORT" >/dev/null 2>&1 ;;
    autocal|orient)
      [ "$BOARD_ENGINE" = tikka-vision ] || { echo '{"ok":false,"message":"Only Tikka Vision calibrates itself."}'; exit 0; }
      [ -z "$ME" ] || is_admin || { echo '{"ok":false,"message":"Only admins can calibrate the cameras."}'; exit 0; }
      case "$act" in autocal) path=auto ;; *) path="orient?number=20" ;; esac
      M=/data/lights/mode
      if [ "$act" = autocal ] && [ -w "$M" ]; then      # calibration needs the board lit: LEDs on, 5 s to settle
        prev=$(cat "$M" 2>/dev/null)
        case "$prev" in auto|off) ;; *) prev=auto ;; esac        # a forced "on" is not put back: LEDs off afterwards
        echo on > "$M"; sleep 5
      fi
      if out=$(wget -qO- -T 120 --post-data= "http://127.0.0.1:$BOARD_PORT/api/config/calibration/$path" 2>/dev/null); then
        :
      else
        out='{"ok":false,"message":"The camera service refused it (is the board empty and lit? was a dart thrown at the 20?)."}'
      fi
      if [ "$act" = autocal ] && [ -n "$prev" ]; then   # back to the old mode, LEDs off right away
        echo "$prev" > "$M"; touch /data/lights/end 2>/dev/null
      fi
      echo "$out"
      exit 0 ;;
    *) wget -qO /dev/null -T 3 --post-data= "http://127.0.0.1:$BOARD_PORT/api/reset" 2>/dev/null ;;
  esac
  echo '{"ok":true}'
  exit 0
fi
wget -qO- -T 3 "http://127.0.0.1:$BOARD_PORT/api/state" 2>/dev/null || echo '{}'
EOF_BOARD
cat > "$DIR/cgi-bin/boardimg" <<'EOF_IMG'
#!/bin/sh
# The camera picture a recent throw was found in, with the detected tip marked (Tikka Vision only):
# boardimg?throw=ID&cam=NAME. Tikka Vision listens only inside the Pi; this hands the picture to signed-in users.
. /data/scoreboard-auth/lock.sh
id=$(printf '%s' "$QUERY_STRING" | sed -n 's/^\(.*&\)\{0,1\}throw=\([0-9]\{1,9\}\)\(&.*\)\{0,1\}$/\2/p')
cam=$(printf '%s' "$QUERY_STRING" | sed -n 's/^\(.*&\)\{0,1\}cam=\([A-Za-z0-9_-]\{1,16\}\)\(&.*\)\{0,1\}$/\2/p')
T=/tmp/boardimg.$$
if [ "$BOARD_ENGINE" = tikka-vision ] && [ -n "$id" ] && [ -n "$cam" ] && \
   wget -qO "$T" -T 5 "http://127.0.0.1:$BOARD_PORT/api/img/throw/$id/$cam" 2>/dev/null && [ -s "$T" ]; then
  printf 'Content-Type: image/jpeg\r\nCache-Control: private, max-age=600\r\n\r\n'
  cat "$T"
else
  printf 'Status: 404 Not Found\r\nContent-Type: text/plain\r\n\r\nno picture\n'
fi
rm -f "$T"
EOF_IMG
cat > "$DIR/cgi-bin/settings" <<'EOF_SET'
#!/bin/sh
# Settings page back end: users, lights and the game lock. GET returns them, POST changes one thing.
# Admins only. While no users exist it works only from the home network, never through the internet link.
. /data/scoreboard-auth/lock.sh
AUTH=/data/scoreboard-auth; CONF=$AUTH/httpd.conf; ADM=$AUTH/admins
SET=/data/scoreboard/data/settings
csrf_check
LPY=/data/lights/venv/bin/python; LCONF=/data/lights/config.json; LMODE=/data/lights/mode
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
fail() { printf '{"ok":false,"error":"%s"}\n' "$1"; exit 0; }
users() { sed -n 's#^/cgi-bin:\([^:]*\):.*#\1#p' "$CONF"; }
isuser() { users | grep -qxF "$1"; }
isadmin() { grep -qxF "$1" "$ADM" 2>/dev/null; }
dropline() { awk -F: -v n="$1" '!($1 == "/cgi-bin" && $2 == n)' "$CONF"; }
nusers=$(users | grep -c .)
if [ "$nusers" -gt 0 ]; then
  is_admin || fail "Only admins can change settings."
else
  case "$REMOTE_ADDR" in *127.0.0.1*|*'::1'*) fail "Add the first user from the home network." ;; esac
fi
reload() { pkill -HUP -f "httpd -f -p [0-9]* -h /data/scoreboard -c" 2>/dev/null; }
set_file() { cat > /tmp/sb-set.$$ && cat /tmp/sb-set.$$ > "$1"; rm -f /tmp/sb-set.$$; }
set_setting() { { grep -v "^$1=" "$SET" 2>/dev/null; [ -n "$2" ] && echo "$1=$2"; } | set_file "$SET"; }

if [ "$REQUEST_METHOD" = POST ]; then
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  [ "$len" -le 4096 ] || fail "Too much data."
  body=$(head -c "$len")
  get() { v=$(printf '%s' "$body" | tr '&' '\n' | sed -n "s/^$1=//p" | head -1); [ -n "$v" ] && httpd -d "$v"; }
  lock_mutex
  name=$(get name)
  # Names are matched as plain text below, never as patterns.
  [ -z "$name" ] || echo "$name" | grep -qE '^[A-Za-z0-9_.-]{1,24}$' || fail "Name: 1-24 letters, digits, _ . or -"
  case "$(get action)" in
    user_add|user_pw)
      act=$(get action); pw=$(get password)
      echo "$name" | grep -qE '^[A-Za-z0-9_.-]{1,24}$' || fail "Name: 1-24 letters, digits, _ . or -"
      [ ${#pw} -ge 6 ] || fail "Password: at least 6 characters."
      case "$pw" in *:*) fail "A password can't contain a colon." ;; esac
      if isuser "$name"; then [ "$act" = user_add ] && fail "$name already exists."
      else [ "$act" = user_pw ] && fail "No user $name."; fi
      h=$(httpd -m "$pw")
      { dropline "$name"; echo "/cgi-bin:$name:$h"; } | set_file "$CONF"
      if [ "$act" = user_add ] && { [ "$nusers" -eq 0 ] || [ "$(get admin)" = 1 ]; }; then
        isadmin "$name" || echo "$name" >> "$ADM"
      fi
      reload ;;
    user_del)
      isuser "$name" || fail "No user $name."
      [ "$name" = "$ME" ] && fail "You can't remove yourself."
      isadmin "$name" && [ "$(grep -c . "$ADM")" -le 1 ] && fail "Keep at least one admin."
      dropline "$name" | set_file "$CONF"
      grep -vxF "$name" "$ADM" | set_file "$ADM"
      reload ;;
    user_admin)
      isuser "$name" || fail "No user $name."
      if [ "$(get on)" = 1 ]; then isadmin "$name" || echo "$name" >> "$ADM"
      else
        [ "$name" = "$ME" ] && fail "You can't remove your own admin rights."
        isadmin "$name" && [ "$(grep -c . "$ADM")" -le 1 ] && fail "Keep at least one admin."
        grep -vxF "$name" "$ADM" | set_file "$ADM"
      fi ;;
    lights_mode)
      [ -w "$LMODE" ] || fail "Lights are not installed."
      case "$(get mode)" in auto|on|off) get mode > "$LMODE" ;; *) fail "Unknown mode." ;; esac ;;
    lights_save)
      [ -x "$LPY" ] || fail "Lights are not installed."
      err=$(L_ID=$(get device_id) L_IP=$(get ip) L_KEY=$(get local_key) L_VER=$(get version) \
            L_IDLE=$(get idle_minutes) L_NOSCORE=$(get no_score_minutes) "$LPY" - <<'PY'
import json, os, re, sys
p = "/data/lights/config.json"
try:
    c = json.load(open(p))
except Exception:
    c = {"api": "http://127.0.0.1:3180/api/state"}
e = os.environ
def bad(m):
    print(m); sys.exit(1)
did, ip, key, ver = e["L_ID"].strip(), e["L_IP"].strip(), e["L_KEY"], e["L_VER"].strip()
if not re.fullmatch(r"[A-Za-z0-9]{10,40}", did): bad("The device ID looks wrong.")
if not re.fullmatch(r"(\d{1,3}\.){3}\d{1,3}", ip) or any(int(x) > 255 for x in ip.split(".")): bad("The IP address looks wrong.")
if key and len(key) != 16: bad("The local key must be 16 characters.")
if not key and not c.get("local_key"): bad("Enter the local key.")
if ver not in ("3.1", "3.2", "3.3", "3.4", "3.5"): bad("Unknown protocol version.")
mins = []
for v in (e["L_IDLE"], e["L_NOSCORE"]):
    if not re.fullmatch(r"\d{1,3}", v.strip()) or not 1 <= int(v) <= 240: bad("Minutes must be 1 to 240.")
    mins.append(int(v))
c.update(device_id=did, ip=ip, version=float(ver), idle_minutes=mins[0], no_score_minutes=mins[1])
if key:
    c["local_key"] = key
open(p, "w").write(json.dumps(c, indent=2) + "\n")
PY
) || fail "$err" ;;
    lock_hours)
      h=$(get hours)
      case "$h" in ''|*[!0-9]*) fail "Hours must be 1 to 48." ;; esac
      [ "$h" -ge 1 ] && [ "$h" -le 48 ] || fail "Hours must be 1 to 48."
      set_setting LOCK_HOURS "$h" ;;
    secure_url)
      u=$(get url)
      if [ -n "$u" ]; then
        printf '%s' "$u" | grep -qE '^https://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._~/-]*)?$' || fail "Use an https:// address, e.g. https://name.tailnet.ts.net/play/"
      fi
      set_setting SECURE_URL "$u" ;;
    *) fail "Unknown action." ;;
  esac
fi

# current settings
printf '{"ok":true,"me":"%s","users":[' "$ME"
sep=
for u in $(users); do
  a=false; isadmin "$u" && a=true
  printf '%s{"name":"%s","admin":%s}' "$sep" "$u" "$a"; sep=,
done
lights='{"installed":false}'
if [ -x "$LPY" ]; then
  lights=$("$LPY" - <<'PY'
import json
try:
    c = json.load(open("/data/lights/config.json"))
except Exception:
    c = {}
try:
    mode = open("/data/lights/mode").read().strip() or "auto"
except OSError:
    mode = "auto"
print(json.dumps({"installed": True, "device_id": c.get("device_id", ""), "ip": c.get("ip", ""),
                  "version": str(c.get("version", 3.3)), "idle_minutes": c.get("idle_minutes", 10),
                  "no_score_minutes": c.get("no_score_minutes", 15), "key_set": bool(c.get("local_key")), "mode": mode}))
PY
) || lights='{"installed":false}'
fi
hours=$(sed -n 's/^LOCK_HOURS=\([0-9]\{1,2\}\)$/\1/p' "$SET" 2>/dev/null)
secure=$(sed -n 's/^SECURE_URL=//p' "$SET" 2>/dev/null | head -1)
printf '],"lights":%s,"lock_hours":%s,"secure_url":"%s"}\n' "$lights" "${hours:-3}" "$secure"
EOF_SET
cat > "$DIR/cgi-bin/lock" <<'EOF_LOCK'
#!/bin/sh
# Game lock. GET: who I am and who holds the board. POST body: acquire | release | force (admins).
. /data/scoreboard-auth/lock.sh
csrf_check
printf 'Content-Type: application/json\r\nCache-Control: no-store\r\n\r\n'
ok=true
if [ "$REQUEST_METHOD" = POST ]; then
  len=${CONTENT_LENGTH:-0}
  case "$len" in ''|*[!0-9]*) len=0 ;; esac
  [ "$len" -le 16 ] || len=16
  act=$(head -c "$len")
  lock_mutex
  o=$(lock_owner)
  case "$act" in
    acquire)
      if [ -z "$o" ] || [ "$o" = "$ME" ]; then
        [ -n "$ME" ] && echo "$(date +%s) $ME" > "$LOCK"
        touch "$SEEN"
      else ok=false; fi ;;
    release) if [ -z "$o" ] || [ "$o" = "$ME" ]; then rm -f "$LOCK"; else ok=false; fi ;;
    force) if is_admin; then rm -f "$LOCK"; else ok=false; fi ;;
    *) ok=false ;;
  esac
fi
o=$(lock_owner)
admin=false; is_admin && admin=true
printf '{"ok":%s,"me":"%s","owner":"%s","admin":%s,"engine":"%s","port":%s}\n' "$ok" "$ME" "$o" "$admin" "$BOARD_ENGINE" "$BOARD_PORT"
EOF_LOCK
chmod 755 "$DIR/cgi-bin" "$DIR/cgi-bin/players" "$DIR/cgi-bin/lights" "$DIR/cgi-bin/game" "$DIR/cgi-bin/board" "$DIR/cgi-bin/lock" "$DIR/cgi-bin/settings" "$DIR/cgi-bin/boardimg"
[ -f "$DIR/data/players.json" ] || echo '{"players":[],"last":[]}' > "$DIR/data/players.json"
chown -R nobody "$DIR/data"

echo "== Sign-in and game lock"
mkdir -p "$AUTH"
[ -f "$AUTH/httpd.conf" ] || : > "$AUTH/httpd.conf"
# Sign-in covers /cgi-bin (all data and actions). The page itself holds no secrets, so it can send
# home-network visitors to the HTTPS address before any password is typed. Older installs used "/".
sed -i 's#^/:#/cgi-bin:#' "$AUTH/httpd.conf"
[ -f "$AUTH/admins" ] || : > "$AUTH/admins"
cat > "$AUTH/lock.sh" <<'EOF_LIB'
# Sourced by the scoreboard CGIs. The game lock is one line "EPOCH USER" in $LOCK.
# A lock is dropped when its owner has shown no activity (game posts) for LOCK_HOURS.
LOCK=/data/scoreboard/data/lock
SEEN=/tmp/scoreboard-lock-seen
LOCK_HOURS=$(sed -n 's/^LOCK_HOURS=\([0-9]\{1,2\}\)$/\1/p' /data/scoreboard/data/settings 2>/dev/null)
[ -n "$LOCK_HOURS" ] && [ "$LOCK_HOURS" -ge 1 ] || LOCK_HOURS=3
BOARD_ENGINE=$(sed -n 's/^BOARD_ENGINE=\(autodarts\|tikka-vision\)$/\1/p' /data/scoreboard/data/settings 2>/dev/null | head -1)
BOARD_PORT=$(sed -n 's/^BOARD_PORT=\([0-9]\{3,5\}\)$/\1/p' /data/scoreboard/data/settings 2>/dev/null | head -1)
[ -n "$BOARD_ENGINE" ] || BOARD_ENGINE=autodarts
[ -n "$BOARD_PORT" ] || BOARD_PORT=3180
ME=${REMOTE_USER:-}
lock_mutex() { exec 9>/tmp/scoreboard-lock.mutex; flock 9; }
lock_owner() {   # prints the user holding a live lock, or nothing
  [ -s "$LOCK" ] || return 0
  read -r t u < "$LOCK"
  case "$t" in ''|*[!0-9]*) rm -f "$LOCK"; return 0 ;; esac
  last=$t
  if [ -f "$SEEN" ]; then s=$(date -r "$SEEN" +%s 2>/dev/null); [ -n "$s" ] && [ "$s" -gt "$last" ] && last=$s; fi
  if [ $(( $(date +%s) - last )) -gt $(( LOCK_HOURS * 3600 )) ]; then rm -f "$LOCK"; return 0; fi
  printf '%s' "$u"
}
# Browsers resend cached Basic-auth credentials on cross-site requests, so a POST from another site
# could act as the signed-in user. Refuse any POST the browser says is not from this page.
csrf_check() {
  [ "$REQUEST_METHOD" = POST ] || return 0
  if [ -n "$HTTP_SEC_FETCH_SITE" ]; then
    case "$HTTP_SEC_FETCH_SITE" in same-origin|none) return 0 ;; esac
  elif [ -z "$HTTP_ORIGIN" ]; then return 0   # not a browser (curl, scripts)
  else case "$HTTP_ORIGIN" in *://"$HTTP_HOST") return 0 ;; esac
  fi
  printf 'Status: 403 Forbidden\r\nContent-Type: application/json\r\nCache-Control: no-store\r\n\r\n{"ok":false,"error":"Cross-site request refused."}\n'
  exit 0
}
may_write() { o=$(lock_owner); [ -z "$o" ] || [ "$o" = "$ME" ]; }
is_admin() { [ -n "$ME" ] && grep -qx "$ME" /data/scoreboard-auth/admins 2>/dev/null; }
EOF_LIB
chown -R root:nobody "$AUTH"; chmod 750 "$AUTH"; chmod 640 "$AUTH/lock.sh"
chown nobody "$AUTH/httpd.conf" "$AUTH/admins"; chmod 600 "$AUTH/httpd.conf" "$AUTH/admins"   # edited by the Settings page

cat > /usr/local/sbin/scoreboard-user <<'EOF_USER'
#!/bin/sh
# scoreboard-user: manage sign-in for the Tikka scoreboard.
#   scoreboard-user add NAME      add a user (asks for a password); the first user becomes admin
#   scoreboard-user passwd NAME   change a password
#   scoreboard-user del NAME      remove a user
#   scoreboard-user admin NAME    make a user admin, or remove admin if they are one
#   scoreboard-user list          list users (* = admin)
#   scoreboard-user unlock        release the game lock
AUTH=/data/scoreboard-auth
CONF=$AUTH/httpd.conf
ADM=$AUTH/admins
[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
name_ok() { echo "$1" | grep -qE '^[A-Za-z0-9_.-]{1,24}$' || { echo "Name: 1-24 letters, digits, _ . -"; exit 1; }; }
has() { grep -q "^/cgi-bin:$1:" "$CONF"; }
reload() { rc-service scoreboard restart >/dev/null 2>&1; }
ask_pw() {
  while :; do
    printf 'Password for %s: ' "$1"; stty -echo 2>/dev/null; read -r p1; stty echo 2>/dev/null; echo
    printf 'Again: ';                stty -echo 2>/dev/null; read -r p2; stty echo 2>/dev/null; echo
    [ "$p1" = "$p2" ] || { echo "Passwords differ."; continue; }
    [ ${#p1} -ge 6 ] || { echo "At least 6 characters."; continue; }
    case "$p1" in *:*) echo "No colons, please."; continue ;; esac
    break
  done
  PW=$p1
}
set_pw() {
  ask_pw "$1"
  h=$(httpd -m "$PW"); unset PW p1 p2
  grep -v "^/cgi-bin:$1:" "$CONF" > "$CONF.new"; echo "/cgi-bin:$1:$h" >> "$CONF.new"
  cat "$CONF.new" > "$CONF"; rm -f "$CONF.new"
}
case "$1" in
  add)    name_ok "$2"; has "$2" && { echo "$2 exists; use passwd."; exit 1; }
          first=; grep -q '^/cgi-bin:' "$CONF" || first=1
          set_pw "$2"; [ -n "$first" ] && { echo "$2" >> "$ADM"; echo "$2 is admin (first user)."; }
          reload; echo "Added $2." ;;
  passwd) name_ok "$2"; has "$2" || { echo "No user $2."; exit 1; }; set_pw "$2"; reload; echo "Password changed." ;;
  del)    name_ok "$2"; has "$2" || { echo "No user $2."; exit 1; }
          grep -v "^/cgi-bin:$2:" "$CONF" > "$CONF.new"; cat "$CONF.new" > "$CONF"; rm -f "$CONF.new"
          grep -vx "$2" "$ADM" > "$ADM.new"; cat "$ADM.new" > "$ADM"; rm -f "$ADM.new"
          reload; echo "Removed $2."
          grep -q '^/cgi-bin:' "$CONF" || echo "No users left: the scoreboard is open without sign-in." ;;
  admin)  name_ok "$2"; has "$2" || { echo "No user $2."; exit 1; }
          if grep -qx "$2" "$ADM"; then grep -vx "$2" "$ADM" > "$ADM.new"; cat "$ADM.new" > "$ADM"; rm -f "$ADM.new"; echo "$2 is no longer admin."
          else echo "$2" >> "$ADM"; echo "$2 is admin."; fi ;;
  list)   sed -n 's#^/cgi-bin:\([^:]*\):.*#\1#p' "$CONF" | while read -r u; do grep -qx "$u" "$ADM" && echo "* $u" || echo "  $u"; done ;;
  unlock) rm -f /data/scoreboard/data/lock; echo "Game lock released." ;;
  *)      sed -n '2,9s/^# \{0,1\}//p' "$0"; exit 1 ;;
esac
EOF_USER
chmod 755 /usr/local/sbin/scoreboard-user
lbu include /usr/local/sbin/scoreboard-user

echo "== Creating the boot service"
cat > /etc/init.d/scoreboard <<EOF
#!/sbin/openrc-run
name="scoreboard"
description="Tikka scoreboard on port $PORT"
command="$HTTPD"
command_args="-f -p $PORT -h $DIR -c $AUTH/httpd.conf -r Tikka"
command_user="nobody"
supervisor="supervise-daemon"
respawn_delay=5
respawn_max=0

depend() {
    need net localmount
}
EOF
chmod 755 /etc/init.d/scoreboard
rc-update add scoreboard default >/dev/null
lbu include /etc/init.d/scoreboard

echo "== Saving and starting"
apk cache sync >/dev/null 2>&1 || true
lbu commit -d
rc-service scoreboard restart >/dev/null 2>&1 || rc-service scoreboard start
sleep 1
# 401 counts as up: it means sign-in is on.
if wget -S -qO /dev/null "http://127.0.0.1:$PORT/" 2>&1 | grep -qE "HTTP/1.[01] (200|401)"; then
  IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
  echo
  echo "Done. Open http://${IP:-<pi-address>}:$PORT on your tablet, phone or TV."
  if grep -q '^/cgi-bin:' "$AUTH/httpd.conf"; then
    echo "Sign-in is on for: $(sed -n 's#^/cgi-bin:\([^:]*\):.*#\1#p' "$AUTH/httpd.conf" | tr '\n' ' ')"
  else
    echo "Sign-in is OFF until you add a user:  scoreboard-user add NAME"
  fi
else
  echo "The scoreboard service did not answer. Check: rc-service scoreboard status"
  exit 1
fi
