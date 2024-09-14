Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Add necessary Win32 API functions
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    }
"@

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.BackColor = [System.Drawing.Color]::Black
$form.TransparencyKey = $form.BackColor
$form.TopMost = $false
$form.StartPosition = "Manual"
$form.ShowInTaskbar = $false  # Hide from taskbar

# Constants for the window styles
$GWL_EXSTYLE = -20
$WS_EX_LAYERED = 0x80000
$WS_EX_TRANSPARENT = 0x20
$WS_EX_TOOLWINDOW = 0x80  # Hides the window from the taskbar

# Get screen dimensions
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Set form size (adjust width and height as needed)
$formWidth = $screenWidth
$formHeight = $screenHeight * 40/100

# Calculate centered horizontal position and place vertically at the top of the screen
$formX = [Math]::Floor(($screenWidth - $formWidth) / 2)
$formY = 0  # Set Y to 0 to position at the top of the screen
$form.Location = New-Object System.Drawing.Point($formX, $formY)
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)

$clockLabel = New-Object System.Windows.Forms.Label
$clockLabel.ForeColor = [System.Drawing.Color]::White
$clockLabel.Font = New-Object System.Drawing.Font("Curlz MT", 30)
$clockLabel.AutoSize = $true
$clockLabel.Location = New-Object System.Drawing.Point(($formWidth/2.3), 45)  # Position label with padding
$form.Controls.Add($clockLabel)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $currentDateTime = Get-Date
    $formattedDate = $currentDateTime.ToString("MM:dd:yyyy")
    $formattedTime = $currentDateTime.ToString("  HH:mm:ss")

    # Retrieve battery percentage
    $batteryStatus = Get-WmiObject -Class Win32_Battery
    if ($batteryStatus) {
        $batteryPercentage = $batteryStatus.EstimatedChargeRemaining
        $batteryText = "$batteryPercentage%"
    } else {
        $batteryText = "N/A"
    }

    $clockLabel.Text = "$formattedTime`n$formattedDate`nBattery: $batteryText"
})
$timer.Start()

$form.Add_Shown({
    # Get the form handle and update the window style to be click-through and remove from taskbar
    $handle = $form.Handle
    $currentStyle = [User32]::GetWindowLongPtr($handle, $GWL_EXSTYLE)
    $newStyle = $currentStyle -bor $WS_EX_LAYERED -bor $WS_EX_TRANSPARENT -bor $WS_EX_TOOLWINDOW
    [User32]::SetWindowLongPtr($handle, $GWL_EXSTYLE, $newStyle)
})

# Show the form
$form.ShowDialog()
 