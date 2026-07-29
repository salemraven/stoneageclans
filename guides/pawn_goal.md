# Stone Age Clans - Character Rendering & Animation System

Version 1.0

## Design Goals

The character system is designed around five core principles:

1. **Large populations** (hundreds of characters simultaneously)
2. **Highly customizable appearance** through layered sprites
3. **Genetics-driven morphology** so characters are recognizable as individuals
4. **Procedural animation** instead of traditional sprite sheets
5. **Performance first**, allowing future optimization by baking layers into textures if needed

The visual goal is to combine the readability and scalability of RimWorld with much richer facial features and individual identity.

---

# Character Philosophy

Characters are not animated using sprite sheets.

Instead, each character is assembled from modular sprite layers attached to procedural animation pivots.

Movement comes from:

* body bobbing
* arm swing
* weapon motion
* head movement
* hand animation
* particles
* shadows

The player should instantly recognize characters by their silhouette and facial structure rather than by clothing alone.

---

# Character Hierarchy

```text
CharacterRoot

├── Shadow

├── BodyPivot
│
│   ├── Torso
│   ├── Chest Hair
│   ├── Body Paint
│   ├── Tattoos
│   ├── Scars
│   ├── Necklaces
│   ├── Fur Clothing
│   ├── Armor
│   ├── Backpack
│   ├── Cloak
│
│   ├── HeadPivot
│   │
│   │   ├── Head Base
│   │   ├── Brow Ridge
│   │   ├── Eyes
│   │   ├── Eyebrows
│   │   ├── Nose
│   │   ├── Mouth
│   │   ├── Teeth
│   │   ├── Beard
│   │   ├── Hair
│   │   ├── Face Paint
│   │   ├── Tattoos
│   │   ├── Earrings
│   │   ├── Feathers
│   │   ├── Helmet
│
│   ├── LeftArmPivot
│   │
│   │   ├── Upper Arm
│   │   ├── Forearm
│   │   ├── Hand
│
│   ├── RightArmPivot
│   │
│   │   ├── Upper Arm
│   │   ├── Forearm
│   │   ├── Hand
│   │   │
│   │   └── Equipped Item
│   │
│   └── Effects
│       ├── Blood
│       ├── Fire
│       ├── Dust
│       └── Status Effects
```

---

# Legs

Characters do not have visible legs.

Instead, walking is communicated through:

* torso bobbing
* shoulder movement
* arm swing
* hand movement
* weapon movement
* dust particles
* shadow movement

This creates a visual style similar to RimWorld while reducing art production significantly.

---

# Hands

Hands are independent sprites.

Weapons attach to hands rather than arms.

```text
Arm

↓

Hand

↓

Weapon
```

Benefits

* Weapons naturally rotate.
* Open and closed hands become possible.
* Carrying objects is easy.
* Gloves and wraps become cosmetic layers.
* Future climbing and crafting animations become much easier.

---

# Procedural Animation

Every character shares the same procedural animation system.

Walking

* torso bob
* arm swing
* slight head bounce
* weapon sway

Idle

* breathing
* subtle weight shift
* occasional head turn

Combat

* shoulder rotation
* arm extension
* wrist rotation
* recoil
* recovery

Harvesting

* repeated arm motion
* torso lean

Eating

* hand raises food
* head tilts

Throwing

* torso twist
* arm windup
* follow-through

No sprite sheet animation is required.

---

# Facial System

The face is completely modular.

Major facial components:

* skull
* brow ridge
* eyes
* eyebrows
* nose
* mouth
* beard
* hair
* ears

Every part can have multiple variants.

---

# Genetics

Every character stores a genotype.

The genotype determines both gameplay statistics and visual appearance.

Example genes:

Body

* height
* shoulder width
* neck thickness
* muscle mass
* body fat
* arm length
* hand size

Head

* skull width
* forehead slope
* brow ridge
* jaw width
* chin size
* cheekbone width
* nose width
* nose projection
* ear size

Hair

* beard density
* hair style
* hair color
* body hair

Skin

* pigmentation
* freckles
* wrinkle tendency

---

# Human Species

Species are not simply different textures.

Each species defines default genetic ranges.

Example

Modern Human

* smaller brow ridge
* prominent chin
* longer limbs
* narrower face

Neanderthal

* massive brow ridge
* wider nose
* thicker neck
* broader shoulders
* heavier jaw
* shorter stockier build
* larger hands

Hybrids naturally inherit intermediate traits.

No special artwork is required for hybrids.

---

# Visual Identity

Characters should be recognizable even while zoomed out.

Priority of recognition:

1. silhouette
2. body size
3. hair
4. beard
5. head shape
6. clothing
7. weapon

When zoomed in, additional details become visible:

* scars
* missing teeth
* tattoos
* paint
* jewelry
* wrinkles
* facial asymmetry

---

# Skin Color

Skin should not require duplicate artwork.

A shader or color overlay determines:

* skin pigmentation
* sunburn
* dirt
* bruising
* sickness
* frostbite
* blood loss

All skin sprites use grayscale source textures.

---

# Clothing

Clothing is entirely layered.

Examples

Torso

* leather vest
* fur cloak
* woven shirt
* armor

Head

* feather crown
* wolf hood
* bone helmet

Hands

* wraps
* gloves

Accessories

* necklaces
* earrings
* belts
* pouches

Every clothing layer follows the body procedurally.

No clothing animation frames exist.

---

# Equipment

Weapons attach to hands.

Possible equipment:

* spear
* club
* axe
* bow
* torch
* shield
* basket
* carcass
* child

Items inherit hand transforms automatically.

---

# Animation Layers

Animations affect pivots instead of sprites.

Examples

Walk

BodyPivot

* vertical bob
* slight rotation

HeadPivot

* counter-balance

ArmPivots

* swing

Hand

* grip

Weapon

* secondary sway

Because every cosmetic layer is a child of these pivots, all equipment and clothing animate automatically.

---

# Performance Strategy

The initial implementation uses layered Sprite2D nodes.

Advantages

* easy customization
* rapid iteration
* flexible equipment
* genetics remain modular

If necessary, future optimization can bake appearance layers into combined textures after character generation.

This would reduce draw calls while preserving customization.

---

# Future Features

The system is designed to support:

* aging
* wrinkles
* growing beards
* changing hairstyles
* body paint application
* scars gained during combat
* amputations
* missing eyes
* broken noses
* facial tattoos
* jewelry
* seasonal clothing
* tribe-specific appearance
* inherited genetics
* racial hybridization
* diseases affecting appearance
* emotional facial expressions

The goal is for every character to become visually identifiable and tell a story through their appearance, while remaining efficient enough to support large prehistoric settlements.
