#!/usr/bin/env python3
"""Enable Blender's official MCP add-on and configure GPU rendering."""

import os
import traceback

import addon_utils
import bpy


ADDON_MODULE = "blender_mcp_addon"
READY_FILE = "/tmp/blender_gui_ready"


def configure_gpu() -> list[str]:
    """Enable available Cycles GPU devices, falling back cleanly to CPU."""
    scene = bpy.context.scene
    # Blender 5.2 renamed the EEVEE identifier back to BLENDER_EEVEE.
    eevee = "BLENDER_EEVEE" if "BLENDER_EEVEE" in {
        item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items
    } else "BLENDER_EEVEE_NEXT"
    scene.render.engine = eevee

    enabled_devices: list[str] = []
    cycles = bpy.context.preferences.addons.get("cycles")
    if cycles is None:
        addon_utils.enable("cycles", default_set=True, persistent=True)
        cycles = bpy.context.preferences.addons.get("cycles")

    if cycles is None:
        print("Cycles add-on is unavailable; EEVEE remains enabled")
        return enabled_devices

    preferences = cycles.preferences
    for backend in ("OPTIX", "CUDA", "HIP", "METAL", "ONEAPI"):
        try:
            preferences.compute_device_type = backend
            preferences.get_devices()
        except (TypeError, RuntimeError):
            continue

        devices = [device for device in preferences.devices if device.type != "CPU"]
        if not devices:
            continue
        for device in preferences.devices:
            device.use = device.type != "CPU"
            if device.use:
                enabled_devices.append(f"{device.type}:{device.name}")
        scene.cycles.device = "GPU"
        print(f"Cycles backend: {backend}; devices: {enabled_devices}")
        return enabled_devices

    scene.cycles.device = "CPU"
    print("No supported Cycles GPU found; using CPU")
    return enabled_devices


def setup_blender_mcp() -> None:
    print(f"Blender version: {bpy.app.version_string}")
    print(f"Online access: {bpy.app.online_access}")
    gpu_devices = configure_gpu()

    addon_utils.enable(ADDON_MODULE, default_set=True, persistent=True)
    addon = bpy.context.preferences.addons.get(ADDON_MODULE)
    if addon is None:
        raise RuntimeError(f"Failed to enable {ADDON_MODULE}")

    addon.preferences.host = "localhost"
    addon.preferences.port = 9876
    result = bpy.ops.blmcp.server_start()
    if "FINISHED" not in result:
        raise RuntimeError(f"Official MCP bridge failed to start: {result}")

    with open(READY_FILE, "w", encoding="utf-8") as ready_file:
        ready_file.write("ready\n")
    print("Official Blender MCP bridge ready on localhost:9876")
    print(f"Cycles GPU devices: {gpu_devices or 'none'}")


if __name__ == "__main__":
    try:
        setup_blender_mcp()
    except Exception:
        traceback.print_exc()
        try:
            os.unlink(READY_FILE)
        except FileNotFoundError:
            pass
        raise
