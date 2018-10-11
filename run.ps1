Start-Transcript -path C:\yields\automation-scripts\run-log.txt -append
Write-Output "Running LJRsync"
java -jar -Xmx1500m -DUSER="c934501" -DPW="c934501" -DENV="CALYPSOPROD" -DFOLDER="./current/" C:\yields\auxiliary-binaries-and-scripts\LJRsync.jar

Write-Output "Get generated file in current directory + its date"
cd current
$file=cmd /r dir /b
$date=$file.SubString(0, $file.length - 4)

Write-Output "Invoke yields env for Docker"
docker-machine env yields  | Invoke-Expression

Write-Output "Run hdfs-client and ingest generated calypso file"
cd C:\yields\platform-hdfs-client
docker-compose run --rm hdfs hdfs dfs -put -f automation-scripts\current\$file hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/raw/ds_calypso
cd C:\yields\automation-scripts

Write-Output "Move ingested calypso file from temp directory"
Move-Item current/*.csv daily/

Write-Output "Execute feature extraction"
docker exec jupyter jupyter nbconvert --execute op_notebooks/feature_extraction.ipynb

Write-Output "Read params from outputed .csv"
cd C:\yields\pohjola-svc-notebooks
$ParametersFile= Import-Csv "OP_model_b643a336-75b3-5b3b-a7e9-dba249344fbd_"+$date+"_parameters.csv"
$Notional=$ParametersFile.Notional
$Bias=$ParametersFile.Bias
$Age=$ParametersFile.Age
$TwoYearsInd=$ParametersFile.TwoYearsInd

Write-Output "Update Calypso with new parameters"
java -jar -Xmx1500m -DUSER="c934501" -DPW="c934501" -DENV="CALYPSOPSC" -DNotional=$Notional -DBias=$Bias -DAge=$Age -DTwoYearsInd=$TwoYearsInd C:\yields\auxiliary-binaries-and-scripts\LJRupdate.jar
Stop-Transcript
