import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { createSignedUploadUrl } from "./r2.js";

interface CreateUploadUrlInput {
  mediaType: "avatar" | "proof";
  mimeType: string;
}

export const createUploadUrl = onCall<CreateUploadUrlInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const mediaType = request.data.mediaType;
  const mimeType = assertString(request.data.mimeType, "mimeType");

  if (!["avatar", "proof"].includes(mediaType)) {
    throw new Error("Invalid mediaType.");
  }

  const ext = mimeType.includes("png") ? "png" : "jpg";
  const assetId = db.collection("mediaAssets").doc().id;
  const key = `${uid}/${mediaType}/${assetId}.${ext}`;
  const signed = await createSignedUploadUrl(key, mimeType);

  await db.collection("mediaAssets").doc(assetId).set({
    ownerId: uid,
    type: mediaType,
    r2Key: key,
    mimeType,
    createdAt: new Date()
  });

  return {
    ok: true,
    assetId,
    key,
    uploadUrl: signed.uploadUrl,
    publicUrl: signed.publicUrl
  };
});
