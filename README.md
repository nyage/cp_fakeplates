# cp_fakeplates - License Plate Hiding Script for FiveM

This repository contains the **cp_fakeplates** script, a FiveM script developed by the **CodePeak DEVELOPMENT TEAM** that allows players to hide and reveal vehicle license plates, as well as interact with NPCs to perform these actions. The script integrates with **ox_target** for vehicle interactions and uses **ESX** framework for server-client communication.

## Features
- Interact with NPCs to hide/reveal vehicle license plates.
- NPC will approach the selected vehicle and initiate the hiding process.
- Configurable cooldown and duration for how long plates remain hidden.
- Realistic animations for NPC actions.
- Integrated with **ox_target** and **ESX Framework**.

## Prerequisites

To use this script, you need the following:
- [FiveM server](https://fivem.net/)
- [ESX Framework](https://esx-framework.org/)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## Installation

1. Download the repository and place it in your server's `resources` folder.
   
2. Add the following line to your `server.cfg`:
   ```bash
   start cp_fakeplates
