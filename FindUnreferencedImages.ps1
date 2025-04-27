<#
.SYNOPSIS
    检测未被博客文章引用的图片文件并提供管理选项。

.DESCRIPTION
    此脚本扫描 'attachments\images' 目录中的所有文件，检查它们是否在 'content\posts' 目录的博客文章中被引用。
    未引用的文件将被列出，并提供将它们移动到备份目录的选项。

.PARAMETER ImageDirectory
    指定图片目录的路径。默认为当前目录下的 'attachments\images'。

.PARAMETER PostsDirectory
    指定博客文章目录的路径。默认为当前目录下的 'content\posts'。

.PARAMETER BackupPrefix
    指定备份目录的前缀。默认为 'UnreferencedImages'。

.NOTES
    作者: PowerShell脚本专家
    版本: 1.0
    适用于: PowerShell 7.5+
#>

[CmdletBinding()]
param (
    [string]$ImageDirectory = (Join-Path -Path (Get-Location) -ChildPath "attachments\images"),
    [string]$PostsDirectory = (Join-Path -Path (Get-Location) -ChildPath "content\posts"),
    [string]$BackupPrefix = "UnreferencedImages"
)

# 设置严格模式
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 函数：获取易读的文件大小格式
function Get-ReadableFileSize {
    param (
        [Parameter(Mandatory = $true)]
        [long]$SizeInBytes
    )
  
    if ($SizeInBytes -lt 1KB) {
        return "$SizeInBytes B"
    }
    elseif ($SizeInBytes -lt 1MB) {
        return "{0:N2} KB" -f ($SizeInBytes / 1KB)
    }
    elseif ($SizeInBytes -lt 1GB) {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
    else {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    }
}

function Test-DirectoryExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$DirectoryType
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        throw "$DirectoryType 目录不存在: $Path"
    }
    
    return $true
}

function Get-UnreferencedImages {
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$PostContents
    )
    
    $unreferencedImages = @()
    
    foreach ($imageFile in $ImageFiles) {
        $isReferenced = $false
        
        # 使用更高效的正则表达式匹配
        $escapedName = [regex]::Escape($imageFile.Name)
        
        foreach ($content in $PostContents.Values) {
            if ($content -match $escapedName) {
                $isReferenced = $true
                break
            }
        }

        if (-not $isReferenced) {
            $fileInfo = [PSCustomObject]@{
                FileName      = $imageFile.Name
                FullPath      = $imageFile.FullName
                FileSize      = Get-ReadableFileSize -SizeInBytes $imageFile.Length
                SizeBytes     = $imageFile.Length
                LastWriteTime = $imageFile.LastWriteTime
            }
            $unreferencedImages += $fileInfo
        }
    }
    
    return $unreferencedImages
}

function Move-UnreferencedImage {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$UnreferencedImages,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupDirectory
    )
    
    $moveAll = $false
    $skipAll = $false
    $movedCount = 0
    $errorCount = 0
    
    foreach ($image in $UnreferencedImages) {
        $moveFile = $false
        
        if (-not $moveAll -and -not $skipAll) {
            $fileResponse = Read-Host "移动文件 '$($image.FileName)'? (Y/N/A-全部移动/S-全部跳过)"
            
            if ($fileResponse -eq "Y" -or $fileResponse -eq "y") {
                $moveFile = $true
            }
            elseif ($fileResponse -eq "A" -or $fileResponse -eq "a") {
                $moveAll = $true
                $moveFile = $true
            }
            elseif ($fileResponse -eq "S" -or $fileResponse -eq "s") {
                $skipAll = $true
                $moveFile = $false
            }
        }
        elseif ($moveAll) {
            $moveFile = $true
        }
        
        if ($moveFile -or $moveAll) {
            try {
                $destPath = Join-Path -Path $BackupDirectory -ChildPath $image.FileName
                Move-Item -Path $image.FullPath -Destination $destPath -Force
                Write-Host "已移动: $($image.FileName)" -ForegroundColor Green
                $movedCount++
            }
            catch {
                Write-Warning "移动文件 '$($image.FileName)' 时出错: $_"
                $errorCount++
            }
        }
    }
    
    return @{
        MovedCount = $movedCount
        ErrorCount = $errorCount
    }
}

function Get-FileContentSafely {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # 对于特大文件使用 .NET 的 StreamReader 而不是 Get-Content
        if ((Get-Item $FilePath).Length -gt 100MB) {
            $reader = [System.IO.StreamReader]::new($FilePath)
            $content = $reader.ReadToEnd()
            $reader.Close()
            $reader.Dispose()
            return $content
        }
        else {
            return Get-Content -Path $FilePath -Raw -ErrorAction Stop
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "没有权限访问文件 '$FilePath'"
        return $null
    }
    catch {
        Write-Warning "读取文件 '$FilePath' 时出错: $_"
        return $null
    }
}

try {
    Write-Host "开始检测未引用的图片文件..." -ForegroundColor Cyan

    # 验证目录是否存在
    [void](Test-DirectoryExists -Path $ImageDirectory -DirectoryType "图片")
    [void](Test-DirectoryExists -Path $PostsDirectory -DirectoryType "博客文章")

    # 获取所有图片文件，排除 .gitkeep 文件
    Write-Host "正在扫描图片目录..." -ForegroundColor Yellow
    $imageFiles = @(Get-ChildItem -Path $ImageDirectory -File -Recurse | Where-Object { $_.Name -ne ".gitkeep" })
    
    if ($imageFiles.Count -eq 0) {
        Write-Host "图片目录中没有找到文件。" -ForegroundColor Green
        exit
    }
    
    Write-Host "找到 $($imageFiles.Count) 个图片文件。" -ForegroundColor Green

    # 获取所有博客文章文件
    Write-Host "正在读取博客文章内容..." -ForegroundColor Yellow
    $postFiles = @(Get-ChildItem -Path $PostsDirectory -File -Recurse -Include "*.md", "*.markdown", "*.html")
    
    if ($postFiles.Count -eq 0) {
        Write-Host "博客文章目录中没有找到文件。" -ForegroundColor Red
        exit
    }
    
    Write-Host "找到 $($postFiles.Count) 个博客文章文件。" -ForegroundColor Green

    # 创建一个哈希表来存储所有文章内容，提高搜索效率
    $postContents = @{}
    $processedFileCount = 0
    $totalPostFiles = $postFiles.Count
    
    foreach ($postFile in $postFiles) {
        $processedFileCount++
        
        # 每处理20个文件显示一次进度
        if ($processedFileCount % 20 -eq 0 -or $processedFileCount -eq $totalPostFiles) {
            Write-Progress -Activity "读取博客文章" -Status "进度: $processedFileCount/$totalPostFiles" -PercentComplete (($processedFileCount / $totalPostFiles) * 100)
        }
        
        $content = Get-FileContentSafely -FilePath $postFile.FullName
        if ($null -ne $content) {
            $postContents[$postFile.FullName] = $content
        }
    }
    
    Write-Progress -Activity "读取博客文章" -Completed

    # 查找未引用的图片
    Write-Host "正在检查引用状态..." -ForegroundColor Yellow
    $unreferencedImages = @(Get-UnreferencedImages -ImageFiles $imageFiles -PostContents $postContents)

    # 输出结果
    if ($unreferencedImages.Count -eq 0) {
        Write-Host "所有图片文件都已被引用。" -ForegroundColor Green
    }
    else {
        Write-Host "发现 $($unreferencedImages.Count) 个未引用的图片文件:" -ForegroundColor Yellow
        
        # 计算总大小
        $totalSize = ($unreferencedImages | Measure-Object -Property SizeBytes -Sum).Sum
        $readableTotalSize = Get-ReadableFileSize -SizeInBytes $totalSize
        
        Write-Host "总计: $($unreferencedImages.Count) 个文件, 总大小: $readableTotalSize" -ForegroundColor Yellow
        
        # 按最后修改时间排序，显示表格
        $unreferencedImages = $unreferencedImages | Sort-Object -Property LastWriteTime -Descending
        $unreferencedImages | Format-Table -Property FileName, FileSize, LastWriteTime -AutoSize
        
        # 为了查看完整路径，单独显示
        $unreferencedImages | Format-Table -Property FileName, FullPath -AutoSize

        # 询问用户是否需要处理未引用的文件
        $response = Read-Host "是否要将这些未引用的图片文件移动到备份目录? (Y/N)"
        
        if ($response -eq "Y" -or $response -eq "y") {
            # 创建带有日期的备份目录
            $backupDirName = "$($BackupPrefix)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $backupDir = Join-Path -Path (Get-Location) -ChildPath $backupDirName
            
            try {
                if (-not (Test-Path -Path $backupDir)) {
                    New-Item -Path $backupDir -ItemType Directory -ErrorAction Stop | Out-Null
                    Write-Host "已创建备份目录: $backupDir" -ForegroundColor Green
                }
                
                $result = Move-UnreferencedImage -UnreferencedImages $unreferencedImages -BackupDirectory $backupDir
                
                Write-Host "操作完成。已移动 $($result.MovedCount) 个文件到备份目录: $backupDir" -ForegroundColor Cyan
                if ($result.ErrorCount -gt 0) {
                    Write-Warning "在移动过程中有 $($result.ErrorCount) 个错误。"
                }
            }
            catch {
                Write-Error "创建或使用备份目录时出错: $_"
            }
        }
        else {
            Write-Host "操作已取消。未移动任何文件。" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-Error "脚本执行过程中出现错误: $_"
    Write-Error $_.ScriptStackTrace
}
