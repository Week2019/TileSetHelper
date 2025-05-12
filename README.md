# TileSetHelper

This plugin is designed to quickly synchronize TileSet configurations (such as physics layers, terrain, navigation, and other properties) within the Godot Editor. It supports copy-and-paste operations across different TileSet sources. Through a dialog interface, users can easily batch-apply copied property configurations.

# Usage Instructions

Opening the TileMap Editor Window
Select a TileMapLayer node in the scene (must be linked to a TileSet resource).

Ensure the TileSet property of the TileMap is correctly set.

Launching the Sync Tool
In the TileSet editor's top toolbar, locate the new Sync button and click it.

A synchronization configuration dialog will appear.

Interface Overview
The dialog includes the following tabs (automatically displayed based on TileSet configuration):

Source: Select the current TileSet source for operations.

Physic: Manage physics layer properties (collision shapes, velocity, etc.).

Terrain: Configure terrain modes and tile adjacency rules.

Navigation: Synchronize navigation polygons.

Custom Data: Copy and paste custom data layer values.

Occluder: Handle occlusion polygons.

Copying Properties
Navigate to the relevant tab (e.g., Physic).

Select a source (e.g., a specific physics layer).

Click the Copy button for that row to save the current configuration.

Pasting Properties
Switch to the target source (using the Source tab).

Select the desired layer or terrain in the corresponding tab.

Click the Paste button to apply the copied configuration to the current sourc
