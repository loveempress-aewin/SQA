# 定義陣列
dir=("/path/to/folder1" "/path/to/folder2 with spaces")

# 遍歷陣列
for item in "${dir[@]}"; do
    echo "Processing: $item"
done
