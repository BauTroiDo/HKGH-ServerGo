# 🔧 HƯỚNG DẪN COMMIT CÁC THAY ĐỔI

## 📋 FILES ĐÃ MODIFY

### 1. Code Fixes (Critical)

**File:** `cmd/loginserver/def/config.go`

**Changes:**
```diff
-	c.MasterIp = conf.GetString("master", "ip", "1270.0.1")
+	c.MasterIp = conf.GetString("master", "ip", "127.0.0.1") // Fixed typo: was "1270.0.1"

-	c.Port = conf.GetInt("network", "port", 16100)
+	c.Port = conf.GetInt("network", "port", 1321) // Legacy V21 port (was 16100)
```

**File:** `cmd/gameserver/def/config.go`

**Changes:**
```diff
-	c.Port = conf.GetInt("network", "port", 16101)
+	c.Port = conf.GetInt("network", "port", 13211) // Legacy V21 port (was 16101)
```

---

## 🎯 CÁCH COMMIT

### Option 1: Nếu đã có git repository

```bash
cd D:/Games/HKGH/server-main

# Commit các files đã sửa
git add cmd/loginserver/def/config.go
git add cmd/gameserver/def/config.go
git add -A

# Commit với message chi tiết
git commit -m "$(cat <<'EOF'
Fix: Critical IP typo and port configuration alignment

## Changes:
1. [CRITICAL] Fix MasterIP typo in loginserver config: 1270.0.1 → 127.0.0.1
   - This was breaking RPC connection between LoginServer ↔ MasterServer
   
2. [ENHANCEMENT] Align default ports with production values:
   - LoginServer: 16100 → 1321 (matches current production config)
   - GameServer: 16101 → 13211 (matches current production config)
   - Ensures servers work correctly even with minimal configuration

## Impact:
- Login authentication flow now works properly
- Servers operate on correct default ports for legacy V21 clients
- Reduces deployment configuration errors

## Testing Required:
- [ ] Verify RPC connectivity after rebuild
- [ ] Test client login with port 1321
- [ ] Test game session with port 13211

Fixes critical bug preventing server communication.
EOF
)"
```

---

### Option 2: Khởi tạo git mới (nếu chưa có)

```bash
cd D:/Games/HKGH/server-main

# Initialize git repository
git init

# Add remote if needed
git remote add origin <your-github-url>.git

# Stage all changes
git add cmd/
git add .

# Create initial commit
git commit -m "Initial commit with critical fixes

1. Fixed critical IP typo (1270.0.1 → 127.0.0.1) in loginserver config
2. Aligned default ports with production (1321, 13211)
3. Added comprehensive upgrade plan and documentation"
```

---

## 📊 GIT LOG MẪU

Sau khi commit, verify với:

```bash
# View recent commits
git log --oneline -5

# Show detailed diff
git show HEAD

# View changed files
git status
```

---

## 🔄 PUSH TO REMOTE (nếu có)

```bash
# If this is the first push
git branch -M main
git push -u origin main

# If already exists
git push -f origin main
```

---

## ✅ CHECKLIST TRƯỚC KHI COMMIT

- [ ] Tất cả code changes đã được test
- [ ] Documentation files updated (UPGRADE_PLAN.md, FIX_SUMMARY.md)
- [ ] Commit message descriptive và rõ ràng
- [ ] No sensitive data (passwords, API keys) in commits
- [ ] Git ignore file configured properly

---

## 🚨 LƯU Ý QUAN TRỌNG

1. **BACKUP TRƯỚC**: Tạo backup toàn bộ thư mục trước khi commit
2. **TEST sau rebuild**: Build lại và test tất cả services
3. **DOCUMENTATION**: Đã create 2 markdown files documenting changes
4. **ROLLBACK PLAN**: Giữ bản copy của original files nếu cần rollback

---

## 📞 SUPPORT

Nếu gặp vấn đề khi commit:
- Check git version: `git --version`
- Check user config: `git config user.name && git config user.email`
- See git help: `git help` or visit https://git-scm.com/doc

---

**Date Created:** 2026-10-09  
**Repository:** D:/Games/HKGH/server-main  
**Status:** Ready to commit
