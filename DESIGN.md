# Yunta Android design system

## Direction

Use the user-selected Stitch “Vecindad Conectada” screens as visual reference
and Material 3 as the Android interaction system. The app should feel calm,
neighborly, fresh, and easy to scan. Preserve the existing Y logo and real app
content; Stitch names, photos, neighborhoods, maps, reviews, and posts are sample
material and must never become seeded user data.

## Color tokens

| Role | Color | Use |
| --- | --- | --- |
| Canvas | `#F4FAFF` | Main screen background |
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
