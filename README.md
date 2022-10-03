
# About
This module covers the foundational setup required for the BigLake Fine Grained Permissions Demo.


## 0. Prerequisites 

#### 1. Create a project".<br>
Note the project number and project ID. <br>
We will need this for the rest fo the lab.<br>
#### 2. Grant yourself security admin role<br>
This is needed for the networking setup.<br>
Go to Cloud IAM and through the UI, grant yourself security admin role.
#### 3. Grant yourself Organization Policy Administrator at an Organization level<br>
This is needed to set project level policies<br>
In the UI, set context to organization level (instead of project)<br>
Go to Cloud IAM and through the UI, grant yourself Organization Policy Administrator at an Organization level.<br>
Don't forget to set the project back to the project you created in Step 1 above in the UI.
#### 4. Create 3 user accounts<br>
TBD...<br>


#### 5. Create Separate Chrome Profiles for 1 or More of the User Accounts
TBD...<br>
[Add Profile Instructions](https://support.google.com/chrome/answer/2364824?hl=en)

### Steps in the lab:
TBD... 
<br><br>


## 1. Details about the environment that is setup by this module

### 1.1. Products/services used in the lab
The following services need to be created for the lab which are covered in the Terraform script-
TBD...
<br><br>

### 1.2. Purpose served by the product/services

| # | Product/Service | Purpose  | 
| -- | :--- | :--- |
| 1. | Cloud Dataproc | Individual Server for USA User |
| 2. | BigQuery | Source for sample data |
| 3. | Cloud IAM | User Managed Service Account, IAM roles |
| 4. | VPC | Network, Subnet |
| 5. | Firewall | Rule to allow internode communication by Spark node roles |
| 6. | Cloud Router<br>Cloud NAT | NAT needed to download spark packages over the internet |
| 7. | Cloud Storage | Pyspark Notebook scripts, and Data Samples |

### 1.3. Tooling

1. Terraform for automation
2. Cloud Shell for executing Terraform

<hr>

## 2. Provision the GCP environment 

### 2.1. Create a directory in Cloud Shell for the workshop
![M1](../00-images/M1-04.png) 
<br><br>

```
cd ~
mkdir biglake_demo
```

### 2.2. Clone the workshop git repo



```
cd ~
git clone https://github.com/j-f-oleary-bigdata/biglake_demo
```

### 2.3. About the Terraform script

#### 2.3.1. Navigate to the Terraform directory
```
cd ~/biglake_demo/demo/terraform
```

#### 2.3.2. Study main.tf
It does the below, except not exactly in sequential order, but rather in parallel where possible-
TBD...
<br><br>

#### 2.3.3. Study variables.tf
The parameters to be passed to the Terraform script are available in this file

#### 2.3.4. What we will do next

1. Define variables for use by the Terraform
2. Initialize Terraform
3. Run a Terraform plan & study it
4. Apply the Terraform to create the environment
5. Validate the environment created

### 2.4. Provision the environment


#### 2.4.1. Define variables for use

Modify the below as appropriate for your deployment..e.g. region, zone etc. Be sure to use the right case for GCP region & zone.<br>
Regions and zones listing can be found [here](https://cloud.google.com/compute/docs/regions-zones)(zone has a -a/b/c as suffix to region/location).<br>

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
ORG_ID=`gcloud organizations list --format="value(name)"`
LOCATION="us-central1"
#ORG_ID="<your or here!!!>"
ORG_ID="jayoleary.altostrat.com"
YOUR_GCP_MULTI_REGION="US"
USA_USERNAME="usa_user"
AUS_USERNAME="aus_user"
MKT_USERNAME="mkt_user"

echo "PROJECT_ID=$PROJECT_ID"
echo "PROJECT_NBR=$PROJECT_NBR"
echo "LOCATION=$LOCATION"
echo "ORG_ID=$ORG_ID"
echo "USA_USERNAME=$USA_USERNAME"
echo "AUS_USERNAME=$AUS_USERNAME"
echo "MKT_USERNAME=$MKT_USERNAME"
```

### 2.4.2. Initialize Terraform for Orginization Policy Configuration

<br><br>

Needs to run in cloud shell from ~/biglake-demo/org_policy
```
terraform init
```

### 2.4.3. Run Provisioning for Orginization Policy Configuration

<br><br>

Needs to run in cloud shell from ~/biglake-demo/org_policy
```
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  --auto-approve
```


### 2.4.4. Initialize Terraform

<br><br>

Needs to run in cloud shell from ~/biglake-demo/demo
```
terraform init
```

#### 2.4.5. Review the Terraform deployment plan
Needs to run in cloud shell from ~/spark-kafka-lab/spark-on-gcp-with-confluent-kafka/01-environment-setup
```
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="org_id=${ORG_ID}" \
  -var="location=${LOCATION}" \
  -var="usa_username=${USA_USERNAME}" \
  -var="aus_username=${AUS_USERNAME}" \
  -var="mkt_username=${MKT_USERNAME}"   
```

#### 2.4.6. Provision the environment
Needs to run in cloud shell from ~/spark-kafka-lab/spark-on-gcp-with-confluent-kafka/01-environment-setup
```
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="org_id=${ORG_ID}" \
  -var="location=${LOCATION}" \
  -var="usa_username=${USA_USERNAME}" \
  -var="aus_username=${AUS_USERNAME}" \
  -var="mkt_username=${MKT_USERNAME}" \
  --auto-approve
```

<hr>

## 3. Validate your Terraform deployment against a pictorial overview of services provisioned & customization

### 3.1. BigQuery Dataset and Tables

TBD...
<br><br>



### 3.2. Dataproc Instances (3)

TBD...
<br><br>


### 3.2. Jupyter Notebook (USA User)

TBD...
<br><br>


<hr>


### 4. To destroy the deployment [DO NOT RUN THIS, ITS JUST FYI]

You can (a) shutdown the project altogether in GCP Cloud Console or (b) use Terraform to destroy. Use (b) at your own risk as its a little glitchy while (a) is guaranteed to stop the billing meter pronto.
<br>
Needs to run in cloud shell from ~/spark-kafka-lab/spark-on-gcp-with-confluent-kafka/01-environment-setup
```
#terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="org_id=${ORG_ID}" \
  -var="location=${LOCATION}" \
  -var="usa_username=${USA_USERNAME}" \
  -var="aus_username=${AUS_USERNAME}" \
  -var="mkt_username=${MKT_USERNAME}" \
  --auto-approve
 ```

