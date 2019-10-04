# yb-portworx-db
Instructions for deploying YugaByte DB with Portworx on GKE.

Prerequisites: https://docs.portworx.com/start-here-installation/#installation-prerequisites

Below are the steps for deployment:
 (for more details refer :https://docs.portworx.com/portworx-install-with-kubernetes/cloud/gcp/gke/#create-your-gke-cluster-using-gcloud)

1. Inside your GKE create a zonal cluster:
```
     gcloud container clusters create px-demo \ 
    --zone us-east1-b \
    --disk-type=pd-ssd \
    --disk-size=50GB \
    --labels=portworx=gke \
    --machine-type=n1-highcpu-8 \
    --num-nodes=3 \
    --image-type ubuntu \
    --scopes compute-rw,storage-ro \
    --enable-autoscaling --max-nodes=6 --min-nodes=3
```

2. set your default cluster:-
``` gcloud config set container/cluster px-demo ```
``` gcloud container clusters get-credentials px-demo --zone us-east1-b ```
``` gcloud services enable compute.googleapis.com ```

 ( Generated px-spec.yaml using the tool, added screenshots for the values reference.
![alt text](https://github.com/infracloudio/yb-portworx-db/blob/development/Images/basic.png)
![alt text](https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Network.png)
![alt text](https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Storage.png)
![alt text](https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Customize.png)
 )
 
3. Apply the specs:-
``` kubectl apply -f px-spec.yaml ```

4. Monitor the portworx pods
Wait till all Portworx pods show as ready in the below output:
``` kubectl get pods -o wide -n kube-system -l name=portworx ```

5. Monitor Portworx cluster status
``` PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}') ```
``` kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl status ```


6. Deploy yugabyte cluster inside the k3s:
    * Run ``` kubectl create -f yugabyte-portworx-db.yaml ```
You can see on gcp console that your pvc's have been created
![alt text](https://github.com/infracloudio/yb-portworx-db/blob/development/Images/pvc.png)

7. Now for testing, lets create, load & test the sample yb_demo database and tables using below scripts:
    * From the host vm run:-
    (Pass value to the variable "tserver" & "namespace" with the name of your tserver pod and namespace, default value set is "yb-tserver-0" & "yb-px-db" respectively.)
        * Create the database and tables
        ``` ./DB_Init.sh ``` 
        (Try to run below both scripts at the same time to verify real time data)
        * Now start loading the data in table "orders" 
        ``` ./DB_Load.sh ```
        * Open host vm in new window and run the test script :-
        ``` ./DB_Test ``` 
        (Pass value to the variable "host" with the name of your tserver node)
        
        If your are getting output with increasing number of counts for the table "orders" you have successfully configured the yugabyte DB with portworx.
