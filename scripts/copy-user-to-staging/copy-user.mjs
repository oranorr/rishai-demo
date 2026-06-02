#!/usr/bin/env node
/**
 * [copy-user] Prod → Staging: копирование пользователя по integer user id.
 *
 * Читает: Directus prod (PROD_DIRECTUS_API_URL + PROD_DIRECTUS_TOKEN)
 * Пишет:  Directus staging (STAGING_DIRECTUS_API_URL + STAGING_DIRECTUS_TOKEN)
 *
 * Запуск из корня репо:
 *   node scripts/copy-user-to-staging/copy-user.mjs --user-id 42
 *   node scripts/copy-user-to-staging/copy-user.mjs --user-id 42 --dry-run
 *   node scripts/copy-user-to-staging/copy-user.mjs --user-id 42 --overwrite
 */

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');

// ─── Env ───────────────────────────────────────────────────────────────────

function parseEnvFile(filePath) {
  if (!existsSync(filePath)) return {};
  const out = {};
  for (const rawLine of readFileSync(filePath, 'utf8').split('\n')) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  return out;
}

function loadConfig() {
  const fromCopyUser = parseEnvFile(resolve(REPO_ROOT, '.env.copy-user'));
  const fromAppEnv = parseEnvFile(resolve(REPO_ROOT, '.env'));
  const env = { ...fromAppEnv, ...fromCopyUser };

  const trimSlash = (url) => (url || '').replace(/\/+$/, '');

  // Prod Directus: явный URL или DIRECTUS_BASE_URL из .env приложения
  const prodDirectusUrl = trimSlash(
    env.PROD_DIRECTUS_URL ||
      env.PROD_DIRECTUS_API_URL ||
      env.DIRECTUS_BASE_URL ||
      (isPivotBackendUrl(env.PROD_DIRECTUS_URL) ? '' : ''),
  );

  const stagingDirectusUrl = trimSlash(
    env.STAGING_DIRECTUS_URL ||
      env.STAGING_DIRECTUS_API_URL ||
      (isPivotBackendUrl(env.STAGING_DIRECTUS_URL) ? '' : ''),
  );

  return {
    prodDirectusUrl,
    stagingDirectusUrl,
    prodToken: env.PROD_DIRECTUS_TOKEN || env.DIRECTUS_ACCESS_TOKEN || '',
    stagingToken: env.STAGING_DIRECTUS_TOKEN || '',
    prodBackendUrl: trimSlash(
      env.PROD_BACKEND_URL ||
        (isPivotBackendUrl(env.PROD_DIRECTUS_URL) ? env.PROD_DIRECTUS_URL : ''),
    ),
    stagingBackendUrl: trimSlash(
      env.STAGING_BACKEND_URL ||
        (isPivotBackendUrl(env.STAGING_DIRECTUS_URL)
          ? env.STAGING_DIRECTUS_URL
          : ''),
    ),
    pivotIdentityKey: env.PIVOT_IDENTITY_KEY || env.AUTH_HEADER_KEY || '',
    usersCollection: env.USERS_COLLECTION || 'user',
    daysCollection: env.DAYS_COLLECTION || 'day',
    weekPlansCollection: env.WEEK_PLANS_COLLECTION || 'weekPlans',
  };
}

function isPivotBackendUrl(url) {
  return typeof url === 'string' && url.includes('pivot-backend');
}

// ─── CLI ───────────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = {
    userId: null,
    stagingUserId: null,
    dryRun: false,
    overwrite: false,
    createUser: false,
    includeWhoop: true,
    includeWeekPlans: true,
    includeDays: true,
    daysLimit: null,
  };

  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--user-id' || a === '-u') {
      args.userId = argv[++i];
    } else if (a === '--staging-user-id') {
      args.stagingUserId = argv[++i];
    } else if (a === '--dry-run') {
      args.dryRun = true;
    } else if (a === '--overwrite') {
      args.overwrite = true;
    } else if (a === '--create-user') {
      args.createUser = true;
    } else if (a === '--no-whoop') {
      args.includeWhoop = false;
    } else if (a === '--no-week-plans') {
      args.includeWeekPlans = false;
    } else if (a === '--no-days') {
      args.includeDays = false;
    } else if (a === '--days-limit') {
      args.daysLimit = parseInt(argv[++i], 10);
    } else if (a === '--help' || a === '-h') {
      printHelp();
      process.exit(0);
    } else {
      fail(`Неизвестный аргумент: ${a}. Запусти с --help`);
    }
  }

  if (args.userId == null || args.userId === '') {
    fail('Укажи --user-id <integer>, например: --user-id 42');
  }

  if (!/^\d+$/.test(String(args.userId))) {
    fail(`--user-id должен быть integer, получено: ${args.userId}`);
  }

  if (args.stagingUserId != null && !/^\d+$/.test(String(args.stagingUserId))) {
    fail(`--staging-user-id должен быть integer, получено: ${args.stagingUserId}`);
  }

  if (args.daysLimit != null && (args.daysLimit < 1 || args.daysLimit > 500)) {
    fail('--days-limit: от 1 до 500');
  }

  return args;
}

function printHelp() {
  console.log(`
[copy-user] Копирование пользователя prod → staging

Использование:
  node scripts/copy-user-to-staging/copy-user.mjs --user-id <id> [опции]

Опции:
  --user-id, -u <id>        Directus user id на PROD (integer) — обязательно
  --staging-user-id <id>    Записать в существующего staging user (если email не найден)
  --create-user             Создать нового staging user (нужен admin-like token!)
  --dry-run                 Только показать план, без записи
  --overwrite               Удалить на staging days/weekPlans target user, потом копировать
  --no-whoop                Не копировать WHOOP-токены
  --no-week-plans           Не копировать weekPlans
  --no-days                 Не копировать days
  --days-limit <N>          Скопировать только N последних дней (max 500)

Важно:
  • weekPlanIds на user не копируем (Directus M2M, token даёт 403).
    Планы привязаны через weekPlans.userId — приложение их подтянет.
  • Если staging token «слабый», новые user создаются пустыми/невидимыми.
    Тогда используй --staging-user-id существующего юзера из staging admin.

Env: файл .env.copy-user в корне репо (см. scripts/copy-user-to-staging/env.example)
`);
}

// ─── Logging ─────────────────────────────────────────────────────────────

function log(msg) {
  console.log(`[copy-user] ${msg}`);
}

function fail(msg) {
  console.error(`[copy-user] ERROR: ${msg}`);
  process.exit(1);
}

/** Человекочитаемая сетьевая ошибка вместо голого «fetch failed». */
function formatFetchError(error, url) {
  const cause = error?.cause ?? error;
  const code = cause?.code ?? '';
  const msg = cause?.message ?? error?.message ?? String(error);

  if (code === 'ENOTFOUND' || msg.includes('getaddrinfo ENOTFOUND')) {
    const host = (() => {
      try {
        return new URL(url).hostname;
      } catch {
        return url;
      }
    })();
    return (
      `хост не найден (DNS NXDOMAIN): ${host}\n` +
      '  → PROD_DIRECTUS_URL, скорее всего, устарел или опечатка.\n' +
      '  → Спроси у админа актуальный URL prod Directus.\n' +
      '  → Либо задай PROD_BACKEND_URL + PIVOT_IDENTITY_KEY (AUTH_HEADER_KEY из .env).'
    );
  }
  if (code === 'ECONNREFUSED') {
    return `соединение отклонено: ${url}\n  → сервер выключен или неверный порт.`;
  }
  if (code === 'ETIMEDOUT' || code === 'UND_ERR_CONNECT_TIMEOUT') {
    return `таймаут: ${url}\n  → VPN / firewall / сервер недоступен.`;
  }
  if (msg.includes('certificate') || msg.includes('SSL')) {
    return `SSL ошибка: ${msg}\n  → URL: ${url}`;
  }
  return `${msg}${code ? ` (${code})` : ''}\n  → URL: ${url}`;
}

async function safeFetch(url, options) {
  try {
    return await fetch(url, options);
  } catch (error) {
    throw new Error(formatFetchError(error, url));
  }
}

// ─── Preflight ─────────────────────────────────────────────────────────────

async function preflightCheck(config) {
  log('Preflight: проверяю доступность…');

  if (config.prodDirectusUrl && config.prodToken) {
    const healthUrl = `${config.prodDirectusUrl}/server/health`;
    try {
      const res = await safeFetch(healthUrl);
      if (!res.ok) {
        log(`  ⚠ prod Directus health → HTTP ${res.status}`);
      } else {
        log(`  ✓ prod Directus: ${config.prodDirectusUrl}`);
      }
    } catch (e) {
      fail(`prod Directus недоступен:\n  ${e.message}`);
    }
  } else if (config.prodBackendUrl && config.pivotIdentityKey) {
    log(`  ✓ prod Pivot Backend: ${config.prodBackendUrl}`);
  }

  if (config.stagingDirectusUrl && config.stagingToken) {
    const healthUrl = `${config.stagingDirectusUrl}/server/health`;
    try {
      const res = await safeFetch(healthUrl);
      if (!res.ok) {
        fail(`staging Directus health → HTTP ${res.status}`);
      }
      log(`  ✓ staging Directus: ${config.stagingDirectusUrl}`);
    } catch (e) {
      fail(`staging Directus недоступен:\n  ${e.message}`);
    }

    // Проверка прав token на запись
    for (const col of [
      config.usersCollection,
      config.daysCollection,
      config.weekPlansCollection,
    ]) {
      try {
        await directusRequest(
          config.stagingDirectusUrl,
          config.stagingToken,
          'GET',
          `/items/${col}?limit=1`,
        );
        log(`  ✓ staging token: read ${col}`);
      } catch (e) {
        log(`  ⚠ staging token: НЕТ read на «${col}» — ${e.message.split('\n')[0]}`);
        log(`    → попроси admin token с CRUD на users, days, weekPlans`);
      }
    }
  }
}

// ─── Directus HTTP ─────────────────────────────────────────────────────────

async function directusRequest(baseUrl, token, method, path, body) {
  const url = `${baseUrl}${path}`;
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  const res = await safeFetch(url, {
    method,
    headers,
    body: body != null ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let json = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text };
    }
  }

  if (!res.ok) {
    const detail =
      json?.errors?.[0]?.message ||
      json?.error?.message ||
      json?.message ||
      text ||
      res.statusText;
    throw new Error(`Directus ${method} ${path} → ${res.status}: ${detail}`);
  }

  return json;
}

async function directusGetItem(baseUrl, token, collection, id, fields) {
  const fieldsQuery = fields ? `?fields=${encodeURIComponent(fields.join(','))}` : '';
  const json = await directusRequest(
    baseUrl,
    token,
    'GET',
    `/items/${collection}/${id}${fieldsQuery}`,
  );
  return json?.data ?? json;
}

async function directusListAll(baseUrl, token, collection, filter, sort, limitCap) {
  const pageSize = 100;
  let offset = 0;
  const all = [];

  while (true) {
    const params = new URLSearchParams();
    params.set('limit', String(pageSize));
    params.set('offset', String(offset));
    if (sort) params.set('sort', sort);
    if (filter) {
      for (const [key, val] of Object.entries(filter)) {
        params.set(`filter[${key}][_eq]`, String(val));
      }
    }

    const json = await directusRequest(
      baseUrl,
      token,
      'GET',
      `/items/${collection}?${params.toString()}`,
    );
    const batch = json?.data ?? [];
    all.push(...batch);

    if (batch.length < pageSize) break;
    if (limitCap != null && all.length >= limitCap) {
      return all.slice(0, limitCap);
    }
    offset += pageSize;
  }

  return limitCap != null ? all.slice(0, limitCap) : all;
}

async function directusDeleteByFilter(baseUrl, token, collection, filter) {
  const params = new URLSearchParams();
  for (const [key, val] of Object.entries(filter)) {
    params.set(`filter[${key}][_eq]`, String(val));
  }
  await directusRequest(
    baseUrl,
    token,
    'DELETE',
    `/items/${collection}?${params.toString()}`,
  );
}

async function directusFindOneByFilter(baseUrl, token, collection, filter) {
  const params = new URLSearchParams();
  params.set('limit', '1');
  for (const [key, val] of Object.entries(filter)) {
    params.set(`filter[${key}][_eq]`, String(val));
  }
  const json = await directusRequest(
    baseUrl,
    token,
    'GET',
    `/items/${collection}?${params.toString()}`,
  );
  const rows = json?.data ?? [];
  return rows[0] ?? null;
}

async function directusCreate(baseUrl, token, collection, payload) {
  const json = await directusRequest(baseUrl, token, 'POST', `/items/${collection}`, payload);
  return json?.data ?? json;
}

async function directusUpdate(baseUrl, token, collection, id, payload) {
  const json = await directusRequest(
    baseUrl,
    token,
    'PATCH',
    `/items/${collection}/${id}`,
    payload,
  );
  return json?.data ?? json;
}

// ─── Pivot Backend (fallback read) ─────────────────────────────────────────

function backendHeaders(identityKey, userId, includeContentType = true) {
  return {
    ...(includeContentType ? { 'Content-Type': 'application/json' } : {}),
    'pivot-identity-key': identityKey,
    'x-user-id': String(userId),
  };
}

async function backendGetUser(backendUrl, identityKey, userId) {
  const url = `${backendUrl}/users/${userId}`;
  const res = await safeFetch(url, {
    headers: backendHeaders(identityKey, userId, false),
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};
  if (!res.ok) {
    throw new Error(`Backend GET /users/${userId} → ${res.status}: ${text}`);
  }
  return json?.data ?? json;
}

async function backendListPaginated(backendUrl, identityKey, userId, path, limitCap) {
  const pageSize = 100;
  let offset = 0;
  const all = [];

  while (true) {
    const url = `${backendUrl}${path}?limit=${pageSize}&offset=${offset}`;
    const res = await safeFetch(url, {
      headers: backendHeaders(identityKey, userId),
    });
    const text = await res.text();
    const json = text ? JSON.parse(text) : {};
    if (!res.ok) {
      throw new Error(`Backend GET ${path} → ${res.status}: ${text}`);
    }
    const batch = json?.data ?? [];
    all.push(...batch);
    if (batch.length < pageSize) break;
    if (limitCap != null && all.length >= limitCap) {
      return all.slice(0, limitCap);
    }
    offset += pageSize;
  }

  return limitCap != null ? all.slice(0, limitCap) : all;
}

// ─── Copy helpers ──────────────────────────────────────────────────────────

const STRIP_FIELDS = new Set([
  'id',
  'date_created',
  'date_updated',
  'user_created',
  'user_updated',
]);

const USER_SKIP_FIELDS = new Set(['adaptyId', 'password', 'token']);

/** M2M/O2M — PATCH с ними даёт 403 на staging token. */
const USER_RELATION_FIELDS = new Set(['weekPlanIds', 'days']);

const WHOOP_FIELDS = [
  'whoopId',
  'whoopRefreshToken',
  'whoopAccessToken',
  'whoopTokenExpiresAt',
  'lastSuccessfulSync',
];

function stripSystemFields(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (STRIP_FIELDS.has(k)) continue;
    out[k] = v;
  }
  return out;
}

function buildUserPayload(sourceUser, includeWhoop) {
  const payload = stripSystemFields(sourceUser);

  for (const f of USER_SKIP_FIELDS) {
    delete payload[f];
  }
  for (const f of USER_RELATION_FIELDS) {
    delete payload[f];
  }

  if (!includeWhoop) {
    for (const f of WHOOP_FIELDS) {
      delete payload[f];
    }
  }

  return payload;
}

function normalizeUserIdForDirectus(userId) {
  const n = parseInt(String(userId), 10);
  return Number.isNaN(n) ? userId : n;
}

function buildWeekPlanPayload(sourcePlan, targetUserId) {
  const payload = stripSystemFields(sourcePlan);
  payload.userId = normalizeUserIdForDirectus(targetUserId);
  return payload;
}

function buildDayPayload(sourceDay, targetUserId) {
  const payload = stripSystemFields(sourceDay);
  payload.userId = normalizeUserIdForDirectus(targetUserId);
  return payload;
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function loadProdUser(config, userId) {
  // 1) Directus prod
  if (config.prodDirectusUrl && config.prodToken) {
    log(`Читаю user ${userId} из Directus prod…`);
    return directusGetItem(
      config.prodDirectusUrl,
      config.prodToken,
      config.usersCollection,
      userId,
    );
  }

  // 2) Pivot Backend fallback
  if (config.prodBackendUrl && config.pivotIdentityKey) {
    log(`Читаю user ${userId} через Pivot Backend prod…`);
    return backendGetUser(config.prodBackendUrl, config.pivotIdentityKey, userId);
  }

  fail(
    'Не настроено чтение prod: задай PROD_DIRECTUS_API_URL + PROD_DIRECTUS_TOKEN ' +
      '(или PROD_BACKEND_URL + PIVOT_IDENTITY_KEY из AUTH_HEADER_KEY)',
  );
}

async function loadProdWeekPlans(config, userId) {
  log(`Читаю weekPlans userId=${userId}…`);

  if (config.prodDirectusUrl && config.prodToken) {
    return directusListAll(
      config.prodDirectusUrl,
      config.prodToken,
      config.weekPlansCollection,
      { userId: String(userId) },
      'startDate',
      null,
    );
  }

  if (config.prodBackendUrl && config.pivotIdentityKey) {
    return backendListPaginated(
      config.prodBackendUrl,
      config.pivotIdentityKey,
      userId,
      '/week-plans',
      null,
    );
  }

  log('⚠ weekPlans: нет prod Directus / prod Backend — пропуск');
  return [];
}

async function loadProdDays(config, userId, daysLimit) {
  log(`Читаю days userId=${userId}${daysLimit ? ` (limit ${daysLimit})` : ''}…`);

  if (config.prodDirectusUrl && config.prodToken) {
    return directusListAll(
      config.prodDirectusUrl,
      config.prodToken,
      config.daysCollection,
      { userId: String(userId) },
      '-dateTime',
      daysLimit,
    );
  }

  if (config.prodBackendUrl && config.pivotIdentityKey) {
    return backendListPaginated(
      config.prodBackendUrl,
      config.pivotIdentityKey,
      userId,
      '/days',
      daysLimit,
    );
  }

  log('⚠ days: нет prod Directus / prod Backend — пропуск');
  return [];
}

async function findStagingUserByFilter(config, filter) {
  return directusFindOneByFilter(
    config.stagingDirectusUrl,
    config.stagingToken,
    config.usersCollection,
    filter,
  );
}

/** Проверяем, что token «видит» user и может создавать day с FK. */
async function verifyStagingUserCanOwnDays(config, targetUserId) {
  const uid = normalizeUserIdForDirectus(targetUserId);
  const visible = await findStagingUserByFilter(config, { id: String(uid) });
  if (!visible) {
    fail(
      `staging user id=${uid} не виден token'у (ghost user).\n` +
        '  → Не используй --create-user с текущим token.\n' +
        '  → Укажи --staging-user-id существующего юзера из staging admin\n' +
        '  → Или попроси admin static token с полными правами на user/day.',
    );
  }

  const probeDateTime = `999999999${uid}`;
  try {
    const created = await directusCreate(
      config.stagingDirectusUrl,
      config.stagingToken,
      config.daysCollection,
      {
        userId: uid,
        dateTime: probeDateTime,
        weekTdeeAverage: 1,
        macros: { kcal: 1, protein: 1, carbs: 1, fat: 1 },
        healthMetrics: { bmi: 1, lastTdee: 1, bmr: 1, bodyFatPerc: 0 },
      },
    );
    await directusRequest(
      config.stagingDirectusUrl,
      config.stagingToken,
      'DELETE',
      `/items/${config.daysCollection}/${created.id}`,
    );
    log(`  ✓ staging user id=${uid} может владеть days`);
  } catch (e) {
    fail(
      `staging user id=${uid} не может создавать days: ${e.message}\n` +
        '  → Используй --staging-user-id другого юзера или admin token.',
    );
  }
}

async function resolveStagingUser(config, sourceUser, args) {
  const email = sourceUser.email;
  if (!email) {
    fail('У prod-пользователя нет email — некуда мапить staging user');
  }

  if (!config.stagingDirectusUrl || !config.stagingToken) {
    fail(
      'Для записи нужны STAGING_DIRECTUS_URL + STAGING_DIRECTUS_TOKEN в .env.copy-user',
    );
  }

  // Явный target id (рекомендуется при слабом token)
  if (args.stagingUserId) {
    log(`Использую --staging-user-id=${args.stagingUserId}…`);
    if (args.dryRun) return args.stagingUserId;
    await verifyStagingUserCanOwnDays(config, args.stagingUserId);
    return args.stagingUserId;
  }

  log(`Ищу staging user по email=${email}…`);
  const existing = await findStagingUserByFilter(config, { email });

  if (existing) {
    log(`  → найден staging user id=${existing.id}`);
    if (!args.dryRun) {
      await verifyStagingUserCanOwnDays(config, existing.id);
    }
    return existing.id;
  }

  if (!args.createUser) {
    fail(
      `staging user с email=${email} не найден (token не видит такого юзера).\n` +
        '  Варианты:\n' +
        '  1) --staging-user-id <id>  — записать в существующего юзера из staging admin\n' +
        '  2) --create-user           — создать нового (нужен мощный admin token)\n' +
        '  3) Попросить admin static token для staging Directus',
    );
  }

  if (args.dryRun) {
    log(`  → [dry-run] создал бы нового staging user для ${email} (полный профиль)`);
    return '(new)';
  }

  log(`  → создаю staging user с полным профилем…`);
  const userPayload = buildUserPayload(sourceUser, args.includeWhoop);
  const created = await directusCreate(
    config.stagingDirectusUrl,
    config.stagingToken,
    config.usersCollection,
    userPayload,
  );
  log(`  → создан staging user id=${created.id}`);

  const visible = await findStagingUserByFilter(config, { email });
  if (!visible) {
    fail(
      `user id=${created.id} создан, но token его не видит (ghost user) — days не привязать.\n` +
        '  → Нужен admin static token для STAGING_DIRECTUS_TOKEN.',
    );
  }

  await verifyStagingUserCanOwnDays(config, created.id);
  return created.id;
}

async function upsertStagingUserProfile(config, targetUserId, sourceUser, includeWhoop) {
  const userPayload = buildUserPayload(sourceUser, includeWhoop);
  log(
    `Обновляю профиль staging user id=${targetUserId} ` +
      `(поля: ${Object.keys(userPayload).join(', ')})…`,
  );
  log('  ℹ weekPlanIds пропущены — Directus M2M; планы через weekPlans.userId');
  await directusUpdate(
    config.stagingDirectusUrl,
    config.stagingToken,
    config.usersCollection,
    targetUserId,
    userPayload,
  );
}

async function copyWeekPlans(config, sourcePlans, targetUserId, dryRun) {
  const map = {};
  const stats = { created: 0, updated: 0, skipped: 0 };

  for (const plan of sourcePlans) {
    const prodId = String(plan.id);
    const startDate = plan.startDate;

    if (dryRun) {
      log(`  [dry-run] weekPlan prod id=${prodId} startDate=${startDate}`);
      map[prodId] = `(new-for-${prodId})`;
      stats.created++;
      continue;
    }

    const existing = await directusFindOneByFilter(
      config.stagingDirectusUrl,
      config.stagingToken,
      config.weekPlansCollection,
      {
        userId: normalizeUserIdForDirectus(targetUserId),
        startDate: String(startDate),
      },
    );

    const payload = buildWeekPlanPayload(plan, targetUserId);

    if (existing) {
      await directusUpdate(
        config.stagingDirectusUrl,
        config.stagingToken,
        config.weekPlansCollection,
        existing.id,
        payload,
      );
      map[prodId] = String(existing.id);
      stats.updated++;
    } else {
      const created = await directusCreate(
        config.stagingDirectusUrl,
        config.stagingToken,
        config.weekPlansCollection,
        payload,
      );
      map[prodId] = String(created.id);
      stats.created++;
    }
  }

  return { map, stats };
}

async function copyDays(config, sourceDays, targetUserId, dryRun) {
  const stats = { created: 0, updated: 0, skipped: 0 };

  for (let i = 0; i < sourceDays.length; i++) {
    const day = sourceDays[i];
    const dateTime = String(day.dateTime);

    if ((i + 1) % 50 === 0 || i === sourceDays.length - 1) {
      log(`  days progress: ${i + 1}/${sourceDays.length}`);
    }

    if (dryRun) {
      stats.created++;
      continue;
    }

    const existing = await directusFindOneByFilter(
      config.stagingDirectusUrl,
      config.stagingToken,
      config.daysCollection,
      {
        userId: normalizeUserIdForDirectus(targetUserId),
        dateTime,
      },
    );

    const payload = buildDayPayload(day, targetUserId);

    if (existing) {
      await directusUpdate(
        config.stagingDirectusUrl,
        config.stagingToken,
        config.daysCollection,
        existing.id,
        payload,
      );
      stats.updated++;
    } else {
      await directusCreate(
        config.stagingDirectusUrl,
        config.stagingToken,
        config.daysCollection,
        payload,
      );
      stats.created++;
    }
  }

  return stats;
}

async function main() {
  const args = parseArgs(process.argv);
  const config = loadConfig();
  const started = Date.now();

  log('─── Copy user prod → staging ───');
  log(`prod user id: ${args.userId}`);
  if (args.dryRun) log('режим: DRY-RUN (запись отключена)');

  validateConfig(config);
  await preflightCheck(config);

  // ── Load source ──
  const sourceUser = await loadProdUser(config, args.userId);
  if (!sourceUser?.id) {
    fail(`Пользователь ${args.userId} не найден на prod`);
  }

  log(`prod user: id=${sourceUser.id} email=${sourceUser.email} name=${sourceUser.name ?? '—'}`);

  let sourceWeekPlans = [];
  let sourceDays = [];

  if (args.includeWeekPlans) {
    sourceWeekPlans = await loadProdWeekPlans(config, args.userId);
    log(`  weekPlans на prod: ${sourceWeekPlans.length}`);
  }

  if (args.includeDays) {
    sourceDays = await loadProdDays(config, args.userId, args.daysLimit);
    log(`  days на prod: ${sourceDays.length}`);
  }

  // ── Resolve target ──
  const targetUserId = await resolveStagingUser(config, sourceUser, args);

  if (args.dryRun) {
    log('');
    log('─── План (dry-run) ───');
    log(`staging user: ${targetUserId}`);
    if (args.overwrite) {
      log('overwrite: удалил бы staging days + weekPlans этого user');
    }
    log(`скопировал бы: weekPlans=${sourceWeekPlans.length}, days=${sourceDays.length}`);
    log(`whoop tokens: ${args.includeWhoop ? 'да' : 'нет'}`);
    log('weekPlanIds: не копируем (M2M), weekPlans.userId достаточно');
    log('Готово (dry-run). Запусти без --dry-run для записи.');
    return;
  }

  const stagingUserId = normalizeUserIdForDirectus(targetUserId);

  // ── Overwrite ──
  if (args.overwrite) {
    log('overwrite: удаляю staging days и weekPlans…');
    await directusDeleteByFilter(
      config.stagingDirectusUrl,
      config.stagingToken,
      config.daysCollection,
      { userId: stagingUserId },
    );
    await directusDeleteByFilter(
      config.stagingDirectusUrl,
      config.stagingToken,
      config.weekPlansCollection,
      { userId: stagingUserId },
    );
  }

  // ── Copy week plans ──
  let weekPlanStats = { created: 0, updated: 0, skipped: 0 };

  if (args.includeWeekPlans && sourceWeekPlans.length > 0) {
    log('Копирую weekPlans…');
    const r = await copyWeekPlans(config, sourceWeekPlans, stagingUserId, false);
    weekPlanStats = r.stats;
  }

  // ── Copy user profile ──
  await upsertStagingUserProfile(
    config,
    stagingUserId,
    sourceUser,
    args.includeWhoop,
  );

  // ── Copy days ──
  let dayStats = { created: 0, updated: 0, skipped: 0 };
  if (args.includeDays && sourceDays.length > 0) {
    log('Копирую days…');
    dayStats = await copyDays(config, sourceDays, stagingUserId, false);
  }

  const durationMs = Date.now() - started;

  log('');
  log('─── Готово ───');
  log(`source: prod user ${args.userId} (${sourceUser.email})`);
  log(`target: staging user ${stagingUserId}`);
  log(
    `weekPlans: created=${weekPlanStats.created} updated=${weekPlanStats.updated}`,
  );
  log(`days: created=${dayStats.created} updated=${dayStats.updated}`);
  log(`whoop: ${args.includeWhoop ? 'скопированы (если были на prod)' : 'пропущены'}`);
  log(`duration: ${(durationMs / 1000).toFixed(1)}s`);
  log('');
  log('Дальше: открой приложение на STAGING и залогинься (email из профиля staging user).');
}

function validateConfig(config) {
  const canReadProdDirectus = config.prodDirectusUrl && config.prodToken;
  const canReadProdBackend =
    config.prodBackendUrl && config.pivotIdentityKey;

  if (!canReadProdDirectus && !canReadProdBackend) {
    fail(
      'Настрой чтение prod:\n' +
        '  • PROD_DIRECTUS_API_URL + PROD_DIRECTUS_TOKEN (лучше всего)\n' +
        '    PROD_DIRECTUS_API_URL можно взять из DIRECTUS_BASE_URL в .env\n' +
        '  • или PROD_BACKEND_URL + PIVOT_IDENTITY_KEY (AUTH_HEADER_KEY из .env)',
    );
  }

  if (!config.stagingDirectusUrl || !config.stagingToken) {
    fail(
      'Настрой запись staging:\n' +
        '  • STAGING_DIRECTUS_API_URL — URL Directus staging (не pivot-backend!)\n' +
        '  • STAGING_DIRECTUS_TOKEN — token со write-доступом',
    );
  }
}

main().catch((e) => {
  const msg = e?.message ?? String(e);
  console.error(`[copy-user] FATAL: ${msg.split('\n').join('\n[copy-user]          ')}`);
  if (process.env.DEBUG) console.error(e);
  process.exit(1);
});
