#!/usr/bin/env zsh
# Show chezmoi status
function st() {
    chezmoi status
}

# Show managed files
function chm() {
    chezmoi managed
}

# Add a specific path
function cadd() {
    local path="$1"
    if [[ -z "$path" ]]; then
        echo "Usage: cadd <path>"
        return 1
    fi
    chezmoi add "$path"
}

# Forget deleted files (DA)
function dfor() {
    deleted_files=$(chezmoi status | grep '^DA' | awk '{print $2}')

    for file in ${(f)deleted_files}; do
        absolute_path="$HOME/$file"
        echo "Forgetting $absolute_path"
        chezmoi forget "$absolute_path"
    done
}

# Add modified or added files (MM, A)
function madd() {
    changed_files=$(chezmoi status | grep -E '^(MM|A)' | awk '{print $2}')

    for file in ${(f)changed_files}; do
        absolute_path="$HOME/$file"
        echo "Adding $absolute_path"
        chezmoi add "$absolute_path"
    done
}

# Push all changes safely
function dp() {
    echo "Starting automation..."

    local repo="$HOME/.local/share/chezmoi"
    cd "$repo" || return 1

    # Detect current branch dynamically
    local branch
    branch=$(git branch --show-current)

    if [[ -z "$branch" ]]; then
        echo "Error: Could not detect current branch"
        cd "$HOME"
        return 1
    fi

    git add .

    # Only commit if there are changes
    if ! git diff --cached --quiet; then
        git commit -m "chezmoi: update dotfiles"
    else
        echo "No changes to commit"
    fi

    # Push current branch safely
    git push -u origin "$branch"

    cd "$HOME" || return 1
}

# Full automation function
function dall() {
    echo "Changes Done..."
    st
    echo

    echo "Adding all the changes to dotfiles repo..."

    # Forget deleted files
    if chezmoi status | grep -q '^DA'; then
        echo "Deleting removed files from dotfiles repo..."
        dfor
        echo
    fi

    # Add changed files
    madd
    echo

    echo "Pushing everything..."
    dp
}
