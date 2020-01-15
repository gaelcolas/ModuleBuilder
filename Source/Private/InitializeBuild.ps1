function InitializeBuild {
    <#
        .SYNOPSIS
            Loads build.psd1 and the module manifest and combines them with the parameter values of the calling function.
        .DESCRIPTION
            This function is for internal use from Build-Module only
            It does a few things that make it really only work properly there:

            1. It calls ResolveBuildManifest to resolve the Build.psd1 from the given -SourcePath (can be Folder, Build.psd1 or Module manifest path)
            2. Then calls GetBuildInfo to read the Build configuration file and override parameters passed through $Invocation (read from the PARENT MyInvocation)
            2. It gets the Module information from the ModuleManifest, and merges it with the $ModuleInfo
        .NOTES
            Depends on the Configuration module Update-Object and (the built in Import-LocalizedData and Get-Module)
    #>
    [CmdletBinding()]
    param(
        # The root folder where the module source is (including the Build.psd1 and the module Manifest.psd1)
        [string]$SourcePath,

        [Parameter(DontShow)]
        [AllowNull()]
        $BuildCommandInvocation = $(Get-Variable MyInvocation -Scope 1 -ValueOnly)
    )
    Write-Debug "Initializing build variables"

    # GetBuildInfo reads the parameter values from the Build-Module command and combines them with the Manifest values
    $BuildManifest = ResolveBuildManifest $SourcePath

    Write-Debug "BuildCommand: $(
        @(
            @($BuildCommandInvocation.MyCommand.Name)
            @($BuildCommandInvocation.BoundParameters.GetEnumerator().ForEach{ "-{0} '{1}'" -f $_.Key, $_.Value })
        ) -join ' ')"
    $BuildInfo = GetBuildInfo -BuildManifest $BuildManifest -BuildCommandInvocation $BuildCommandInvocation

    # Finally, add all the information in the module manifest to the return object
    if ($ModuleInfo = ImportModuleManifest $BuildInfo.SourcePath) {
        # Update the module manifest with our build configuration and output it
        Update-Object -InputObject $ModuleInfo -UpdateObject $BuildInfo
    } else {
        throw "Unresolvable problems in module manifest: '$($BuildInfo.SourcePath)'"
    }
}
