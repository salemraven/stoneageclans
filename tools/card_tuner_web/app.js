const canvas = document.getElementById("stage");
const ctx = canvas.getContext("2d");
const statusEl = document.getElementById("status");
const valuesEl = document.getElementById("values");
const zoomResetBtn = document.getElementById("zoomResetBtn");

const DISPLAY_HEIGHT = 128;
const WALK_AMP = 2.5;
const WALK_SPEED = 8;
const MIN_ZOOM = 0.25;
const MAX_ZOOM = 6;
const ZOOM_STEP = 1.15;

const state = {
  bodyImg: null,
  headImg: null,
  layout: null,
  preset: null,
  handles: [],
  active: null,
  walking: false,
  walkPhase: 0,
  lastTs: 0,
  footY: 0,
  bodyW: 352,
  bodyH: 470,
  viewZoom: 1,
  viewPanX: 0,
  viewPanY: 0,
  stageCenterX: 360,
  stageCenterY: 460,
};

const handleDefs = [
  { id: "neck", label: "H", color: "#73bff2", kind: "layout", key: "body_neck_socket_px", texture: "body" },
  { id: "shoulder", label: "1", color: "#e64d4d", kind: "preset", key: "shoulder_offset_px" },
  { id: "hand", label: "1", color: "#36d95c", kind: "preset", key: "hand_grip_offset_px" },
  { id: "support_shoulder", label: "2", color: "#bf2626", kind: "preset", key: "support_shoulder_offset_px" },
  { id: "support_hand", label: "2", color: "#2eb34a", kind: "preset", key: "support_hand_idle_offset_px" },
  { id: "weapon", label: "3", color: "#f2bf26", kind: "preset", key: "overlay_offset_idle_px" },
];

function setStatus(text) {
  statusEl.textContent = text;
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function updateZoomLabel() {
  if (zoomResetBtn) {
    zoomResetBtn.textContent = `${Math.round(state.viewZoom * 100)}%`;
  }
}

function screenToWorld(x, y) {
  return {
    x: (x - state.viewPanX) / state.viewZoom,
    y: (y - state.viewPanY) / state.viewZoom,
  };
}

function zoomAt(screenX, screenY, factor) {
  const before = screenToWorld(screenX, screenY);
  state.viewZoom = clamp(state.viewZoom * factor, MIN_ZOOM, MAX_ZOOM);
  state.viewPanX = screenX - before.x * state.viewZoom;
  state.viewPanY = screenY - before.y * state.viewZoom;
  updateZoomLabel();
}

function resetZoom() {
  state.viewZoom = 1;
  state.viewPanX = 0;
  state.viewPanY = 0;
  updateZoomLabel();
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = url;
  });
}

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.json();
}

async function postJson(url, payload) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const data = await res.json();
  if (!res.ok || !data.ok) throw new Error(data.error || `Save failed (${res.status})`);
  return data;
}

function bodyScale() {
  return DISPLAY_HEIGHT / state.bodyH;
}

function stageCenter() {
  return { x: state.stageCenterX, y: state.stageCenterY };
}

function characterBoundsLocal() {
  const s = bodyScale();
  const off = state.layout?.body_offset_px || [0, 0];
  const neck = state.layout?.body_neck_socket_px || [176, 24];
  const pivot = state.layout?.head_pivot_px || [153, 345];

  let minX = (-state.bodyW * 0.5 + off[0]) * s;
  let minY = (-state.bodyH * 0.5 + off[1]) * s;
  let maxX = minX + state.bodyW * s;
  let maxY = minY + state.bodyH * s;

  if (state.headImg) {
    const pivotLocalX = (neck[0] - state.bodyW * 0.5 + off[0]) * s;
    const pivotLocalY = (neck[1] - state.bodyH * 0.5 + off[1]) * s;
    const headX = pivotLocalX - pivot[0] * s;
    const headY = pivotLocalY - pivot[1] * s;
    minX = Math.min(minX, headX);
    minY = Math.min(minY, headY);
    maxX = Math.max(maxX, headX + state.headImg.width * s);
    maxY = Math.max(maxY, headY + state.headImg.height * s);
  }

  if (state.preset) {
    for (const def of handleDefs) {
      if (def.kind !== "preset") continue;
      const p = state.preset[def.key];
      if (!p) continue;
      minX = Math.min(minX, p[0] * s - 24);
      minY = Math.min(minY, p[1] * s - 24);
      maxX = Math.max(maxX, p[0] * s + 24);
      maxY = Math.max(maxY, p[1] * s + 24);
    }
  }

  return { minX, minY, maxX, maxY };
}

function fitStageToCanvas() {
  const pad = 56;
  const bounds = characterBoundsLocal();
  const charCenterX = (bounds.minX + bounds.maxX) * 0.5;
  const charCenterY = (bounds.minY + bounds.maxY) * 0.5;
  const charW = bounds.maxX - bounds.minX;
  const charH = bounds.maxY - bounds.minY;

  state.stageCenterX = canvas.width * 0.5 - charCenterX;
  // Bias down so the head stays comfortably inside the canvas.
  state.stageCenterY = canvas.height * 0.54 - charCenterY;

  const fitZoom = Math.min(
    (canvas.width - pad * 2) / Math.max(charW, 1),
    (canvas.height - pad * 2) / Math.max(charH, 1),
    1.35,
  );
  state.viewZoom = clamp(fitZoom, MIN_ZOOM, MAX_ZOOM);
  state.viewPanX = 0;
  state.viewPanY = 0;
  updateZoomLabel();
}

function textureToCanvas(texX, texY, bobY = 0, tilt = 0) {
  const center = stageCenter();
  const s = bodyScale();
  const off = state.layout?.body_offset_px || [0, 0];
  const localX = (texX - state.bodyW * 0.5) * s + off[0] * s;
  const localY = (texY - state.bodyH * 0.5) * s + off[1] * s + bobY;
  const cos = Math.cos(tilt);
  const sin = Math.sin(tilt);
  return {
    x: center.x + localX * cos - localY * sin,
    y: center.y + localX * sin + localY * cos,
  };
}

function canvasToTexture(x, y, bobY = 0, tilt = 0) {
  const center = stageCenter();
  const s = bodyScale();
  const off = state.layout?.body_offset_px || [0, 0];
  const dx = x - center.x;
  const dy = y - center.y - bobY;
  const cos = Math.cos(-tilt);
  const sin = Math.sin(-tilt);
  const localX = dx * cos - dy * sin;
  const localY = dx * sin + dy * cos;
  return {
    x: localX / s + state.bodyW * 0.5 - off[0],
    y: localY / s + state.bodyH * 0.5 - off[1],
  };
}

function displayToCanvas(dx, dy, bobY = 0, tilt = 0) {
  const center = stageCenter();
  const s = bodyScale();
  const localX = dx * s;
  const localY = dy * s + bobY;
  const cos = Math.cos(tilt);
  const sin = Math.sin(tilt);
  return {
    x: center.x + localX * cos - localY * sin,
    y: center.y + localX * sin + localY * cos,
  };
}

function canvasToDisplay(x, y, bobY = 0, tilt = 0) {
  const center = stageCenter();
  const s = bodyScale();
  const dx = x - center.x;
  const dy = y - center.y - bobY;
  const cos = Math.cos(-tilt);
  const sin = Math.sin(-tilt);
  const localX = dx * cos - dy * sin;
  const localY = dx * sin + dy * cos;
  return { x: localX / s, y: localY / s };
}

function getMotion() {
  const bobY = state.walking ? Math.sin(state.walkPhase) * WALK_AMP : 0;
  const tilt = state.walking ? Math.sin(state.walkPhase) * 0.06 : 0;
  const headBob = state.walking ? Math.sin(state.walkPhase - 0.45) * WALK_AMP : 0;
  return { bobY, tilt, headBob };
}

function rebuildHandles() {
  const { bobY, tilt } = getMotion();
  state.handles = handleDefs.map((def) => {
    let tex = null;
    let display = null;
    if (def.kind === "layout") {
      tex = state.layout[def.key];
    } else {
      display = state.preset[def.key];
    }
    const pos = tex
      ? textureToCanvas(tex[0], tex[1], bobY, tilt)
      : displayToCanvas(display[0], display[1], bobY, tilt);
    return { ...def, pos };
  });
}

function drawCharacter() {
  const { bobY, tilt, headBob } = getMotion();
  const center = stageCenter();
  const s = bodyScale();
  const off = state.layout?.body_offset_px || [0, 0];

  ctx.clearRect(0, 0, canvas.width, canvas.height);

  ctx.save();
  ctx.translate(state.viewPanX, state.viewPanY);
  ctx.scale(state.viewZoom, state.viewZoom);

  ctx.save();
  ctx.translate(center.x, center.y + bobY);
  ctx.rotate(tilt);

  const bodyDrawX = (-state.bodyW * 0.5 + off[0]) * s;
  const bodyDrawY = (-state.bodyH * 0.5 + off[1]) * s;
  ctx.drawImage(state.bodyImg, bodyDrawX, bodyDrawY, state.bodyW * s, state.bodyH * s);

  const neck = state.layout.body_neck_socket_px;
  const pivot = state.layout.head_pivot_px;
  const headW = state.headImg.width;
  const headH = state.headImg.height;
  const pivotLocalX = (neck[0] - state.bodyW * 0.5 + off[0]) * s;
  const pivotLocalY = (neck[1] - state.bodyH * 0.5 + off[1]) * s + headBob;
  const headX = pivotLocalX - pivot[0] * s;
  const headY = pivotLocalY - pivot[1] * s;
  ctx.drawImage(state.headImg, headX, headY, headW * s, headH * s);

  ctx.restore();

  const shoulder = state.handles.find((h) => h.id === "shoulder");
  const hand = state.handles.find((h) => h.id === "hand");
  const supportShoulder = state.handles.find((h) => h.id === "support_shoulder");
  const supportHand = state.handles.find((h) => h.id === "support_hand");

  drawArmLine(shoulder?.pos, hand?.pos, "#8b5a2b");
  drawArmLine(supportShoulder?.pos, supportHand?.pos, "#6d4a2a");

  for (const handle of state.handles) {
    drawHandle(handle);
  }

  ctx.restore();
}

function drawArmLine(a, b, color) {
  if (!a || !b) return;
  ctx.strokeStyle = color;
  ctx.lineWidth = 4 / state.viewZoom;
  ctx.lineCap = "round";
  ctx.beginPath();
  ctx.moveTo(a.x, a.y);
  ctx.lineTo(b.x, b.y);
  ctx.stroke();
}

function drawHandle(handle) {
  const r = 10 / state.viewZoom;
  ctx.fillStyle = handle.color;
  ctx.strokeStyle = "#111";
  ctx.lineWidth = 2 / state.viewZoom;
  ctx.beginPath();
  ctx.arc(handle.pos.x, handle.pos.y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = "#fff";
  ctx.font = `bold ${11 / state.viewZoom}px system-ui`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(handle.label, handle.pos.x, handle.pos.y);
}

function updateValues() {
  valuesEl.textContent = JSON.stringify(
    {
      layout: state.layout,
      preset: state.preset,
      view: { zoom: state.viewZoom, pan: [state.viewPanX, state.viewPanY] },
    },
    null,
    2,
  );
}

function pickHandle(x, y) {
  const world = screenToWorld(x, y);
  const pickRadius = 18 / state.viewZoom;
  let best = null;
  let bestDist = Infinity;
  for (const handle of state.handles) {
    const d = Math.hypot(handle.pos.x - world.x, handle.pos.y - world.y);
    if (d <= pickRadius && d < bestDist) {
      best = handle;
      bestDist = d;
    }
  }
  return best;
}

function pointerPos(evt) {
  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  return {
    x: (evt.clientX - rect.left) * scaleX,
    y: (evt.clientY - rect.top) * scaleY,
  };
}

function moveActiveHandle(screenX, screenY) {
  if (!state.active) return;
  const world = screenToWorld(screenX, screenY);
  const { bobY, tilt } = getMotion();
  if (state.active.kind === "layout") {
    const tex = canvasToTexture(world.x, world.y, bobY, tilt);
    state.layout[state.active.key] = [round(tex.x), round(tex.y)];
  } else {
    const display = canvasToDisplay(world.x, world.y, bobY, tilt);
    state.preset[state.active.key] = [round(display.x, 2), round(display.y, 2)];
  }
  rebuildHandles();
  updateValues();
}

function round(v, places = 0) {
  const m = 10 ** places;
  return Math.round(v * m) / m;
}

canvas.addEventListener(
  "wheel",
  (evt) => {
    evt.preventDefault();
    const pos = pointerPos(evt);
    const factor = evt.deltaY < 0 ? ZOOM_STEP : 1 / ZOOM_STEP;
    zoomAt(pos.x, pos.y, factor);
    drawCharacter();
  },
  { passive: false },
);

canvas.addEventListener("pointerdown", (evt) => {
  const pos = pointerPos(evt);
  const picked = pickHandle(pos.x, pos.y);
  if (!picked) return;
  state.active = picked;
  canvas.classList.add("dragging");
  canvas.setPointerCapture(evt.pointerId);
});

canvas.addEventListener("pointermove", (evt) => {
  if (!state.active) return;
  const pos = pointerPos(evt);
  moveActiveHandle(pos.x, pos.y);
  drawCharacter();
});

canvas.addEventListener("pointerup", () => {
  state.active = null;
  canvas.classList.remove("dragging");
});

canvas.addEventListener("pointercancel", () => {
  state.active = null;
  canvas.classList.remove("dragging");
});

async function loadAll() {
  const [bodyImg, headImg, layout, preset] = await Promise.all([
    loadImage("/assets/character_cards/body1.png"),
    loadImage("/assets/character_cards/head1.png"),
    fetchJson("/api/layout"),
    fetchJson("/api/preset"),
  ]);
  state.bodyImg = bodyImg;
  state.headImg = headImg;
  state.bodyW = bodyImg.width;
  state.bodyH = bodyImg.height;
  state.layout = layout;
  if (!state.layout.body_offset_px) {
    state.layout.body_offset_px = [0, 0];
  }
  state.preset = preset;
  state.footY = -DISPLAY_HEIGHT * 0.5;
  fitStageToCanvas();
  rebuildHandles();
  updateValues();
  updateZoomLabel();
  setStatus("Drag handles, scroll to zoom, then Save.");
}

async function saveAll() {
  setStatus("Saving…");
  await postJson("/api/layout", state.layout);
  await postJson("/api/preset", state.preset);
  setStatus("Saved to assets/character_cards/layered_blank_1.tres and club_clansmen_1.tres");
}

function tick(ts) {
  if (!state.lastTs) state.lastTs = ts;
  const dt = (ts - state.lastTs) / 1000;
  state.lastTs = ts;
  if (state.walking) {
    state.walkPhase += dt * WALK_SPEED;
    rebuildHandles();
  }
  drawCharacter();
  requestAnimationFrame(tick);
}

document.getElementById("saveBtn").addEventListener("click", () => {
  saveAll().catch((err) => setStatus(String(err)));
});

document.getElementById("reloadBtn").addEventListener("click", () => {
  loadAll()
    .then(() => setStatus("Reloaded from disk."))
    .catch((err) => setStatus(String(err)));
});

document.getElementById("walkBtn").addEventListener("click", () => {
  state.walking = !state.walking;
  if (!state.walking) state.walkPhase = 0;
  rebuildHandles();
  setStatus(state.walking ? "Walk preview ON" : "Walk preview OFF");
});

document.getElementById("zoomInBtn").addEventListener("click", () => {
  zoomAt(canvas.width * 0.5, canvas.height * 0.5, ZOOM_STEP);
  drawCharacter();
});

document.getElementById("zoomOutBtn").addEventListener("click", () => {
  zoomAt(canvas.width * 0.5, canvas.height * 0.5, 1 / ZOOM_STEP);
  drawCharacter();
});

document.getElementById("zoomResetBtn").addEventListener("click", () => {
  fitStageToCanvas();
  rebuildHandles();
  drawCharacter();
});

loadAll()
  .then(() => requestAnimationFrame(tick))
  .catch((err) => setStatus(`Load failed: ${err}`));
