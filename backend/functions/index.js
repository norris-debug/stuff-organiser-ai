const express = require("express");
const admin = require("firebase-admin");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket();
const SECRET = defineSecret("SHARED_SECRET");
const app = express();
app.use(express.json({ limit: "11mb" }));
app.use((req, res, next) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});
const SCAN_ID = /^t\d+(-\d+)?$/;
const bad = (res, code, err, fields) => res.status(code).json({ error: err, ...(fields ? { fields } : {}) });
const pub = (scanId, kind, n) => `https://storage.googleapis.com/${bucket.name}/scans/${scanId}/${kind}/angle-${n}`;
async function authed(req, res) {
  const s = SECRET.value();
  if (!s) { bad(res, 500, "secret_not_configured"); return false; }
  if ((req.get("Authorization") || "") !== `Bearer ${s}`) { bad(res, 401, "bad_bearer"); return false; }
  return true;
}
app.post("/api/scans", async (req, res) => {
  if (!(await authed(req, res))) return;
  const { scanId, venue, notes, photos } = req.body || {};
  if (!SCAN_ID.test(String(scanId || ""))) return bad(res, 400, "invalid_body", ["scanId"]);
  if (!Array.isArray(photos) || photos.length < 1 || photos.length > 6) return bad(res, 400, "invalid_body", ["photos"]);
  for (const p of photos) if (!p || !p.dataBase64 || !(p.angleIndex >= 1) || !p.mimeType) return bad(res, 400, "invalid_body", ["photos"]);
  const ref = db.collection("scans").doc(String(scanId));
  const doc = await ref.get();
  if (doc.exists && doc.data().status === "ready") return bad(res, 409, "already_ready");
  for (const p of photos) {
    const f = bucket.file(`scans/${scanId}/photos/angle-${p.angleIndex}`);
    await f.save(Buffer.from(p.dataBase64, "base64"), { metadata: { contentType: p.mimeType }, resumable: false });
    await f.makePublic().catch(() => {});
  }
  const now = new Date().toISOString();
  await ref.set({ scanId, venue: venue || "", notes: notes || "", photoCount: photos.length,
    status: doc.exists ? "processing" : "received", revision: doc.exists ? doc.data().revision || 0 : 0,
    submittedAtUtc: doc.exists ? doc.data().submittedAtUtc : now, updatedAtUtc: now }, { merge: true });
  return res.status(202).json({ scanId, status: "received" });
});
app.get("/api/scans", async (req, res) => {
  if (!(await authed(req, res))) return;
  const snap = await db.collection("scans").where("status", "==", req.query.status || "received").limit(20).get();
  const scans = [];
  for (const d of snap.docs) {
    const v = d.data();
    const photos = [];
    for (let i = 1; i <= v.photoCount; i++) photos.push({ angleIndex: i, url: pub(d.id, "photos", i) });
    scans.push({ scanId: d.id, venue: v.venue || "", notes: v.notes || "", photos });
  }
  res.json({ scans });
});
app.post("/api/renders/:scanId", async (req, res) => {
  if (!(await authed(req, res))) return;
  const scanId = req.params.scanId;
  const ref = db.collection("scans").doc(scanId);
  const doc = await ref.get();
  if (!doc.exists) return bad(res, 404, "unknown_scan_id");
  const cur = doc.data();
  const b = req.body || {};
  const rev = Number(b.revision);
  if (!(rev >= 1)) return bad(res, 400, "invalid_body", ["revision"]);
  if (cur.status === "ready" && rev < (cur.revision || 1)) return bad(res, 409, "stale_revision", { currentRevision: cur.revision });
  const renders = Array.isArray(b.renders) ? b.renders : [];
  if (!renders.length) return bad(res, 400, "invalid_body", ["renders"]);
  for (const r of renders) {
    if (!r || !r.dataBase64 || !(r.angleIndex >= 1)) return bad(res, 400, "invalid_body", ["renders"]);
    const f = bucket.file(`scans/${scanId}/renders/angle-${r.angleIndex}`);
    await f.save(Buffer.from(r.dataBase64, "base64"), { metadata: { contentType: r.mimeType || "image/png" }, resumable: false });
    await f.makePublic().catch(() => {});
  }
  const now = new Date().toISOString();
  const renderUrls = renders.map(r => pub(scanId, "renders", r.angleIndex)).sort((a, c) => a.localeCompare(c));
  await ref.set({ status: "ready", revision: rev, venue: b.venue || cur.venue || "",
    itemList: b.itemList || [], tidyPlan: b.tidyPlan || [], assumptions: b.assumptions || [],
    renderUrls, deliveredAtUtc: b.deliveredAtUtc || now, updatedAtUtc: now }, { merge: true });
  return res.status(201).json({ scanId, status: "stored", revision: rev, renderUrls,
    resultsUrl: `https://storage.googleapis.com/${bucket.name}/scans/${scanId}/results.json`, receivedAtUtc: now });
});
app.get("/api/results/:scanId", async (req, res) => {
  const doc = await db.collection("scans").doc(req.params.scanId).get();
  if (!doc.exists) return bad(res, 404, "unknown_scan_id");
  const v = doc.data();
  return res.json({ scanId: req.params.scanId, status: v.status === "ready" ? "ready" : "processing",
    revision: v.revision || 0, venue: v.venue || "", renders: v.renderUrls || [],
    itemList: v.itemList || [], tidyPlan: v.tidyPlan || [], assumptions: v.assumptions || [],
    deliveredAtUtc: v.deliveredAtUtc || null });
});
app.use((req, res) => bad(res, 404, "unknown_route"));
exports.scanApi = onRequest({ secrets: [SECRET], region: "us-central1", maxInstances: 10 }, app);
