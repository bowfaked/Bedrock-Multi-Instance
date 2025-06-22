Add-Type -AssemblyName PresentationFramework

function Get-MinecraftPackageId {
    $basePath = "HKCU:\SOFTWARE\Classes\Extensions\ContractId\Windows.Launch\PackageId"
    $keys = Get-ChildItem $basePath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like "Microsoft.MinecraftUWP_*" }
    return $keys.PSChildName
}

function Get-MultiInstanceState {
    $packageId = Get-MinecraftPackageId
    if (-not $packageId) { return $null }

    $fullPath = "HKCU:\SOFTWARE\Classes\Extensions\ContractId\Windows.Launch\PackageId\$packageId\ActivatableClassId\App\CustomProperties"
    try {
        $value = Get-ItemPropertyValue -Path $fullPath -Name "SupportsMultipleInstances" -ErrorAction Stop
        return [bool]$value
    } catch {
        return $false
    }
}

function Set-MultiInstance($enable) {
    $packageId = Get-MinecraftPackageId
    if (-not $packageId) {
        [System.Windows.MessageBox]::Show("Minecraft UWP PackageId not found in the registry.","Error","OK","Error")
        return
    }

    $fullPath = "HKCU:\SOFTWARE\Classes\Extensions\ContractId\Windows.Launch\PackageId\$packageId\ActivatableClassId\App\CustomProperties"
    New-Item -Path $fullPath -Force | Out-Null
    $value = if ($enable) { 1 } else { 0 }
    Set-ItemProperty -Path $fullPath -Name "SupportsMultipleInstances" -Value $value -Type DWord

if ($enable) {
    [System.Windows.MessageBox]::Show("Multiple instances are now ENABLED for Minecraft Bedrock.`nNO GAME RESTART IS NEEDED.","Success","OK","Info")
} else {
    [System.Windows.MessageBox]::Show("Multiple instances are now DISABLED for Minecraft Bedrock.`nPlease restart Minecraft to apply this change.","Success","OK","Info")
}

    UpdateButtonStates
}

function UpdateButtonStates {
    $state = Get-MultiInstanceState
    if ($state -eq $true) {
        $enableBtn.IsEnabled = $false
        $disableBtn.IsEnabled = $true
    } elseif ($state -eq $false) {
        $enableBtn.IsEnabled = $true
        $disableBtn.IsEnabled = $false
    } else {
        $enableBtn.IsEnabled = $false
        $disableBtn.IsEnabled = $false
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Minecraft MultiInstance"
        Height="240" Width="400"
        ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen">
    <StackPanel Margin="20">
        <TextBlock Text="Minecraft UWP Multi-Instance Control" FontWeight="Bold" FontSize="16" Margin="0,0,0,20" HorizontalAlignment="Center"/>
        <Button Name="EnableBtn" Content="Enable Multi-Instance" Height="35" Margin="0,0,0,10"/>
        <Button Name="DisableBtn" Content="Disable Multi-Instance" Height="35" Margin="0,0,0,10"/>
        <Button Name="ExitBtn" Content="Exit" Height="30"/>
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$enableBtn = $window.FindName("EnableBtn")
$disableBtn = $window.FindName("DisableBtn")
$exitBtn = $window.FindName("ExitBtn")

$enableBtn.Add_Click({ Set-MultiInstance $true })
$disableBtn.Add_Click({ Set-MultiInstance $false })
$exitBtn.Add_Click({ $window.Close() })

UpdateButtonStates
$null = $window.ShowDialog()
