// Where the "Get the app" buttons point. The release workflow keeps the
// latest arm64 APK at this public Appwrite Storage URL.
export const APPWRITE_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
export const APPWRITE_PROJECT = '6b012dd80037b9146a2b';
export const DOWNLOAD_URL =
  import.meta.env.VITE_DOWNLOAD_URL ??
  `${APPWRITE_ENDPOINT}/storage/buckets/downloads/files/oobli-android/download?project=${APPWRITE_PROJECT}`;

// TODO: replace with a real, monitored inbox before launch.
export const CONTACT_EMAIL = 'hello@oobli.app';
export const CONTACT_URL = `mailto:${CONTACT_EMAIL}`;
export const UPDATED = '22 November 2026';
