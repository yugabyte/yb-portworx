# yb-portworx-db
Instructions for deploying YugaByte DB with Portworx on GKE.

## Pre-req
Before installing Portworx-Enterprise, make sure your environment meets the following requirements: 

* Image type: Portworx is supported on GKE clusters provisioned on Ubuntu Node Images. So it is important to specify the node image as Ubuntu when creating clusters.

* Resource requirements: Portworx requires that each node in the Kubernetes cluster has at least 4 CPUs and 4 GB memory for Portworx. It is important to keep this in mind when selecting the machine types during cluster creation.

* Compute Admin and Service Account User Roles: These roles provides Portworx access to the Google Cloud Storage APIs to provision persistent disks. Make sure the user creating the GKE cluster has these roles.

* For more details refer [here](https://docs.portworx.com/start-here-installation/)

## Config
Below are the steps for deployment:

1. Create a GKE cluster
    Configure gcloud
    If this is your first time running with Google Cloud, please follow the steps below to install the gcloud shell, configure your project and compute zone. If you already have gcloud set up, you can skip to the next step.
```
    export PROJECT_NAME=<PUT-YOUR-PROJECT-NAME-HERE>
    gcloud config set project $PROJECT_NAME
    gcloud config set compute/region us-east1
    gcloud config set compute/zone us-east1-b
    sudo gcloud components update
```

2. Create a zonal cluster using gcloud
* To create a 3-node zonal cluster in us-east1-b with auto-scaling enabled, run:
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

3. Set your default cluster while using gcloud:-
``` 
gcloud config set container/cluster px-demo 
gcloud container clusters get-credentials px-demo --zone us-east1-b
gcloud services enable compute.googleapis.com 
```
4. Provide permissions to Portworx
* Portworx requires a ClusterRoleBinding for your user to deploy the specs. You can do this using:
```
kubectl create clusterrolebinding myname-cluster-admin-binding \
    --clusterrole=cluster-admin --user=`gcloud info --format='value(config.account)'`
```
 
5.  Clone this repo: 
*  ``` git clone git@github.com:infracloudio/yb-portworx-db.git ```
* Change to yb-portworx-db directory in the cloned directory

6. Apply the specs:-
``` kubectl apply -f px-spec.yaml ```

    Note:- Generate px-spec.yaml using the spec-genrator tool [here](https://central.portworx.com/) with your account. With new account it will have License Trial with 31 days of expiry.
 * Added screenshots for the referred values while generating the spec file.
<img src="https://github.com/infracloudio/yb-portworx-db/blob/development/Images/basic.png" width="900" >
<img src="https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Network.png" width="900" >
<img src="https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Storage.png" width="900" >
<img src="https://github.com/infracloudio/yb-portworx-db/blob/development/Images/Customize.png" width="900" >

7. Monitor the portworx pods
* Wait till all Portworx pods show as ready in the below output:
``` 
kubectl get pods -o wide -n kube-system -l name=portworx 
```

8. Monitor Portworx cluster status
```
PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl status
```

* For more details and options for portworx setup refer [here](https://docs.portworx.com/portworx-install-with-kubernetes/cloud/gcp/gke/#create-your-gke-cluster-using-gcloud)

9. Deploy yugabyte cluster inside the GKE cluster:
    * Run 
``` 
kubectl create -f yugabyte-portworx-db.yaml 
```
10. Portworx UI
* We can access Portworx UI using “Lighthouse”, which is a GUI dashboard. It can be accessed using a NodePort service:
```
kubectl get nodes -o wide (use any external ip)
kubectl get svc -n kube-system  px-lighthouse
```
    Open: http://<node_ip>:<service_nodeport> (default login is admin/Password1)


11. Now for testing lets create, load & test the sample yb_demo database and tables using below scripts:
    * From the host vm run:-
    (Pass value to the variable "tserver" & "namespace" with the name of your tserver pod and namespace, default value set is "yb-tserver-0" & "yb-px-db" respectively.)
        * Create the database and tables
        ``` ./DB_Init.sh ``` 
        (Try to run below both scripts at the same time to verify real time data)
        * Now start loading the data in table "orders" 
        ``` ./DB_Load.sh ```
        * Open host vm in new window and run the test script :-
        ``` ./DB_Test.sh ``` 
        (Pass value to the variable "host" with the name of your tserver node)
        * If your are getting output with increasing number of counts for the table "orders" you have successfully configured the yugabyte DB with portworx.
