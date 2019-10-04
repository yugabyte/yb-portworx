#!/bin/bash
tserver="yb-tserver-0"
files=("products" "users")
data_dir="data"
namespace="yb-px-db"

function getFiles() {
    mkdir $data_dir && cd $_
    wget https://raw.githubusercontent.com/yugabyte/yb-sql-workshop/master/query-using-bi-tools/schema.sql
    wget https://github.com/yugabyte/yb-sql-workshop/raw/master/query-using-bi-tools/sample-data.tgz
    tar zxvf sample-data.tgz
    kubectl cp ./schema.sql -n $namespace $tserver:/home/yugabyte/.
    kubectl exec -n $namespace $tserver mkdir $data_dir
}
getFiles

function copyFiles() {
   arr=("$@")
   for i in "${arr[@]}";
      do
          kubectl cp ./$data_dir/$i.sql -n $namespace $tserver:/home/yugabyte/$data_dir/.
      done

}
copyFiles "Copying" "${files[@]}"

function createDatabase() {
    kubectl exec -it -n $namespace $tserver /home/yugabyte/bin/ysqlsh -- -h $tserver  --echo-queries <<EOF
    Drop DATABASE yb_demo;
    CREATE DATABASE yb_demo;
    GRANT ALL ON DATABASE yb_demo to postgres;
    \c yb_demo;
    \i 'schema.sql';
    \i '$data_dir/products.sql'
    \i '$data_dir/users.sql'
EOF
}
createDatabase

function cleanup() {
    cd ..
    rm -rf $data_dir schema.sql
    kubectl exec -n $namespace yb-tserver-0 -- rm -rf $data_dir schema.sql
}
cleanup
