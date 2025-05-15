#!/bin/bash

# Định nghĩa thư mục chứa file
folder_path="/Users/richard/Data/80/files"

# Tạo thư mục đích nếu chưa tồn tại
mkdir -p "$folder_path/so_chan" "$folder_path/so_le"

# Lặp qua các file khớp với mẫu
for file in "$folder_path"/ABC-DT*.csv "$folder_path"/DT*.fin; do
  # Kiểm tra file có tồn tại không (tránh lỗi nếu không có file nào khớp)
  if [[ ! -e "$file" ]]; then
    continue
  fi

  # Lấy tên file (không bao gồm đường dẫn)
  file_name=$(basename "$file")

  # Trích xuất số đầu tiên tìm thấy trong tên file
  number=$(echo "$file_name" | grep -oE '[0-9]+')

  # Kiểm tra nếu không tìm thấy số
  if [[ -z "$number" ]]; then
    echo "Không tìm thấy số trong tên file: $file_name"
    continue
  fi

  # Kiểm tra chẵn/lẻ và di chuyển file
  if (( number % 2 == 0 )); then
    mv "$file" "$folder_path/so_chan/"
  else
    mv "$file" "$folder_path/so_le/"
  fi
done

echo "Hoàn thành phân loại file!"

bash /Users/richard/Data/80/17/check-pid.sh &
bash /Users/richard/Data/80/18/check-pid.sh &
exit 0