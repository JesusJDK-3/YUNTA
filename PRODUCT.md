# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter and Dart for the Android app; Supabase anonymous Auth, PostgreSQL, Row Level Security and Realtime; foreground Android location permission; Flutter/Gradle APK builds; GitHub for source and milestone commits. The previous Vite PWA is archived under `legacy-web/` and is no longer the application being developed.

## Users

Neighbors who need to ask for or offer help, find local products and services, or organize support during an emergency. Users coordinate around their neighborhood and may have intermittent internet access.

## Product Purpose

Yunta connects neighbors who are close enough to help each other. Its wall lets a neighbor ask or offer help, publish a local product or service, and report an emergency. The app supports both one-to-one assistance and group coordination through case-specific chats.

## Positioning

Yunta organizes neighborhood help around approximate location and gives each case a coordination flow suited to its need: one accepted helper for an individual case, or a shared participant chat for a group case.

## Operating Context

- The app uses a persistent Supabase anonymous session on Android; registration collects a display name and a validated private phone number, without SMS during the demo.
- GPS suggests the user's location. A user may mark an approximate point on the map; the app never asks for a neighborhood name.
- Posts are discovered within 500 meters of the user's location. The public wall shows an approximate zone and distance; exact addresses may be shared during coordination when needed.
- A post can be drafted offline after the app has been opened online. It remains in private native storage until Supabase confirms the save; the app retries with the same post identifier while it is open and internet returns. Live chat requires internet.

## Capabilities and Constraints

- The wall contains Help, Products and services, and Emergencies.
- Individual cases allow one accepted helper at a time. Reopening releases that assignment and removes the prior helper's chat access.
- Group cases let active participants share a chat tied to that case. Repeated joins by the same neighbor do not create duplicate participants.
- The author controls editing and closing their post. The recipient of help or a service rates the provider after an individual case is resolved; recommending an advertisement is a separate action.
- Phone numbers and exact personal locations are private. Chat access and data changes are enforced by Supabase RLS, not only by interface controls.
- Do not place private profiles, exact coordinates, chat contents, or user data in public or shared device storage.
- The operative nearby radius is 500 meters. The 1 km distance in the source document is an illustrative example only.

## Brand Commitments

The product name is Yunta. Its existing Y mark is a brand commitment and must not be replaced by a heart. The Word document defines the original palette; the user later approved a white background, vivid but gentle yellow primary actions, and slow water-like motion, recorded in `docs/ESPECIFICACION.md`.

## Evidence on Hand

- The user supplied `YUNTA.docx`; its full functional requirements are transcribed in `docs/ESPECIFICACION.md`.
- The user supplied screenshots showing a Supabase Free organization and a Vercel Hobby account.
- Local Supabase URL and publishable key are configured for APK builds and excluded from Git. Never put a service-role key in the app or repository.
- No legal copy, analytics approval, user testimonials, or production posts were supplied. Do not invent them.

## Product Principles

- Keep discovery local and reveal only approximate location publicly.
- Match coordination to the case: one-to-one assignment or a shared emergency group.
- Keep private identifiers and data protected by database access rules.
- Treat offline posting as a local pending action; do not imply that the chat works offline.
