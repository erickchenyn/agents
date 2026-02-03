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

# Workspace checkout with auto-switch
wcheckout() {
    # Check if this is a help request
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        "$WC_SCRIPT_DIR/workspace-checkout.sh" "$@"
        return $?
    fi

    # Create temporary file to capture the last line (switch command)
    local temp_output=$(mktemp)

    # Run script with output visible to user, capture exit code
    "$WC_SCRIPT_DIR/workspace-checkout.sh" "$@" | tee "$temp_output"
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

# Workspace list (no auto-switch needed)
wlist() {
    "$WC_SCRIPT_DIR/workspace-list.sh" "$@"
}

# Show usage information
whelp() {
    echo "Workspace Management Functions:"
    echo ""
    echo "  wcreate [options]             Create new workspace and switch to it"
    echo "  wcheckout <branch|pr> [opts]  Checkout workspace and switch to it"
    echo "  wlist [options]               List all workspaces with safety status"
    echo "  wclean [options]              Clean safe worktrees"
    echo ""
    echo "wcreate and wcheckout automatically switch to the new workspace directory"
    echo "after successful operations."
    echo ""
    echo "Examples:"
    echo "  wcreate                       # Creates and switches to new workspace"
    echo "  wcheckout 123                 # Checkout PR #123 and switch to it"
    echo "  wlist                         # List all workspaces with status"
    echo "  wlist -v                      # List with detailed safety analysis"
    echo "  wlist -j                      # List in JSON format"
    echo "  wclean                        # Clean safe worktrees"
    echo ""
    echo "For detailed options, run:"
    echo "  $WC_SCRIPT_DIR/workspace-create.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-checkout.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-list.sh --help"
    echo "  $WC_SCRIPT_DIR/workspace-clean.sh --help"
}

echo "Workspace functions loaded: wcreate, wcheckout, wlist, wclean, whelp"