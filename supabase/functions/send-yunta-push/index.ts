const firebaseScope = 'https://www.googleapis.com/auth/firebase.messaging';
const oauthUrl = 'https://oauth2.googleapis.com/token';

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const webhookSecret = Deno.env.get('PUSH_WEBHOOK_SECRET');
  if (!webhookSecret || request.headers.get('x-yunta-push-secret') !== webhookSecret) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!serviceAccountJson || !supabaseUrl || !serviceKey) {
    return json({ error: 'Push service is not configured' }, 503);
  }

  try {
    const event = await request.json();
    const record = event?.record;
    if (event?.type !== 'INSERT' || !isNotification(record)) {
      return json({ ignored: true });
    }

    const rows = await loadTokens(supabaseUrl, serviceKey, record.recipient_id);
    if (rows.length === 0) return json({ sent: 0 });

    const account = JSON.parse(serviceAccountJson);
    const accessToken = await createAccessToken(account);
    const results = await Promise.all(
      rows.map(({ fid }) => sendToDevice(
        account.project_id,
        accessToken,
        fid,
        record,
      )),
    );
    return json({ sent: results.filter(Boolean).length });
  } catch (error) {
    console.error('Push delivery failed:', error instanceof Error ? error.message : 'unknown');
    return json({ error: 'Push delivery failed' }, 502);
  }
});

function isNotification(value: Record<string, unknown> | undefined): boolean {
  return Boolean(
    value?.id && value.recipient_id && value.post_id &&
    ['offer_received', 'group_joined', 'offer_accepted'].includes(String(value.kind)),
  );
}

async function loadTokens(
  url: string,
  key: string,
  userId: string,
): Promise<Array<{ fid: string }>> {
  const query = new URLSearchParams({ user_id: `eq.${userId}`, select: 'fid' });
  const response = await fetch(`${url}/rest/v1/push_tokens?${query}`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
  if (!response.ok) throw new Error('Could not load recipient devices');
  return await response.json();
}

async function createAccessToken(account: {
  client_email: string;
  private_key: string;
  project_id: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url({ alg: 'RS256', typ: 'JWT' });
  const claims = base64Url({
    iss: account.client_email,
    scope: firebaseScope,
    aud: oauthUrl,
    iat: now,
    exp: now + 3600,
  });
  const unsigned = `${header}.${claims}`;
  const pem = account.private_key.replace(/-----[^-]+-----/g, '').replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pem), (char) => char.charCodeAt(0));
  const privateKey = await crypto.subtle.importKey(
    'pkcs8', keyBytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Bytes(new Uint8Array(signature))}`;
  const response = await fetch(oauthUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error('Google OAuth exchange failed');
  const result = await response.json();
  return result.access_token as string;
}

async function sendToDevice(
  projectId: string,
  accessToken: string,
  fid: string,
  record: Record<string, unknown>,
): Promise<boolean> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          fid,
          notification: {
            title: 'Actividad nueva en Yunta',
            body: 'Hay una novedad en uno de tus avisos. Abre la app para verla.',
          },
          data: {
            notification_id: String(record.id),
            post_id: String(record.post_id),
            kind: String(record.kind),
          },
          android: { priority: 'HIGH' },
        },
      }),
    },
  );
  if (response.ok) return true;
  const details = await response.text();
  if (response.status === 404 || details.includes('UNREGISTERED')) {
    await removeFid(fid, String(record.recipient_id));
    return false;
  }
  throw new Error(`FCM send failed (${response.status})`);
}

async function removeFid(fid: string, userId: string) {
  const url = Deno.env.get('SUPABASE_URL')!;
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const query = new URLSearchParams({ fid: `eq.${fid}`, user_id: `eq.${userId}` });
  await fetch(`${url}/rest/v1/push_tokens?${query}`, {
    method: 'DELETE',
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
}

function base64Url(value: unknown) {
  return base64Bytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64Bytes(bytes: Uint8Array) {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
