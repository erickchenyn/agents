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
        "$WC_SCRIPT_DIR/wc" create "$@"
        return $?
    fi

    local switch_cmd
    switch_cmd=$("$WC_SCRIPT_DIR/wc" create "$@")
    if [[ $? -eq 0 ]] && [[ -n "$switch_cmd" ]]; then
        # Execute the switch command
        eval "$switch_cmd"
    fi
}

# Workspace checkout with auto-switch
wcheckout() {
    # Check if this is a help request
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        "$WC_SCRIPT_DIR/wc" checkout "$@"
        return $?
    fi

    local switch_cmd
    switch_cmd=$("$WC_SCRIPT_DIR/wc" checkout "$@")
    if [[ $? -eq 0 ]] && [[ -n "$switch_cmd" ]]; then
        # Execute the switch command
        eval "$switch_cmd"
    fi
}

# Workspace remove (no auto-switch needed)
wremove() {
    "$WC_SCRIPT_DIR/wc" remove "$@"
}

# Show usage information
whelp() {
    echo "Workspace Management Functions:"
    echo ""
    echo "  wcreate [options]             Create new workspace and switch to it"
    echo "  wcheckout <branch|pr> [opts]  Checkout workspace and switch to it"
    echo "  wremove [options]             Remove safe worktrees"
    echo ""
    echo "These functions automatically switch to the new workspace directory"
    echo "and execute 'cc' command after successful operations."
    echo ""
    echo "Examples:"
    echo "  wcreate -b feature-auth       # Creates and switches to new workspace"
    echo "  wcheckout 123                 # Checkout PR #123 and switch to it"
    echo "  wremove                       # Remove safe worktrees"
    echo ""
    echo "For detailed options, run:"
    echo "  $WC_SCRIPT_DIR/wc --help"
}

echo "Workspace functions loaded: wcreate, wcheckout, wremove, whelp"
echo "Try: wcreate -b my-feature"