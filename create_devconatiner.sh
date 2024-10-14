#!/bin/bash

# Get all installed extensions
extensions=$(code --list-extensions | sed -e 's/^/"/' -e 's/$/",/')

# Create or overwrite devcontainer.json with the extensions
cat <<EOF > .devcontainer/devcontainer.json
{
    "name": "Your Dev Container",
    "image": "your-docker-image",
    "extensions": [
$extensions
    ],
    "postCreateCommand": "echo 'Container setup complete!'",
    "settings": {
        "editor.formatOnSave": true
    }
}
EOF
