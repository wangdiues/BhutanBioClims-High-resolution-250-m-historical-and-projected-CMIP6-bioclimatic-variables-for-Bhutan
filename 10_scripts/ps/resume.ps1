# 🚀 Quick Resume Script - Next Session

# Run this at the start of your next session

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Bhutan CMIP6 BIOCLIM - Resume Session" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

# Check git status
Write-Host "1. Checking Git Status..." -ForegroundColor Yellow
git status --short

# Check current branch
Write-Host "`n2. Current Branch:" -ForegroundColor Yellow
git branch --show-current

# Check remote
Write-Host "`n3. Remote Configuration:" -ForegroundColor Yellow
git remote -v

# Verify tracked files
Write-Host "`n4. Tracked Files:" -ForegroundColor Yellow
git ls-files | Measure-Object | Select-Object Count

# Check for cleanup items
Write-Host "`n5. Checking Cleanup Items..." -ForegroundColor Yellow

# Check 00_project_metadata\data_download.md for placeholders
$placeholders = Select-String -Path "00_project_metadata\data_download.md" -Pattern "Replace with actual" -Quiet
if ($placeholders) {
    Write-Host "  ⚠️  00_project_metadata\data_download.md has placeholder URLs" -ForegroundColor Red
} else {
    Write-Host "  ✅ 00_project_metadata\data_download.md - URLs updated" -ForegroundColor Green
}

# Check branch name
$branch = git branch --show-current
if ($branch -eq "main") {
    Write-Host "  ✅ Branch name: $branch" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Branch name: $branch (should be 'main')" -ForegroundColor Red
}

# Check remote
$remote = git remote get-url origin 2>$null
if ($remote) {
    Write-Host "  ✅ Remote configured" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Remote not configured" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Ready to Continue!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Fix placeholder URLs in 00_project_metadata\data_download.md"
Write-Host "2. Rename branch: git branch -M master main"
Write-Host "3. Add remote: git remote add origin <URL>"
Write-Host "4. Push to GitHub: git push -u origin main"
Write-Host ""
