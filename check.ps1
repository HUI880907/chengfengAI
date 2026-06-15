# ChengFengAI - Project Check Script (PowerShell)
# Usage: Run from project root: .\check.ps1

$ErrorActionPreference = "Continue"

# ============================================================
# Configuration
# ============================================================

# Get the directory where THIS script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Set project root to script directory
$projectRoot = $scriptDir

# Define subdirectories (using variables to avoid encoding issues)
$srcSubDir = "ChengFengAI"
$testSubDir = "Tests"

# First try: the English directory name
$srcDir = (Join-Path $projectRoot $srcSubDir)
$testDir = (Join-Path $projectRoot $testSubDir)
$logFile = (Join-Path $projectRoot "check_results.log")

# Alternative: try the 乘风AI directory (which may appear as different bytes)
# Scan for any subdirectory containing .swift files
if (-not (Test-Path $srcDir)) {
    $subDirs = Get-ChildItem -Path $projectRoot -Directory -ErrorAction SilentlyContinue
    foreach ($d in $subDirs) {
        $potentialSwiftDir = (Join-Path $d.FullName "*.swift")
        $hasSwift = Test-Path $potentialSwiftDir
        if ($hasSwift) {
            $srcDir = $d.FullName
            break
        }
    }
}

# If still not found, search for Models directory as reference
if (-not (Test-Path (Join-Path $srcDir "Models"))) {
    $modelsDirs = Get-ChildItem -Path $projectRoot -Recurse -Directory -Filter "Models" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($modelsDirs) {
        $srcDir = Split-Path -Parent $modelsDirs.FullName
    }
}

# Print paths for debugging
Write-Host "=========================================="
Write-Host "  ChengFengAI - Project Check Tool"
Write-Host "  Version 1.0.0"
Write-Host "  Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=========================================="
Write-Host ""
Write-Host "Script dir: $scriptDir"
Write-Host "Project root: $projectRoot"
Write-Host "Source dir: $srcDir"
Write-Host "Tests dir: $testDir"
Write-Host "Log file: $logFile"
Write-Host ""

# Counter variables
$script:successCount = 0
$script:failCount = 0
$script:warnCount = 0

# ============================================================
# Helper Functions
# ============================================================

function Write-Info  { param($m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-OK    { param($m) Write-Host "[OK]    $m" -ForegroundColor Green; $script:successCount++ }
function Write-Warn  { param($m) Write-Host "[WARN]  $m" -ForegroundColor Yellow; $script:warnCount++ }
function Write-Fail  { param($m) Write-Host "[FAIL]  $m" -ForegroundColor Red; $script:failCount++ }
function Write-Sep   { Write-Host "==========================================" -ForegroundColor Gray }
function Write-Log   { param($m) Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" }

# Clear old log
if (Test-Path $logFile) { Remove-Item $logFile -Force }
Write-Log "=== ChengFengAI Project Check START ==="
Write-Log "Project: $projectRoot"
Write-Log "Source: $srcDir"
Write-Log "Tests: $testDir"

# ============================================================
# Check 1: Directory Structure
# ============================================================

Write-Info "Check 1: Directory structure verification"

$requiredDirs = @(
    "Models",
    "Services",
    "Services\APIClient",
    "Services\LocalModel",
    "Services\ModelScheduler",
    "Services\Storage",
    "Services\Speech",
    "Services\Export",
    "Services\FileInteraction",
    "Services\TokenUsage",
    "Services\SystemIntegration",
    "Views",
    "Views\Chat",
    "Views\Components",
    "Views\Settings",
    "Views\Sidebar",
    "Views\Export",
    "Views\Theme",
    "ViewModels",
    "Utils"
)

$dirsFound = 0
$dirsMissing = @()
foreach ($dir in $requiredDirs) {
    $fullPath = (Join-Path $srcDir $dir)
    if (Test-Path $fullPath) {
        $dirsFound++
    } else {
        $dirsMissing += $dir
    }
}

Write-Info "Directories found: $dirsFound/$($requiredDirs.Count)"
if ($dirsMissing.Count -eq 0) {
    Write-OK "Directory structure complete"
} else {
    foreach ($d in $dirsMissing) {
        Write-Warn "Missing directory: $d"
    }
}
Write-Host ""

# ============================================================
# Check 2: Swift Source Files
# ============================================================

Write-Log "Check 2: Swift files"
Write-Info "Check 2: Swift source files"

$swiftFiles = @(Get-ChildItem -Path $srcDir -Filter "*.swift" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
$testFiles = @(Get-ChildItem -Path $testDir -Filter "*.swift" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)

Write-Info "Source files: $($swiftFiles.Count) files"
Write-Info "Test files: $($testFiles.Count) files"

if ($swiftFiles.Count -eq 0) {
    Write-Fail "No Swift source files found!"
}

# Critical files list
$criticalFiles = @(
    "Models\Message.swift",
    "Models\Conversation.swift",
    "Models\Attachment.swift",
    "Models\UserProfile.swift",
    "Models\AppSettings.swift",
    "Models\ModelProvider.swift",
    "Models\APICredential.swift",
    "Services\APIClient\QwenAPIClient.swift",
    "Services\LocalModel\IOSLocalModelService.swift",
    "Services\ModelScheduler\ModelScheduler.swift",
    "Services\Storage\ConversationStore.swift",
    "Services\Storage\SettingsStore.swift",
    "Services\Speech\SpeechService.swift",
    "Services\Speech\SpeechSettings.swift",
    "Services\Export\ExportService.swift",
    "Views\Chat\RootView.swift",
    "Views\Chat\MainChatView.swift",
    "Views\Chat\MessageListView.swift",
    "Views\Chat\MessageBubbleView.swift",
    "Views\Chat\ChatInputBarView.swift",
    "Views\Chat\AttachmentPickerView.swift",
    "Views\Components\ActivityView.swift",
    "Views\Components\ClipboardSuggestionView.swift",
    "Views\Components\TokenUsageIndicator.swift",
    "Views\Components\ProviderSwitchBanner.swift",
    "Views\Sidebar\SidebarView.swift",
    "Views\Settings\SettingsView.swift",
    "Views\Theme\ThemeManager.swift",
    "ViewModels\ChatViewModel.swift",
    "Utils\String+Helpers.swift",
    "Utils\Date+Helpers.swift",
    "Utils\Color+AppTheme.swift",
    "Utils\Bundle+AppVersion.swift",
    "ChengFengAIApp.swift"
)

$criticalFound = 0
$criticalMissing = @()
foreach ($file in $criticalFiles) {
    $fullPath = (Join-Path $srcDir $file)
    if (Test-Path $fullPath) {
        $criticalFound++
    } else {
        $criticalMissing += $file
    }
}

Write-Info "Critical files: $criticalFound/$($criticalFiles.Count) found"
if ($criticalMissing.Count -eq 0) {
    Write-OK "All critical files present"
} else {
    foreach ($f in $criticalMissing) {
        Write-Warn "Missing: $f"
    }
}
Write-Host ""

# ============================================================
# Check 3: Basic Syntax Verification
# ============================================================

Write-Log "Check 3: Basic Swift syntax"
Write-Info "Check 3: Basic Swift syntax check"

$totalLines = 0
$totalSize = 0
$filesWithIssues = @()

foreach ($swiftFile in $swiftFiles) {
    try {
        $content = Get-Content $swiftFile -Raw -Encoding UTF8 -ErrorAction Stop
        $fileLines = [int]((Get-Content $swiftFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines)
        $fileSize = (Get-Item $swiftFile -ErrorAction SilentlyContinue).Length
        $totalLines += $fileLines
        $totalSize += $fileSize

        # Check: must have 'import' statement
        if (-not ($content -match "import")) {
            $fileName = Split-Path $swiftFile -Leaf
            Write-Warn "$fileName : Missing 'import' statement"
            $filesWithIssues += $swiftFile
        }

        # Check: Model files should have Codable
        if ($swiftFile -match "Models" -and -not ($content -match "Codable")) {
            $fileName = Split-Path $swiftFile -Leaf
            Write-Warn "$fileName : Model missing Codable"
        }

        # Check: View files should have SwiftUI
        if ($swiftFile -match "Views" -and -not ($content -match "SwiftUI")) {
            $fileName = Split-Path $swiftFile -Leaf
            Write-Warn "$fileName : View missing SwiftUI"
        }

    } catch {
        $fileName = Split-Path $swiftFile -Leaf
        Write-Warn "Cannot read: $fileName"
        $filesWithIssues += $swiftFile
    }
}

$sizeKB = [math]::Round($totalSize / 1KB, 2)
Write-Info "Total lines: $totalLines"
Write-Info "Total size: $sizeKB KB"
if ($filesWithIssues.Count -eq 0) {
    Write-OK "All Swift files passed basic check"
} else {
    Write-Warn "$($filesWithIssues.Count) files have potential issues"
}
Write-Host ""

# ============================================================
# Check 4: Configuration Files
# ============================================================

Write-Log "Check 4: Config files"
Write-Info "Check 4: Configuration files"

$configFiles = @{
    "project.yml" = "XcodeGen configuration"
    "Package.swift" = "Swift Package Manager config"
    "build.sh" = "Build script"
    ".gitignore" = "Git ignore rules"
    "README.md" = "Documentation"
}

$configFound = 0
$configMissing = @()
foreach ($cfg in $configFiles.Keys) {
    $fullPath = (Join-Path $projectRoot $cfg)
    if (Test-Path $fullPath) {
        $configFound++
        $sizeKB2 = [math]::Round((Get-Item $fullPath).Length / 1KB, 2)
        Write-Log "Config OK: $cfg ($sizeKB2 KB)"
    } else {
        $configMissing += $cfg
        Write-Warn "Missing config: $cfg ($($configFiles[$cfg]))"
    }
}

# Check Info.plist in source dir
$infoPlist = (Join-Path $srcDir "Info.plist")
if (Test-Path $infoPlist) {
    $configFound++
    Write-Log "Config OK: Info.plist"
} else {
    $configMissing += "Info.plist"
    Write-Warn "Missing: Info.plist (iOS app config)"
}

# Check GitHub CI workflow
$ciConfig = (Join-Path $projectRoot ".github\workflows\ci.yml")
if (Test-Path $ciConfig) {
    $configFound++
    Write-Log "Config OK: GitHub CI workflow"
} else {
    $configMissing += "ci.yml"
    Write-Warn "Missing: GitHub CI workflow"
}

Write-Info "Config files found: $configFound"
if ($configMissing.Count -eq 0) {
    Write-OK "All configuration files present"
} else {
    Write-Fail "Missing $($configMissing.Count) config files"
}
Write-Host ""

# ============================================================
# Check 5: Test Files Verification
# ============================================================

Write-Log "Check 5: Test files"
Write-Info "Check 5: Test files"

if ($testFiles.Count -gt 0) {
    Write-Info "Test files: $($testFiles.Count) files"

    $testClasses = @()
    foreach ($testFile in $testFiles) {
        try {
            $content = Get-Content $testFile -Raw -Encoding UTF8 -ErrorAction Stop
            $matched = [regex]::Matches($content, "final class (\w+)")
            foreach ($m in $matched) {
                if ($m.Groups[1].Value -notlike "*Tests*") {
                    # Skip non-test classes
                }
                $testClasses += $m.Groups[1].Value
            }
        } catch {
            $fileName = Split-Path $testFile -Leaf
            Write-Warn "Cannot read test: $fileName"
        }
    }

    if ($testClasses.Count -gt 0) {
        Write-Info "Test classes detected: $($testClasses.Count)"
        foreach ($tc in $testClasses | Select-Object -Unique) {
            Write-Info "  - $tc"
        }
        Write-OK "Test file structure OK"
    } else {
        Write-Warn "No XCTestCase classes detected"
    }
} else {
    Write-Warn "No test files found"
}
Write-Host ""

# ============================================================
# Check 6: Code Statistics
# ============================================================

Write-Log "Check 6: Statistics"
Write-Info "Check 6: Code statistics"

$statsModels = 0; $countModels = 0
$statsServices = 0; $countServices = 0
$statsViews = 0; $countViews = 0
$statsViewModels = 0; $countViewModels = 0
$statsUtils = 0; $countUtils = 0
$statsTests = 0; $countTests = 0

foreach ($swiftFile in $swiftFiles) {
    $fileName = $swiftFile.ToLower()
    $lines = [int]((Get-Content $swiftFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines)

    if ($fileName -match "models") { $statsModels += $lines; $countModels++ }
    elseif ($fileName -match "services") { $statsServices += $lines; $countServices++ }
    elseif ($fileName -match "views") { $statsViews += $lines; $countViews++ }
    elseif ($fileName -match "viewmodels") { $statsViewModels += $lines; $countViewModels++ }
    elseif ($fileName -match "utils") { $statsUtils += $lines; $countUtils++ }
}

foreach ($testFile in $testFiles) {
    $lines = [int]((Get-Content $testFile -ErrorAction SilentlyContinue | Measure-Object -Line).Lines)
    $statsTests += $lines
    $countTests++
}

Write-Host ""
Write-Host "  +-------------------------------------+" -ForegroundColor Gray
Write-Host "  |        Code Statistics             |" -ForegroundColor White
Write-Host "  +-------------------------------------+" -ForegroundColor Gray
Write-Host "  |  Models      : $countModels files, $statsModels lines      |" -ForegroundColor Cyan
Write-Host "  |  Services    : $countServices files, $statsServices lines      |" -ForegroundColor Cyan
Write-Host "  |  Views       : $countViews files, $statsViews lines      |" -ForegroundColor Cyan
Write-Host "  |  ViewModels  : $countViewModels files, $statsViewModels lines      |" -ForegroundColor Cyan
Write-Host "  |  Utils       : $countUtils files, $statsUtils lines      |" -ForegroundColor Cyan
Write-Host "  |  Tests       : $countTests files, $statsTests lines      |" -ForegroundColor Cyan
Write-Host "  +-------------------------------------+" -ForegroundColor Gray
$totalFileCount = $swiftFiles.Count + $testFiles.Count
Write-Host "  |  TOTAL       : $totalFileCount files, $totalLines lines      |" -ForegroundColor Green
Write-Host "  +-------------------------------------+" -ForegroundColor Gray
Write-Host ""

# ============================================================
# Check 7: Packaging Readiness
# ============================================================

Write-Log "Check 7: Packaging readiness"
Write-Info "Check 7: Packaging readiness"

$packChecks = @{
    "Main entry (ChengFengAIApp.swift)" = (Test-Path (Join-Path $srcDir "ChengFengAIApp.swift"))
    "Model files (>= 7)" = ($criticalFound -ge 7)
    "Service files" = ($countServices -gt 0)
    "View files" = (Test-Path (Join-Path $srcDir "Views\Chat\RootView.swift"))
    "ViewModel" = (Test-Path (Join-Path $srcDir "ViewModels\ChatViewModel.swift"))
    "Utils (>= 3)" = ($countUtils -ge 3)
    "Tests (>= 2 files)" = ($testFiles.Count -ge 2)
    "project.yml" = (Test-Path (Join-Path $projectRoot "project.yml"))
    "Package.swift" = (Test-Path (Join-Path $projectRoot "Package.swift"))
    "build.sh" = (Test-Path (Join-Path $projectRoot "build.sh"))
    "GitHub CI config" = (Test-Path $ciConfig)
    "Info.plist" = (Test-Path $infoPlist)
    ".gitignore" = (Test-Path (Join-Path $projectRoot ".gitignore"))
    "README.md" = (Test-Path (Join-Path $projectRoot "README.md"))
}

$packPassed = 0
$packFailed = 0

Write-Host ""
foreach ($check in $packChecks.Keys) {
    if ($packChecks[$check]) {
        Write-Host "  [OK] $check" -ForegroundColor Green
        $packPassed++
        Write-Log "Pack OK: $check"
    } else {
        Write-Host "  [!!] $check" -ForegroundColor Red
        $packFailed++
        Write-Log "Pack FAIL: $check"
    }
}
Write-Host ""

if ($packFailed -eq 0) {
    Write-OK "Packaging readiness verified ($packPassed/$($packChecks.Count))"
} else {
    Write-Fail "Packaging issues found: $packFailed items"
}
Write-Host ""

# ============================================================
# Final Result Summary
# ============================================================

Write-Log "=== Project Check END ==="
Write-Log "SUCCESS: $script:successCount, WARNINGS: $script:warnCount, FAILURES: $script:failCount"

Write-Sep
Write-Host "  Final Result Summary" -ForegroundColor White
Write-Sep
Write-Host "  Success checks: $script:successCount" -ForegroundColor Green
Write-Host "  Warnings: $script:warnCount items" -ForegroundColor Yellow
Write-Host "  Failures: $script:failCount items" -ForegroundColor Red
Write-Sep
Write-Host ""
Write-Host "  Detailed log: $logFile" -ForegroundColor Gray
Write-Host ""

# Final judgment
if ($script:failCount -eq 0 -and $packFailed -eq 0) {
    Write-Host "  [PASS] Project check PASSED!" -ForegroundColor Green
    Write-Host "  [PASS] Ready for building and packaging!" -ForegroundColor Green
    Write-Host ""
    exit 0
} elseif ($script:failCount -eq 0 -and $packFailed -le 2) {
    Write-Host "  [PASS] Project passed with minor issues" -ForegroundColor Yellow
    Write-Host "  [PASS] Can proceed with build (review warnings)" -ForegroundColor Yellow
    Write-Host ""
    exit 0
} else {
    Write-Host "  [FAIL] Project has issues - review before building!" -ForegroundColor Red
    Write-Host ""
    exit 1
}
