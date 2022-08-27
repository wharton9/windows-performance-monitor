# 
#windows GPU/CPU and network performance report 
#
<#
    .SYNOPSIS
        
    .DESCRIPTION
    This tool is for generating system gpu/network performance report
    and the result logs could be consumed by analysis tool
    
    .PARAMETER gpu
    <number1> sample intervals , in seconds ,default is 2 seconds
    <number2> test time , in minutes ,default is 5 mins
    
    .EXAMPLE
    PS> perfreport.ps1  2 5
    PS> perfreport.ps1  3 10
    PS> perfreport.ps1 
    .NOTES
       Author: Wharton Wang
       Date: 17th August,2022
    
#>
param(
[SupportsWildcards()]
#$cType = "gpu",
$SmplIntvl = 2,    #GPU samples interval
$tt = 5     #total test time, in minutes 
#   [string] $nCounter, 
#   [string] $cResult
)


#counters and result files

$GpuCounter = "\GPU Engine(*engtype_3D)\Utilization Percentage"
$Gpuresult = ".\gpuresult.log"
$CpuCounter = "\Processor(_Total)\% Processor Time"
$Cpuresult = ".\cpuresult.log"
$NetRcvCounter = "\Network Interface(*)\Bytes Received/sec"
$NetRcvresult = ".\netrcvresult.log"
$NetSntCounter = "\Network Interface(*)\Bytes Sent/sec"
$NetSntresult = ".\netsntresult.log"
#$gpudata =@()
$gpudata =[System.Collections.Concurrent.ConcurrentBag[object]]::new()
$cpudata =[System.Collections.Concurrent.ConcurrentBag[object]]::new()
$netrdata =[System.Collections.Concurrent.ConcurrentBag[object]]::new()
$netsdata =[System.Collections.Concurrent.ConcurrentBag[object]]::new()

$tCounter = $GpuCounter,$CpuCounter,$NetRcvCounter,$NetSntCounter


function checkFile($cResult){
    if(Test-Path -path $cResult -PathType Leaf){
        Clear-Content $cResult -Force
    }
    else{
        New-Item . -Name $cResult -ItemType File
    }
}

checkFile $Gpuresult 
checkFile $Cpuresult 
checkFile $NetRcvresult 
checkFile $NetSntresult

$ttlsamples = ($tt*60)/$SmplIntvl
$ttlsamples =$([math]::Round($ttlsamples,0))

get-counter $tCounter -MaxSamples $ttlsamples -SampleInterval $SmplIntvl |
#get-counter $tCounter -MaxSamples 5 -SampleInterval 1|
ForEach-object -Parallel{
    $getGpuresult = (($_.CounterSamples.Where({$_.path -match 'gpu'})|Where-Object CookedValue).cookedvalue |measure-object -sum).sum
    $getGpuresult= $([math]::Round($getGpuresult,2))
   # $gpudata += $getGpuresult
    $gpuarray =$using:gpudata 
    $gpuarray.add($getGpuresult)
    $getGpuresult|Out-File -FilePath $($using:GPUresult) -Append
    Write-Host "the gpu re is $getGpuresult%"
    
    $getCpuresult = (($_.CounterSamples.Where({$_.path -match 'Total'})|Where-Object CookedValue).cookedvalue |measure-object -sum).sum
    $getCpuresult= $([math]::Round($getCpuresult,2))
    $cpuarray =$using:cpudata 
    $cpuarray.add($getCpuresult)
    $getCpuresult|Out-File -FilePath $($using:CPUresult) -Append
    Write-Host "the cpu re is $getCpuresult%"

    $getNetRcvresult = (($_.CounterSamples.Where({$_.path -match 'receive'})|Where-Object CookedValue).cookedvalue |measure-object -sum).sum*0.008
    $getNetRcvresult= $([math]::Round($getNetRcvresult,2))
    $netrarray =$using:netrdata 
    $netrarray.add($getNetRcvresult)
    $getNetRcvresult|Out-File -FilePath $($using:NetRcvresult) -Append
    Write-Host "the net received speed re is $getNetRcvresult Kbps"

    $getNetSntresult = (($_.CounterSamples.Where({$_.path -match 'sent'})|Where-Object CookedValue).cookedvalue |measure-object -sum).sum*0.008
    $getNetSntresult= $([math]::Round($getNetSntresult,2))
    $netsarray =$using:netsdata 
    $netsarray.add($getNetSntresult)
    $getNetSntresult|Out-File -FilePath $($using:NetSntresult) -Append
    Write-Host "the net sent speed re is $getNetSntresult Kbps"
   
}
#$fCpuCounter= ((Get-Counter $CpuCounter).CounterSamples | Where-Object CookedValue).CookedValue
#$fNetRcvCounter= ((((Get-Counter $NetRcvCounter).CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum)/8192
#$fNetSntCounter= ((((Get-Counter $NetSntCounter).CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum)/8192
#function Getresult($cType,$nCounter,$cResult){
##    $UseTotal = (((Get-Counter $nCounter).CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
#    $timeinsec = $tt*60
#    while($timeinsec -gt 0){
#        Start-Sleep $SmplIntvl
#        $timeinsec = $timeinsec - $SmplIntvl
#        $Ttlusage =(((Get-Counter $nCounter).CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
#        $Cusage = $([math]::Round($Ttlusage,2))
#        Write-Output "Total $cType Engine Usage: $Cusage"
#        $resultdata += $Cusage
#        $Cusage|Out-File -FilePath $cResult -Append
#    }

#show the test results
write-Host -foregroundcolor Green "Run the test every $SmplIntvl seconds in $tt mins."
Write-Host -ForegroundColor Yellow "The [GPU] test result is: " 
$gpudata|Measure-Object -Maximum -Average -Minimum|Format-List -Property Count,average,Maximum
Write-Host -ForegroundColor Yellow "The [CPU] test result is: " 
$cpudata|Measure-Object -Maximum -Average -Minimum|Format-List -Property Count,average,Maximum
Write-Host -ForegroundColor Yellow "The network [received] speed test result is: " 
$netrdata|Measure-Object -Maximum -Average -Minimum|Format-List -Property Count,average,Maximum
Write-Host -ForegroundColor Yellow "The network [sent] speed test result is: " 
$netsdata|Measure-Object -Maximum -Average -Minimum|Format-List -Property Count,average,Maximum
