$tableName = 'V3NewOrdersTexts'

dtexec /f ".\SQL\SSIS\$tableName.dtsx" /l "DTS.LogProviderTextFile;.\.assets\logs\ssis_.$tableName.log"
