script_dir=$(dirname "$(realpath "$0")")
source "${script_dir}/upload_configs.conf"

# upload_configs.conf
# SERVER_IP=
# SERVER_PORT=
# SERVER_USER=
# SERVER_DIRECTORY=
# SERVER_SH_PATH=
# LOCAL_DIRECTORY=

cd $LOCAL_DIRECTORY || { echo "Failed to change directory"; exit 1; }

mogrify -resize 15% * || { echo "Failed to resize images"; exit 1; }
exiftool -gps:all= -v -overwrite_original . || { echo "Failed to remove GPS info"; exit 1; }

files=(*)

if [ ${#files[@]} -eq 0 ]; then
    echo "No files to transfer"
    exit 1
fi

scp -r -P ${SERVER_PORT} "${files[@]}" ${SERVER_USER}@${SERVER_IP}:${SERVER_DIRECTORY}

if [ $? -eq 0 ]; then
    rm -rf "${files[@]}"
    echo "Files successfully transferred and deleted locally"
else
    echo "File transfer failed, local files not deleted"
    exit 1
fi

ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" "bash $SERVER_SH_PATH"