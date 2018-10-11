Write-Output "Invoke env for Docker"
docker-machine env yields  | Invoke-Expression

Write-Output "Test data-lake ingestion"
$file="LEGACY/old-stuff-put-here-sept-13/test_100000/test_100000.csv"
cd C:\yields\platform-hdfs-client
docker-compose run --rm hdfs hdfs dfs -put -f $file hdfs://namenode:8020/data_hub/data/lake/client-pohjola/dept1/data_spec_rim/raw/ds_dummy

Start-Sleep -s 10s