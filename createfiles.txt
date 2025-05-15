#!/bin/bash

# Tạo thư mục để lưu các file (nếu cần)
output_dir="/Users/richard/Data/80/files"
mkdir -p "$output_dir"

# Yêu cầu người dùng nhập số lượng file
read -p "Nhập số lượng file muốn tạo: " file_count

# Kiểm tra nếu người dùng không nhập hoặc nhập giá trị không hợp lệ
if ! [[ "$file_count" =~ ^[0-9]+$ ]] || [ "$file_count" -le 0 ]; then
    echo "Vui lòng nhập một số nguyên dương hợp lệ."
    exit 1
fi

# Tạo file với dung lượng 10,000 kilobit (1,250 KB)
for random in $(seq 1 "$file_count"); do
    # Tạo file ABC-DT${random}.csv
    dd if=/dev/zero of="$output_dir/ABC-DT${random}.csv" bs=125 count=100 &>/dev/null
    
    # Tạo file DT${random}.csv.fin
    dd if=/dev/zero of="$output_dir/DT${random}.fin" bs=125 count=100 &>/dev/null
done

echo "Hoàn thành việc tạo $file_count file trong thư mục $output_dir"