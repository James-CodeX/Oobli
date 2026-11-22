// Uploads a file to Appwrite Storage, replacing any previous version.
// Files over 5 MB go up in 5 MB chunks, as the Appwrite API requires.
//
// Usage: APPWRITE_API_KEY=... node appwrite-upload.mjs <bucketId> <fileId> <path> [name]
import { readFile } from 'node:fs/promises';
import { basename } from 'node:path';

const [bucketId, fileId, path, name = basename(path)] = process.argv.slice(2);
const endpoint = process.env.APPWRITE_ENDPOINT ?? 'https://sgp.cloud.appwrite.io/v1';
const project = process.env.APPWRITE_PROJECT_ID ?? '6b012dd80037b9146a2b';
const key = process.env.APPWRITE_API_KEY;
if (!bucketId || !fileId || !path || !key) {
  console.error('Usage: APPWRITE_API_KEY=... node appwrite-upload.mjs <bucketId> <fileId> <path> [name]');
  process.exit(2);
}

const headers = { 'X-Appwrite-Project': project, 'X-Appwrite-Key': key };
const url = `${endpoint}/storage/buckets/${bucketId}/files`;
const CHUNK = 5 * 1024 * 1024;

const del = await fetch(`${url}/${fileId}`, { method: 'DELETE', headers });
if (!del.ok && del.status !== 404) throw new Error(`Delete failed: ${del.status} ${await del.text()}`);

const bytes = await readFile(path);
for (let start = 0; start < bytes.length; start += CHUNK) {
  const end = Math.min(start + CHUNK, bytes.length) - 1;
  const form = new FormData();
  form.append('fileId', fileId);
  form.append('file', new Blob([bytes.subarray(start, end + 1)]), name);
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      ...headers,
      ...(bytes.length > CHUNK && { 'Content-Range': `bytes ${start}-${end}/${bytes.length}` }),
      ...(start > 0 && { 'x-appwrite-id': fileId }),
    },
    body: form,
  });
  if (!res.ok) throw new Error(`Upload failed at byte ${start}: ${res.status} ${await res.text()}`);
  console.log(`Uploaded ${end + 1}/${bytes.length} bytes`);
}
console.log(`${endpoint}/storage/buckets/${bucketId}/files/${fileId}/download?project=${project}`);
