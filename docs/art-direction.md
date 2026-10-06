# Art direction: "War Grimoire" (woodblock print)

## Seed-derived direction

Seed: a 256-character random alphanumeric string (used as inspiration only, not reproduced in the product).

What the string's patterns suggested:
- **Hard consonant clusters** (`K`, `C`, `P`, `T`, runs like `KKTbKk`, `CJAkCDBo`) suggested hard, stamped, carved edges. Something cut and printed, not airbrushed.
- **Zero and O side by side** (`B0`, `0OL`, `Bo93`) suggested the circle as the main sign. In this game that means the summoning ring and the ensō brush circle.
- **`Ix` / `xI` crossings** (`IxoIxE`) suggested crosshatching as the material texture.
- **Sparse digit pairs** (about one character in four) suggested sparse colour accents in a mostly two-tone field. The base is ink plus paper, with one hot accent.
- **The string ends in `LVL`.** Waves, levels and a ledger led to the numbered, ruled-column look of the HUD.

Derived palette: kozo paper `#EDE3CC`, sumi ink `#1E1B18`, vermilion seal `#D8452B` (the only hot accent), with indigo `#27466B` as the second printing block.
Layout skeleton: an asymmetric page. A heavy left illustration sits against a narrow right column of entries, like a grimoire margin.
Type: one brush face (Ma Shan Zheng) for all display text in both languages, and one serif (Noto Serif SC) for all body text.
Material and metaphor: a woodblock print. That means a sumi keyline, flat pigment blocks, slight misregistration, kento registration marks and paper fibre.

## 15 shallow directions

1. **War Grimoire.** The arena is a printed page of a battle spellbook. Every creature is an ink-stamped woodblock figure. *Device: a vermilion seal stamp marks you.*
2. **Brass Orrery.** The arena is a star chart and the waves are planets. *Device: concentric engraved rings.*
3. **Chalk Circle.** The battle is a summoning drawn on a slate board. *Device: smudged chalk sigils.*
4. **Cathedral Glass.** The arena is a rose window. *Device: lead-came outlines.*
5. **Arcana Deck.** Every wave is a drawn tarot card. *Device: tarot border frames.*
6. *(unreasonable)* **Doppler Radar of a Mana Storm.** *Device: a rotating green sweep.*
7. *(unreasonable)* **Transit Map of the Abyss.** The factions are subway lines. *Device: line roundels.*
8. *(unreasonable)* **Cross-stitch Sampler.** The battle is embroidered as it happens. *Device: X-stitch pixels.*
9. *(unreasonable)* **Mage Bank Ledger.** The war is double-entry bookkeeping. *Device: red-ink debit columns.*
10. *(unreasonable)* **Cyanotype Blueprint.** The battle is a sun-printed schematic. *Device: white lines on Prussian blue.*
11. **Ukiyo-e Night Raid.** *Device: seigaiha wave pattern.*
12. *(unreasonable)* **Petri Dish.** The enemies are bacterial colonies. *Device: agar rings.*
13. **Rune Tablet.** The arena is chiselled stone. *Device: carved grooves.*
14. *(unreasonable)* **Thermal Receipt.** Each run prints out as a till slip. *Device: dithered monochrome.*
15. **Illuminated Margin.** The battle is marginalia. *Device: a gold-leaf drop cap.*

## Pick: 1, War Grimoire

It fits the seed best: carved edges, circles, hatching and one hot accent. It is also the boldest choice for this genre. Survival arena shooters are almost always dark and neon. This one is printed on paper.

## Build brief (<=200 words)

**Aesthetic.** An Edo-period woodblock print of a magic war, made as a playable page. The look is flat and carved, with no glow.

**Palette.** Kozo paper, sumi ink and indigo carry the field. Vermilion appears only on the player, on HP and on the current choice. Enemy types each keep one traditional pigment: crimson, rokushō green, murasaki violet, gamboge and persimmon, so their attack telegraphs stay readable.

**Layout.** The menu is an asymmetric print. A big illustration with a vermilion sun sits on the left, and a vertical entry column sits on the right. The HUD uses rectangular title cartouches (the boxes on Hiroshige prints) at the page corners.

**Type.** Exactly two faces ship, on the menu and in the HUD alike. Display: Ma Shan Zheng (brush; its Latin is used for English titles too). Body: Noto Serif SC, Regular and Bold. Both are subset to the shipped strings; there is no fallback font. Numerals are large, set in the display face, in a ledger.

**Material.** Paper fibre, sumi keylines offset 2px from the colour block (misregistration), kento corner marks. The ensō is the menu's sign only. In battle everything is cut, not brushed: walls are keylines with diagonal gouge hatching, rings are carved (three arcs with chipped gaps and gouge ticks), the sword is a single vermilion crescent, and the wave counter is a white-character (白文) seal with a chipped edge and a broken carved border.

**Forbidden.** Gradients without a woodblock reason (bokashi is allowed), glows, glassmorphism, rounded cards, neon cyan, floating geometric confetti and centred-panel menus.
