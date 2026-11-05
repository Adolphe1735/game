#!/usr/bin/env bash
# Generates all Neon Void audio assets procedurally with ffmpeg.
# Run from the repository root:  bash scripts/generate_audio.sh
set -euo pipefail
OUT="assets/audio"
mkdir -p "$OUT"

# sfx <name> <lavfi-source> <duration-seconds> <filter-chain> <volume>
sfx() {
  local name="$1" src="$2" dur="$3" chain="${4:-}" vol="${5:-0.9}"
  local af="volume=${vol}"
  if [ -n "$chain" ]; then af="${chain},volume=${vol}"; fi
  ffmpeg -y -hide_banner -loglevel error \
    -f lavfi -i "$src" -t "$dur" \
    -af "$af" -ar 44100 -ac 2 -b:a 160k "$OUT/$name.mp3"
  echo "  + $name.mp3"
}

# Pink-noise explosion bed helper
noise_src() { echo "anoisesrc=d=$1:c=pink:r=44100:a=0.6"; }

echo "Generating Neon Void audio..."

# ------------------------------------------------------------ weapon SFX
sfx shoot         "sine=f=880:d=0.16"   0.16 "aeval=val(0)*exp(-14*t),highpass=f=400" 0.50
sfx laser         "sine=f=1500:d=0.24"  0.24 "aeval=val(0)*exp(-9*t),tremolo=f=42:d=0.6,highpass=f=600" 0.45
sfx plasma        "sine=f=320:d=0.36"   0.36 "aeval=val(0)*exp(-6*t),lowpass=f=2400,aphaser=type=t" 0.55
sfx spread        "sine=f=520:d=0.22"   0.22 "aeval=val(0)*exp(-11*t),chorus=0.6:0.9:40|55:0.25|0.3:0.3|0.25" 0.45
sfx rapid         "sine=f=1100:d=0.11"  0.11 "aeval=val(0)*exp(-20*t),highpass=f=700" 0.38
sfx railgun       "sine=f=180:d=0.58"   0.58 "aeval=val(0)*exp(-4*t),lowpass=f=1800,aecho=0.7:0.6:60:0.4" 0.60
sfx reload        "sine=f=240:d=0.32"   0.32 "aeval=val(0)*exp(-8*t),asetrate=44100*1.4,aresample=44100" 0.40
sfx empty         "square=f=140:d=0.13" 0.13 "lowpass=f=900" 0.40

# ---------------------------------------------------------- impact SFX
sfx hit           "sine=f=200:d=0.20"   0.20 "aeval=val(0)*exp(-16*t),distortion=0.4" 0.50
sfx explosion     "$(noise_src 0.62)"   0.62 "lowpass=f=1800,aeval=val(0)*exp(-7*t),aecho=0.6:0.4:40:0.3" 0.80
sfx big_explosion "$(noise_src 1.45)"   1.45 "lowpass=f=1200,aeval=val(0)*exp(-3.4*t),aecho=0.8:0.6:90|140:0.4|0.3" 0.90
sfx shield_hit    "sine=f=660:d=0.27"   0.27 "aeval=val(0)*exp(-10*t),vibrato=f=8:d=0.6" 0.50

# ------------------------------------------------------------- pickups
sfx powerup     "sine=f=560:d=0.30"     0.30 "aeval=val(0)*exp(-6*t),vibrato=f=14:d=0.4" 0.55
sfx coin        "sine=f=1320:d=0.18"    0.18 "aeval=val(0)*exp(-12*t),vibrato=f=22:d=0.5" 0.50
sfx gem         "sine=f=1760:d=0.32"    0.32 "aeval=val(0)*exp(-7*t),tremolo=f=18:d=0.7,aecho=0.5:0.5:30:0.35" 0.50
sfx levelup     "sine=f=440:d=0.62"     0.62 "aeval=val(0)*exp(-3*t),vibrato=f=6:d=0.5" 0.60
sfx achievement "sine=f=990:d=0.92"     0.92 "aeval=val(0)*exp(-2.6*t),aecho=0.7:0.5:80|160:0.4|0.28" 0.55

# ------------------------------------------------------------- UI SFX
sfx ui_click  "sine=f=760:d=0.08"       0.08 "aeval=val(0)*exp(-26*t),highpass=f=500" 0.42
sfx ui_hover  "sine=f=1200:d=0.06"      0.06 "aeval=val(0)*exp(-30*t),highpass=f=800" 0.28
sfx ui_back   "sine=f=420:d=0.13"       0.13 "aeval=val(0)*exp(-16*t)" 0.40
sfx ui_error  "square=f=180:d=0.23"     0.23 "lowpass=f=700" 0.40

# ---------------------------------------------------------- game state
sfx gameover   "sine=f=300:d=1.62"      1.62 "aeval=val(0)*exp(-1.8*t),asetrate=44100*0.75,aresample=44100,aecho=0.8:0.5:120:0.35" 0.70
sfx victory    "sine=f=640:d=1.82"      1.82 "aeval=val(0)*exp(-1.6*t),tremolo=f=9:d=0.5,aecho=0.7:0.6:90|180:0.4|0.3" 0.65
sfx boss_enter "sine=f=90:d=1.85"       1.85 "aeval=val(0)*exp(-1.4*t),lowpass=f=900,aecho=0.85:0.6:150:0.4" 0.85
sfx boss_phase "sine=f=120:d=1.15"      1.15 "aeval=val(0)*exp(-2.2*t),distortion=0.25,lowpass=f=1400" 0.70
sfx warp       "sine=f=160:d=0.92"      0.92 "aeval=val(0)*exp(-2*t),asetrate=44100*1.6,aresample=44100,aphaser=type=i" 0.55

# --------------------------------------------------------- music loops
echo "Generating music loops..."
# Menu: slow evolving pad, 24s loopable
ffmpeg -y -hide_banner -loglevel error -f lavfi -i \
"sine=f=110:d=24,volume=0.50[a];sine=f=164.81:d=24,volume=0.32[b];sine=f=220:d=24,volume=0.26[c];sine=f=329.63:d=24,volume=0.18[d];sine=f=440:d=24,volume=0.12[e];[a][b][c][d][e]amix=inputs=5:normalize=0,tremolo=f=0.22:d=0.75,aecho=0.8:0.55:220|440:0.35|0.22,lowpass=f=2600,afade=t=in:st=0:d=2,afade=t=out:st=22:d=2,volume=0.55" \
  -t 24 -ar 44100 -ac 2 -b:a 128k "$OUT/music_menu.mp3"
echo "  + music_menu.mp3"

# Battle: driving bass pulse, 32s loopable
ffmpeg -y -hide_banner -loglevel error -f lavfi -i \
"sine=f=55:d=32,volume=0.55[a];sine=f=82.41:d=32,volume=0.30[b];sine=f=110:d=32,volume=0.28[c];sine=f=164.81:d=32,volume=0.12[d];[a][b][c][d]amix=inputs=4:normalize=0,tremolo=f=2.2:d=0.55,aecho=0.75:0.45:180|360:0.3|0.18,highpass=f=40,lowpass=f=3200,volume=0.50" \
  -t 32 -ar 44100 -ac 2 -b:a 128k "$OUT/music_battle.mp3"
echo "  + music_battle.mp3"

# Boss: darker, faster tension bed, 32s loopable
ffmpeg -y -hide_banner -loglevel error -f lavfi -i \
"sine=f=44:d=32,volume=0.60[a];sine=f=87.31:d=32,volume=0.30[b];sine=f=130.81:d=32,volume=0.20[c];[a][b][c]amix=inputs=3:normalize=0,tremolo=f=3.4:d=0.6,aecho=0.8:0.6:200|400:0.35|0.2,distortion=0.15,lowpass=f=2400,volume=0.55" \
  -t 32 -ar 44100 -ac 2 -b:a 128k "$OUT/music_boss.mp3"
echo "  + music_boss.mp3"

echo "Done - $(ls -1 "$OUT" | wc -l) audio files in $OUT"
du -sh "$OUT"
