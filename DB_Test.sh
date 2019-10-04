#!/bin/bash
host="yb-tserver-0"
namespace="yb-px-db"
function CountData() {

    for i in {1..100};
    do
        kubectl exec -n $namespace $host -- /home/yugabyte/bin/ysqlsh -h $host -d yb_demo -c "select count(1) from orders;"
    sleep 3s;
    done
}
CountData
