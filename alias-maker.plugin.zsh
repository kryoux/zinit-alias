# =========================
# Alias Maker Plugin
# =========================

# Plugin version and name
declare -r alias_maker_version="1.0.0"
declare -r alias_maker_name="alias-maker"

# Ensure ~/.zsh_aliases exists
if [[ ! -f "$HOME/.zsh_aliases" ]]; then
    echo "Creating aliases file at ~/.zsh_aliases..."
    touch "$HOME/.zsh_aliases"
fi

# Ensure .zshrc sources ~/.zsh_aliases
if ! grep -q 'source ~/.zsh_aliases' "$HOME/.zshrc"; then
    echo "source ~/.zsh_aliases" >> "$HOME/.zshrc"
fi

# Main command dispatcher
function am() {
    local subcommand=$1
    shift

    case $subcommand in
        -h | --help)
            show_help
            ;;
        create_alias)
            amc "$@"
            ;;
        delete_alias)
            amd "$1"
            ;;
        -l | --list)
            list_aliases
            ;;
        *)
            echo "❌ Error: Invalid subcommand '$subcommand'. Use 'am -h' for help." >&2
            return 1
            ;;
    esac
}

# Create a new alias
function amc() {
    local -r alias_name="$1"
    local alias_command="$2"

    if [[ -z "$alias_name" || -z "$alias_command" ]]; then
        echo "❌ Error: Missing alias name or command." >&2
        return 1
    fi

    # Reject dangerous characters
    if [[ "$alias_name" == *[';`']* || "$alias_command" == *[';`']* ]]; then
        echo "❌ Error: Alias name or command contains invalid characters." >&2
        return 1
    fi

    # Check if alias already exists in file
    if grep -q "^alias $alias_name=" "$HOME/.zsh_aliases"; then
        echo "❌ Error: Alias '$alias_name' already exists in ~/.zsh_aliases." >&2
        return 1
    fi

    echo "alias $alias_name=\"$alias_command\"" >> "$HOME/.zsh_aliases"
    source "$HOME/.zsh_aliases"

    echo "✅ Alias created:"
    echo "  ➤ \`$alias_name\` will run: \`$alias_command\`"
}

# Delete an existing alias
function amd() {
    local -r alias_name="$1"

    if [[ -z "$alias_name" ]]; then
        echo "❌ Error: Please provide an alias name to delete." >&2
        return 1
    fi

    if ! grep -q "^alias $alias_name=" "$HOME/.zsh_aliases"; then
        echo "❌ Error: Alias '$alias_name' not found in ~/.zsh_aliases." >&2
        return 1
    fi

    sed -i.bak "/^alias $alias_name=/d" "$HOME/.zsh_aliases" && rm "$HOME/.zsh_aliases.bak"
    unalias "$alias_name" 2>/dev/null

    echo "✅ Alias '$alias_name' has been deleted."
}

# List all custom aliases
function list_aliases() {
    local rc_file="$HOME/.zsh_aliases"

    if [[ ! -f "$rc_file" ]]; then
        echo "⚠️  No .zsh_aliases file found." >&2
        return 1
    fi

    local -a aliases=()
    while read -r line; do
        [[ "$line" == alias* ]] && aliases+=("$line")
    done < "$rc_file"

    if [[ ${#aliases[@]} -eq 0 ]]; then
        echo "📂 No custom aliases found in $rc_file."
    else
        echo "🔧 Custom aliases from $rc_file:"
        for alias in "${aliases[@]}"; do
            local name="${alias%%=*}"
            local command="${alias#*=}"
            name="${name#alias }"
            echo "  - $name → ${command//\"/}"
        done
    fi
}

# Display usage/help
function show_help() {
    echo ""
    echo "🛠  Usage: am [subcommand] [args]"
    echo ""
    echo "Subcommands:"
    echo "  create_alias <alias_name> <alias_command>   Create a new alias"
    echo "  delete_alias <alias_name>                   Delete an existing alias"
    echo "  -l, --list                                   List all aliases"
    echo "  -h, --help                                   Show this help message"
    echo ""
}
