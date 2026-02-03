#!/bin/bash

# workspace-list.sh - List all workspace worktrees with their safety status
# Script implementation of workspace-list skill

set -e  # Exit on error

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workspace-util.sh"

# Configuration
VERBOSE=false
JSON_OUTPUT=false

# Show help information
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show help information
    -v, --verbose           Show detailed safety analysis for each worktree
    -j, --json              Output in JSON format

Examples:
    $0                      # List all worktrees with safety status
    $0 -v                   # Show detailed analysis
    $0 -j                   # Output JSON format
    $0 -v -j                # Verbose JSON output

Description:
    Lists all non-main worktrees and their cleanup safety status.
    Shows branch information, commit status, and whether each worktree
    can be safely cleaned up.

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Format safety status for display
format_safety_status() {
    local safety_json="$1"
    local verbose="$2"

    local is_safe=$(echo "$safety_json" | jq -r '.safe')
    local warnings=($(echo "$safety_json" | jq -r '.warnings[]' 2>/dev/null || echo))
    local info=($(echo "$safety_json" | jq -r '.info[]' 2>/dev/null || echo))

    if [[ "$is_safe" == "true" ]]; then
        echo -n "✅ Safe to clean"
    else
        echo -n "⚠️  Not safe"
    fi

    if [[ "$verbose" == "true" ]]; then
        echo ""
        for warning in "${warnings[@]}"; do
            [[ -n "$warning" ]] && echo "    ⚠️  $warning"
        done
        for item in "${info[@]}"; do
            [[ -n "$item" ]] && echo "    ℹ️  $item"
        done
    fi
}

# List worktrees in table format
list_worktrees_table() {
    local worktrees=()
    mapfile -t worktrees < <(get_worktrees)

    if [[ ${#worktrees[@]} -eq 0 ]]; then
        log_info "No non-main worktrees found"
        return 0
    fi

    echo
    printf "%-40s %-30s %-20s\n" "WORKTREE" "BRANCH" "STATUS"
    printf "%-40s %-30s %-20s\n" "$(printf '=%.0s' {1..40})" "$(printf '=%.0s' {1..30})" "$(printf '=%.0s' {1..20})"

    for worktree in "${worktrees[@]}"; do
        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local name=$(basename "$path")

        # Get safety status
        local safety_json=$(check_worktree_safety "$path" "$branch")

        printf "%-40s %-30s " "$name" "$branch"
        format_safety_status "$safety_json" "$VERBOSE"
        echo
    done
    echo
}

# List worktrees in JSON format
list_worktrees_json() {
    local worktrees=()
    mapfile -t worktrees < <(get_worktrees)

    echo "{"
    echo "  \"worktrees\": ["

    local first=true
    for worktree in "${worktrees[@]}"; do
        [[ "$first" != "true" ]] && echo ","
        first=false

        local path=$(echo "$worktree" | cut -d'|' -f1)
        local branch=$(echo "$worktree" | cut -d'|' -f2)
        local name=$(basename "$path")

        # Get safety status
        local safety_json=$(check_worktree_safety "$path" "$branch")

        echo "    {"
        echo "      \"name\": \"$name\","
        echo "      \"path\": \"$path\","
        echo "      \"branch\": \"$branch\","
        echo -n "      \"safety\": $safety_json"
        echo
        echo -n "    }"
    done
    echo
    echo "  ],"
    echo "  \"total\": ${#worktrees[@]},"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
    echo "}"
}

# Main function
main() {
    parse_args "$@"

    # Check workspace environment
    check_workspace_environment "workspace-list"

    # Check GitHub CLI availability for PR status
    check_gh_available

    log_info "Listing workspace worktrees..."

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        list_worktrees_json
    else
        list_worktrees_table

        # Summary
        local worktrees=()
        mapfile -t worktrees < <(get_worktrees)
        local safe_count=0
        local unsafe_count=0

        for worktree in "${worktrees[@]}"; do
            local path=$(echo "$worktree" | cut -d'|' -f1)
            local branch=$(echo "$worktree" | cut -d'|' -f2)
            local safety_json=$(check_worktree_safety "$path" "$branch")
            local is_safe=$(echo "$safety_json" | jq -r '.safe')

            if [[ "$is_safe" == "true" ]]; then
                safe_count=$((safe_count + 1))
            else
                unsafe_count=$((unsafe_count + 1))
            fi
        done

        echo "Summary:"
        echo "  Total worktrees: ${#worktrees[@]}"
        echo "  Safe to clean: $safe_count"
        echo "  Not safe to clean: $unsafe_count"

        if [[ $safe_count -gt 0 ]]; then
            echo
            log_info "Use 'wclean' to clean up safe worktrees"
        fi
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi