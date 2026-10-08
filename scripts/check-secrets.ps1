# =============================================================================
# Check for Secrets Before Git Push
# PowerShell Script - Run before git push to ensure no sensitive data leaked
# =============================================================================

param(
    [switch]$VerboseMode
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HKGH Server - Security Pre-Push Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# =============================================================================
# Pattern Detection
# =============================================================================

$secretPatterns = @(
    @{Name="MySQL Password"; Regex='password\s*=\s*["'']?\w+["'']?'; CaseSensitive=$false}
    @{Name="Database Password"; Regex='DB_\w+_PASSWORD\s*=\s*["'']?\S+["'']?'; CaseSensitive=$true}
    @{Name="API Key"; Regex='api[_\-]?(key|secret)\s*[:=]\s*["'']?\w+["'']?'; CaseSensitive=$false}
    @{Name="Private Key"; Regex='-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'; CaseSensitive=$true}
    @{Name="JWT Secret"; Regex='jwt[_\-]?(secret|key|signingKey)\s*[:=]\s*["'']?\w+["'']?'; CaseSensitive=$false}
    @{Name="AWS Key"; Regex='AKIA[0-9A-Z]{16}'; CaseSensitive=$true}
)

$configExtensions = @('.ini', '.cfg', '.conf', '.yaml', '.yml', '.json', '.env')

# =============================================================================
# Scan Configuration Files
# =============================================================================

Write-Host "[1/3] Scanning configuration files..." -ForegroundColor Yellow

Get-ChildItem -Recurse -Include *${configExtensions} -Exclude .gitignore,.env.example | 
    ForEach-Object {
        $fileContent = Get-Content $_.FullName -Raw
        
        foreach ($pattern in $secretPatterns) {
            if ([regex]::IsMatch($fileContent, $pattern.Regex, 
                [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
                
                # Skip placeholder values
                $matches = [regex]::Matches($fileContent, $pattern.Regex, 
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                foreach ($match in $matches) {
                    $value = $match.Value.Trim()
                    
                    # Check if it's a placeholder or localhost value
                    if (-not ($value -like "*change_me*" -or 
                             $value -like "*your_password*" -or
                             $value -like "localhost" -or
                             $value -like "127.0.0.1" -or
                             $value -like "*" -or
                             $value -eq "")) {
                        
                        $errors += "🚫 SECRET FOUND in $($_.FullName):"
                        $errors += "   Type: $($pattern.Name)"
                        $errors += "   Match: $($match.Value)"
                        $errors += "   Line: $(Get-Content $_.FullName | Select-String -Pattern $pattern.Regex).LineNumber"
                        $errors += ""
                    }
                }
            }
        }
    }

# =============================================================================
# Check Environment Variables
# =============================================================================

Write-Host ""
Write-Host "[2/3] Checking environment files..." -ForegroundColor Yellow

# Check if .env exists and has real values
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    
    $hasRealPasswords = $false
    $passwordVars = @('DB_LOGIN_PASSWORD', 'DB_WORLD_PASSWORD', 'MYSQL_PASSWORD', 'ROOT_PASSWORD')
    
    foreach ($var in $passwordVars) {
        if ($envContent -match "$var\s*=\s*['\"\']?\S+") {
            $value = ($envContent -match "$var\s*=\s*(.*)" -replace "$var\s*=\s*", "").Trim("'`" ")
            
            if ($value -and 
                $value -ne "change_me" -and 
                $value -ne "your_password" -and
                $value.Length -gt 0) {
                $hasRealPasswords = $true
                break
            }
        }
    }
    
    if ($hasRealPasswords) {
        $warnings += "⚠️ .env file contains password entries"
        $warnings += "   This is OK for local development, but NEVER commit .env file!"
        $warnings += "   Make sure .env is listed in .gitignore"
        $warnings += ""
    }
} else {
    Write-Host "   ✅ No .env file found (this is fine for production deployments)" -ForegroundColor Green
}

# =============================================================================
# Check Git Status
# =============================================================================

Write-Host ""
Write-Host "[3/3] Checking git status..." -ForegroundColor Yellow

try {
    $gitStatus = git status --porcelain
    
    if ([string]::IsNullOrEmpty($gitStatus)) {
        Write-Host "   ✅ Working directory is clean" -ForegroundColor Green
    } else {
        Write-Host "   📝 Files staged for commit:" -ForegroundColor Yellow
        
        $stagedFiles = $gitStatus.Split("`n") | Where-Object { $_ -like " A*" -or $_ -like "MM*" }
        
        if ($stagedFiles.Count -eq 0) {
            $stagedFiles = $gitStatus.Split("`n") | Where-Object { $_.Trim() -ne "" }
        }
        
        foreach ($file in $stagedFiles) {
            $status = $file.Substring(0, 2)
            $filepath = $file.Substring(2).Trim()
            
            # Check if it's a config or sensitive file
            if ($configExtensions -contains [IO.Path]::GetExtension($filepath)) {
                Write-Host "   ⚡ CONFIG FILE: $filepath" -ForegroundColor Cyan
            }
            
            # Check for suspicious filenames
            if ($filepath -like "*password*" -or 
                $filepath -like "*secret*" -or
                $filepath -like "*credential*" -or
                $filepath -like "*private*") {
                $errors += "🚨 Potentially sensitive file staged: $filepath"
            }
        }
    }
} catch {
    Write-Host "   ❌ Could not run git command" -ForegroundColor Red
    $errors += "Error checking git status: $($_.Exception.Message)"
}

# =============================================================================
# Report Results
# =============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SECURITY CHECK RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -gt 0) {
    Write-Host "❌ CRITICAL ERRORS DETECTED!" -ForegroundColor Red
    Write-Host "DO NOT PUSH UNTIL THESE ARE FIXED!" -ForegroundColor Red
    Write-Host ""
    
    foreach ($error in $errors) {
        Write-Host $error -ForegroundColor Red
    }
    
    exit 1
} elseif ($warnings.Count -gt 0) {
    Write-Host "⚠️ WARNINGS FOUND" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($warning in $warnings) {
        Write-Host $warning -ForegroundColor Yellow
    }
    
    $response = Read-Host "`nContinue with push anyway? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        exit 1
    }
} else {
    Write-Host "✅ ALL SECURITY CHECKS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can safely proceed with git push" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Check completed at: $(Get-Date)" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan

exit 0
