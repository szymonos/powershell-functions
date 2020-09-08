<#
.Example
db\SQLServer\UserObjects.ps1
#>

$dbList = @(
    [PSCustomObject]@{ServerName = 'UFO3X'; DBName = 'SLAB'}
    [PSCustomObject]@{ServerName = 'UFO3X'; DBName = 'XLINK'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'AC'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'DOCS'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'EDI'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'LANG'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'REKL2005'}
    [PSCustomObject]@{ServerName = 'ABCUFO'; DBName = 'SCM'}
)

$queryPath = '.\.include\sql\sel_objects.sql'
$query = [System.IO.File]::ReadAllText($queryPath)

$objectsList = @()
foreach ($db in $dblist) {
    #$db = $dblist[2]
    Write-Output ('Enumerating objects in database: ' + $db)
    $objectsList += Invoke-Sqlcmd -Query $query -ServerInstance $db.ServerName -Database $db.DBName
}
$objectsList | Export-Csv -Path '.\.assets\export\ObjectList.csv' -Encoding utf8 -NoTypeInformation
