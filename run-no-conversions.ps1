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

Write-Output "--------2: Run hdfs-client & ingest generated calypso file---------"
Write-Output (Get-Date -UFormat "--------------------Time: %R Date: %d-%m-%Y-------------------")
Write-Output "-------------------------------------------------------------------"
cd C:\yields\platform-hdfs-client
Write-Output (docker-compose run --rm hdfs hdfs dfs -put -f automation-scripts/current/$file hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/raw/ds_calypso)
cd C:\yields\automation-scripts

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

} else {Write-Output "Error: Calypso did not output any .csv"}
Stop-Transcript