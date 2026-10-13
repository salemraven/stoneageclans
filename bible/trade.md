# Trade

**Status:** Not built. Design only.  
**Related:** `scripts/ai/clan_brain.gd` (`get_neighbor_claims()`), `bible/raid.md`

The neighbor list is the road. Trade is a later trip along that road.

## Network

A clan reads `get_neighbor_claims()`.

- The 3 closest camps are always neighbors.
- Slots 4 through 10 fill only when that camp is within 3 times the distance to the nearest neighbor.
- The list stops at 10.
- The clan that carries the goods uses its own list. A far camp can still walk to a stronger neighbor who does not list him back.

Raid and defense use this same list. Trade does not add a second one.

## The trip

One small group leaves home with goods, walks to one neighbor, asks for goods in return, and walks home.

- No prices, no market, no coins.
- They do not trade with a neighbor they are already raiding.
- They do not start a raid against a neighbor while a trade group is on the way there.

## Later, still the same trip

Protection is not a new system. A weaker clan carries goods to a stronger neighbor and asks not to be raided. Strong versus weak is the living fighter count already on that neighbor.

A clansman who leaves and plants a nearby claim shows up on the next neighbor refresh. He does not need a special trade link.
