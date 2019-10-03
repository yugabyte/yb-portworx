#!/bin/bash
host="yb-tserver-0"
function CountData() {

    for i in {1..100};
    do
        kubectl exec -n yb-portworx-db $host -- /home/yugabyte/bin/ysqlsh -h $host -d yb_demo -c "select count(1) from orders;"
    sleep 3s;
    done
}
CountData
