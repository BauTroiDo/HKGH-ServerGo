# 🚀 KẾ HOẠCH NÂNG CẤP SERVER GO - HKGH

**Ngày lập:** 2026-10-09  
**Phiên bản hiện tại:** server-main (Go)  
**Mức độ ưu tiên:** CRITICAL ⚠️

---

## 🎯 MỤC TIÊU

1. ✅ **Fix critical bug** - Lỗi typo IP làm break toàn bộ hệ thống
2. ⚡ **Chuẩn hóa port configuration** - Loại bỏ sự mơ hồ giữa default và config
3. 🔒 **Cải thiện security** - Thêm validation, monitoring, graceful shutdown
4. 🏗️ **Nâng cao reliability** - Handle edge cases, improve error handling
5. 📊 **Tăng maintainability** - Code clarity, documentation, testing

---

## 🔴 TASK 1: FIX CRITICAL BUG - [URGENT]

### Problem: Typo trong MasterIP default value

**File:** `cmd/loginserver/def/config.go:43`

```go
// ❌ HIỆN TẠI (SAI NGHIÊM TRỌNG)
c.MasterIp = conf.GetString("master", "ip", "1270.0.1")

// ✅ PHẢI SỬA THÀNH
c.MasterIp = conf.GetString("master", "ip", "127.0.0.1")
```

**Impact:**
- LoginServer không thể connect tới MasterServer qua RPC
- Toàn bộ authentication flow bị break
- User không thể login vào game

**Action Plan:**
1. Sửa giá trị default trong config.go
2. Run tests để verify connection works
3. Update documentation

**Deadline:** NGAY LẬP TỨC (P0 Critical)

---

## 🟡 TASK 2: CHUẨN HÓA PORT CONFIGURATION

### Problem: Default value không khớp với config thực tế gây nhầm lẫn

**Current State:**
| Server | Default Code | Config Value | Status |
|--------|-------------|--------------|--------|
| LoginServer | 16100 | 1321 | ⚠️ Mismatch |
| GameServer | 16101 | 13211 | ⚠️ Mismatch |
| MasterServer | 9001 | 9001 | ✅ Perfect |

### Solution: Align defaults with legacy compatibility

**Files cần sửa:**

#### 1. `cmd/loginserver/def/config.go:36`
```go
// Change default to match V21 legacy + current production
c.Port = conf.GetInt("network", "port", 1321)  // Was: 16100
```

#### 2. `cmd/gameserver/def/config.go:52`
```go
// Change default to match V21 legacy + current production
c.Port = conf.GetInt("network", "port", 13211)  // Was: 16101
```

**Rationale:**
- Client V21 đã hardcoded port 1321/13211
- Production đang dùng 1321/13211
- Default code phải match production để avoid config-less errors

---

## 🟡 TASK 3: IMPROVE NETWORK MANAGEMENT

### 3.1 Add Port Conflict Detection

**File:** `share/network/network.go:22`

Add pre-check before listen:

```go
func (n *Network) Init(port int, s *server.Settings, protocol Protocol) {
    // ... existing setup ...
    
    // NEW: Check if port is already in use
    conn, err := net.DialTimeout("tcp", ":"+strconv.Itoa(port), 1*time.Second)
    if err == nil {
        conn.Close()
        log.Fatalf("Port %d is already in use!", port)
    }
    
    // Then proceed with normal listen...
}
```

### 3.2 Add SO_REUSEADDR Option

```go
import "golang.org/x/sys/unix"

listen, err := sysnet.ListenTCP("tcp", &net.TCPAddr{Port: port})
if err != nil {
    log.Fatal(err)
}

// Set SO_REUSEADDR on raw connection
rawConn, err := listen.SyscallConn()
if err == nil {
    rawConn.Control(func(fd uintptr) {
        unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_REUSEADDR, 1)
    })
}
```

### 3.3 Add Connection Timeout

```go
l, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
if err != nil {
    log.Fatal(err.Error())
}

// Set listener timeout
l.SetDeadline(time.Now().Add(10 * time.Minute))
```

---

## 🟡 TASK 4: WEBSERVER REFACTORING

### Problem: Hard-coded port, no lifecycle management

**File:** `cmd/gameserver/packet/v21_webshop_server.go`

### Requirements:
1. Make port configurable via env/config
2. Add graceful shutdown
3. Add health check endpoint
4. Add metrics/logging

### Implementation:

```go
type WebShopServer struct {
    mux      *http.ServeMux
    server   *http.Server
    port     string
    doneChan chan struct{}
}

func StartWebShopServer(configPort string) (*WebShopServer, error) {
    // Use env override or config file
    port := os.Getenv("WEBSHOP_PORT")
    if port == "" {
        port = configPort
    }
    
    s := &WebShopServer{
        mux:      http.NewServeMux(),
        port:     port,
        doneChan: make(chan struct{}),
    }
    
    // Setup routes
    s.mux.HandleFunc("/shop", handleShopPage)
    s.mux.HandleFunc("/shop/api/catalog", handleShopCatalog)
    s.mux.HandleFunc("/shop/api/info", handleShopInfo)
    s.mux.HandleFunc("/shop/api/buy", handleShopBuy)
    s.mux.HandleFunc("/health", handleHealth)
    
    addr := ":" + port
    s.server = &http.Server{
        Addr:         addr,
        Handler:      s.mux,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }
    
    go func() {
        log.Infof("[WEBSHOP] Starting Bách Bảo Các web shop at http://127.0.0.1:%s", port)
        if err := s.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Errorf("[WEBSHOP] HTTP server stopped: %v", err)
            close(s.doneChan)
        }
    }()
    
    return s, nil
}

// Add GracefulShutdown method
func (s *WebShopServer) GracefulShutdown(ctx context.Context) error {
    defer close(s.doneChan)
    return s.server.Shutdown(ctx)
}

// Add Health Check handler
func handleHealth(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}
```

---

## 🟡 TASK 5: ADD MONITORING & METRICS

### Create `/share/monitoring/server_stats.go`

```go
package monitoring

import (
    "expvar"
    "net/http"
)

var ServerStats = new(expvar.Map)

func init() {
    // Export standard Go runtime stats
    expvar.Publish("goroutines", expvar.Func(func() interface{} {
        return runtime.NumGoroutine()
    }))
    
    expvar.Publish("memory_alloc", expvar.Func(func() interface{} {
        var m runtime.MemStats
        runtime.ReadMemStats(&m)
        return m.Alloc
    }))
    
    // Custom stats
    ServerStats.Init()
    ServerStats.Add("online_users", 0)
    ServerStats.Add("rpc_connections", 0)
    ServerStats.Add("web_requests", 0)
    
    // Mount metrics endpoint
    http.Handle("/metrics", expvar.Handler())
}
```

### Add startup metric endpoint registration

**File:** `cmd/gameserver/main.go`

```go
// After all initializations
go func() {
    metricsAddr := ":9090"
    log.Infof("Starting metrics endpoint at http://localhost%s/metrics", metricsAddr)
    http.ListenAndServe(metricsAddr, nil)
}()
```

---

## 🟢 TASK 6: SECURITY HARDENING

### 6.1 Input Validation for Ports

**File:** `share/conf/config_validator.go` (new file)

```go
package conf

func ValidatePort(port int, min, max int) error {
    if port < min || port > max {
        return fmt.Errorf("invalid port %d: must be between %d and %d", port, min, max)
    }
    if port < 1024 && os.Geteuid() != 0 {
        log.Warnf("Port %d requires root privileges", port)
    }
    return nil
}
```

### 6.2 Rate Limiting for Network Connections

```go
type RateLimitedNetwork struct {
    *Network
    limiter *rate.Limiter
}

func NewRateLimitedNetwork(port int, ...) (*RateLimitedNetwork, error) {
    n, err := net.Dial("tcp", addr)
    if err != nil {
        return nil, err
    }
    
    rl := RateLimitedNetwork{
        Network: n,
        limiter: rate.NewLimiter(rate.Every(time.Second), 100),
    }
    
    return &rl, nil
}
```

---

## 🟢 TASK 7: TESTING & VALIDATION

### Unit Tests Required:

1. **Port Configuration Tests**
   ```go
   func TestPortConfiguration(t *testing.T) {
       tests := []struct {
           name     string
           input    string
           expected int
       }{
           {"valid config", "1321", 1321},
           {"default fallback", "", 1321}, // Should use new default
       }
       
       for _, tt := range tests {
           t.Run(tt.name, func(t *testing.T) {
               // Test port parsing
           })
       }
   }
   ```

2. **Connection Tests**
   - Test RPC connectivity between Login ↔ Master
   - Test client → Login → Game chain
   
3. **Stress Tests**
   - 1000 concurrent connections
   - Memory leak detection
   - Session cleanup verification

---

## 📊 IMPLEMENTATION ROADMAP

### Phase 1: Emergency Fixes (Day 1)
- ✅ Fix typo IP bug (CRITICAL)
- ✅ Verify RPC connection works
- ✅ Deploy hotfix to production

### Phase 2: Configuration Cleanup (Week 1)
- Align default ports with production
- Document all port assignments
- Create port reference guide

### Phase 3: Infrastructure Improvements (Week 2-3)
- Add port conflict detection
- Implement graceful shutdown
- Add health check endpoints
- Add metrics/exporters

### Phase 4: Security Hardening (Week 4)
- Input validation
- Rate limiting
- Connection pooling optimization
- Security audit

### Phase 5: Testing & Documentation (Week 5)
- Comprehensive test suite
- Performance benchmarks
- Deployment runbooks
- Operations documentation

---

## 📋 CHECKLIST

### Pre-deployment:
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance benchmarks documented
- [ ] Security scan clean
- [ ] Rollback plan prepared

### Post-deployment:
- [ ] Monitor metrics dashboards
- [ ] Alert rules configured
- [ ] Log aggregation working
- [ ] Backup procedures tested

---

## 🔧 TOOLING & DEPENDENCIES

### New Go packages needed:
```go
import (
    "golang.org/x/sys/unix"              // For SO_REUSEADDR
    "github.com/prometheus/client_golang" // Metrics (optional)
    "github.com/rs/zerolog"              // Better logging
)
```

### Build commands:
```bash
# Build all servers
cd server-main
go build -o bin/masterserver ./cmd/masterserver
go build -o bin/loginserver ./cmd/loginserver
go build -o bin/gameserver ./cmd/gameserver

# Run tests
go test ./... -race -cover

# Run benchmark
go test -bench=. -benchmem
```

---

## 📞 CONTACTS & RESOURCES

- **Project:** HKGH (Heaven Kingdom Giang Hồ)
- **Repository:** D:\Games\HKGH\server-main
- **Issue Tracker:** GitHub Issues
- **Documentation:** `/docs/` folder

---

## ⚠️ WARNING

**TRƯỚC KHI BẮT ĐẦU:**
1. Create full backup of current deployment
2. Notify all stakeholders
3. Schedule maintenance window
4. Prepare rollback procedures
5. Test in staging environment first!

---

**Last Updated:** 2026-10-09  
**Version:** 1.0  
**Status:** Ready for Review
