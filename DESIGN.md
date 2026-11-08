# AYNI Android design system

## Direction

Use the user-selected Stitch “Vecindad Conectada” screens as visual reference
and Material 3 as the Android interaction system. The app should feel calm,
neighborly, fresh, and easy to scan. Use the supplied AYNI wordmark and Andean spiral icon with real app
content; Stitch names, photos, neighborhoods, maps, reviews, and posts are sample
material and must never become seeded user data.

## Color tokens

| Role | Color | Use |
| --- | --- | --- |
| Canvas | `#F4FAFF` | Secondary screens |
| Registration canvas | `#F1FAF5` | Registration flow |
| Home canvas | `#BCE8C4` | Mint-green neighborhood wall |
| Surface | `#FBFEFD` / `#FFFFFF` | Cards, forms, sheets |
| Ink | `#1A5268` | Brand text and icons |
| Strong ink | `#001F2A` | Headings and text on aqua actions |
| Primary | `#006971` | Navigation, selected controls, focus |
| Primary action | `#05A8B5` | Main buttons and active highlights |
| Soft blue | `#E7F6FF` | Secondary information surfaces |
| Soft mint | `#E3F5EF` | Supporting surfaces and pills |
| Emergency | `#A13D42` | Emergency and error states only |
| Success | `#27724A` | Real available or completed states |

Use dark ink on bright aqua actions for readable contrast. Keep small metadata
compact but legible; reserve the brightest accent for selected and actionable
states. Type follows the reference scale through Android's native sans face.

## Components and motion

- Use Material 3 controls, touch targets of at least 48 dp, and system Back.
- Cards use white surfaces, subtle outlines, 16–22 dp corners, and no stacked
  decorative elevation. Pills are for compact filters and status.
- Preserve the 500 m radius, private phone and exact coordinates, real GPS/map
  behavior, and Supabase-backed posts, notifications, and chat.
- Keep the existing slow registration bubbles and reduced-motion handling.
  Use Material ripples and short state transitions elsewhere; do not animate
  feed content or messages continuously.

## Screen compositions

- Registration centers the circular AYNI mark, community badge, and welcome copy
  above separate profile and location panels. It shows the real 500 m map only
  after GPS or a map point is selected, never a neighborhood name.
- The wall uses the approved mint-green canvas, a compact AYNI/radius/profile
  header, greeting and a real location-source label, three horizontal category
  filters with live counts, tappable white announcement cards, and a centered
  publish action above Muro/Casos navigation. Notifications stay in the header.
- Emergency cards use the brick-red alert treatment and may show an attached
  photo. Post photos are optional and use private Supabase Storage. Never show a
  neighborhood name, street label, invented avatar, sample review, or sample post.
- The publish sheet stays grouped by category. Its editor uses separate cards
  for post content, coordination mode, and the real post location, with the
  submit action anchored at the bottom.
- Detail follows the selected reference with the real post type, relative
  publish time, title, author, description, mode, participants, approximate
  distance, and live status. Keep photos optional and show only eligible
  coordination actions; show the author's pending support offers immediately
  after the summary, with the whole offer card clearly tappable to accept and
  open chat. Omit fake case IDs, unrecorded duration, protected community
  perimeter, map, and delivery zone. Eligible recipients can open the optional
  rating flow after an individual case is resolved.
- Chat uses a participant header, an actual case-status strip, and a working
  details action. Individual chats show the real counterpart name; group chats
  show the real participant count. Never imply online presence, encryption, or
  read receipts when those features are not implemented.
- Chat history is chronological, labels incoming messages with the real sender
  name, and keeps the composer fixed below the scrollable history. The author
  can finish an active case from the status strip. Do not show a meeting-point
  map unless a real agreed point is stored for that case. Reopening an
  individual case starts a separate conversation so a new helper cannot see
  the previous helper's private messages.
- Rating asks for an optional 1–5 score and comment; eligibility and storage
  remain enforced by the existing Supabase RPC.

For registration, follow the user's latest reference: pale mint canvas,
centered circular AYNI mark, community badge, separate white profile and location
panels, country-code badge, privacy notes, actual 500 m map preview, fixed
primary action, and a short working tutorial link. Use the AYNI wordmark and Andean spiral; do not copy
the heart mark, sample neighborhood name, or sample city from the reference.
