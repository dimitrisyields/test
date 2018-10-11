############-Test_1: Hdfs client-##############
Write-Output "Get generated file in current directory"
cd current
$file=cmd /r dir /b

Write-Output "Invoke env for Docker"
docker-machine env yields  | Invoke-Expression

Write-Output "Run hdfs-client and ingest generated calypso file"
cd C:\yields\platform-hdfs-client
docker-compose run --rm hdfs hdfs dfs -put -f automation-scripts/current/$file hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/raw/ds_calypso


############-Test_2: Execute notebook-##############
Write-Output "Execute feature extraction"
docker exec jupyter jupyter nbconvert --execute op_notebooks/test.ipynb

Start-Sleep -s 15