# Cost Optimization Plan: Runway Gen-3 Alpha

## Overview
Runway Gen-3 Alpha is a high-cost API resource. Without strict controls, costs can scale linearly with users, making the business model unsustainable. This plan outlines a strategy to decouple user growth from generation costs.

## 1. The Global Asset Cache (Tier 1 Defense)
**Concept:** Never generate the same asset twice.
**Implementation:**
- **Prompt Hashing:** Create a deterministic SHA-256 hash of the prompt + parameters (seed, duration).
- **Lookup First:** Before calling `/gen3turbo/create`, the backend checks the database for `asset_hash`.
- **Global Reuse:** If User A generates a "Cyberpunk Katana", User B gets the *exact same video* if they request a "Cyberpunk Katana" in the same context.

## 2. The "Illusion of Choice" System (Tier 2 Defense)
**Concept:** Funnel users towards pre-generated outcomes.
**Implementation:**
- Instead of open-ended generation (e.g., "Generate *anything*"), the Logic Engine picks from a curated list of potential items.
- **Example:** The Director AI decides the next item is a *Key*, *Gun*, or *Datapad*. It forces the narrative to one of these paths where assets are likely already cached.

## 3. Client-Side Caching (Tier 3 Defense)
**Concept:** Bandwidth reduction.
**Implementation:**
- Flutter `HolographicDisplay` (as implemented in `video_widget.dart`) checks local filesystem storage.
- If `asset_123.webm` exists locally, no network request is made to the backend or CDN.

## 4. User Tiering Strategy
| Feature | Free User | Premium User (€1.99/wk) |
| :--- | :--- | :--- |
| **Asset Type** | Pre-Cached Only | On-Demand Generation (capped) |
| **Resolution** | 720p (Compressed) | 1080p/4K Upscaled |
| **Customization**| Generic "Spy" | Unique Avatar Generation |

## 5. Technical Implementation Details
- **CDN:** Store generated videos on AWS S3 / Cloudflare R2 behind a CDN (CloudFront).
- **TTL:** Set Time-To-Live for unused niche assets to save storage, but keep "Core Assets" (Generic Keys, Weapons) permanently.
- **Analysis:** Monitor "Cache Hit Rate". Target > 90% for standard gameplay elements.

## Summary
By combining **Strict Global Caching** with **Narrative Funneling**, we can reduce API calls by an estimated 90-95% compared to naive implementation.
