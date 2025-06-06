#!/bin/bash

BASE_DIR="/a/b/c/log"
selected_date=""
LOG_DIR=""
LOG_IN=""
LOG_OUT=""
LOG_PROCESS=""

# Màu sắc
NC='\033[0m' # No Color
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
BOLD='\033[1m'

# ===== CHỌN NGÀY LOG =====
choose_date() {
    echo -e "\n${CYAN}🔍 Đang tìm thư mục log trong $BASE_DIR...${NC}"

    available_dates=($(find "$BASE_DIR" -maxdepth 1 -type d -printf "%f\n" | grep -E '^[0-9]{8}$' | sort -r | head -n 10))

    if [[ ${#available_dates[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không có thư mục log hợp lệ trong $BASE_DIR${NC}"
        exit 1
    fi

    echo -e "${BLUE}🗂️  Các ngày log gần nhất:${NC}"
    for i in "${!available_dates[@]}"; do
        echo -e "${YELLOW}$((i+1)))${NC} ${available_dates[$i]}"
    done

    read -p "$(echo -e "${BOLD}🔢 Chọn số tương ứng (1-${#available_dates[@]}):${NC} ")" day_choice

    if [[ "$day_choice" =~ ^[0-9]+$ ]] && (( day_choice >= 1 && day_choice <= ${#available_dates[@]} )); then
        selected_date="${available_dates[$((day_choice-1))]}"
        LOG_DIR="$BASE_DIR/$selected_date"
        LOG_IN="$LOG_DIR/log-in.log"
        LOG_OUT="$LOG_DIR/log-out.log"
        LOG_PROCESS="$LOG_DIR/log-process.log"
        echo -e "${GREEN}✅ Đã chọn: $LOG_DIR${NC}"
    else
        echo -e "${RED}❌ Lựa chọn không hợp lệ. Thoát.${NC}"
        exit 1
    fi
}

# ===== CHỌN FILE LOG =====
choose_log_file() {
    read -p "$(echo -e "${BOLD}🔢 Nhập số tương ứng (1:log-in, 2:log-out, 3:log-process):${NC} ")" log_choice

    case "$log_choice" in
        1) log_file="$LOG_IN" ;;
        2) log_file="$LOG_OUT" ;;
        3) log_file="$LOG_PROCESS" ;;
        *) log_file="none" ;;
    esac

    echo "$log_file"
}

# ======= HỎI GHI FILE ========
ask_save_file() {
    local output_file="$1"
    read -p "$(echo -e "${YELLOW}💾 Bạn có muốn ghi kết quả ra tệp '$output_file'? (y/n): ${NC}")" save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

# ===== BẮT BUỘC CHỌN NGÀY BAN ĐẦU =====
echo -e "${BOLD}${CYAN}===== CHỌN NGÀY LOG =====${NC}"
choose_date

# ===== MENU CHÍNH =====
while true; do
    echo -e "\n${BOLD}${BLUE}===== MENU CHÍNH (Ngày: $selected_date) =====${NC}"
    echo -e "${YELLOW}1)${NC} Đếm số dòng trong log"
    echo -e "${YELLOW}2)${NC} Tìm kiếm tên file trong log"
    echo -e "${YELLOW}3)${NC} So sánh mã file (.csv & .fin) giữa log-in và log-process"
    echo -e "${YELLOW}4)${NC} Kiểm tra file trùng trong log-out.log"
    echo -e "${YELLOW}5)${NC} 🔁 Chọn lại ngày log"
    echo -e "${YELLOW}0)${NC} Thoát"
    echo -e "${BOLD}=============================================${NC}"
    read -p "$(echo -e "${BOLD}Chọn một tùy chọn (0-5):${NC} ")" choice

    case "$choice" in
        1)
            echo -e "\n${CYAN}===== CHỌN FILE LOG =====${NC}"
            echo -e "1) log-in.log      (${GREEN}$LOG_IN${NC})"
            echo -e "2) log-out.log     (${GREEN}$LOG_OUT${NC})"
            echo -e "3) log-process.log (${GREEN}$LOG_PROCESS${NC})"
            echo "========================="
            log_file=$(choose_log_file)
            if [[ "$log_file" == "none" || ! -f "$log_file" ]]; then
                echo -e "${RED}❌ Lựa chọn không hợp lệ hoặc file không tồn tại!${NC}"
            else
                count=$(wc -l < "$log_file")
                echo -e "${GREEN}✅ Số dòng trong $(basename "$log_file"): $count dòng${NC}"
            fi
            ;;
        2)
            echo -e "\n${CYAN}===== CHỌN FILE LOG =====${NC}"
            echo -e "1) log-in.log      (${GREEN}$LOG_IN${NC})"
            echo -e "2) log-out.log     (${GREEN}$LOG_OUT${NC})"
            echo -e "3) log-process.log (${GREEN}$LOG_PROCESS${NC})"
            echo "========================="
            log_file=$(choose_log_file)
            if [[ "$log_file" == "none" || ! -f "$log_file" ]]; then
                echo -e "${RED}❌ Lựa chọn không hợp lệ hoặc file không tồn tại!${NC}"
            else
                read -p "$(echo -e "${BOLD}Nhập từ khóa cần tìm:${NC} ")" keyword
                echo -e "${CYAN}📂 Kết quả tìm '${YELLOW}$keyword${CYAN}' trong ${BOLD}$(basename "$log_file")${NC}:"
                grep --color=always "$keyword" "$log_file" || echo -e "${YELLOW}⚠️ Không tìm thấy!${NC}"
            fi
            ;;
        3)
            if [[ ! -f "$LOG_IN" || ! -f "$LOG_PROCESS" ]]; then
                echo -e "${RED}❌ Thiếu log-in.log hoặc log-process.log!${NC}"
                continue
            fi

            echo -e "${CYAN}🔍 So sánh mã DTxxxxx giữa log-in và log-process...${NC}"

            awk '{print $2}' "$LOG_IN" \
                | grep -E '\.csv$|\.fin$' \
                | grep -oE 'DT[0-9]+' \
                | sort -u > /tmp/in_codes.txt

            awk '{print $2}' "$LOG_PROCESS" \
                | sed 's/^processed-//' \
                | grep -E '\.csv$|\.fin$' \
                | grep -oE 'DT[0-9]+' \
                | sort -u > /tmp/process_codes.txt

            DIFF_OUTPUT="./diff_result_$selected_date.txt"
            comm -23 /tmp/in_codes.txt /tmp/process_codes.txt > "$DIFF_OUTPUT"

            count_diff=$(wc -l < "$DIFF_OUTPUT")
            echo -e "${GREEN}✅ Tổng số mã DT khác biệt: $count_diff${NC}"

            if [[ "$(ask_save_file "$DIFF_OUTPUT")" == "yes" ]]; then
                echo -e "${GREEN}✅ Đã ghi các mã DT chưa xử lý vào: $DIFF_OUTPUT${NC}"
            else
                echo -e "${CYAN}Kết quả:${NC}"
                cat "$DIFF_OUTPUT"
                rm -f "$DIFF_OUTPUT"
            fi

            # --------- So sánh FILE KHÁC ----------
            awk '{print $2}' "$LOG_IN" \
                | grep -E '\.csv$|\.fin$' \
                | grep -vE 'DT[0-9]+' \
                | sort -u > /tmp/in_others.txt

            awk '{print $2}' "$LOG_PROCESS" \
                | sed 's/^processed-//' \
                | grep -E '\.csv$|\.fin$' \
                | grep -vE 'DT[0-9]+' \
                | sort -u > /tmp/process_others.txt

            OTHERS_IN_ONLY="./others_in_only_$selected_date.txt"
            OTHERS_PROCESS_ONLY="./others_process_only_$selected_date.txt"

            comm -23 /tmp/in_others.txt /tmp/process_others.txt > "$OTHERS_IN_ONLY"
            comm -13 /tmp/in_others.txt /tmp/process_others.txt > "$OTHERS_PROCESS_ONLY"

            cnt_in_only=$(wc -l < "$OTHERS_IN_ONLY")
            cnt_process_only=$(wc -l < "$OTHERS_PROCESS_ONLY")
            echo -e "${GREEN}✅ Các file khác chỉ có trong log-in: $cnt_in_only${NC}"
            echo -e "${GREEN}✅ Các file khác chỉ có trong log-process: $cnt_process_only${NC}"

            if [[ "$(ask_save_file "$OTHERS_IN_ONLY")" != "yes" ]]; then
                echo -e "${CYAN}Các file khác chỉ có trong log-in:${NC}"
                cat "$OTHERS_IN_ONLY"
                rm -f "$OTHERS_IN_ONLY"
            else
                echo -e "${GREEN}Đã ghi danh sách vào $OTHERS_IN_ONLY${NC}"
            fi

            if [[ "$(ask_save_file "$OTHERS_PROCESS_ONLY")" != "yes" ]]; then
                echo -e "${CYAN}Các file khác chỉ có trong log-process:${NC}"
                cat "$OTHERS_PROCESS_ONLY"
                rm -f "$OTHERS_PROCESS_ONLY"
            else
                echo -e "${GREEN}Đã ghi danh sách vào $OTHERS_PROCESS_ONLY${NC}"
            fi
            ;;
        4)
            if [[ ! -f "$LOG_OUT" ]]; then
                echo -e "${RED}❌ log-out.log không tồn tại!${NC}"
                continue
            fi

            echo -e "${CYAN}🔍 Đang kiểm tra file trùng trong log-out.log...${NC}"

            # Kiểm tra trùng file .csv (match cả tên dài processed-ABC-DTxxxx-vxxxxx.csv)
            awk '{print $2}' "$LOG_OUT" | grep -E '^processed-ABC-DT[0-9]+.*\.csv$' | sort | uniq -d > ./dup_csv_out_$selected_date.txt
            # Kiểm tra trùng file .fin (match cả tên dài processed-DTxxxx-vxxxxx.fin)
            awk '{print $2}' "$LOG_OUT" | grep -E '^processed-DT[0-9]+.*\.fin$' | sort | uniq -d > ./dup_fin_out_$selected_date.txt

            if [[ -s ./dup_csv_out_$selected_date.txt ]]; then
                echo -e "${YELLOW}⚠️ Các file .csv trùng!${NC}"
                if [[ "$(ask_save_file ./dup_csv_out_$selected_date.txt)" == "yes" ]]; then
                    echo -e "${GREEN}✅ Danh sách file .csv trùng đã lưu ở ./dup_csv_out_$selected_date.txt${NC}"
                else
                    cat ./dup_csv_out_$selected_date.txt
                    rm -f ./dup_csv_out_$selected_date.txt
                fi
            else
                echo -e "${GREEN}✅ Không phát hiện file .csv nào bị trùng!${NC}"
                rm -f ./dup_csv_out_$selected_date.txt
            fi

            if [[ -s ./dup_fin_out_$selected_date.txt ]]; then
                echo -e "${YELLOW}⚠️ Các file .fin trùng!${NC}"
                if [[ "$(ask_save_file ./dup_fin_out_$selected_date.txt)" == "yes" ]]; then
                    echo -e "${GREEN}✅ Danh sách file .fin trùng đã lưu ở ./dup_fin_out_$selected_date.txt${NC}"
                else
                    cat ./dup_fin_out_$selected_date.txt
                    rm -f ./dup_fin_out_$selected_date.txt
                fi
            else
                echo -e "${GREEN}✅ Không phát hiện file .fin nào bị trùng!${NC}"
                rm -f ./dup_fin_out_$selected_date.txt
            fi
            ;;

        5)
            choose_date
            ;;
        0)
            echo -e "${BOLD}${CYAN}👋 Thoát chương trình. Hẹn gặp lại!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}⚠️ Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}"
            ;;
    esac
done
