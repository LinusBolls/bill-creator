#!/bin/sh

REPO_NAME="bill-creator"
REPO_URL="https://github.com/linusbolls/$REPO_NAME/archive/refs/heads/master.zip"

ARCHITECTURE=$(sysctl -n machdep.cpu.brand_string)
LAUNCH_PATH=$(cd "$(dirname "$0")"; pwd)
APP_PATH="$LAUNCH_PATH/../.."

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

mkdir "$DATA_PATH"

echo $HEADER >> "$LOG"
echo $HEADER >> "$ERR"
echo "app folder is $APP_PATH" >> "$LOG"
echo "data folder is $DATA_PATH" >> "$LOG"
echo "startup folder is $STARTUP_PATH" >> "$LOG"

INFO="/dev/null"

makeUpdatingWindow() {

    INFO="/tmp/srv-input"

    rm "$INFO"
    mkfifo "$INFO"
    tail -f "$INFO" | /usr/bin/python3 "$WINDOW_PY" & infoPid=$!
}
updateSrc() {
    # download and unpack update
    echo "Fetching Source..." > "$INFO"

    curl -L "$REPO_URL" --output "$DATA_PATH/update.zip"

    echo "Unpacking Source..." > "$INFO"

    unzip "$DATA_PATH/update.zip" -d "$DATA_PATH/update"

    # replace relevant files of .app with files of update
    cp -fr "$DATA_PATH/update/$REPO_NAME-master/src" "$APP_PATH/Contents"
    cp -fr "$DATA_PATH/update/$REPO_NAME-master/requirements.txt" "$APP_PATH/Contents"

    # cleanup
    rm "$DATA_PATH/update.zip"
    rm -rf "$DATA_PATH/update"
}
updateDependencies() {

    # if requirements dir exists, try updating it
    if test -d "$REQ_PATH"; then # test -dr

        echo "checking for dependency updates" >> "$LOG"

        if pip3 -vvv freeze -r "$REQ_TXT" --path "$REQ_PATH" | grep "not installed"; then
            echo "updating dependencies" >> "$LOG"
            /usr/bin/pip3 install -r "$REQ_TXT" -t "$REQ_PATH"
        else
            echo "all ok" >> "$LOG";
        fi

    # if requirements.zip exists, unzip it
    elif test -f "$REQ_ZIP"; then # test -er

        echo "unzipping dependencies" >> "$LOG"
        
        unzip "$REQ_ZIP" -d "$REQ_PATH"

        rm "$REQ_ZIP"

    # else fatal
    else
        echo "could not find $REQ_PATH nor $REQ_ZIP" >> "$ERR"
        exit 1
    fi
}
launch() {

    echo "test" >> "$LOG"

    echo "Launching..." > "$INFO"

    sleep 1

    echo "test2" >> "$LOG"

    kill -9 "$infoPid"

    echo "test3" >> "$LOG"

    if [[ $ARCHITECTURE == "Apple M1" ]]; then
        echo "running on $ARCHITECTURE, switching to arm64" >> "$LOG"
        $env /usr/bin/arch -arm64  /usr/bin/python3 "$ENTRY_PY" >> "$LOG" 2>> "$ERR"
    else
        echo "running on $ARCHITECTURE" >> "$LOG"
        /usr/bin/python3 "$ENTRY_PY" >> "$LOG" 2>> "$ERR"
    fi
}
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1

# if wifi connection
if [ $? -eq 0 ]; then

    # makeUpdatingWindow
    updateSrc
    updateDependencies
fi
launch