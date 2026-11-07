# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

React, Vite and CSS; Supabase anonymous Auth, PostgreSQL, Row Level Security and Realtime; a PWA service worker and IndexedDB outbox; GitHub and Vercel. The user delegated implementation and deployment within this stack.

## Users

Neighbors who need to ask for or offer help, find local products and services, or organize support during an emergency. Users coordinate around their neighborhood and may have intermittent internet access.

## Product Purpose

Yunta connects neighbors who are close enough to help each other. Its wall lets a neighbor ask or offer help, publish a local product or service, and report an emergency. The app supports both one-to-one assistance and group coordination through case-specific chats.

## Positioning

Yunta organizes neighborhood help around approximate location and gives each case a coordination flow suited to its need: one accepted helper for an individual case, or a shared participant chat for a group case.

## Operating Context

- The app uses a browser session created with Supabase anonymous Auth; registration collects a display name and a phone number whose format is validated, without SMS during the demo.
- GPS suggests the user's location. A user may choose the neighborhood manually and mark an approximate point.
- Posts are discovered within 500 meters of the user's location. The public wall shows an approximate zone and distance; exact addresses may be shared during coordination when needed.
- A post can be drafted offline after the app has been opened online. It remains local until Supabase confirms the save; the app retries with the same post identifier while it is open and internet returns. Live chat requires internet.

## Capabilities and Constraints

- The wall contains Help, Products and services, and Emergencies.
- Individual cases allow one accepted helper at a time. Reopening releases that assignment and removes the prior helper's chat access.
- Group cases let active participants share a chat tied to that case. Repeated joins by the same neighbor do not create duplicate participants.
- The author controls editing and closing their post. The recipient of help or a service rates the provider after an individual case is resolved; recommending an advertisement is a separate action.
- Phone numbers and exact personal locations are private. Chat access and data changes are enforced by Supabase RLS, not only by interface controls.
- Do not cache private profiles, exact coordinates, chat contents, or user data in a public service-worker cache.
- The operative nearby radius is 500 meters. The 1 km distance in the source document is an illustrative example only.

## Brand Commitments

The product name is Yunta. Its existing Y mark is a brand commitment and must not be replaced by a heart. The Word document defines the original palette; the user later approved a white background, soft sunny-yellow primary actions, and restrained liquid motion, recorded in `docs/ESPECIFICACION.md`.

## Evidence on Hand

- The user supplied `YUNTA.docx`; its full functional requirements are transcribed in `docs/ESPECIFICACION.md`.
- The user supplied screenshots showing a Supabase Free organization and a Vercel Hobby account.
- No Supabase project credentials, database password, Vercel domain, legal copy, analytics approval, user testimonials, or production data were supplied. Do not invent them.

## Product Principles

- Keep discovery local and reveal only approximate location publicly.
- Match coordination to the case: one-to-one assignment or a shared emergency group.
- Keep private identifiers and data protected by database access rules.
- Treat offline posting as a local pending action; do not imply that the chat works offline.
