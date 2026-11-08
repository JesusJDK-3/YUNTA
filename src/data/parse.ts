/**
 * Lo que llega de Supabase se valida antes de pintar.
 * Si la función SQL devolviera un punto, este esquema lo rechaza:
 * FeedItem no tiene latitud ni longitud.
 */

import { z } from "zod";
import { YuntaError } from "../domain/errors";
import type { Detail, FeedItem, FeedResult, Session } from "../domain/types";
import { ZONES } from "../domain/types";

const zoneIds = ZONES.map((zone) => zone.id) as ["norte", "centro", "sur", "este"];

const feedItemSchema = z
  .object({
    id: z.string().uuid(),
    kind: z.enum(["anuncio", "caso"]),
    category: z.string(),
    type: z.string(),
    title: z.string(),
    description: z.string(),
    zoneId: z.enum(zoneIds),
    zoneName: z.string(),
    areaLabel: z.string(),
    distanceLabel: z.string().nullable(),
    coordinationMode: z.enum(["individual", "grupal"]).nullable(),
    status: z.string(),
    recommendationCount: z.number(),
    ratingAverage: z.number().nullable(),
    ratingCount: z.number(),
    authorId: z.string().uuid(),
    authorName: z.string(),
    sourceAnuncioId: z.string().uuid().nullable(),
    createdAt: z.string(),
  })
  .strict();

const memberSchema = z
  .object({
    userId: z.string().uuid(),
    displayName: z.string(),
    role: z.enum(["prestador", "receptor", "participante"]),
    status: z.enum(["pendiente", "aceptado", "retirado"]),
  })
  .strict();

const messageSchema = z
  .object({
    id: z.string().uuid(),
    senderId: z.string().uuid(),
    senderName: z.string(),
    body: z.string(),
    createdAt: z.string(),
  })
  .strict();

const detailSchema = z
  .object({
    item: feedItemSchema,
    members: z.array(memberSchema).default([]),
    pending: z.array(memberSchema).default([]),
    messages: z.array(messageSchema).default([]),
    myRole: z.enum(["prestador", "receptor", "participante"]).nullable().default(null),
    myStatus: z.enum(["pendiente", "aceptado", "retirado"]).nullable().default(null),
    isAuthor: z.boolean().default(false),
    chatOpen: z.boolean().default(false),
    canSend: z.boolean().default(false),
    canRecommend: z.boolean().default(false),
    alreadyRecommended: z.boolean().default(false),
    canOfferHelp: z.boolean().default(false),
    canRequestHelp: z.boolean().default(false),
    canJoinGroup: z.boolean().default(false),
    canResolve: z.boolean().default(false),
    canCancel: z.boolean().default(false),
    canReopen: z.boolean().default(false),
    canSharePhone: z.boolean().default(false),
    canEdit: z.boolean().default(false),
    canRetire: z.boolean().default(false),
    canRate: z.boolean().default(false),
    myRating: z
      .object({ score: z.number(), comment: z.string() })
      .nullable()
      .default(null),
  })
  .strict();

const feedSchema = z
  .object({
    items: z.array(feedItemSchema),
    needsLocation: z.boolean(),
  })
  .strict();

const sessionSchema = z
  .object({
    userId: z.string().uuid(),
    displayName: z.string(),
    zoneId: z.enum(zoneIds),
    zoneName: z.string(),
  })
  .strict();

export function parseFeed(value: unknown): FeedResult {
  const parsed = feedSchema.safeParse(value);
  if (!parsed.success) throw new YuntaError("unexpected");
  return parsed.data;
}

export function parseDetail(value: unknown): Detail {
  const parsed = detailSchema.safeParse(value);
  if (!parsed.success) throw new YuntaError("unexpected");
  return parsed.data;
}

export function parseSession(value: unknown): Session | null {
  if (value == null) return null;
  const parsed = sessionSchema.safeParse(value);
  if (!parsed.success) throw new YuntaError("unexpected");
  return parsed.data as Session;
}

export function parseFeedItem(value: unknown): FeedItem {
  const parsed = feedItemSchema.safeParse(value);
  if (!parsed.success) throw new YuntaError("unexpected");
  return parsed.data;
}
