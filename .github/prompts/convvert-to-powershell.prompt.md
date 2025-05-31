---
mode: 'agent'
tools: ['githubRepo', 'codebase']
description: 'Convert this script to a PowerShell script'
---
Craate a PowerShell script of this bash script.

- Begin with a short synopsis.
- Try to write the script in a way that it can be run directly.
- Use standard PowerShell cmdlets and avoid external dependencies.
- Try to use Invoke-RestMethod for HTTP requests.
- Ignore logging but write comments where logging is skipped.

### Example PowerShell synopsis

```powershell
<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Name

    .INPUTS

    .OUTPUTS

    .EXAMPLE

    .LINK
#>
```    