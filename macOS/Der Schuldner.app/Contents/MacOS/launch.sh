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
isWithUpdateWindow=false

export REQ_TXT="$APP_PATH/Contents/requirements.txt"
export REQ_ZIP="$APP_PATH/Contents/requirements.zip"
export REQ_PATH="$APP_PATH/Contents/requirements"
export PYTHONPATH="$PYTHONPATH:$REQ_PATH"

export DATA_PATH="$HOME/Library/Application Support/Der Schuldner"
export DOWNLOADS_PATH="$HOME/downloads"

# check if download folder exists and can be written to
if [ test -d "$DOWNLOADS_PATH" ] && [ test -w "$DOWNLOADS_PATH" ]; then
    export STARTUP_PATH="$DOWNLOADS_PATH"
else
    export STARTUP_PATH="$HOME"
fi
mkdir "$DATA_PATH" 2>/dev/null

echo $HEADER >> "$LOG"
echo $HEADER >> "$ERR"
echo "app folder is $APP_PATH" >> "$LOG"
echo "data folder is $DATA_PATH" >> "$LOG"
echo "startup folder is $STARTUP_PATH" >> "$LOG"

INFO="/dev/null"

if which python3 > /dev/null 2>&1; then
  alias PYTHON=$(which python3)
else if which python2 > /dev/null 2>&1; then
  alias PYTHON=$(which python2)
else if which python > /dev/null 2>&1; then
  alias PYTHON=$(which python)
else
  echo "fatal: no python executable found" >> "$ERR"
  exit 1
fi
echo "python executable is $PYTHON" >> "$LOG"

PYTHON -m pip > /dev/null 2>&1

hasPip=$?

launchUpdateWindow() {

    INFO="/tmp/srv-input"

    rm "$INFO"
    mkfifo "$INFO"
    tail -f "$INFO" | PYTHON "$WINDOW_PY" & infoPid=$!
}
killUpdateWindow() {

    kill -9 "$infoPid"
}
updateSrc() {

    echo "checking for source updates" >> "$LOG"

    currentCommitHash=$(cat "$CURRENT_COMMIT_JSON" | PYTHON -c "import sys, json; d = json.load(sys.stdin); print(d['sha'])")

    curl -L "$REPO_LATEST_COMMIT_URL" --output "$CURRENT_COMMIT_JSON"

    latestCommitHash=$(cat "$CURRENT_COMMIT_JSON" | PYTHON -c "import sys, json; d = json.load(sys.stdin); print(d['sha'])")
    latestCommitMsg=$(cat "$CURRENT_COMMIT_JSON" | PYTHON -c "import sys, json; d = json.load(sys.stdin); print(d['commit']['message'])")

    if [[ $currentCommitHash = $latestCommitHash && $currentCommitHash != "" ]]; then
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
    if test -f "$REQ_ZIP"; then

        echo "unzipping dependencies" >> "$LOG"
        
        unzip "$REQ_ZIP" -d "$APP_PATH/Contents"

        rm "$REQ_ZIP"

    # if requirements.zip exists, unzip it
    elif test -d "$REQ_PATH"; then

        if $hasPip; then

            echo "checking for dependency updates" >> "$LOG"

            if PYTHON -m pip -vvv freeze -r "$REQ_TXT" --path "$REQ_PATH" | grep "not installed"; then
                echo "dependencies not up to date, updating" >> "$LOG"
                PYTHON -m pip install -r "$REQ_TXT" -t "$REQ_PATH"
            else
                echo "dependencies up to date" >> "$LOG";
            fi
        else
            echo "pip command not found, skipping dependency update check" >> "$LOG"

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
    $env /usr/bin/arch -x86_64 PYTHON -c "import numpy" 2>/dev/null

    if [ $? -eq 1 ]; then
        echo "fatal: dependencies compiled for architecture other than x86_64" >> "$ERR"
        exit 1
    fi

    $env /usr/bin/arch -x86_64 PYTHON "$ENTRY_PY" >> "$LOG" 2>>"$ERR"
}
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1

hasWifi=[ $? -eq 0 ]

start=`date +%s`

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
end=`date +%s`
startupTime=$((end-start))

echo "launched in $startupTime seconds"

launch