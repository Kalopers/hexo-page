#!/bin/bash
cd /usr/hexo
git fetch
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ $LOCAL != $REMOTE ]; then
    echo "Detected changes, updating and rebuilding Hexo..."
    git pull
    hexo clean
    hexo generate
    hexo server -d
else
    echo "No changes detected."
fi
