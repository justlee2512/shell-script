#!/bin/bash

# ================== CẤU HÌNH ==================
REMOTE_USER="wasadm"
REMOTE_HOST="vn120158541"
REMOTE_DIR="/appvol/tuan/files-in/"
LOCAL_DEST="/Users/richard/Data/80/18/inwark-file"
PROCESSED_DIR="/Users/richard/Data/80/18/process-file"
OTHER_DIR="$PROCESSED_DIR/other"
NUM_WORKERS=4
RSYNC_INTERVAL=5
HOSTNAME=$(hostname)

# Cấu hình đẩy file đã xử lý đi
DEST_USER="wasadm"
DEST_HOST="vn120158542"
DEST_DIR="/appvol/tuan/files-out/"
PUSH_INTERVAL=5

# Thư mục log
LOG_DIR="/Users/richard/Data/80/18/log"
mkdir -p "$LOCAL_DEST" "$PROCESSED_DIR" "$OTHER_DIR" "$LOG_DIR"

# ========== HÀM GHI LOG ==========
log_in() {
    log_date=$(date +'%Y%d%m')
    mkdir -p "$LOG_DIR/$log_date"
    echo "$(date +'%T') $1" >> "$LOG_DIR/$log_date/in.log"
}
log_process() {
    log_date=$(date +'%Y%d%m')
    mkdir -p "$LOG_DIR/$log_date"
    echo "$(date +'%T') $1" >> "$LOG_DIR/$log_date/process.log"
}
log_out() {
    log_date=$(date +'%Y%d%m')
    mkdir -p "$LOG_DIR/$log_date"
    echo "$(date +'%T') $1" >> "$LOG_DIR/$log_date/out.log"
}

# ========== XỬ LÝ FILE ==========
process_file() {
    file="$1"
    base_name=$(basename "$file")
    ext="${base_name##*.}"
    name_without_ext="${base_name%.*}"
    new_name="$PROCESSED_DIR/processed-${name_without_ext}-${HOSTNAME}.${ext}"

    if [[ "$base_name" == ABC-DT*.csv || "$base_name" == DT*.fin ]]; then
        mv "$file" "$new_name"
        log_process "$(basename "$new_name")"
    else
        mv "$file" "$OTHER_DIR/"
        log_process "$base_name"
    fi
}

export -f process_file
export -f log_process
export PROCESSED_DIR
export OTHER_DIR
export HOSTNAME
export LOG_DIR

# ========== WORKER POOL SỬ DỤNG XARGS ==========
run_worker_pool() {
    while true; do
        # Cleanup các file .lock cũ trên 10 phút
        find "$LOCAL_DEST" -name "*.lock" -mmin +10 -delete

        find "$LOCAL_DEST" -maxdepth 1 \( -name "*.csv" -o -name "*.fin" \) -type f -mmin +0.5 -print0 | \
        xargs -0 -P "$NUM_WORKERS" -I {} bash -c '
            file="{}"
            lockfile="$file.lock"
            exec 200>"$lockfile"
            # Đảm bảo dù lỗi gì cũng xóa lockfile
            trap "rm -f \"$lockfile\"; flock -u 200; exec 200>&-; exit" INT TERM EXIT
            if flock -n 200; then
                if [ -f "$file" ]; then
                    process_file "$file"
                fi
                rm -f "$lockfile"
                flock -u 200
                exec 200>&-
            fi
        '
        sleep 1
    done
}

# ========== RSYNC LẤY FILE VỀ VÀ GHI LOG IN ==========
rsync_loop() {
    while true; do
        ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && find . -type f -mmin +1 | head -n 1000 | tr '\n' '\0'" > /tmp/rsync_in.list
        if [ -s /tmp/rsync_in.list ]; then
            rsync -av --remove-source-files --files-from=/tmp/rsync_in.list --from0 $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR $LOCAL_DEST
            while IFS= read -r -d '' fname; do
                bname=$(basename "$fname")
                log_in "$bname"
            done < /tmp/rsync_in.list
            rm -f /tmp/rsync_in.list
        fi
        sleep $RSYNC_INTERVAL
    done
}

# ========== RSYNC ĐẨY FILE ĐÃ XỬ LÝ RA VÀ GHI LOG OUT ==========
push_loop() {
    while true; do
        find "$PROCESSED_DIR" -maxdepth 1 -type f -mmin +0.5 | head -n 1000 | tr '\n' '\0' > /tmp/rsync_out.list
        if [ -s /tmp/rsync_out.list ]; then
            rsync -av --remove-source-files --files-from=/tmp/rsync_out.list --from0 "$PROCESSED_DIR" "$DEST_USER@$DEST_HOST:$DEST_DIR"
            while IFS= read -r -d '' fname; do
                bname=$(basename "$fname")
                log_out "$bname"
            done < /tmp/rsync_out.list
            rm -f /tmp/rsync_out.list
        fi
        sleep $PUSH_INTERVAL
    done
}

# ========== KHỞI ĐỘNG WORKER & CÁC LUỒNG ==========
run_worker_pool &
rsync_loop &
push_loop &

wait
