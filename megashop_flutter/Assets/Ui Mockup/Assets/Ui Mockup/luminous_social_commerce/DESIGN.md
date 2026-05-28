---
name: Luminous Social Commerce
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#4a4455'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#7b7487'
  outline-variant: '#ccc3d8'
  surface-tint: '#732ee4'
  primary: '#630ed4'
  on-primary: '#ffffff'
  primary-container: '#7c3aed'
  on-primary-container: '#ede0ff'
  inverse-primary: '#d2bbff'
  secondary: '#855300'
  on-secondary: '#ffffff'
  secondary-container: '#fea619'
  on-secondary-container: '#684000'
  tertiary: '#7d3d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#a15100'
  on-tertiary-container: '#ffe0cd'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#eaddff'
  primary-fixed-dim: '#d2bbff'
  on-primary-fixed: '#25005a'
  on-primary-fixed-variant: '#5a00c6'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#ffdcc6'
  tertiary-fixed-dim: '#ffb784'
  on-tertiary-fixed: '#301400'
  on-tertiary-fixed-variant: '#713700'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  price-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '800'
    lineHeight: 24px
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  safe-area-top: 59px
  safe-area-bottom: 34px
  edge-margin: 16px
  gutter: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The brand personality is high-end, energetic, and highly social. This design system bridges the gap between premium fashion editorial and seamless e-commerce utility. It targets a modern, trend-conscious audience that values speed, curation, and social proof. 

The visual style is **Modern Minimalism** with a touch of **Glassmorphism** specifically for video overlays. The interface emphasizes content—products and user-generated videos—through expansive whitespace and a restrained but punchy color palette. The emotional response should be one of "effortless discovery": a sophisticated, clean environment where the products are the hero and the purchase path is friction-free.

## Colors

The palette is driven by a vibrant **Vivid Purple** for primary brand elements and navigational cues. This is contrasted by a high-conversion **Amber** used exclusively for transactional actions (Add to Cart, Buy Now) and price points to ensure they pop against the clean background.

- **Primary (Purple):** Used for active navigation states, brand icons, and progress indicators.
- **Secondary/Accent (Amber):** The "Conversion Color." Reserved for buttons that move the user closer to purchase and for displaying currency.
- **Background:** Primarily pure white to maintain a high-end feel, with a subtle light gray for section headers or background containers.
- **Splash Exception:** The splash screen uses a deep purple gradient (#4C1D95 to #7C3AED) to establish brand presence immediately upon launch.

## Typography

This design system utilizes **Plus Jakarta Sans** for its modern, friendly, yet professional geometric qualities. 

The type hierarchy is designed for quick scanning in a mobile-first social environment. Headlines are bold with tight letter-spacing to feel impactful. Body copy remains legible with generous line heights. A specific "Price" style is defined to ensure costs are immediately visible when paired with the Amber accent color. On mobile, display sizes are slightly reduced to ensure no awkward line breaks occur on smaller viewports.

## Layout & Spacing

The layout follows a strict **Safe-Area Informed Grid**. 
- **Horizontal:** A consistent 16px margin is maintained on the left and right edges of the screen.
- **Vertical:** Content must respect the 59px top safe area (status bar/notches) and the 34px bottom safe area (home indicator).
- **Grid:** For product feeds, a 2-column fluid grid is used with a 12px gutter. For social feeds (Reels), content is edge-to-edge (0px margin) to maximize immersion.

Spacing follows a 4px/8px base-8 system for internal component padding, ensuring a rhythmic and organized appearance across all screen densities.

## Elevation & Depth

Depth is achieved through **Tonal Layers** and **Soft Ambient Shadows**. 
1. **Level 0 (Base):** Pure white or light gray background.
2. **Level 1 (Cards):** White surfaces with a very soft, diffused shadow (0px 4px 20px rgba(0,0,0,0.05)).
3. **Level 2 (Overlays/Modals):** Elements that float above the main UI use a stronger shadow and a slight backdrop blur (10px-20px) if they appear over video content.

For video overlays in the "Reels" section, use a dark-to-transparent linear gradient at the bottom to ensure white text and Amber buttons remain legible against varied video backgrounds.

## Shapes

The shape language is consistently **Rounded**, reflecting a modern and approachable social aesthetic.
- **Small Elements (Chips, Tags):** 8px radius.
- **Standard Elements (Buttons, Input Fields):** 12px radius.
- **Large Elements (Product Cards, Bottom Sheets):** 16px radius.

Interactive elements should never be sharp. The generous rounding communicates a "high-end tech" feel and aligns with the soft curves of modern mobile hardware.

## Components

### Buttons
- **Primary Action (Add to Cart/Buy Now):** Amber background (#F59E0B), white bold text, 12px-16px corner radius. High elevation on tap.
- **Secondary Action:** Ghost buttons with Purple outlines or light Purple subtle backgrounds.
- **Social Actions (Like, Comment):** Icon-based with white glyphs and subtle drop shadows when overlaid on video.

### Cards
- **Product Cards:** 16px radius, minimal border (1px #F3F4F6), or soft ambient shadow. Product image takes up the top 70% of the card.
- **Profile Cards:** Circular avatars with a 2px Purple ring to indicate "Active Stories" or "Live" status.

### Input Fields
- **Search & Text Entry:** 12px radius, light gray background (#F3F4F6), no border unless focused. When focused, use a 1.5px Purple border.

### Chips & Badges
- **Status Badges (New, Sale):** Small, 8px radius, high-contrast background colors.
- **Category Chips:** Pill-shaped, light gray background, switching to Purple background when selected.

### Navigation
- **Bottom Tab Bar:** Glassmorphic effect (backdrop blur) with a fixed 34px bottom safe area. Active icons are Purple; inactive are Medium Gray.