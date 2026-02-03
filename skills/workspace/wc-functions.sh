#!/bin/bash

# wc-functions.sh - Shell functions for seamless workspace management
# Source this file to get convenient workspace functions with auto-switch capability

# Get the directory where this script is located
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    WC_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
else
    # Fallback: assume we're in the skills/workspace directory
    WC_SCRIPT_DIR="/home/wukong/.claude/skills/workspace"
fi

# Workspace create with auto-switch
wcreate() {
    # Check if this is a help request
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        "$WC_SCRIPT_DIR/workspace-create.sh" "$@"
        return $?
    fi

    # Create temporary file to capture the last line (switch command)
    local temp_output=$(mktemp)

    # Run script with output visible to user, capture exit code
    "$WC_SCRIPT_DIR/workspace-create.sh" "$@" | tee "$temp_output"
    local exit_code=${PIPESTATUS[0]}

    # Get the last line which should be the switch command
    local switch_cmd=$(tail -n 1 "$temp_output")
    rm -f "$temp_output"

    # Execute switch command if script succeeded and command exists
    if [[ $exit_code -eq 0 ]] && [[ -n "$switch_cmd" ]]; then
        eval "$switch_cmd"
    fi
}

# Workspace switch with auto-switch
wswitch() {
    # Check if this is a help request
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        "$WC_SCRIPT_DIR/workspace-switch.sh" "$@"
        return $?
    fi

    # Create temporary file to capture the last line (switch command)
    local temp_output=$(mktemp)

    # Run script with output visible to user, capture exit code
    "$WC_SCRIPT_DIR/workspace-switch.sh" "$@" | tee "$temp_output"
    local exit_code=${PIPESTATUS[0]}

    # Get the last line which should be the switch command
    local switch_cmd=$(tail -n 1 "$temp_output")
    rm -f "$temp_output"

    # Execute switch command if script succeeded and command exists
    if [[ $exit_code -eq 0 ]] && [[ -n "$switch_cmd" ]]; then
        eval "$switch_cmd"
    fi
}

# Workspace clean (no auto-switch needed)
wclean() {
    "$WC_SCRIPT_DIR/workspace-clean.sh" "$@"
}

# Workspace check (no auto-switch needed)
wcheck() {
    "$WC_SCRIPT_DIR/workspace-check.sh" "$@"
}

# Show usage information
whelp() {
    echo "Workspace Management Functions:"
    echo ""
    echo "  wcreate [options]             Create new workspace and switch to it"
    echo "  wswitch <branch|pr> [opts]    Switch to workspace and switch to it"
    echo "  wcheck                        Check all workspaces with safety status"
    echo "  wclean [options]              Clean safe worktrees"
    echo ""
    echo "wcreate and wswitch automatically switch to the new workspace directory"
    echo "after successful operations."
    echo ""
    echo "Examples:"
    echo "  wcreate                       # Creates and switches to new workspace"
    echo "  wswitch 123                   # Switch to PR #123 workspace"
    echo "  wcheck                        # Check all workspaces with status"
    echo "  wclean                        # Clean safe worktrees"
    echo ""
    echo "For detailed options, run:"
    echo "  $WC_SCRIPT_DIR/workspace-create.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-switch.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-check.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-clean.sh --help"
}

echo "Workspace functions loaded: wcreate, wswitch, wcheck, wclean, whelp"