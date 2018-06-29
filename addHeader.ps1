Get-ChildItem "C:\Users\jim\Desktop\ds2" -Filter *.csv | 
Foreach-Object {
    $headerToAdd = "id_2,curr_date,service_name,curr_int_rate,curr_upb,age,remain_to_mat,adj_remain_to_mat,mat_date,msa,deliq_stat,modif_flag,zero_bal_code,zero_bal_date,last_paid_date,foreclosure_date,disp_date,foreclosure_cost,preservation,recovery_cost,misc,taxes,net_sale,cred_enh,repurchase,other,bearing_upb,forgiveness_upb,flag,foreclosure_amount,serv_ind"
    if ((Get-Content $_.FullName -Raw).StartsWith("i")){
        (Get-Content $_.FullName -Raw) | Set-Content $_.FullName
    }
    else{
        $headerToAdd + "`n" + (Get-Content $_.FullName -Raw) | Set-Content $_.FullName
    }
    
}
