#!/bin/bash

echo "🚀 Starting Blender GUI with MCP addon..."

# Function to check if port is open
check_port() {
    nc -z localhost 9876 2>/dev/null
}

# Function to start Blender with GUI and TCP server
start_blender_gui() {
    echo "🖼️ Starting Blender with GUI and MCP addon..."
    
    # Start Blender with Python and auto-exec enabled
    blender \
        --enable-autoexec \
        --python-use-system-env \
        --factory-startup \
        --python /home/$(whoami)/setup_blender_mcp.py &
    
    BLENDER_PID=$!
    echo "Blender GUI PID: $BLENDER_PID"
    
    # Wait for Blender to be ready
    echo "⏳ Waiting for Blender GUI to initialize..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if [ -f "/tmp/blender_gui_ready" ]; then
            echo "✅ Blender GUI is ready!"
            break
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "❌ Timeout waiting for Blender GUI"
        return 1
    fi
    
    # Wait for TCP server to be ready
    echo "⏳ Waiting for TCP server on port 9876..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if check_port; then
            echo "✅ TCP server is ready on port 9876!"
            break
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "❌ Timeout waiting for TCP server"
        return 1
    fi
    
    return 0
}

# Function to monitor Blender process
monitor_blender() {
    echo "🎉 Blender GUI with MCP fully operational!"
    echo "🖼️ GUI: Ready for visual interaction"
    echo "📡 TCP Server: Ready on port 9876"
    echo "⚡ Ready to receive commands from mcp_blender"
    
    # Keep the container running and monitor Blender
    while true; do
        sleep 10
        
        # Check if Blender is still running
        if ! kill -0 $BLENDER_PID 2>/dev/null; then
            echo "❌ Blender process died"
            exit 1
        fi
        
        # Check if Blender addon server is still responsive
        if ! check_port; then
            echo "⚠️ Blender addon server not responsive"
            echo "❌ Blender addon server failed"
            exit 1
        fi
    done
}

# Main execution
if start_blender_gui; then
    monitor_blender
else
    echo "❌ Failed to start Blender GUI"
    exit 1
fi