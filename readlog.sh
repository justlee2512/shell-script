#!/bin/bash

BASE_DIR="/a/b/c/log"
selected_date=""
LOG_DIR=""
LOG_IN=""
LOG_OUT=""
LOG_PROCESS=""

# ===== CHỌN NGÀY LOG =====
choose_date() {
    echo ""
    echo "🔍 Đang tìm thư mục log trong $BASE_DIR..."

    available_dates=($(find "$BASE_DIR" -maxdepth 1 -type d -printf "%f\n" | grep -E '^[0-9]{8}$' | sort -r | head -n 10))

    if [[ ${#available_dates[@]} -eq 0 ]]; then
        echo "❌ Không có thư mục log hợp lệ trong $BASE_DIR"
        exit 1
    fi

    echo "🗂️  Các ngày log gần nhất:"
    for i in "${!available_dates[@]}"; do
        echo "$((i+1))) ${available_dates[$i]}"
    done

    read -p "🔢 Chọn số tương ứng (1-${#available_dates[@]}): " day_choice

    if [[ "$day_choice" =~ ^[0-9]+$ ]] && (( day_choice >= 1 && day_choice <= ${#available_dates[@]} )); then
        selected_date="${available_dates[$((day_choice-1))]}"
        LOG_DIR="$BASE_DIR/$selected_date"
        LOG_IN="$LOG_DIR/log-in.log"
        LOG_OUT="$LOG_DIR/log-out.log"
        LOG_PROCESS="$LOG_DIR/log-process.log"
        echo "✅ Đã chọn: $LOG_DIR"
    else
        echo "❌ Lựa chọn không hợp lệ. Thoát."
        exit 1
    fi
}

# ===== CHỌN FILE LOG =====
choose_log_file() {
    read -p "🔢 Nhập số tương ứng (1:log-in, 2:log-out, 3:log-process): " log_choice

    case "$log_choice" in
        1) log_file="$LOG_IN" ;;
        2) log_file="$LOG_OUT" ;;
        3) log_file="$LOG_PROCESS" ;;
        *) log_file="none" ;;
    esac

    echo "$log_file"
}

# ===== BẮT BUỘC CHỌN NGÀY BAN ĐẦU =====
echo "===== CHỌN NGÀY LOG ====="
choose_date

# ===== MENU CHÍNH =====
while true; do
    echo ""
    echo "===== MENU CHÍNH (Ngày: $selected_date) ====="
    echo "1) Đếm số dòng trong log"
    echo "2) Tìm kiếm tên file trong log"
    echo "3) So sánh tên file giữa log-in và log-process"
    echo "4) 🔁 Chọn lại ngày log"
    echo "0) Thoát"
    echo "============================================="
    read -p "Chọn một tùy chọn (0-4): " choice

    case "$choice" in
        1)
            echo ""
            echo "===== CHỌN FILE LOG ====="
            echo "1) log-in.log      ($LOG_IN)"
            echo "2) log-out.log     ($LOG_OUT)"
            echo "3) log-process.log ($LOG_PROCESS)"
            echo "========================="
            log_file=$(choose_log_file)
            if [[ "$log_file" == "none" || ! -f "$log_file" ]]; then
                echo "❌ Lựa chọn không hợp lệ hoặc file không tồn tại!"
            else
                echo "✅ Số dòng trong $(basename "$log_file"): $(wc -l < "$log_file") dòng"
            fi
            ;;
        2)
            echo ""
            echo "===== CHỌN FILE LOG ====="
            echo "1) log-in.log      ($LOG_IN)"
            echo "2) log-out.log     ($LOG_OUT)"
            echo "3) log-process.log ($LOG_PROCESS)"
            echo "========================="
            log_file=$(choose_log_file)
            if [[ "$log_file" == "none" || ! -f "$log_file" ]]; then
                echo "❌ Lựa chọn không hợp lệ hoặc file không tồn tại!"
            else
                read -p "Nhập từ khóa cần tìm: " keyword
                echo "📂 Kết quả tìm '$keyword' trong $(basename "$log_file"):"
                grep --color=always "$keyword" "$log_file" || echo "⚠️ Không tìm thấy!"
            fi
            ;;
        3)
            if [[ ! -f "$LOG_IN" || ! -f "$LOG_PROCESS" ]]; then
                echo "❌ Thiếu log-in.log hoặc log-process.log!"
                continue
            fi

            echo "🔍 So sánh tên file giữa log-in và log-process..."

            awk '{print $2}' "$LOG_IN" | sort | uniq > /tmp/in_files.txt
            awk '{print $2}' "$LOG_PROCESS" | sed 's/^processed-//' | sort | uniq > /tmp/process_files.txt

            DIFF_OUTPUT="./diff_result_$selected_date.txt"
            comm -23 /tmp/in_files.txt /tmp/process_files.txt > "$DIFF_OUTPUT"

            echo "✅ Đã lưu file khác biệt: $DIFF_OUTPUT"
            echo "✅ Số file khác nhau: $(wc -l < "$DIFF_OUTPUT")"
            ;;
        4)
            choose_date
            ;;
        0)
            echo "👋 Thoát chương trình. Hẹn gặp lại!"
            exit 0
            ;;
        *)
            echo "⚠️ Lựa chọn không hợp lệ. Vui lòng thử lại."
            ;;
    esac
done
