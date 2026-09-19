# Courseplay & AutoDrive: Smart Lights (FS25_AISmartLights)

[![Game](https://img.shields.io/badge/Game-Farming%20Simulator%2025-green.svg)](https://www.farming-simulator.com/)
[![Courseplay Add-on](https://img.shields.io/badge/Add--on%20for-Courseplay-blue.svg)](https://github.com/Courseplay/Courseplay_FS25)
[![AutoDrive Add-on](https://img.shields.io/badge/Add--on%20for-AutoDrive-blue.svg)](https://github.com/Stephan-S/FS25_AutoDrive)
[![RMS Add-on](https://img.shields.io/badge/Add--on%20for-Realistic%20Mechanical%20Systems-orange.svg)](https://github.com/Squallqt/FS25_RealisticMechanicalSystems)
[![GitHub Repository](https://img.shields.io/badge/GitHub-FS25__AISmartLights-181717?logo=github)](https://github.com/exekx/FS25_AISmartLights)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/Version-1.0.0.0-brightgreen.svg)](https://github.com/exekx/FS25_AISmartLights/releases)

**Automated Battery Protection for Realistic Mechanical Systems (RMS)**  
*Author: [exekx](https://github.com/exekx)*

---

## Overview

When playing Farming Simulator 25 with **Courseplay**, **AutoDrive**, and **Realistic Mechanical Systems (RMS)**, machinery operating under automated drivers frequently turns off engines while waiting at waypoints, waiting for combines, waiting to load or unload, or during fuel-saving idle stops.

However, neither Courseplay nor AutoDrive manages vehicle work lights or headlights. In **RMS**, running headlights and work lights draw an electrical current between **20A and 27A**. When the engine is off, the alternator produces **0A**, causing the tractor's battery to discharge to 0% in a very short time. Once drained, the starter motor cannot crank the engine, leaving the vehicle completely stranded in the field and requiring jumper cables to start again.

**Smart Lights** is a lightweight, zero-overhead add-on that completely eliminates this issue by automatically coordinating lights with automated engine states.

---

## How It Works

1. **Engine Shutdown (Battery Protection):**
   - When an AI vehicle driven by **Courseplay** or **AutoDrive** stops its motor (`stopMotor`), Smart Lights intercepts the event.
   - It captures and saves the active lighting configuration (headlights, front/rear work lights, and beacon lights).
   - It immediately turns off all active lights and beacons (`setLightsTypesMask(0)`).
   - In RMS, electrical load drops from ~25A back down to the vehicle's resting quiescent state of 0.5A, preserving 100% battery capacity indefinitely.

2. **Engine Restart (Seamless Restoration):**
   - As soon as the unloader or field worker restarts its engine (`startMotor`) to resume transit or fieldwork, Smart Lights restores the exact saved lighting mask and beacon configuration.
   - If an idle vehicle stood parked until nightfall, headlights are automatically engaged upon starting up so workers never navigate in pitch darkness.

3. **Silent Background Execution:**
   - Operates unobtrusively in the background without spamming your HUD or screen with popups. All status updates are written cleanly to `log.txt`.

4. **Zero Interference with Player Driving:**
   - Only triggers on machinery operating under Courseplay or AutoDrive control. Your manual control over lights when operating vehicles yourself remains completely untouched.

---

## Key Features

- **Automated RMS Battery Protection:** Stops catastrophic battery drainage caused by idle AI machinery leaving lights on.
- **Bi-Directional State Restoration:** Preserves and restores exact light levels (front work lights, rear work lights, beacons, high beams).
- **Darkness Fallback:** Automatically switches on headlights if an engine starts in the dark or overnight.
- **Universal Multi-Language Support:** Includes 27 built-in language translations matching standard Courseplay localizations.
- **Multiplayer & Dedicated Server Compatible:** Fully synchronized across server and clients using standard GIANTS network events.
- **Ultra-Lightweight & Clean:** Pure event-driven hooks on engine start and stop with zero per-frame performance cost.

---

## Requirements

- **Farming Simulator 25** (Version 1.2 or higher)
- **Courseplay** ([FS25_Courseplay](https://github.com/Courseplay/Courseplay_FS25))
- **AutoDrive** ([FS25_AutoDrive](https://github.com/Stephan-S/FS25_AutoDrive))
- **Realistic Mechanical Systems** ([FS25_RealisticMechanicalSystems](https://github.com/Squallqt/FS25_RealisticMechanicalSystems)) *(Optional, but primary beneficiary)*

---

## Installation

1. Download the latest `FS25_AISmartLights.zip` from the [Releases](https://github.com/exekx/FS25_AISmartLights/releases) section.
2. Place the `.zip` file directly into your Farming Simulator 25 mods directory:
   - **Windows:** `Documents\My Games\FarmingSimulator2025\mods\`
   - **Mac:** `~/Library/Application Support/FarmingSimulator2025/mods/`
3. Launch the game and ensure **Courseplay & AutoDrive: Smart Lights** is checked in the mod activation screen.

---

## Credits & Linked Projects

- **Add-on Author:** `exekx` ([GitHub Profile](https://github.com/exekx))
- **Add-on Repository:** [exekx/FS25_AISmartLights](https://github.com/exekx/FS25_AISmartLights)
- **Courseplay for FS25:** Developed and maintained by the **Courseplay.devTeam** ([Courseplay GitHub](https://github.com/Courseplay/Courseplay_FS25))
- **AutoDrive for FS25:** Developed and maintained by **Stephan-S** ([AutoDrive GitHub](https://github.com/Stephan-S/FS25_AutoDrive))
- **Realistic Mechanical Systems (RMS):** Developed by **Squallqt** ([RMS GitHub](https://github.com/Squallqt/FS25_RealisticMechanicalSystems))
- **License:** Distributed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.

---

## Support the Project

If you find this add-on helpful and want to support ongoing mod development:

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/exekx)