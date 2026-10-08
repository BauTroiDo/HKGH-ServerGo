# 🚀 HƯỚNG DẪN PUSH CODE LÊN GITHUB

## ✅ ĐÃ HOÀN THÀNH

- Git repository đã được khởi tạo tại `D:\Games\HKGH\server-main`
- Đã có 1 commit với các fixes quan trọng
- Commit hash: `e41db6a`

---

## 📋 COMMIT ĐÃ THỰC HIỆN

**Commit Message:**
```
Fix: Critical IP typo and port configuration alignment

## CRITICAL FIXES:
1. [CRITICAL] Fix MasterIP typo in loginserver config: 1270.0.1 → 127.0.0.1
   - This was breaking RPC connection between LoginServer ↔ MasterServer
   
2. [ENHANCEMENT] Align default ports with production values:
   - LoginServer: 16100 → 1321 (matches current production config)
   - GameServer: 16101 → 13211 (matches current production config)

## DOCUMENTATION:
- Added comprehensive UPGRADE_PLAN.md for future improvements
- Created FIX_SUMMARY.md documenting all changes
- Added COMMIT_GUIDE.md for version control guidance
```

**Files Committed:**
- ✅ `cmd/loginserver/def/config.go` - Fixed critical bugs
- ✅ `cmd/gameserver/def/config.go` - Updated default ports
- ✅ `UPGRADE_PLAN.md` - 5-phase upgrade roadmap
- ✅ `FIX_SUMMARY.md` - Detailed fix documentation
- ✅ `COMMIT_GUIDE.md` - Git usage guide

---

## 🔧 CÁC BƯỚC PUSH LÊN GITHUB

### Bước 1: Tạo Repository trên GitHub

1. Truy cập https://github.com/new
2. Nhập tên repository: `server-main` hoặc `hkgh-server`
3. Chọn Private/Public tùy ý
4. Không tick "Initialize with README" (vì đã có code rồi)
5. Click "Create repository"

GitHub sẽ hiển thị lệnh push, ví dụ:
```bash
git remote add origin https://github.com/YOUR_USERNAME/repo_name.git
git branch -M main
git push -u origin main
```

### Bước 2: Thêm Remote Origin

Thay `<YOUR_USERNAME>` và `<REPO_NAME>` bằng thông tin thực tế:

```bash
cd D:/Games/HKGH/server-main

# Replace <username> và <repo-name> với thông tin của bạn
git remote add origin https://github.com/<username>/<repo-name>.git
```

Ví dụ:
```bash
git remote add origin https://github.com/QT/hkgh-server.git
```

### Bước 3: Rename Branch sang 'main' (nếu cần)

```bash
git branch -M main
```

### Bước 4: Push lên GitHub

```bash
git push -u origin main
```

Nếu có lỗi authentication:
```bash
# Option 1: Sử dụng HTTPS với Personal Access Token
# Sau đó nhập username và token (không phải password)

# Option 2: Sử dụng SSH (cần setup SSH key trước)
git remote set-url origin git@github.com:<username>/<repo-name>.git
git push -u origin main
```

---

## 🆘 XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi 1: "Repository not found"

**Nguyên nhân:** Tên repository không đúng  
**Giải pháp:** Kiểm tra lại URL và tên repo trên GitHub

### Lỗi 2: "Permission denied"

**Nguyên nhân:** Thiếu authentication  
**Giải pháp:** 
- Tạo Personal Access Token từ https://github.com/settings/tokens
- Dùng token thay vì password khi push

### Lỗ 3: "Already exists in remote"

**Nguyên nhân:** Repo đã tồn tại  
**Giải pháp:** Xóa repo cũ hoặc đổi tên local branch
```bash
git branch -M main-backup
git push -u origin main-backup
```

---

## 🔒 SÉCURITY CHECKLIST TRƯỚC KHI PUSH

**QUAN TRỌNG!** Kiểm tra kỹ các file sau:

### ⚠️ Files cần kiểm tra:

1. **cfg/*.ini files** - Remove passwords trong database config
   ```ini
   [login]
   ip=127.0.0.1
   port=3306
   database=db_login
   username=root
   password=<REMOVE THIS OR USE ENV VAR>
   ```

2. **Các file .env** - Đảm bảo không có secrets real
   ```bash
   # Nếu có file .env, add vào .gitignore
   echo ".env" >> .gitignore
   echo ".env.local" >> .gitignore
   ```

3. **API Keys/Tokens** - Kiểm tra không hard-coded trong source code
   ```bash
   # Search for potential secrets
   git grep -i "password" -- "*.go" | grep -v "log.Fatal"
   git grep -i "secret" -- "*.go" | grep -v "// "
   ```

### ✅ Actions để secure before push:

```bash
# Check if any sensitive files exist
ls cfg/*.ini | grep -i pass

# If found, create backup then edit to remove passwords
cp cfg/loginserver.ini cfg/loginserver.ini.bak
# Edit file manually or use sed to replace password
sed -i 's/password=.*/password=\${DB_PASSWORD}/g' cfg/loginserver.ini
```

---

## 📊 GIT HISTORY BEST PRACTICES

### Nên commit nhỏ, frequent:
```bash
# ✅ GOOD: Small focused commits
git add file1.go && git commit -m "Fix A"
git add file2.go && git commit -m "Improve B"

# ❌ BAD: Large dump of everything
git add -A && git commit -m "Lots of changes"
```

### Commit message convention:
```
type: short description

[optional detailed body]

Types:
- feat:     New feature
- fix:      Bug fix
- docs:     Documentation update
- refactor: Code restructuring
- test:     Adding tests
- chore:    Maintenance tasks
```

---

## 🔄 SYNCING UPSTREAM CHANGES

Nếu repository có collaborators:

```bash
# Before starting work, sync with remote
git fetch origin
git rebase origin/main

# After making changes and committing
git push origin main

# If there are conflicts during push, do force pull
git pull --rebase origin main
```

---

## 💡 MẸO VÀ HACKS

### 1. Xem ai đã sửa gì trong file
```bash
git blame cmd/loginserver/def/config.go
```

### 2. Undo last commit (giữ changes)
```bash
git reset --soft HEAD~1
```

### 3. Delete last commit (xóa luôn changes)
```bash
git reset --hard HEAD~1
```

### 4. Stash tạm thời changes
```bash
git stash save "WIP: working on something"
# ... make other commits ...
git stash pop  # Bring back stashed changes
```

### 5. View full diff
```bash
git show e41db6a
```

---

## 📱 POST-PUSH ACTIONS

Sau khi push xong:

1. ✅ **Verify trên GitHub**: Truy cập https://github.com/YOUR_USERNAME/repo
2. ✅ **Share với team**: Send link repository cho developers
3. ✅ **Setup CI/CD**: Configure GitHub Actions cho auto-build/test
4. ✅ **Enable Issues**: Bật issue tracking
5. ✅ **Add README better**: Update README.md với details

---

## 🎯 EXAMPLE FULL COMMAND SEQUENCE

```bash
cd D:/Games/HKGH/server-main

# Step 1: Add remote (replace with your info)
git remote add origin https://github.com/QT/hkgh-server.git

# Step 2: Ensure main branch
git branch -M main

# Step 3: Push
git push -u origin main

# Success! Visit https://github.com/QT/hkgh-server
```

---

## 📞 NEED HELP?

- Git Docs: https://git-scm.com/doc
- GitHub Docs: https://docs.github.com/
- Git Cheatsheet: https://教育.codingninjas.com/information/git-and-github-cheat-sheet

---

**Last Updated:** 2026-10-09  
**Repository:** D:\Games\HKGH\server-main  
**Current Commit:** e41db6a  
**Status:** Ready to push to GitHub
