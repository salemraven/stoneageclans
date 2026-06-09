Stone Age Clans — Pixel Character Generator &
Editor
Project Overview
Stone Age Clans requires a reusable 2D pixel-art character generator and editor built in Godot 4.x. The
system will allow real-time customization of body proportions and visual features, and will also be used
to procedurally generate large numbers of unique NPC characters for gameplay.
Primary Goals
• Build a real-time pixel character editor with adjustable body proportions
• Support modular, cutout-style pixel characters using bones
• Allow both manual customization and procedural generation
• Maintain pixel-perfect visual quality at all times
Engine & Technical Stack
• Godot 4.x
• Skeleton2D + Bone2D cutout animation
• Pixel-perfect rendering rules (integer scaling and snapping)
Character Rig Requirements
Reusable base rig for 64x64 pixel characters with segmented limbs:
• Upper arm, lower arm, hand
• Upper leg, lower leg, foot
• Torso, neck, head attachment
• Optional spine/posture control
Rig must support:
• Adjustable limb length via bone lengths
• Adjustable limb thickness via limited scaling
• Overall height via bone spacing
• Slight posture/hunch adjustment
Editable Parameters (Editor Sliders)
• Height
• Torso width
• Arm length
• Arm thickness
• Leg length
• Leg thickness
• Neck length
• Posture (upright to hunched)
Variant Sprite System
• Head/skull variants
• Brow ridge variants
• Jaw variants
• Hands and feet variants
• Hair styles
• Body hair overlays
Character Editor UI
• Live sliders controlling proportions
• Dropdowns for variant selection
• Real-time visual updates
• Save/load character presets
Procedural Generation Support
The same parameter system must support automatic generation of varied NPC characters using
presets and randomized values, ensuring large populations of visually distinct characters.
Pixel Art Constraints
• Preserve crisp pixel edges
• Avoid blurry non-integer scaling
• Limit deformation ranges to protect silhouettes
Deliverables
• Reusable Skeleton2D character rig scene
• Parameter-driven character system
• Variant sprite swapping system
• Example character editor UI scene
• Documentation for extending and maintaining the system
Non-Goals
• No procedural pixel-level sprite editing
• No automatic redrawing of silhouettes
• No 3D systems or mesh morphing
Client-Provided Art
• Base limb sprites
• Head and facial feature variants
• Hair and body hair overlays
Success Criteria
The system is successful if characters can be customized live, silhouettes remain clean at all
proportions, and large numbers of visually distinct pixel characters can be generated efficiently.