---
name: Academic Precision
colors:
  surface: '#f9f9ff'
  surface-dim: '#d8d9e2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3fc'
  surface-container: '#ecedf6'
  surface-container-high: '#e6e8f1'
  surface-container-highest: '#e1e2eb'
  on-surface: '#191c22'
  on-surface-variant: '#414753'
  inverse-surface: '#2e3037'
  inverse-on-surface: '#eff0f9'
  outline: '#727784'
  outline-variant: '#c1c6d5'
  surface-tint: '#005cba'
  primary: '#004e9f'
  on-primary: '#ffffff'
  primary-container: '#0066cc'
  on-primary-container: '#dfe8ff'
  inverse-primary: '#aac7ff'
  secondary: '#5f5e60'
  on-secondary: '#ffffff'
  secondary-container: '#e1dfe1'
  on-secondary-container: '#636264'
  tertiary: '#883700'
  on-tertiary: '#ffffff'
  tertiary-container: '#af4900'
  on-tertiary-container: '#ffe3d6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#00458e'
  secondary-fixed: '#e4e2e4'
  secondary-fixed-dim: '#c8c6c8'
  on-secondary-fixed: '#1b1b1d'
  on-secondary-fixed-variant: '#474649'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb692'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#793000'
  background: '#f9f9ff'
  on-background: '#191c22'
  surface-variant: '#e1e2eb'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.2'
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: '1.4'
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: '1.4'
  label-lg:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: '1.2'
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: '1.1'
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  container-margin: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-padding: 48px
---

## Brand & Style

The design system adopts a rigorous, high-fidelity aesthetic inspired by modern editorial standards and the Apple Design Language. It targets students and professionals who value clarity, focus, and efficiency. The interface avoids unnecessary ornamentation, relying instead on a "Parchment and Ink" philosophy where content is elevated through structural hierarchy rather than decorative elements.

The style is **Modern/Corporate** with a focus on **Minimalism**. It uses a sophisticated interplay of light backgrounds and deep, authoritative dark tiles to create a rhythmic visual flow. The emotional response is one of calm productivity and intellectual reliability.

## Colors

This design system utilizes a structured monochromatic foundation punctuated by a singular "Action Blue" for interactivity. 

- **Primary Canvas:** Use `#ffffff` for the main workspace and active card fronts.
- **Parchment:** Use `#f5f5f7` for secondary backgrounds and section headers to provide subtle contrast.
- **Ink System:** Text uses varying opacities of black (Ink) to establish hierarchy.
- **Dark Accents:** Use `surface-tile-1` and `surface-tile-3` for high-contrast product tiles and immersive study modes. 
- **Action:** `#0066cc` is reserved strictly for primary buttons, links, and active states.

## Typography

The typography system utilizes Inter (as a high-fidelity proxy for SF Pro) with a focus on tight leading and negative letter-spacing for headlines to mimic premium editorial layouts.

- **Headlines:** Use tight line heights (1.1x to 1.2x) to create dense, impactful blocks of text.
- **Body:** Standardized at 17px for optimal readability on mobile devices, following HIG accessibility guidelines.
- **Labels:** Use uppercase for category headers and utility labels to provide clear distinction from body content.

## Layout & Spacing

The layout follows a strict **Fluid Grid** model with high horizontal margins to focus the eye on the center of the screen.

- **Mobile:** 20px side margins, 16px gutters.
- **Desktop:** Max-width container of 1200px, centered.
- **Rhythm:** Utilize alternating background colors (`canvas` vs `parchment`) to segment long-form content. Transitions between these colors should happen at section boundaries without visible borders.
- **Vertical Spacing:** Use 48px increments for top/bottom section padding to ensure the "parchment" feel of the layout.

## Elevation & Depth

Visual hierarchy is achieved through **Tonal Layers** and **Hairline Borders** rather than traditional shadows.

- **Surfaces:** Use a 0.5pt or 1px hairline border (`rgba(0,0,0,0.1)`) for all light-themed cards and inputs.
- **The Study Shadow:** Only the active flashcard during a study session receives depth. Use `rgba(0,0,0,0.22)` with a 3px horizontal, 5px vertical offset, and 30px blur.
- **Active States:** Interactive elements should feel grounded. Use subtle shifts in background opacity (e.g., 90% opacity on press) rather than lifting the element.

## Shapes

The shape language is a mix of high-radius "Pill" shapes for interactive elements and structured "Apple-style" rounded rectangles for containers.

- **Buttons:** All buttons must be fully pill-shaped (100px or higher radius).
- **Cards:** Utility cards must use `rounded-lg` (18px) to provide a friendly but structured enclosure.
- **Inputs:** Search and text fields use a 12px corner radius to differentiate them from primary action buttons.

## Components

### Buttons
- **Primary:** Pill-shaped, `#0066cc` background, white text.
- **Secondary:** Pill-shaped, `parchment` background, `#0066cc` text.
- **Ghost:** Pill-shaped, transparent background, `#0066cc` text, no border.

### Product Tiles
- **Dark Tile:** `surface-tile-1` background, white typography. High contrast, used for featured decks or active classes.
- **Utility Card:** `canvas` background, 1px hairline border, 18px corner radius.

### Inputs
- **Search Input:** 12px radius, `parchment` background, leading icon in `inkMuted48`. No border when focused, use a subtle `Action Blue` outer glow if necessary for accessibility.

### Navigation
- **Bottom Bar:** 88px height (iOS standard). Clear frosted glass effect (Backdrop Blur) or solid `canvas` with a 0.5pt top border. Icons are 24px, using `inkMuted48` for inactive and `Action Blue` for active states.

### Cards
- **Active Flashcard:** White `canvas`, 18px radius, specific `product-shadow`. Front/Back transitions should be vertical flips.