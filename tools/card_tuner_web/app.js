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
const UPPER_ARM_LEN = 24;
const LOWER_ARM_LEN = 22;
const ELBOW_HINT_OUTWARD = 18;
const ELBOW_FOLD_MIN_DEG = 8;
const ELBOW_FOLD_MAX_DEG = 150;
const ARM_LINE_WIDTH = 14;
const CLUB_PIVOT_Y_FRAC = 0.88;
const CLUB_TEX_W = 471;
const CLUB_TEX_H = 835;
const OVERLAY_SCALE = 1.0;

const state = {
  bodyImg: null,
  headImg: null,
  clubImg: null,
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
  { id: "weapon_elbow", label: "1e", color: "#f28c1a", kind: "preset", key: "weapon_elbow_pole_idle_px", onArm: true },
  { id: "hand", label: "1", color: "#36d95c", kind: "preset", key: "hand_grip_offset_px" },
  { id: "support_shoulder", label: "2", color: "#bf2626", kind: "preset", key: "support_shoulder_offset_px" },
  { id: "support_elbow", label: "2e", color: "#33bfd9", kind: "preset", key: "support_elbow_pole_idle_px", onArm: true },
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

function vec2FromDisplayPair(x, y, places = 2) {
  return [round(x, places), round(y, places)];
}

function displayPairToCanvas(pair, bobY = 0, tilt = 0) {
  const [dx, dy] = normalizeVec2(pair);
  return displayToCanvas(dx, dy, bobY, tilt);
}

function normalizeVec2(value, fallback = [0, 0]) {
  if (!value) {
    return [...fallback];
  }
  if (Array.isArray(value) && value.length >= 2) {
    return [Number(value[0]), Number(value[1])];
  }
  if (typeof value === "object" && value.x != null && value.y != null) {
    return [Number(value.x), Number(value.y)];
  }
  return [...fallback];
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

function reachLimits(upperLen, lowerLen) {
  const minFold = (ELBOW_FOLD_MIN_DEG * Math.PI) / 180;
  const maxFold = (ELBOW_FOLD_MAX_DEG * Math.PI) / 180;
  const maxReach =
    Math.sqrt(upperLen * upperLen + lowerLen * lowerLen - 2 * upperLen * lowerLen * Math.cos(Math.PI - minFold)) -
    0.01;
  const minReach =
    Math.sqrt(upperLen * upperLen + lowerLen * lowerLen - 2 * upperLen * lowerLen * Math.cos(Math.PI - maxFold)) +
    0.01;
  return { minReach, maxReach };
}

function elbowPoleHint(shoulder, hand, bendSign) {
  const toHand = { x: hand.x - shoulder.x, y: hand.y - shoulder.y };
  const len = Math.hypot(toHand.x, toHand.y);
  if (len < 0.01) {
    toHand.y = 1;
    toHand.x = 0;
  } else {
    toHand.x /= len;
    toHand.y /= len;
  }
  const outward = { x: -toHand.y * bendSign, y: toHand.x * bendSign };
  const dist = ELBOW_HINT_OUTWARD * bodyScale();
  return {
    x: shoulder.x + outward.x * dist,
    y: shoulder.y + outward.y * dist,
  };
}

function solveIk(shoulder, hand, upperLen, lowerLen, poleHint) {
  const scale = bodyScale();
  const upper = upperLen * scale;
  const lower = lowerLen * scale;
  let dx = hand.x - shoulder.x;
  let dy = hand.y - shoulder.y;
  let dist = Math.hypot(dx, dy);
  if (dist < 0.001) {
    return { x: shoulder.x + upper, y: shoulder.y };
  }
  const limits = reachLimits(upper, lower);
  dist = clamp(dist, limits.minReach, limits.maxReach);
  const dir = { x: dx / dist, y: dy / dist };

  let cosShoulder = (upper * upper + dist * dist - lower * lower) / (2 * upper * dist);
  cosShoulder = clamp(cosShoulder, -1, 1);
  const shoulderAngle = Math.acos(cosShoulder);

  const mid = { x: shoulder.x + dir.x * (dist * 0.5), y: shoulder.y + dir.y * (dist * 0.5) };
  let poleSide = (poleHint.x - mid.x) * dir.y - (poleHint.y - mid.y) * dir.x;
  poleSide = poleSide === 0 ? 1 : Math.sign(poleSide);

  const elbowDirX = dir.x * Math.cos(shoulderAngle * poleSide) - dir.y * Math.sin(shoulderAngle * poleSide);
  const elbowDirY = dir.x * Math.sin(shoulderAngle * poleSide) + dir.y * Math.cos(shoulderAngle * poleSide);
  return { x: shoulder.x + elbowDirX * upper, y: shoulder.y + elbowDirY * upper };
}

function autoElbowPole(shoulder, hand, bendSign) {
  return elbowPoleHint(shoulder, hand, bendSign);
}

function overlayOriginCanvas(bobY = 0, tilt = 0) {
  const p = state.preset?.overlay_offset_idle_px || [22, -34];
  return displayToCanvas(p[0], p[1], bobY, tilt);
}

function overlayLocalToCanvas(localX, localY, bobY = 0, tilt = 0) {
  const origin = overlayOriginCanvas(bobY, tilt);
  const s = bodyScale() * OVERLAY_SCALE;
  const lx = localX * s;
  const ly = localY * s;
  return { x: origin.x + lx, y: origin.y + ly };
}

function handGripCanvas(bobY = 0, tilt = 0) {
  const grip = state.preset?.hand_grip_offset_px || [0, 0];
  return overlayLocalToCanvas(grip[0], grip[1], bobY, tilt);
}

function weaponGripAnchorCanvas(bobY = 0, tilt = 0) {
  // Swing club pivot sits on the overlay node — grip anchor = overlay origin.
  return overlayOriginCanvas(bobY, tilt);
}

function moveWeaponGripToCanvas(canvasX, canvasY) {
  const { bobY, tilt } = getMotion();
  const display = canvasToDisplay(canvasX, canvasY, bobY, tilt);
  state.preset.overlay_offset_idle_px = [round(display.x, 2), round(display.y, 2)];
  state.preset.hand_grip_offset_px = [0, 0];
}

function migrateCorruptedPreset() {
  if (!state.preset) return;
  const hand = normalizeVec2(state.preset.hand_grip_offset_px);
  const overlay = normalizeVec2(state.preset.overlay_offset_idle_px);
  state.preset.hand_grip_offset_px = hand;
  state.preset.overlay_offset_idle_px = overlay;
  state.preset.weapon_elbow_pole_idle_px = normalizeVec2(state.preset.weapon_elbow_pole_idle_px);
  state.preset.support_elbow_pole_idle_px = normalizeVec2(state.preset.support_elbow_pole_idle_px);
  const handLooksLikeBodyDisplay =
    Math.abs(hand[0]) > 120 || Math.abs(hand[1]) > 120 || Math.abs(hand[0] - overlay[0]) < 20;
  if (handLooksLikeBodyDisplay) {
    state.preset.hand_grip_offset_px = [0, 0];
    if (Math.abs(overlay[0]) > 120) {
      state.preset.overlay_offset_idle_px = [22, -34];
    }
  }
}

function seedElbowPoles() {
  if (!state.preset) return;
  const shoulder = displayToCanvas(
    state.preset.shoulder_offset_px[0],
    state.preset.shoulder_offset_px[1],
  );
  const hand = handGripCanvas();
  const supportShoulder = displayToCanvas(
    state.preset.support_shoulder_offset_px[0],
    state.preset.support_shoulder_offset_px[1],
  );
  const supportHand = displayToCanvas(
    state.preset.support_hand_idle_offset_px[0],
    state.preset.support_hand_idle_offset_px[1],
  );

  if (!state.preset.weapon_elbow_pole_idle_px || poleLength(state.preset.weapon_elbow_pole_idle_px) < 0.01) {
    const pole = autoElbowPole(shoulder, hand, -1);
    const display = canvasToDisplay(pole.x, pole.y);
    state.preset.weapon_elbow_pole_idle_px = vec2FromDisplayPair(display.x, display.y);
  }
  if (!state.preset.support_elbow_pole_idle_px || poleLength(state.preset.support_elbow_pole_idle_px) < 0.01) {
    const pole = autoElbowPole(supportShoulder, supportHand, 1);
    const display = canvasToDisplay(pole.x, pole.y);
    state.preset.support_elbow_pole_idle_px = vec2FromDisplayPair(display.x, display.y);
  }
}

function poleLength(p) {
  const [x, y] = normalizeVec2(p);
  return Math.hypot(x, y);
}

function poleFromElbow(shoulder, hand, elbow, bendSign) {
  const mid = { x: (shoulder.x + hand.x) * 0.5, y: (shoulder.y + hand.y) * 0.5 };
  const toElbow = { x: elbow.x - mid.x, y: elbow.y - mid.y };
  const len = Math.hypot(toElbow.x, toElbow.y);
  if (len < 0.01) {
    return autoElbowPole(shoulder, hand, bendSign);
  }
  const dist = ELBOW_HINT_OUTWARD * bodyScale();
  return { x: mid.x + (toElbow.x / len) * dist, y: mid.y + (toElbow.y / len) * dist };
}

function poleCanvasFromPreset(key) {
  const p = normalizeVec2(state.preset?.[key]);
  if (poleLength(p) < 0.01) {
    return null;
  }
  const { bobY, tilt } = getMotion();
  return displayPairToCanvas(p, bobY, tilt);
}

function resolveElbowOnArm(shoulderPos, handPos, poleKey, bendSign) {
  if (!shoulderPos || !handPos) {
    return null;
  }
  const pole = poleCanvasFromPreset(poleKey) || autoElbowPole(shoulderPos, handPos, bendSign);
  return solveIk(shoulderPos, handPos, UPPER_ARM_LEN, LOWER_ARM_LEN, pole);
}

function computeArmAnchors(bobY = 0, tilt = 0) {
  const shoulder = displayToCanvas(
    state.preset.shoulder_offset_px[0],
    state.preset.shoulder_offset_px[1],
    bobY,
    tilt,
  );
  const hand = handGripCanvas(bobY, tilt);
  const supportShoulder = displayToCanvas(
    state.preset.support_shoulder_offset_px[0],
    state.preset.support_shoulder_offset_px[1],
    bobY,
    tilt,
  );
  const supportHand = displayToCanvas(
    state.preset.support_hand_idle_offset_px[0],
    state.preset.support_hand_idle_offset_px[1],
    bobY,
    tilt,
  );
  return { shoulder, hand, supportShoulder, supportHand };
}

function computeElbowPositions(bobY = 0, tilt = 0) {
  const anchors = computeArmAnchors(bobY, tilt);
  return {
    ...anchors,
    weapon: resolveElbowOnArm(
      anchors.shoulder,
      anchors.hand,
      "weapon_elbow_pole_idle_px",
      -1,
    ),
    support: resolveElbowOnArm(
      anchors.supportShoulder,
      anchors.supportHand,
      "support_elbow_pole_idle_px",
      1,
    ),
  };
}

function refreshElbowHandlePositions() {
  const { bobY, tilt } = getMotion();
  const elbows = computeElbowPositions(bobY, tilt);
  const weaponElbow = state.handles.find((h) => h.id === "weapon_elbow");
  const supportElbow = state.handles.find((h) => h.id === "support_elbow");

  if (weaponElbow && elbows.weapon && state.active?.id !== "weapon_elbow") {
    weaponElbow.pos = elbows.weapon;
  }
  if (supportElbow && elbows.support && state.active?.id !== "support_elbow") {
    supportElbow.pos = elbows.support;
  }
}

function syncElbowHandlesOnArms() {
  refreshElbowHandlePositions();
}

function handleCanvasPos(def, bobY, tilt) {
  if (def.id === "hand") {
    return handGripCanvas(bobY, tilt);
  }
  if (def.id === "weapon") {
    return weaponGripAnchorCanvas(bobY, tilt);
  }
  let tex = null;
  let display = null;
  if (def.kind === "layout") {
    tex = state.layout[def.key];
  } else {
    display = state.preset[def.key];
  }
  return tex
    ? textureToCanvas(tex[0], tex[1], bobY, tilt)
    : displayToCanvas(display[0], display[1], bobY, tilt);
}

function rebuildHandles() {
  const { bobY, tilt } = getMotion();
  const elbows = computeElbowPositions(bobY, tilt);
  state.handles = handleDefs.map((def) => {
    if (def.id === "weapon_elbow") {
      return { ...def, pos: elbows.weapon || elbows.shoulder };
    }
    if (def.id === "support_elbow") {
      return { ...def, pos: elbows.support || elbows.supportShoulder };
    }
    return { ...def, pos: handleCanvasPos(def, bobY, tilt) };
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

  const anchors = computeArmAnchors(bobY, tilt);
  const elbows = computeElbowPositions(bobY, tilt);
  const shoulder = { id: "shoulder", pos: anchors.shoulder };
  const hand = { id: "hand", pos: anchors.hand };
  const supportShoulder = { id: "support_shoulder", pos: anchors.supportShoulder };
  const supportHand = { id: "support_hand", pos: anchors.supportHand };
  let weaponElbowPos = elbows.weapon;
  let supportElbowPos = elbows.support;
  if (state.active?.id === "weapon_elbow" && state.active.pos) {
    weaponElbowPos = state.active.pos;
  }
  if (state.active?.id === "support_elbow" && state.active.pos) {
    supportElbowPos = state.active.pos;
  }
  refreshElbowHandlePositions();
  const weapon = state.handles.find((h) => h.id === "weapon");
  drawClub(weapon?.pos);

  if (shoulder.pos && hand.pos) {
    const pole = poleCanvasFromPreset("weapon_elbow_pole_idle_px") || autoElbowPole(shoulder.pos, hand.pos, -1);
    drawArmSegments(shoulder.pos, hand.pos, pole, "#8b5a2b", null);
  }
  if (supportShoulder.pos && supportHand.pos) {
    const pole =
      poleCanvasFromPreset("support_elbow_pole_idle_px") || autoElbowPole(supportShoulder.pos, supportHand.pos, 1);
    drawArmSegments(supportShoulder.pos, supportHand.pos, pole, "#6d4a2a", null);
  }

  if (weaponElbowPos) {
    drawElbowHandle(weaponElbowPos, "1e", "#f28c1a");
  }
  if (supportElbowPos) {
    drawElbowHandle(supportElbowPos, "2e", "#33bfd9");
  }

  if (hand.pos && weapon?.pos) {
    const gripDist = Math.hypot(hand.pos.x - weapon.pos.x, hand.pos.y - weapon.pos.y);
    if (gripDist > 1.5 / state.viewZoom) {
      const width = 3 / state.viewZoom;
      ctx.strokeStyle = "rgba(242, 191, 38, 0.85)";
      ctx.lineWidth = width;
      ctx.setLineDash([4 / state.viewZoom, 3 / state.viewZoom]);
      ctx.beginPath();
      ctx.moveTo(hand.pos.x, hand.pos.y);
      ctx.lineTo(weapon.pos.x, weapon.pos.y);
      ctx.stroke();
      ctx.setLineDash([]);
    }
  }

  for (const handle of state.handles) {
    if (handle.id === "weapon" || handle.onArm) {
      continue;
    }
    drawHandle(handle);
  }
  const weaponHandle = state.handles.find((h) => h.id === "weapon");
  if (weaponHandle) {
    drawHandle(weaponHandle);
  }

  ctx.restore();
}

function drawClub(overlayNodePos) {
  if (!state.clubImg || !overlayNodePos) return;
  const s = bodyScale() * OVERLAY_SCALE;
  const drawW = CLUB_TEX_W * s;
  const drawH = CLUB_TEX_H * s;
  const pivotOffsetY = (0.5 - CLUB_PIVOT_Y_FRAC) * drawH;
  const drawX = overlayNodePos.x - drawW * 0.5;
  const drawY = overlayNodePos.y - drawH * 0.5 + pivotOffsetY;
  ctx.drawImage(state.clubImg, drawX, drawY, drawW, drawH);
}

function drawJointMarker(pos, fill, stroke, radiusScale = 0.5) {
  const width = ARM_LINE_WIDTH / state.viewZoom;
  const r = width * radiusScale;
  ctx.fillStyle = fill;
  ctx.strokeStyle = stroke;
  ctx.lineWidth = Math.max(2, width * 0.16);
  ctx.beginPath();
  ctx.arc(pos.x, pos.y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
}

function drawArmSegments(shoulder, hand, pole, color, elbowJointColor) {
  const elbow = solveIk(shoulder, hand, UPPER_ARM_LEN, LOWER_ARM_LEN, pole);
  const width = ARM_LINE_WIDTH / state.viewZoom;
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.beginPath();
  ctx.moveTo(shoulder.x, shoulder.y);
  ctx.lineTo(elbow.x, elbow.y);
  ctx.lineTo(hand.x, hand.y);
  ctx.stroke();

  if (elbowJointColor) {
    drawJointMarker(elbow, elbowJointColor, "#111", 0.42);
  }
  drawJointMarker(shoulder, "#c9a07a", "#3a2518", 0.34);
  drawJointMarker(hand, "#9fd4a0", "#1f3a22", 0.38);
  return elbow;
}

function drawElbowHandle(pos, label, color) {
  const r = Math.max(14, 20 / state.viewZoom);
  const ring = r + 4 / state.viewZoom;
  ctx.save();
  ctx.fillStyle = "#ffffff";
  ctx.strokeStyle = "#000000";
  ctx.lineWidth = 3 / state.viewZoom;
  ctx.beginPath();
  ctx.arc(pos.x, pos.y, ring, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.arc(pos.x, pos.y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = "#111";
  ctx.font = `bold ${Math.max(12, 14 / state.viewZoom)}px system-ui`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(label, pos.x, pos.y);
  ctx.restore();
}

function drawHandle(handle) {
  const r = (handle.onArm ? 16 : 10) / state.viewZoom;
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
  const elbowPickRadius = Math.max(20, 28 / state.viewZoom);
  const { bobY, tilt } = getMotion();
  const elbows = computeElbowPositions(bobY, tilt);
  let best = null;
  let bestDist = Infinity;

  const elbowPicks = [
    { id: "weapon_elbow", label: "1e", color: "#f28c1a", pos: state.active?.id === "weapon_elbow" ? state.active.pos : elbows.weapon, onArm: true, kind: "preset", key: "weapon_elbow_pole_idle_px" },
    { id: "support_elbow", label: "2e", color: "#33bfd9", pos: state.active?.id === "support_elbow" ? state.active.pos : elbows.support, onArm: true, kind: "preset", key: "support_elbow_pole_idle_px" },
  ];
  for (const handle of elbowPicks) {
    if (!handle.pos) continue;
    const d = Math.hypot(handle.pos.x - world.x, handle.pos.y - world.y);
    if (d <= elbowPickRadius && d < bestDist) {
      best = handle;
      bestDist = d;
    }
  }

  for (const handle of state.handles) {
    if (handle.onArm) continue;
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

function elbowDragContext(handleId) {
  if (handleId === "weapon_elbow") {
    return {
      shoulderId: "shoulder",
      handId: "hand",
      poleKey: "weapon_elbow_pole_idle_px",
      bendSign: -1,
    };
  }
  return {
    shoulderId: "support_shoulder",
    handId: "support_hand",
    poleKey: "support_elbow_pole_idle_px",
    bendSign: 1,
  };
}

function moveElbowHandle(handle, worldX, worldY) {
  const { bobY, tilt } = getMotion();
  const ctx = elbowDragContext(handle.id);
  const shoulder = state.handles.find((h) => h.id === ctx.shoulderId)?.pos;
  const hand = state.handles.find((h) => h.id === ctx.handId)?.pos;
  if (!shoulder || !hand) {
    return;
  }
  handle.pos = { x: worldX, y: worldY };
  const pole = poleFromElbow(shoulder, hand, handle.pos, ctx.bendSign);
  const display = canvasToDisplay(pole.x, pole.y, bobY, tilt);
  state.preset[ctx.poleKey] = [round(display.x, 2), round(display.y, 2)];
}

function moveActiveHandle(screenX, screenY) {
  if (!state.active) return;
  const world = screenToWorld(screenX, screenY);
  if (state.active.onArm) {
    moveElbowHandle(state.active, world.x, world.y);
    updateValues();
    return;
  }
  if (state.active.id === "hand" || state.active.id === "weapon") {
    moveWeaponGripToCanvas(world.x, world.y);
    rebuildHandles();
    updateValues();
    return;
  }
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
  if (state.active?.onArm) {
    rebuildHandles();
  }
  state.active = null;
  canvas.classList.remove("dragging");
});

canvas.addEventListener("pointercancel", () => {
  state.active = null;
  canvas.classList.remove("dragging");
});

async function loadBuildInfo() {
  try {
    const info = await fetchJson("/api/version");
    const el = document.getElementById("buildInfo");
    if (el) {
      el.textContent = `build ${info.sha} · ${info.branch}`;
    }
    return info;
  } catch (_err) {
    return null;
  }
}

async function loadAll() {
  const [bodyImg, headImg, clubImg, layout, preset, build] = await Promise.all([
    loadImage("/assets/character_cards/body1.png"),
    loadImage("/assets/character_cards/head1.png"),
    loadImage("/assets/placeholder_cards/club.png"),
    fetchJson("/api/layout"),
    fetchJson("/api/preset"),
    loadBuildInfo(),
  ]);
  state.bodyImg = bodyImg;
  state.headImg = headImg;
  state.clubImg = clubImg;
  state.bodyW = bodyImg.width;
  state.bodyH = bodyImg.height;
  state.layout = layout;
  if (!state.layout.body_offset_px) {
    state.layout.body_offset_px = [0, 0];
  }
  state.preset = preset;
  migrateCorruptedPreset();
  if (!state.preset.weapon_elbow_pole_idle_px) state.preset.weapon_elbow_pole_idle_px = [0, 0];
  if (!state.preset.support_elbow_pole_idle_px) state.preset.support_elbow_pole_idle_px = [0, 0];
  state.footY = -DISPLAY_HEIGHT * 0.5;
  fitStageToCanvas();
  seedElbowPoles();
  rebuildHandles();
  updateValues();
  updateZoomLabel();
  const buildLabel = build ? `build ${build.sha}` : "web preview";
  setStatus(`Loaded (${buildLabel}). Drag handles, scroll to zoom, then Save.`);
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
    .then(() => {
      fitStageToCanvas();
      rebuildHandles();
      setStatus("Reloaded from disk.");
    })
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
