#!/bin/bash

# Color definitions
BLUE="\e[96m"
YELLOW="\e[93m"
RED="\e[91m"
GREEN="\e[92m"
GRAY="\e[37m"
BOLD="\e[1m"
RESET="\e[0m"
CYAN="\e[36m"

LINE="------------------------------------------------------------"

BASE_DIR="/a/b/c/log"
selected_date=""
LOG_DIR=""
LOG_IN=""
LOG_OUT=""
LOG_PROCESS=""

print_menu_border() {
    echo -e "${CYAN}${LINE}${RESET}"
}

print_section_title() {
    print_menu_border
    echo -e "${BOLD}${BLUE}$1${RESET}"
    print_menu_border
}

choose_date() {
    print_section_title "SELECT LOG DATE"
    echo -e "${BLUE}Scanning log folders in $BASE_DIR ...${RESET}"

    available_dates=($(find "$BASE_DIR" -maxdepth 1 -type d -printf "%f\n" | grep -E '^[0-9]{8}$' | sort -r | head -n 10))

    if [[ ${#available_dates[@]} -eq 0 ]]; then
        echo -e "${RED}No valid log folders found in $BASE_DIR.${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}Recent log dates:${RESET}"
    for i in "${!available_dates[@]}"; do
        printf "  %2d) %s\n" $((i+1)) "${available_dates[$i]}"
    done
    print_menu_border

    read -p "Select a date by number (1-${#available_dates[@]}): " day_choice

    if [[ "$day_choice" =~ ^[0-9]+$ ]] && (( day_choice >= 1 && day_choice <= ${#available_dates[@]} )); then
        selected_date="${available_dates[$((day_choice-1))]}"
        LOG_DIR="$BASE_DIR/$selected_date"
        LOG_IN="$LOG_DIR/log-in.log"
        LOG_OUT="$LOG_DIR/log-out.log"
        LOG_PROCESS="$LOG_DIR/log-process.log"
        echo -e "${GREEN}Selected log date: $selected_date${RESET}"
    else
        echo -e "${RED}Invalid selection. Exiting.${RESET}"
        exit 1
    fi
}

choose_log_file() {
    print_menu_border
    echo -e "${BLUE}Select a log file:${RESET}"
    echo "  1) log-in.log      ($LOG_IN)"
    echo "  2) log-out.log     ($LOG_OUT)"
    echo "  3) log-process.log ($LOG_PROCESS)"
    print_menu_border
    read -p "Enter choice (1/2/3 or q to return): " log_choice
    case "$log_choice" in
        1)
            log_file="$LOG_IN"
            log_name="log-in.log"
            ;;
        2)
            log_file="$LOG_OUT"
            log_name="log-out.log"
            ;;
        3)
            log_file="$LOG_PROCESS"
            log_name="log-process.log"
            ;;
        [Qq])
            log_file="__back__"
            log_name=""
            ;;
        *)
            log_file="__invalid__"
            log_name=""
            ;;
    esac
    echo "$log_file|$log_name"
}

save_to_file() {
    local default_file="$1"
    local content="$2"
    read -p "Do you want to save the result to a file? (y/n): " ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        read -p "Enter file name to save [default: $default_file]: " output_file
        [[ -z "$output_file" ]] && output_file="$default_file"
        echo -e "$content" > "$output_file"
        echo -e "${GREEN}Result saved to: $output_file${RESET}"
    fi
}

choose_date

while true; do
    print_section_title "MAIN MENU"
    echo -e "Current log date: ${YELLOW}$selected_date${RESET}"
    echo -e "${BOLD}  1)${RESET} Count lines in log"
    echo -e "${BOLD}  2)${RESET} Search file name in log"
    echo -e "${BOLD}  3)${RESET} Compare codes (.csv & .fin) between log-in and log-process"
    echo -e "${BOLD}  4)${RESET} Check for duplicate files in log-out.log"
    echo -e "${BOLD}  5)${RESET} Change log date"
    echo -e "${BOLD}  0)${RESET} Exit"
    print_menu_border
    read -p "Select an option (0-5): " choice

    case "$choice" in
        1)
            while true; do
                result=$(choose_log_file)
                log_file="${result%%|*}"
                log_name="${result##*|}"

                [[ "$log_file" == "__back__" ]] && break

                # Handle invalid selection
                if [[ "$log_file" == "__invalid__" ]]; then
                    echo -e "${RED}Invalid selection! Please enter 1, 2, 3, or q.${RESET}"
                    continue
                fi

                echo -e "${YELLOW}Selected: $log_name${RESET}"

                # Check existence
                if [[ ! -f "$log_file" ]]; then
                    echo -e "${RED}File does not exist!${RESET}"
                    break  # Return to main menu if file doesn't exist
                fi

                print_menu_border
                result_line="$log_name has $(wc -l < "$log_file") lines."
                echo -e "${GREEN}$result_line${RESET}"
                print_menu_border
                save_to_file "count_lines_${log_name}_$selected_date.txt" "$result_line"

                echo -e "${GRAY}Press [Enter] to count another file, or type 'q' to return to main menu...${RESET}"
                read back
                [[ "$back" == "q" || "$back" == "Q" ]] && break
            done
            ;;
        2)
            while true; do
                result=$(choose_log_file)
                log_file="${result%%|*}"
                log_name="${result##*|}"

                [[ "$log_file" == "__back__" ]] && break
                if [[ "$log_file" == "__invalid__" ]]; then
                    echo -e "${RED}Invalid selection! Please enter 1, 2, 3, or q.${RESET}"
                    continue
                fi

                echo -e "${YELLOW}Selected: $log_name${RESET}"

                if [[ ! -f "$log_file" ]]; then
                    echo -e "${RED}File does not exist!${RESET}"
                    break
                fi

                read -p "Enter keyword to search: " keyword
                print_menu_border
                echo -e "${BOLD}${BLUE}Search results for '$keyword' in $log_name:${RESET}"
                print_menu_border
                found=0
                search_result=""
                while IFS= read -r line; do
                    if [[ "$line" == *"$keyword"* ]]; then
                        found=1
                        highlight=$(echo "$line" | sed "s/$keyword/${YELLOW}${BOLD}${keyword}${RESET}${BLUE}/g")
                        search_result+="$line\n"
                        echo -e "${YELLOW}$highlight${RESET}"
                    fi
                done < "$log_file"
                if [[ $found -eq 0 ]]; then
                    echo -e "${YELLOW}No results found.${RESET}"
                fi
                print_menu_border
                [[ $found -eq 1 ]] && save_to_file "search_${keyword}_$log_name_$selected_date.txt" "$(echo -e "$search_result")"

                echo -e "${GRAY}Press [Enter] to search again, or type 'q' to return to main menu...${RESET}"
                read back
                [[ "$back" == "q" || "$back" == "Q" ]] && break
            done
            ;;
        3)
            while true; do
                if [[ ! -f "$LOG_IN" || ! -f "$LOG_PROCESS" ]]; then
                    echo -e "${RED}log-in.log or log-process.log not found!${RESET}"
                    break
                fi
                print_section_title "COMPARING DTxxxxx CODES"
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

                result="Unprocessed DT codes saved in: $DIFF_OUTPUT\nNumber of missing codes: $(wc -l < "$DIFF_OUTPUT")"
                echo -e "${GREEN}$result${RESET}"

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

                other_result="Files (not DT code) only in log-in: $OTHERS_IN_ONLY ($(wc -l < "$OTHERS_IN_ONLY"))\nFiles (not DT code) only in log-process: $OTHERS_PROCESS_ONLY ($(wc -l < "$OTHERS_PROCESS_ONLY"))"
                echo -e "${YELLOW}$other_result${RESET}"
                print_menu_border
                save_to_file "compare_result_$selected_date.txt" "$result\n$other_result"

                echo -e "${GRAY}Press [Enter] to compare again, or type 'q' to return to main menu...${RESET}"
                read back
                [[ "$back" == "q" || "$back" == "Q" ]] && break
            done
            ;;
        4)
            while true; do
                if [[ ! -f "$LOG_OUT" ]]; then
                    echo -e "${RED}log-out.log does not exist!${RESET}"
                    break
                fi
                print_section_title "CHECKING DUPLICATES IN LOG-OUT.LOG"
                awk '{print $2}' "$LOG_OUT" | grep -E '^processed-ABC-DT[0-9]+\.csv$' | sort | uniq -d > ./dup_csv_out_$selected_date.txt
                awk '{print $2}' "$LOG_OUT" | grep -E '^processed-DT[0-9]+\.fin$' | sort | uniq -d > ./dup_fin_out_$selected_date.txt

                content=""
                if [[ -s ./dup_csv_out_$selected_date.txt ]]; then
                    echo -e "${YELLOW}Duplicate .csv files found:${RESET}"
                    cat ./dup_csv_out_$selected_date.txt
                    content+="Duplicate .csv files:\n$(cat ./dup_csv_out_$selected_date.txt)\n"
                else
                    echo -e "${GREEN}No duplicate .csv files found.${RESET}"
                    content+="No duplicate .csv files found.\n"
                fi

                if [[ -s ./dup_fin_out_$selected_date.txt ]]; then
                    echo -e "${YELLOW}Duplicate .fin files found:${RESET}"
                    cat ./dup_fin_out_$selected_date.txt
                    content+="Duplicate .fin files:\n$(cat ./dup_fin_out_$selected_date.txt)\n"
                else
                    echo -e "${GREEN}No duplicate .fin files found.${RESET}"
                    content+="No duplicate .fin files found.\n"
                fi
                print_menu_border
                save_to_file "duplicate_result_$selected_date.txt" "$content"

                echo -e "${GRAY}Press [Enter] to check again, or type 'q' to return to main menu...${RESET}"
                read back
                [[ "$back" == "q" || "$back" == "Q" ]] && break
            done
            ;;
        5)
            while true; do
                choose_date
                echo -e "${GRAY}Type 'q' to return to main menu, or press [Enter] to change date again...${RESET}"
                read back
                [[ "$back" == "q" || "$back" == "Q" ]] && break
            done
            ;;
        0)
            print_menu_border
            echo -e "${GREEN}Goodbye!${RESET}"
            print_menu_border
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${RESET}"
            ;;
    esac
done
