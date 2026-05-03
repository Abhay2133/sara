Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 512,512
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(255,29,19,48))
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,255,255,255))
$font = New-Object System.Drawing.Font 'Segoe UI',160,[System.Drawing.FontStyle]::Bold
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.DrawString('S',$font,$brush,[System.Drawing.RectangleF]::new(0,0,512,512),$sf)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,0,229,255)),24
$g.DrawEllipse($pen,40,40,432,432)
$bmp.Save('assets/icon.png',[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host 'PNG created'
