# 🔒 HƯỚNG DẪN QUẢN LÝ MẬT KHẨU & SECRET CHO HKGH SERVER

## 🎯 MỤC TIÊU

- Bảo mật thông tin nhạy cảm (passwords, API keys) không bị commit lên git
- Dễ dàng deployment với environment variables
- Standard hóa cấu hình giữa các environments (dev/staging/prod)

---

## ✅ CÁC FILES AN TOÀN ĐỂ COMMIT

### Files đã được approve để commit:

1. **cfg/loginserver.ini** - Cấu hình cơ bản (không có password)
2. **cfg/masterserver.ini** - Cấu trúc database template
3. **cfg/gameserver_1.ini** - Game configuration
4. **.gitignore** - Đã cập nhật để exclude sensitive files

---

## ⚠️ FILES KHÔNG ĐƯỢC COMMIT

### Các file này sẽ được .gitignore exclude:

```bash
# User-specific configs với passwords
cfg/*.local.ini
.env
.env.local
.env.production

# Secrets files
secrets.json
passwords.txt
credentials.yml
```

---

## 📋 CÁCH SỬ DỤNG

### Bước 1: Tạo .env file cho local development

```bash
cd D:/Games/HKGH/server-main

# Copy template
copy .env.example .env

# Edit .env và fill passwords thực tế của bạn
notepad .env
```

### Bước 2: Sử dụng trong code

Các servers tự động load `.env` nếu có:

```go
import "github.com/joho/godotenv"

func init() {
    godotenv.Load() // Load from .env if exists
    
    // Get password from env var
    dbPassword := os.Getenv("DB_LOGIN_PASSWORD")
}
```

---

## 🔧 CONFIG FILES BEST PRACTICES

### Nguyên tắc vàng:

✅ **COMMIT:** Config templates với placeholder values  
❌ **DO NOT COMMIT:** Config files với real passwords

### Cấu trúc khuyến nghị:

```
cfg/
├── loginserver.ini          ✅ Commit (template)
├── masterserver.ini         ✅ Commit (template)
├── gameserver_1.ini         ✅ Commit (template)
├── loginserver.local.ini    ❌ Don't commit (override với passwords)
├── .env                     ❌ Don't commit (env variables)
└── .env.example             ✅ Commit (template for others)
```

---

## 🛡️ TẠO LOCAL OVERRIDE FILES

### Nếu cần customize cho local machine:

#### 1. Tạo `loginserver.local.ini`:
```ini
; Overrides for your local development
[network]
port=1321

[login]
ip=localhost
port=3306
database=db_login
username=root
password=YOUR_LOCAL_PASSWORD ; Change this!
```

#### 2. Code load cả hai files:
```go
// First read base config
config.Read("cfg/loginserver.ini")

// Then override with local file if exists
if _, err := os.Stat("cfg/loginserver.local.ini"); err == nil {
    config.Read("cfg/loginserver.local.ini")
}
```

---

## 🌍 MULTIPLE ENVIRONMENTS

### Example directory structure:

```
D:/Games/HKGH/server-main/
├── cfg/
│   ├── loginserver.ini           # Base template
│   ├── loginserver.dev.ini       # Local dev overrides
│   ├── loginserver.staging.ini   # Staging environment
│   └── loginserver.prod.ini      # Production secrets
│
├── .env                          # Current environment active
├── .env.dev                      # Dev environment vars
├── .env.staging                  # Staging environment vars
└── .env.prod                     # Production environment vars
```

### Script để switch environments:

```bash
#!/bin/bash
# switch-env.sh

ENV=$1

case $ENV in
  dev)
    cp .env.dev .env
    echo "Switched to DEV environment"
    ;;
  staging)
    cp .env.staging .env
    echo "Switched to STAGING environment"
    ;;
  prod)
    cp .env.prod .env
    echo "Switched to PROD environment"
    ;;
  *)
    echo "Usage: ./switch-env.sh [dev|staging|prod]"
    exit 1
    ;;
esac
```

---

## 🔄 DEPLOYMENT SECURITY CHECKLIST

### Trước khi deploy:

- [ ] Verify .env file không có trong git repo
- [ ] Check tất cả passwords là unique cho mỗi server
- [ ] Sử dụng strong passwords (min 12 chars, mix upper/lower/numbers/symbols)
- [ ] Rotate passwords định kỳ
- [ ] Limit DB user permissions (không dùng root trong production)

### Sau khi deploy:

- [ ] Test connection với credentials mới
- [ ] Monitor logs cho any unauthorized access attempts
- [ ] Enable firewall rules chỉ allow từ internal IPs
- [ ] Setup HTTPS cho web endpoints
- [ ] Enable rate limiting

---

## 🐛 XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi: "Database connection failed"

**Nguyên nhân:** Password incorrect hoặc host unreachable  
**Giải pháp:**
```bash
# Check your .env file
cat .env | grep DB_LOGIN

# Verify credentials work manually
mysql -h localhost -u root -p -e "SHOW DATABASES;"
```

### Lỗi: "Port already in use"

**Nguyên nhân:** Port conflict  
**Giải pháp:**
```bash
# Find what's using the port
netstat -ano | findstr :1321

# Kill the process
taskkill /PID <PID> /F
```

---

## 🚀 CI/CD PIPELINE TIPS

### GitHub Actions: Store secrets securely

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      # Create .env from secrets
      - name: Create .env
        run: |
          echo "${{ secrets.ENV_CONTENT }}" > .env
      
      # Build and test
      - name: Build
        run: go build ./...
      
      # Deploy
      - name: Deploy
        run: ./deploy.sh
```

### GitHub Secrets setup:

1. Go to repository Settings → Secrets → New repository secret
2. Add sensitive variables:
   - `DB_LOGIN_PASSWORD`
   - `DB_WORLD_PASSWORD`
   - `CASH_WEB_API_KEY`
   
---

## 📊 MONITORING SECURITY

### Log-sensitive-events:

```go
package logging

func LoginAttempt(username string, success bool) {
    level := "INFO"
    if !success {
        level = "WARN"
    }
    
    log.Logf(level, "Login attempt: %s, Success: %t", username, success)
}
```

### Alert thresholds:

- Failed login attempts > 5 per minute → Send alert
- Database connection errors > 3 per hour → Investigate
- Unusual network traffic → Security review

---

## 🎓 TÀI NGUYÊN THAM KHẢO

- **OWASP Secret Management**: https://owasp.org/www-project-secrets-management/
- **GitHub Secrets Docs**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **Go Environment Variables**: https://pkg.go.dev/os#Env
- **Best Practices**: https://12factor.net/config

---

**Last Updated:** 2026-10-09  
**Author:** HKGH Dev Team  
**Status:** Active
