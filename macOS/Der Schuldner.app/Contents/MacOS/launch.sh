#!/bin/sh

REPO_OWNER="linusbolls"
REPO_NAME="bill-creator"
REPO_ZIP_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/master.zip"
REPO_LATEST_COMMIT_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/master"

ARCHITECTURE=$(sysctl -n machdep.cpu.brand_string)
LAUNCH_PATH=$(cd "$(dirname "$0")"; pwd)
APP_PATH="$LAUNCH_PATH/../.."

CURRENT_COMMIT_JSON="$APP_PATH/Contents/currentCommit.json"
ENTRY_PY="$APP_PATH/Contents/src/index.py"
WINDOW_PY="$APP_PATH/Contents/src/updatingWindow.py"
LOG="$APP_PATH/logs/log.txt"
ERR="$APP_PATH/logs/err.txt"

TIMESTAMP=$(date +'%m/%d/%Y - %H:%M:%S')
HEADER="===== $TIMESTAMP ====="

export REQ_TXT="$APP_PATH/Contents/requirements.txt"
export REQ_ZIP="$APP_PATH/Contents/requirements.zip"
export REQ_PATH="$APP_PATH/Contents/requirements"
export PYTHONPATH="$PYTHONPATH:$REQ_PATH"

export DATA_PATH="$HOME/Library/Application Support/Der Schuldner"
export DOWNLOADS_PATH="$HOME/downloads"

# check if download folder exists and is accessible
if test -d "$DOWNLOADS_PATH"; then
    export STARTUP_PATH="$DOWNLOADS_PATH"
else
    export STARTUP_PATH="$HOME"
fi

isWithUpdateWindow=false

mkdir "$DATA_PATH" 2>/dev/null

echo $HEADER >> "$LOG"
echo $HEADER >> "$ERR"
echo "app folder is $APP_PATH" >> "$LOG"
echo "data folder is $DATA_PATH" >> "$LOG"
echo "startup folder is $STARTUP_PATH" >> "$LOG"

INFO="/dev/null"

launchUpdateWindow() {

    INFO="/tmp/srv-input"

    rm "$INFO"
    mkfifo "$INFO"
    tail -f "$INFO" | /usr/bin/python3 "$WINDOW_PY" & infoPid=$!
}
killUpdateWindow() {
    kill -9 "$infoPid"
}
updateSrc() {
    echo "checking for source updates" >> "$LOG"

    currentCommitHash=$(cat "$CURRENT_COMMIT_JSON" | /usr/bin/python3 -c "import sys, json; d = json.loads(sys.stdin); print(d['sha'])")

    curl "$REPO_LATEST_COMMIT_URL" -o "$CURRENT_COMMIT_JSON"

    latestCommitHash=$(cat "$CURRENT_COMMIT_JSON" | /usr/bin/python3 -c "import sys, json; d = json.loads(sys.stdin); print(d['sha'])")
    latestCommitMsg=$(cat "$CURRENT_COMMIT_JSON" | /usr/bin/python3 -c "import sys, json; d = json.loads(sys.stdin); print(d['commit']['message'])")

    if [ $currentCommitHash = $latestCommitHash ]; then
        echo "source up to date" >> "$LOG"
    else
        echo "source not up to date, updating" >> "$LOG"
        
        echo "Fetching Source..." > "$INFO"

        curl -L "$REPO_ZIP_URL" --output "$DATA_PATH/update.zip"

        echo "Unpacking Source..." > "$INFO"

        unzip "$DATA_PATH/update.zip" -d "$DATA_PATH/update"

        # replace relevant files of .app with files of update
        cp -fr "$DATA_PATH/update/$REPO_NAME-master/src" "$APP_PATH/Contents"
        cp -fr "$DATA_PATH/update/$REPO_NAME-master/requirements.txt" "$APP_PATH/Contents"

        # cleanup
        rm "$DATA_PATH/update.zip"
        rm -rf "$DATA_PATH/update"
    fi
    echo "current commit hash is '$currentCommitHash', latest commit hash is '$latestCommitHash'" >> "$LOG"
    echo "latest commit message: '$latestCommitMsg'" >> "$LOG"
}
updateDependencies() {

    # if requirements dir exists, try updating it
    if test -d "$REQ_PATH"; then # test -dr

        echo "checking for dependency updates" >> "$LOG"

        if /usr/bin/pip3 -vvv freeze -r "$REQ_TXT" --path "$REQ_PATH" | grep "not installed"; then
            echo "dependencies not up to date, updating" >> "$LOG"
            /usr/bin/pip3 install -r "$REQ_TXT" -t "$REQ_PATH"
        else
            echo "dependencies up to date" >> "$LOG";
        fi

    # if requirements.zip exists, unzip it
    elif test -f "$REQ_ZIP"; then # test -er

        echo "unzipping dependencies" >> "$LOG"
        
        unzip "$REQ_ZIP" -d "$APP_PATH/Contents"

        rm "$REQ_ZIP"

    # else fatal
    else
        echo "fatal: could not find $REQ_PATH nor $REQ_ZIP" >> "$ERR"
        exit 1        
    fi
}
launch() {

    echo "Launching..." > "$INFO"

    if $isWithUpdateWindow; then
        sleep 1
    fi
    $env /usr/bin/arch -x86_64 /usr/bin/python3 -c "import numpy" 2>/dev/null

    if [ $? -eq 1 ]; then
        echo "fatal: dependencies compiled for architecture other than x86_64" >> "$ERR"
        exit 1
    fi

    $env /usr/bin/arch -x86_64 /usr/bin/python3 "$ENTRY_PY" >> "$LOG" 2>>"$ERR"
}
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1

hasWifi=[ $? -eq 0 ]

if $hasWifi; then

    if $isWithUpdateWindow; then
        launchUpdateWindow

        updateSrc
        updateDependencies
    
        killUpdateWindow
    else
        updateSrc
        updateDependencies
    fi
else
    echo "no wifi connection, skipping update checks" >> "$LOG"
fi
launch