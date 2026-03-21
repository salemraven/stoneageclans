#!/bin/bash
# Woman transport test: only player, land claim + ovens + 2 women (no cavemen)
# Tests: women move items to ovens, occupy, produce bread, move bread to land claim

/Applications/Godot.app/Contents/MacOS/Godot \
  --path /Users/macbook/Desktop/stoneageclans \
  --woman-test \
  --debug \
  --log-console \
  --verbose
