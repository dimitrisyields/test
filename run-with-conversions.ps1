Start-Transcript -path C:\yields\automation-scripts\run-log.txt -append
Write-Output "-------------------------1: Running LJRsync------------------------"
Write-Output (Get-Date -UFormat "--------------------Time: %R Date: %d-%m-%Y-------------------")
Write-Output "-------------------------------------------------------------------"
java -jar -Xmx1500m -DUSER="c934501" -DPW="c934501" -DENV="CALYPSOPROD" -DFOLDER="./current/" C:\yields\auxiliary-binaries-and-scripts\LJRsync.jar

Write-Output "Get generated file in current directory + its date"
cd C:\yields\automation-scripts\current
$file = cmd /r dir /b
Write-Output ("Output file from calypso is: " + $file)
$fileLength = $file.length
Write-Output ("Length of today's file is: "+ $fileLength)
$date=$file.SubString(0, $fileLength - 4)
Write-Output ("Date of today's file is: " + $date)

Write-Output "Check if calypso jar outputted a csv" #will enter the clause if $file is not empty string
if ($file){

Write-Output "Invoke yields env for Docker"
docker-machine env yields  | Invoke-Expression

Write-Output "Remove and re-up zookeeper that causes problems with conversion"
cd C:\yields\platform-compose
Write-Output (docker-compose stop zookeeper)
Write-Output (docker-compose rm -f zookeeper)
Write-Output (docker volume rm platform-compose_zookeeper)
Write-Output (docker-compose up -d)

Start-Sleep -s 60

Write-Output "Get current timestamp with -3 hours offset -align system time to namenode time"
$currentTimeStamp = (Get-Date (Get-Date).addhours(-3) -UFormat "%Y%m%d%R") -replace ":", ""
$currentTimeStamp = [double]$currentTimeStamp

Write-Output "--------2: Run hdfs-client & ingest generated calypso file---------"
Write-Output (Get-Date -UFormat "--------------------Time: %R Date: %d-%m-%Y-------------------")
Write-Output "-------------------------------------------------------------------"
cd C:\yields\platform-hdfs-client
Write-Output (docker-compose run --rm hdfs hdfs dfs -put -f automation-scripts/current/$file hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/raw/ds_calypso)
cd C:\yields\automation-scripts

Start-Sleep -s 60

Write-Output "Get modification date and time of ds_calypso _SUCCESS file in converted folder"
$successFileInfo = (docker exec namenode hdfs dfs -ls hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/yields/converted/ds_calypso/_SUCCESS )
$ModDate = $successFileInfo.split()[16]
Write-Output "moddate: " $ModDate
$ModTime = $successFileInfo.split()[17]
Write-Output "modtime: " $ModTime
$ModTimeStamp = ($ModDate+$ModTime) -replace ":", ""
$ModTimeStamp = ($ModTimeStamp) -replace "-", ""
$ModTimeStamp = [double]$ModTimeStamp

Write-Output "Check if conversion happened"
if ($ModTimeStamp -gt $currentTimeStamp){

Write-Output "Move ingested calypso file from temp directory"
Move-Item current/*.csv daily/

Write-Output "-------------------3: Execute feature extraction-------------------"
Write-Output (Get-Date -UFormat "--------------------Time: %R Date: %d-%m-%Y-------------------")
Write-Output "-------------------------------------------------------------------"
Write-Output (docker exec jupyter jupyter nbconvert --execute op_notebooks/feature_extraction.ipynb)

Write-Output "Read params from outputed .csv"
cd C:\yields\pohjola-svc-notebooks
$ParametersFileName = "C:\yields\pohjola-svc-notebooks\"+"OP_model_b643a336-75b3-5b3b-a7e9-dba249344fbd_"+$date+"_parameters.csv"
if(![System.IO.File]::Exists($ParametersFileName)){
Write-Output "Parameters file was not found"
exit
}
$ParametersFile = Import-Csv $ParametersFileName
$Notional=$ParametersFile.Notional
$Bias=$ParametersFile.Bias
$Age=$ParametersFile.Age
$TwoYearsInd=$ParametersFile.TwoYearsInd

Write-Output "---------------4: Update Calypso with new parameters---------------"
Write-Output (Get-Date -UFormat "--------------------Time: %R Date: %d-%m-%Y-------------------")
Write-Output "-------------------------------------------------------------------"
$updateCalypsoParams = Start-Job -Name "Update" -ScriptBlock {
java -jar -Xmx1500m -DUSER="c934501" -DPW="c934501" -DENV="CALYPSOPSC" -DNotional=$Notional -DBias=$Bias -DAge=$Age -DTwoYearsInd=$TwoYearsInd C:\yields\auxiliary-binaries-and-scripts\LJRupdate.jar
}
$updateCalypsoParams | Wait-Job -Timeout 3600
} else {Write-Output "Error: Conversion did not happen within the designated Start-Sleep period"}
} else {Write-Output "Error: Calypso did not output any .csv"}
Stop-Transcript
