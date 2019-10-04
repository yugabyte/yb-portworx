#!/bin/bash
tserver="yb-tserver-0"
namespace="yb-px-db"

function LoadData() {
    kubectl exec -n $namespace $tserver /home/yugabyte/bin/ysqlsh -- -h $tserver -d yb_demo -c "TRUNCATE TABLE ORDERS;"
    for i in {1..1000};
    do 
        kubectl exec -n $namespace $tserver /home/yugabyte/bin/ysqlsh -- -h $tserver -d yb_demo -c "INSERT INTO orders(id,created_at,discount,product_id,quantity,subtotal,tax,total,user_id) VALUES ($i,'2018-05-15T08:04:04.580Z',NULL,123,3,110.93145648834248,6.1,117.0376564084763,1)"
    done
}
LoadData
