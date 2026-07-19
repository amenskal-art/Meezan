/**
 * MEEZAN Cloud Functions
 * ----------------------
 * 1. geminiChat            - Secure server-side proxy to the Google Gemini API.
 *                            The API key NEVER ships inside the mobile/web app.
 *                            The system prompt adapts to the caller's Firebase role:
 *                              client -> "Legal Assistant AI"
 *                              lawyer -> "Co-Counsel AI"
 * 2. onLawyerStatusChange  - Firestore trigger. When an admin approves/rejects a
 *                            lawyer, an email document is queued into /mail for the
 *                            Firebase "Trigger Email" extension to deliver.
 *
 * Secrets (set once):
 *   firebase functions:secrets:set GEMINI_API_KEY
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { GoogleGenerativeAI } = require("@google/generative-ai");

initializeApp();
const db = getFirestore();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.0-flash";

/** Role-aware system instructions (Arabic-first, Kurdish-capable). */
function systemPromptFor(role, name) {
  const common = `
You are "MEEZAN AI" (ميزان), the built-in assistant of an Iraqi legal services app.
Always answer in the same language the user writes in (Arabic, Kurdish Sorani, or English).
Ground every legal answer in IRAQI law: the Civil Code No. 40 of 1951, Penal Code No. 111 of 1969,
Personal Status Law No. 188 of 1959, Civil Procedure Code No. 83 of 1969, Labor Law No. 37 of 2015,
Evidence Law No. 107 of 1979, and the 2005 Constitution. If a matter is governed by the
Kurdistan Region's amendments, say so explicitly.
Always end substantive legal answers with a short disclaimer that this is general information,
not formal legal advice, and that a licensed Iraqi lawyer should be consulted.`;
  if (role === "lawyer") {
    return `${common}
The user (${name || "the user"}) is a VERIFIED IRAQI LAWYER. Act as a professional "Co-Counsel AI":
- Summarize long case briefs into issues, facts, applicable articles, and recommended strategy.
- Analyze pasted documents/contracts clause-by-clause and flag risks under Iraqi statutes.
- Draft contract and pleading templates citing the relevant Iraqi code articles.
- Track statutory deadlines (e.g. appeal windows under the Civil Procedure Code) when asked.
Be precise, cite article numbers when you can, and keep a professional tone.`;
  }
  return `${common}
The user (${name || "the user"}) is a CLIENT with no legal background. Act as a friendly "Legal Assistant AI":
- Answer general Iraqi legal FAQs in simple language.
- Guide them through the MEEZAN app (booking consultations, tracking cases, uploading documents).
- Help them identify WHICH lawyer specialization fits their problem
  (personal status, criminal, civil, commercial, labor, real estate, administrative)
  and encourage them to book a verified lawyer from the directory.
Never draft binding legal documents for clients; recommend a lawyer instead.`;
}

exports.geminiChat = onCall(
  { secrets: [GEMINI_API_KEY], timeoutSeconds: 120, memory: "512MiB" },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "Sign in first.");

    // Load the caller's role from Firestore (server-side truth, not client claims).
    const snap = await db.collection("users").doc(req.auth.uid).get();
    if (!snap.exists) throw new HttpsError("failed-precondition", "Profile not found.");
    const user = snap.data();
    const role = user.role === "lawyer" && user.status === "approved" ? "lawyer" : "client";

    const history = Array.isArray(req.data?.messages) ? req.data.messages.slice(-20) : [];
    const docText = typeof req.data?.documentText === "string"
      ? req.data.documentText.slice(0, 60000) : "";

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({
      model: GEMINI_MODEL,
      systemInstruction: systemPromptFor(role, user.name),
      generationConfig: { temperature: 0.4, maxOutputTokens: 2048 },
    });

    const contents = history.map((m) => ({
      role: m.role === "model" ? "model" : "user",
      parts: [{ text: String(m.text || "").slice(0, 8000) }],
    }));
    if (docText && role === "lawyer" && contents.length) {
      contents[contents.length - 1].parts.push({
        text: `\n\n--- ATTACHED DOCUMENT (analyze under Iraqi law) ---\n${docText}`,
      });
    }
    if (!contents.length) throw new HttpsError("invalid-argument", "No messages.");

    try {
      const result = await model.generateContent({ contents });
      return { text: result.response.text(), role };
    } catch (e) {
      console.error("Gemini error:", e);
      throw new HttpsError("internal", "AI service is temporarily unavailable.");
    }
  }
);

/**
 * Email notification on lawyer approval / rejection.
 * Requires the official Firebase "Trigger Email" extension installed and
 * configured to watch the "mail" collection (see README step 6).
 */
exports.onLawyerStatusChange = onDocumentUpdated("users/{uid}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!after || after.role !== "lawyer") return;
  if (before.status === after.status) return;

  let subject, html;
  if (after.status === "approved") {
    subject = "MEEZAN – تم قبول حسابك | Your lawyer account is approved";
    html = `<div dir="rtl" style="font-family:Tahoma"><h2>مبروك ${after.name || ""} 🎉</h2>
      <p>تمت الموافقة على حسابك كمحامٍ في تطبيق ميزان بعد التحقق من هوية نقابة المحامين.</p>
      <p>أصبح بإمكانك الآن الظهور في دليل المحامين واستقبال الموكلين وإدارة القضايا.</p></div>`;
  } else if (after.status === "rejected") {
    subject = "MEEZAN – طلبك بحاجة إلى مراجعة | Your application was not approved";
    html = `<div dir="rtl" style="font-family:Tahoma"><h2>عزيزي ${after.name || ""}</h2>
      <p>نأسف، لم تتم الموافقة على طلب التحقق الخاص بك.</p>
      <p><b>السبب:</b> ${after.rejectionReason || "لم يُذكر سبب"}</p>
      <p>يمكنك إعادة رفع مستند صحيح من داخل التطبيق وسيُعاد النظر في طلبك.</p></div>`;
  } else {
    return;
  }

  await db.collection("mail").add({
    to: after.email,
    message: { subject, html },
    createdAt: FieldValue.serverTimestamp(),
  });
});
