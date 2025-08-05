#!/usr/bin/env python3
"""
Blender MCP Setup Script
BlenderのMCPアドオンを有効化し、TCPサーバーを起動する
"""

import bpy
import addon_utils
import time
import sys
import traceback
import os

def configure_blender_opengl():
    """OpenGL設定の調整"""
    try:
        # OpenGLバージョンを強制的に下げる
        bpy.context.preferences.system.gl_texture_limit = 'CLAMP_8192'
        bpy.context.preferences.system.anisotropic_filter = 'FILTER_0'
        
        # レンダリング設定をCPUに変更（GPUが不安定な場合）
        scene = bpy.context.scene
        scene.render.engine = 'BLENDER_EEVEE'
        
        # ビューポート設定を軽量化
        for screen in bpy.data.screens:
            for area in screen.areas:
                if area.type == 'VIEW_3D':
                    for space in area.spaces:
                        if space.type == 'VIEW_3D':
                            space.shading.type = 'SOLID'
                            space.overlay.show_overlays = False
        
        print('🔧 OpenGL settings configured for compatibility')
        
    except Exception as e:
        print(f'⚠️ OpenGL configuration warning: {e}')

def setup_blender_mcp():
    """Blender MCPアドオンの設定とTCPサーバーの起動"""
    
    print('🔧 Setting up Blender MCP addon...')
    
    try:
        # OpenGL設定を最初に調整
        configure_blender_opengl()
        
        # Enable the addon
        result = addon_utils.enable('blender_mcp', default_set=True, persistent=True)
        print(f'✅ Addon enable result: {result}')
        
        # Wait for addon to load
        print('⏳ Waiting for addon to load...')
        time.sleep(3)
        
        # Check if addon loaded properly
        enabled_addons = bpy.context.preferences.addons.keys()
        print(f'📋 Enabled addons: {list(enabled_addons)}')
        
        if 'blender_mcp' in enabled_addons:
            print('✅ Addon loaded successfully')
            
            # Check available operators
            print('🔍 Checking available MCP operators...')
            mcp_ops = [op for op in dir(bpy.ops) if 'blendermcp' in op.lower()]
            print(f'🔧 Available MCP operators: {mcp_ops}')
            
            # Start the MCP server
            if hasattr(bpy.ops, 'blendermcp') and hasattr(bpy.ops.blendermcp, 'start_server'):
                print('🚀 Starting MCP TCP server...')
                result = bpy.ops.blendermcp.start_server()
                print(f'📡 Start server result: {result}')
                print('✅ MCP TCP server started on port 9876')
                
                # Signal success
                with open('/tmp/blender_gui_ready', 'w') as f:
                    f.write('ready')
                
                print('🎉 Blender GUI with MCP ready!')
                print('🔌 TCP Server: localhost:9876')
                print('🖼️ GUI: Ready for interaction')
                
            else:
                print('❌ start_server operator not found')
                print(f'Available blendermcp attributes: {dir(bpy.ops.blendermcp) if hasattr(bpy.ops, "blendermcp") else "No blendermcp"}')
                
        else:
            print('❌ Addon failed to load')
            print('🔍 Checking addon availability...')
            addon_path = os.path.expanduser("~/.config/blender/4.3/scripts/addons/blender_mcp")
            print(f'📁 Addon path: {addon_path}')
            if os.path.exists(addon_path):
                files = os.listdir(addon_path)
                print(f'📄 Addon files: {files}')
            else:
                print('❌ Addon path does not exist')
                
    except Exception as e:
        print(f'❌ Error during setup: {e}')
        traceback.print_exc()
        sys.exit(1)

def main():
    """メイン実行関数"""
    print('🐍 Starting Blender MCP Python setup...')
    print(f'🔧 Blender version: {bpy.app.version_string}')
    print(f'📁 Blender executable: {bpy.app.binary_path}')
    
    setup_blender_mcp()
    
    print('✅ Python setup completed')

if __name__ == "__main__":
    main()