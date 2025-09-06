<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>DualSmell Visualize</title>
  <style>
    :root{
      --bg:#0e1525; --card:#1a2235; --muted:#ccc; --on:#6ee7b7; --active-pad:#ffd166;
    }<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>DualSense Button Debug</title>
</head>
<body>
  <h1>Press buttons to see their index</h1>
  <pre id="out">Waiting...</pre>

  <script>
    const out = document.getElementById("out");

    function update() {
      const pads = navigator.getGamepads();
      let text = "";
      for (let i = 0; i < pads.length; i++) {
        const gp = pads[i];
        if (!gp) continue;
        text += `Gamepad ${gp.index}: ${gp.id}\n`;
        gp.buttons.forEach((b, j) => {
          if (b.pressed || b.value > 0) {
            text += `  Button ${j}: pressed=${b.pressed}, value=${b.value}\n`;
          }
        });
        text += "\n";
      }
      out.textContent = text || "No controller detected";
      requestAnimationFrame(update);
    }
    update();
  </script>
</body>
</html>

    html,body{height:100%;margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;color:#eef;background:var(--bg);display:flex;align-items:center;justify-content:center}
    .wrap{width:92vw;max-width:1000px;text-align:center}
    svg{width:100%;height:auto;display:block}
    .button{fill:#444;transition:fill .08s,opacity .08s}
    .button.active{fill:var(--on);opacity:1}
    .stick{fill:#222;transition:cx .06s,cy .06s,fill .06s}
    .stick.active{fill:var(--on)}
    .trigger-fill{fill:var(--on);transition:width .06s}
    .touch{fill:var(--on);opacity:.9;pointer-events:none;transition:cx .04s,cy .04s}
    #touchpad{fill:#333;stroke:#222;stroke-width:2}
    #touchpad.active{stroke:var(--active-pad);stroke-width:3;fill:rgba(255,209,102,0.04)}
    .label{font-size:14px;color:var(--muted);margin:8px 0}
  </style>
</head>
<body>
  <div class="wrap">
    <h2 style="margin:8px 0">DualSmell Visualizer</h2>


    <svg viewBox="0 0 1200 600" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet">
      <!-- controller background -->
      <rect x="50" y="100" width="1100" height="400" rx="100" fill="var(--card)"/>

      <!-- left stick -->
      <circle id="lsBase" cx="350" cy="300" r="60" fill="#333"/>
      <circle id="ls" class="stick" cx="350" cy="300" r="35"/>
      <circle id="l3" class="button" cx="350" cy="300" r="25"/>

      <!-- right stick -->
      <circle id="rsBase" cx="850" cy="300" r="60" fill="#333"/>
      <circle id="rs" class="stick" cx="850" cy="300" r="35"/>
      <circle id="r3" class="button" cx="850" cy="300" r="25"/>

      <!-- dpad -->
      <rect id="d_up" class="button" x="200" y="220" width="40" height="40" rx="6"/>
      <rect id="d_down" class="button" x="200" y="300" width="40" height="40" rx="6"/>
      <rect id="d_left" class="button" x="160" y="260" width="40" height="40" rx="6"/>
      <rect id="d_right" class="button" x="240" y="260" width="40" height="40" rx="6"/>

      <!-- face -->
      <circle id="btn_triangle" class="button" cx="1000" cy="220" r="22"/>
      <circle id="btn_circle" class="button" cx="1040" cy="260" r="22"/>
      <circle id="btn_cross" class="button" cx="1000" cy="300" r="22"/>
      <circle id="btn_square" class="button" cx="960" cy="260" r="22"/>

      <!-- bumpers -->
      <rect id="l1" class="button" x="190" y="150" width="110" height="18" rx="6"/>
      <rect id="r1" class="button" x="900" y="150" width="110" height="18" rx="6"/>

      <!-- triggers -->
      <rect x="200" y="80" width="200" height="20" rx="6" fill="#333"/>
      <rect id="l2fill" y="80" x="200" width="0" height="20" class="trigger-fill"/>
      <rect x="800" y="80" width="200" height="20" rx="6" fill="#333"/>
      <rect id="r2fill" y="80" x="800" width="0" height="20" class="trigger-fill"/>

      <!-- options/share/ps -->
      <rect id="share" class="button" x="460" y="200" width="30" height="20" rx="4"/>
      <rect id="options" class="button" x="710" y="200" width="30" height="20" rx="4"/>
      <circle id="ps" class="button" cx="600" cy="250" r="18"/>

      <!-- touchpad (visual) -->
      <!-- change these to move/resize touchpad if you like -->
      <rect id="touchpad" x="500" y="120" width="200" height="80" rx="12"/>
      <rect id="touchClickOverlay" x="500" y="120" width="200" height="80" rx="12" fill="transparent" />
      <circle id="touchCursor" class="touch" cx="600" cy="160" r="0"/>

    </svg>

    <div class="label" id="status">Status: waiting for controller...</div>
  </div>

  <script>
    // elements
    const statusEl = document.getElementById('status');
    const lsEl = document.getElementById('ls'), rsEl = document.getElementById('rs');
    const l2fill = document.getElementById('l2fill'), r2fill = document.getElementById('r2fill');
    const touchCursor = document.getElementById('touchCursor');
    const touchpadEl = document.getElementById('touchpad');
    const touchOverlay = document.getElementById('touchClickOverlay');

    // state
    let prevButtons = [];
    let prevAxes = [];
    let touchAxes = null;         // {x: index, y: index} or null
    let touchButtonIndex = null;  // learned button index for pad click (if any)
    const AXIS_MOVE_THRESHOLD = 0.06; // jitter cutoff

    // helper to toggle classes (works for svg elements)
    function toggleActive(elOrId, on) {
      if (!elOrId) return;
      const el = (typeof elOrId === 'string') ? document.getElementById(elOrId) : elOrId;
      if (!el) return;
      if (on) el.classList.add('active'); else el.classList.remove('active');
    }

    // map pretty much the conventional mapping (best-effort)
    function applyMapping(gp) {
      // basic info
      statusEl.textContent = `Status: ${gp.id} (index ${gp.index})`;

      // sticks (axes 0..3 usually)
      const ax0 = gp.axes[0] || 0, ax1 = gp.axes[1] || 0, ax2 = gp.axes[2] || 0, ax3 = gp.axes[3] || 0;
      lsEl.setAttribute('cx', 350 + ax0 * 25);
      lsEl.setAttribute('cy', 300 + ax1 * 25);
      rsEl.setAttribute('cx', 850 + ax2 * 25);
      rsEl.setAttribute('cy', 300 + ax3 * 25);

      // stick clicks L3/R3 -> buttons 10/11
      toggleActive('l3', !!(gp.buttons[10] && gp.buttons[10].pressed));
      toggleActive('r3', !!(gp.buttons[11] && gp.buttons[11].pressed));
      toggleActive('l1', !!(gp.buttons[4] && gp.buttons[4].pressed));
      toggleActive('r1', !!(gp.buttons[5] && gp.buttons[5].pressed));

      // dpad 12..15
      toggleActive('d_up', !!(gp.buttons[12] && gp.buttons[12].pressed));
      toggleActive('d_down', !!(gp.buttons[13] && gp.buttons[13].pressed));
      toggleActive('d_left', !!(gp.buttons[14] && gp.buttons[14].pressed));
      toggleActive('d_right', !!(gp.buttons[15] && gp.buttons[15].pressed));

      // face 0..3
      toggleActive('btn_cross', !!(gp.buttons[0] && gp.buttons[0].pressed));
      toggleActive('btn_circle', !!(gp.buttons[1] && gp.buttons[1].pressed));
      toggleActive('btn_square', !!(gp.buttons[2] && gp.buttons[2].pressed));
      toggleActive('btn_triangle', !!(gp.buttons[3] && gp.buttons[3].pressed));

      // triggers 6/7
      const l2v = (gp.buttons[6] && gp.buttons[6].value) || 0;
      const r2v = (gp.buttons[7] && gp.buttons[7].value) || 0;
      l2fill.setAttribute('width', Math.max(0, Math.min(200, l2v * 200)));
      r2fill.setAttribute('width', Math.max(0, Math.min(200, r2v * 200)));

      // share/options/ps
      toggleActive('share', !!(gp.buttons[8] && gp.buttons[8].pressed));
      toggleActive('options', !!(gp.buttons[9] && gp.buttons[9].pressed));
      toggleActive('ps', !!(gp.buttons[16] && gp.buttons[16].pressed));

      // --- TOUCHPAD detection & visualization ---

      // detect likely touch axes automatically:
      // prefer pairs starting at index 4 upwards (typical DualSense uses 4/5),
      // but pick the first pair that shows movement greater than threshold.
      const axes = gp.axes || [];
      let found = null;
      for (let k = 4; k < axes.length - 1; k++) {
        if (Math.abs(axes[k]) > AXIS_MOVE_THRESHOLD || Math.abs(axes[k + 1]) > AXIS_MOVE_THRESHOLD) {
          found = { x: k, y: k + 1 };
          break;
        }
      }
      // fallback: if nothing moved but axes length >=6, assume 4/5 are touch axes
      if (!found && axes.length >= 6) found = { x: 4, y: 5 };

      if (found) {
        touchAxes = found;
        const tx = axes[touchAxes.x];
        const ty = axes[touchAxes.y];

        // normalized 0..1 coords
        const nx = (tx + 1) / 2;
        const ny = (ty + 1) / 2;

        // pad position (must match SVG touchpad coords)
        const padX = 500, padY = 120, padW = 200, padH = 80;

        // show cursor when there's meaningful movement OR when the learned touch button is pressed
        const movement = (Math.abs(tx) > AXIS_MOVE_THRESHOLD) || (Math.abs(ty) > AXIS_MOVE_THRESHOLD);
        const touchBtnPressed = touchButtonIndex !== null && gp.buttons[touchButtonIndex] && gp.buttons[touchButtonIndex].pressed;

        if (movement || touchBtnPressed) {
          // clamp
          const cx = padX + Math.max(0, Math.min(1, nx)) * padW;
          const cy = padY + Math.max(0, Math.min(1, ny)) * padH;
          touchCursor.setAttribute('cx', cx);
          touchCursor.setAttribute('cy', cy);
          touchCursor.setAttribute('r', 8);
          touchpadEl.classList.add('active');
        } else {
          touchCursor.setAttribute('r', 0);
          // clear active only if no button pressed
          if (!touchBtnPressed) touchpadEl.classList.remove('active');
        }

        // learn which button is the touchpad click:
        // if touch movement or showing cursor and any button just pressed, capture it
        gp.buttons.forEach((btn, idx) => {
          const prev = prevButtons[idx];
          if (btn && btn.pressed && !prev && (movement || Math.abs(tx) > 0.01 || Math.abs(ty) > 0.01)) {
            // if we haven't learned, capture this as touchpad button
            if (touchButtonIndex === null) {
              touchButtonIndex = idx;
              console.log('Learned touch click button index:', touchButtonIndex);
            }
          }
        });

        // highlight overlay if learned button is currently pressed
        if (touchButtonIndex !== null) {
          const pressed = !!(gp.buttons[touchButtonIndex] && gp.buttons[touchButtonIndex].pressed);
          if (pressed) {
            touchOverlay.setAttribute('fill', 'rgba(255,209,102,0.08)');
            touchOverlay.setAttribute('stroke', 'rgba(255,209,102,0.6)');
            touchOverlay.style.transition = 'fill .06s, stroke .06s';
          } else {
            touchOverlay.setAttribute('fill', 'transparent');
            touchOverlay.setAttribute('stroke', 'transparent');
          }
        } else {
          // no learned button yet — try common index 17 also for visual feedback
          if (gp.buttons[17] && gp.buttons[17].pressed) {
            touchOverlay.setAttribute('fill', 'rgba(255,209,102,0.08)');
            touchOverlay.setAttribute('stroke', 'rgba(255,209,102,0.6)');
          } else {
            touchOverlay.setAttribute('fill', 'transparent');
            touchOverlay.setAttribute('stroke', 'transparent');
          }
        }

      } else {
        // no touch axes found
        touchCursor.setAttribute('r', 0);
        touchpadEl.classList.remove('active');
        touchOverlay.setAttribute('fill', 'transparent');
        touchOverlay.setAttribute('stroke', 'transparent');
      }
    }

    // polling loop
    function poll() {
      const pads = (navigator.getGamepads && navigator.getGamepads()) || [];
      const gp = pads[0] || null;
      if (gp) {
        applyMapping(gp);
        // update prev arrays
        prevButtons = gp.buttons.map(b => !!b.pressed);
        prevAxes = gp.axes.slice();
      } else {
        statusEl.textContent = 'Status: no controller detected';
        // hide touch visuals
        touchCursor.setAttribute('r', 0);
        touchpadEl.classList.remove('active');
      }
      requestAnimationFrame(poll);
    }

    // init prev arrays to avoid undefined errors
    prevButtons = [];
    prevAxes = [];
    poll();

    // helpful connection logs
    window.addEventListener('gamepadconnected', e => {
      console.log('gamepad connected', e.gamepad);
      statusEl.textContent = `Status: ${e.gamepad.id} connected`;
    });
    window.addEventListener('gamepaddisconnected', e => {
      console.log('gamepad disconnected', e.gamepad);
      statusEl.textContent = 'Status: controller disconnected';
    });
  </script>
</body>
</html>

<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>DualSense Button Debug</title>
</head>
<body>
  <h1>Press buttons to see their index</h1>
  <pre id="out">Waiting...</pre>

  <script>
    const out = document.getElementById("out");

    function update() {
      const pads = navigator.getGamepads();
      let text = "";
      for (let i = 0; i < pads.length; i++) {
        const gp = pads[i];
        if (!gp) continue;
        text += `Gamepad ${gp.index}: ${gp.id}\n`;
        gp.buttons.forEach((b, j) => {
          if (b.pressed || b.value > 0) {
            text += `  Button ${j}: pressed=${b.pressed}, value=${b.value}\n`;
          }
        });
        text += "\n";
      }
      out.textContent = text || "No controller detected";
      requestAnimationFrame(update);
    }
    update();
  </script>
</body>
</html>
