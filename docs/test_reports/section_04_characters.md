# Section 4 character implementation validation

Godot 4.7.1 stable was used for headless scene launch and automated checks. All 13 test runners passed. Both the main scene and the character gallery launched headlessly. `git diff --check` found no patch errors.

## Automated coverage

- Roster tests validate nine identities, 27 distinct role-valid patterns, star card capacity, duplicate rejection, order, and looping.
- Economy and shared-session tests validate atomic purchases, deployed-copy merge inheritance, chained upgrades to three stars, the star ceiling, and card capacity after upgrade.
- Gallery and UI tests validate authored visual variants, badges, ability cues, tag cue, victory cue, and the player-facing tournament flow.
- The remaining simulation, formation, match, bot, tournament, and loop test runners guard integration and deterministic results.
- The UI merge test uses seed `1` and the real opening shop offers, then deploys, chooses a card, buys two matching copies, and verifies the selected survivor and retained state.

The Godot editor import completed with exit code 0 and no script parse error. It printed a Windows safe-save warning while writing editor state to the temporary application-data directory.

## Manual acceptance pending

The developer should inspect the gallery at gameplay camera distance and play the main scene through a purchase, card choice, seed-1 merge, battle, results, and next round. Visual quality and usability have not yet been manually confirmed.
