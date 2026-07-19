#!/usr/bin/env node
/**
 * Grants (or removes) the `admin` custom claim used by the Admin Control Panel
 * and by Firestore/Storage security rules.
 *
 * Usage (GitHub Action "Grant admin role" runs this for you):
 *   GOOGLE_APPLICATION_CREDENTIALS=sa.json node scripts/set-admin.js owner@example.com
 *   GOOGLE_APPLICATION_CREDENTIALS=sa.json node scripts/set-admin.js owner@example.com --remove
 */
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

(async () => {
  const email = process.argv[2];
  const remove = process.argv.includes("--remove");
  if (!email) { console.error("Usage: node set-admin.js <email> [--remove]"); process.exit(1); }

  initializeApp({ credential: applicationDefault() });
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, remove ? { admin: null } : { admin: true });
  console.log(`${remove ? "Removed" : "Granted"} admin claim for ${email} (${user.uid}).`);
  console.log("The user must sign out and back in for the claim to take effect.");
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
