# 🔒 AN TOÀN GIT - KHÔNG XÓA CODE

## ⚠️ BÀI HỌC RÚT RA

**Lỗi nghiêm trọng vừa xảy ra:**
1. Đã chạy `git reset --hard HEAD` → xóa toàn bộ local changes
2. Chạy `git clean -fd` → xóa tất cả untracked files
3. Kết quả: Code source Go đã mất!

## ✅ PHẢI LÀM NGAY

### Bước 1: Khôi phục code từ đâu đó

Tìm code ở đâu?
- [ ] Backup từ trước khi cleanup
- [ ] Clone lại từ GitHub/V21 original repo  
- [ ] Copy từ thư mục khác có chứa source code
- [ ] Từ archive file (.rar, .zip)

### Bước 2: Sau khi khôi phục code

```bash
cd D:/Games/HKGH/server-main

# Khôi phục full code về workspace
# ... hướng dẫn cụ thể tùy nơi lấy code ...

# Verify file count
find . -name "*.go" | wc -l

# Add code một cách cẩn thận
git add .

# Commit BEFORE push
git commit -m "feat: Restore complete source code"

# Now test commit first
git status

# Only then consider pushing
```

## 🛡️ PREVENTION - TRÁNH SAI LẦM TƯƠNG LAI

### Trước khi chạy Git commands:

**LUÔN CHECK:**
```bash
# 1. Xem diff sẽ thay đổi gì
git status

# 2. Xem file nào sẽ bị delete
git clean -ndf  # dry run ONLY

# 3. Backup tạm thời
cp -r . ~/backup-$(date +%Y%m%d)

# 4. Thử nghiệm trên branch riêng
git checkout -b test-cleanup
```

### NEVER RUN these without backup:
```bash
❌ git reset --hard       # Delete ALL changes!
❌ git clean -fd          # Delete UNTRACKED files!
❌ rm -rf                 # Dangerous!
```

### SAFE alternatives:
```bash
✅ git stash              # Save changes safely
✅ git branch new-branch  # Work on separate branch
✅ cp -r . backup/        # Manual backup
```

## 📋 CHECKLIST KHÔI PHỤC CODE

### Nếu có backup:
```bash
# Restore from backup folder
rm -rf cmd/ share/ cfg/ script/
cp -r ~/backup-folder/cmd/ .
cp -r ~/backup-folder/share/ .
cp -r ~/backup-folder/cfg/ .
cp -r ~/backup-folder/script/ .

# Re-add all code
git add .
git commit -m "Restore from backup"
```

### Nếu không có backup:
```bash
# Option 1: Clone từ nguồn gốc
cd /tmp
git clone https://github.com/rxjh-emu/server.git
cp -r /tmp/server/cmd D:/Games/HKGH/server-main/
cp -r /tmp/server/share D:/Games/HKGH/server-main/

# Then fix port configurations again
# See FIX_SUMMARY.md for details
```

### Nếu có file source cũ:
```bash
# Unrar hoặc unzip file source
unrar x server-source.rar D:/Games/HKGH/restore/

# Copy lại
cp D:/Games/HKGH/restore/*.go D:/Games/HKGH/server-main/
```

## 🎯 NEXT STEPS NGAY LẬP TỨC

1. **DỪNG** mọi thao tác git để tránh làm mất thêm
2. **TIM** nơi lưu trữ code source Go
3. **RESTORE** code vào thư mục
4. **VERIFY** số lượng file Go (should be hundreds)
5. **COMMIT** cẩn thận vào git
6. **TEST** build thành công
7. **THẤY** remote github với code đầy đủ

## 🆘 CẦN GIUP?

Nếu bạn không thể tìm được source code backup, cho biết:
- Bạn có file `.rar`, `.zip`, `.7z` nào chứa source code không?
- Bạn có path tới repository gốc (rxjh-emu) không?
- Có email hoặc cloud storage nào lưu source không?

Tôi sẽ giúp bạn khôi phục! 😊
