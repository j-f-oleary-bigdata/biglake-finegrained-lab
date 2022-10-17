
# About<br>
This lab showcases fine-grained access control made possible by BigLake with a minimum viable Spark sample notebook on a Cloud Dataproc cluster. 


## 1. Prerequisites 

### 1.1. Create a project
Note the project number and project ID. <br>
We will need this for the rest of the lab.

### 1.2. Grant yourself Security Administrator role<br>
This is needed for the networking setup.<br>
Go to Cloud IAM and through the UI, grant yourself security admin role.

### 1.3. Grant yourself Organization Policy Administrator at an Organization level<br>
This is needed to set project level policies<br>
In the UI, set context to organization level (instead of project)<br>
Go to Cloud IAM and through the UI, grant yourself Organization Policy Administrator at an Organization level.<br>
Don't forget to set the project back to the project you created in Step 1 above in the UI.

### 1.4. Create 3 user accounts<br>
Go To admin.google.com...<br>
* Click on 'Add a user'<br>
* And add a user as shown below:<br><br>
![PICT1](./images/add_user.png) 

<br>
- You will add three users: <br>
1. One user with access to all USA records in the dataset <br>
2. One user with access to all Australia records in the dataset<br>
3. One marketing user with access to both USA and Australia recoreds but restricted to certain columns<br>
<br>
- While you can use any usernames you want, we recommend you use the following as we have tested with these: <br>
1. usa_user <br>
2. aus_user <br>
3. mkt_user <br>

<br>

### 1.5. Create Separate Chrome Profiles for 1 or More of the User Accounts
To make it easier to demo the three different personas (users) we recommend you set up 3 profiles in your browser<br>
<br>
- To add a profile<br>
* click on your profile picture at the far right of the screen next to the vertical 3 dots. <br>
* Then click on '+ Add' at the bottom of the screen as shown below: <br>
![PICT2](./images/add_profile.png) 
<br>

We recommend you setup three profiles: <br>
1. One for the USA User
2. One for the Australia User
3. And one for the Marketing User

For more information see these instructions --> [Add Profile Instructions](https://support.google.com/chrome/answer/2364824?hl=en)

<hr>

## 2. Details about the environment that is setup by this module

### 2.1. Products/services used in the lab
The following services and resources will be created via Terraform scripts:
<br><br>
1. VPC, Subnetwork and NAT rules
2. IAM Groups for USA and Australia
3. Dataplex Policy for Column level Access
4. BigQuery Dataset, Table and Row Level Policies
5. Dataproc 'Personal' Clusters: a cluster each for USA, Australia and Marketing Users
6. Preconfigured Jupyter Notebooks

### 2.2. Tooling

1. Terraform for automation
2. Cloud Shell for executing Terraform

<hr>

## 3. Provision the GCP environment 

This section covers creating the environment via Terraform from Cloud Shell.
1. Launch cloud shell
2. Clone this git repo
3. Provision foundational resources such as Google APIs and Organization Policies
4. Provision the GCP data Analytics services and their dependencies for the lab

### 3.1. Create a Cloud Shell Session
Instructions for launching and using cloud shell are available [here](https://cloud.google.com/shell/docs/launching-cloud-shell).

### 3.2. Clone the workshop git repo

```
cd ~
git clone https://github.com/j-f-oleary-bigdata/biglake-finegrained-demo
```

### 3.3. About the Terraform scripts

#### 3.3.1. Navigate to the Terraform directory
```
cd ~/biglake-finegrained-demo/
```

#### 3.3.2. Review the Terraform directory structure (& optionally, the content)

Browse and familiarize yourself with the layout and optionally, review the scripts for an understanding of the constructs as well as how dependencies are managed.

#### 3.3.3. What's involved with provisioning with Terraform

1. Define variables for use with Terraform
2. Initialize Terraform
3. Run a Terraform plan & study it
4. Apply the Terraform to create the environment
5. Validate the environment created

### 3.4. Provision the environment

#### 3.4.1. Define variables for use

Modify the below as appropriate for your deployment..e.g. region, zone etc. Be sure to use the right case for GCP region & zone.<br>
Make the corrections as needed below and then cut and paste the text into the Cloud Shell Session. <br>

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
LOCATION="us-central1"
ORG_ID=`gcloud organizations list | grep DISPLAY_NAME | cut -d':' -f2 | xargs`
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

#### 3.4.2. Provision foundational resources

Foundational resources in this lab constitute Google APIs and Organizational Policies. 

##### 3.4.2.1. Initialize Terraform
The command below needs to run in cloud shell from ~/biglake-finegrained-demo/org_policy

```
cd ~/biglake-finegrained-demo/org_policy
terraform init
```

#### 3.4.2.2. Terraform deploy the resources

The terraform below first enables Google APIs needed for the demo, and then updates organization policies. It needs to run in cloud shell from ~/biglake-finegrained-demo/org_policy

```
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  --auto-approve
```


#### 3.4.3. Initialize Terraform for the data analytics services & dependencies

##### 3.4.3.1. Initialize Terraform

Needs to run in cloud shell from ~/biglake-finegrained-demo/demo
```
cd ~/biglake-finegrained-demo/demo
terraform init
```

##### 3.4.3.2. Review the Terraform deployment plan

Needs to run in cloud shell from ~/biglake-finegrained-demo/demo
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

##### 3.4.3.3. Terraform provision the data analytics services & dependencies

Needs to run in cloud shell from ~/biglake-finegrained-demo/demo
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

## 4. Validate the Terraform deployment

### 4.1. IAM users, groups, permissions


### 4.2. Network

### 4.3. Policy Tags and Resource Affiliation

### 4.4. BigQuery Dataset and Tables

From your admin account, go to the cloud console and then the BigQuery UI<br><br>
Validate that you have the following resources as shown in the screeshot below:
1. An external connection called 'us-central1.biglake.gcs'
2. A dataset called biglake_dataset
3. A table called IceCreamSales
<br><br>
![PICT3](./images/bigquery.png) 


### 4.5. Dataproc Instances (3)

From your admin account, go to the cloud console and then the Dataproc UI<br><br>

- Validate that you have the following three (3) Dataproc Clusters: 
1. aus-dataproc-cluster
2. usa-dataproc-cluster
3. mkt-dataproc-cluster
<br><br>
![PICT3](./images/dataproc.png) 

### 3.3. Jupyter Notebook (USA User)

### 3.3.1 Create a personal authentication session...

- From your USA User Account (usa_user in this example), go to the cloud console and then the Dataproc UI<br><br>
- Make sure to select the project you created in the step above.  In this example, the project is 'biglake-demov4' as shown below:
![PICT4](./images/dataproc_user.png)
<br><br>
Click on the usa-dataproc-cluster link<br>
Open up a new cloudshell session by click on the cloudshell link that looks like this --> '>_'<br>
<br>
Enter the following text:
<br>
Make sure to subsitute your project name for &lt;your project name here&gt;
<br><br>
```
gcloud dataproc clusters enable-personal-auth-session \
    --project=<your project name here> \
    --region=us-central1 \
    --access-boundary=<(echo -n "{}") \
   usa-dataproc-cluster
```

You will be prompted with:
```
A personal authentication session will propagate your personal credentials to the cluster, so make sure you trust the cluster and the user who created it.

Do you want to continue (Y/n)?
```

Respond with 'Y' and hit enter <br>
You will see the following text
```
Injecting initial credentials into the cluster usa-dataproc-cluster...done.     
Periodically refreshing credentials for cluster usa-dataproc-cluster. This will continue running until the command is interrupted...working.  
```

Leave this Cloud Shell running while you complete the next steps.

### 3.3.2 Initiate the kerberos session on the Personal Dataproc Cluster...
From your USA User Account (usa_user in this example), go to the cloud console and then the Dataproc UI<br><br>
Make sure to select the project you created at the beginning of the lab.  In this example, the project is 'biglake-demov4'.
<br><br>
#Next:

1. Click on the usa-dataproc-cluster link<br>
2. Then click on the 'WEB INTERFACES' link <br>
3. Scroll to the bottom of the page and you should see a link for 'Jupyter Lab' <br>
4. Click on the 'Jupyter Lab' link and this should bring up a new tab as shown below:
![PICT4](./images/jupyter1.png)
<br><br>
In Jupyter, Click on File..New Launcher and then Terminal (at bottom of screen under 'Other' <br>
In terminal screen, enter the following:

```
kinit -kt /etc/security/keytab/dataproc.service.keytab dataproc/$(hostname -f)
```
<br>
You can then close the the terminal screen.

### 3.3.3 Run the 'IceCream.ipynb' Notebook...
From the Jupyter Lab tab you created above, doublce click on the 'IceCream.ipynb' file as shown below...<br>
1. Then click on the icon on the right that says 'Python 3' with a circle next to it...<br>
2. A dialog box that says 'Select Kernel' will appear, choose 'PySpark' and hit select
![PICT5](./images/jupyter6.png)
<br><br>

In the second cell, 
- change &lt;your-project-name-here&gt; to the your project name 
![PICT5](./images/jupyter2.png)
<br><br>
- In this example, the project name is 'biglake-demov4' as shown below:
![PICT6](./images/jupyter3.png)
<br><br>
- You can now run all cells.  
* From the 'Run..Run all Cells' menu.   <br>
* Below cell 3, you should see data only for the 'United States' as shown below:
![PICT7](./images/jupyter4.png)
<br><br>

### 3.4. Jupyter Notebook (Aus User - aus_user)

Follow steps 3.2.1 and 3.2.2 and 3.2.3 from above but choose the aus-dataproc-cluster instead.<br>
- Remember to use the 'aus-dataproc-cluster' when running the 'gcloud dataproc clusters...' command <br>

- The major difference is that in cell 3, you should see data only for the 'Australia' as shown below:
![PICT8](./images/jupyter7.png)
<br>
<hr>

### 3.5. Jupyter Notebook (Marketing User - mkt_user)

### 3.5.1 Create a personal authentication session...

- From your Marketing User Account (mkt_user in this example), 
* go to the cloud console and then the Dataproc UI<br><br>
* Make sure to select the project you created in the step above.  
* In this example, the project is 'biglake-demov4' as shown below:
![PICT4](./images/dataproc_user.png)
<br><br>
- Click on the mkt-dataproc-cluster link<br>
* Open up a new cloudshell session by click on the cloudshell link that looks like this --> '>_'<br>
<br>
* Enter the following text:
<br>
* Make sure to subsitute your project name for &lt;your-project-name-here&gt;
<br><br>
```
gcloud dataproc clusters enable-personal-auth-session \
    --project=<your project name here> \
    --region=us-central1 \
    --access-boundary=<(echo -n "{}") \
   mkt-dataproc-cluster
```

- You will be prompted with:
```
A personal authentication session will propagate your personal credentials to the cluster, so make sure you trust the cluster and the user who created it.

Do you want to continue (Y/n)?
```

- Respond with 'Y' and hit enter <br>
* You will see the following text
```
Injecting initial credentials into the cluster usa-dataproc-cluster...done.     
Periodically refreshing credentials for cluster usa-dataproc-cluster. This will continue running until the command is interrupted...working.  
```

- Leave this Cloud Shell running while you complete the next steps.

### 3.5.2 Initiate the kerberos session on the Personal Dataproc Cluster...
- From your Marketing User Account (mkt_user in this example), 
* go to the cloud console and then the Dataproc UI<br><br>
* Make sure to select the project you created at the beginning of the lab.  
* In this example, the project is 'biglake-demov4'.
<br><br>
- Click on the usa-dataproc-cluster link<br>
* Then click on the 'WEB INTERFACES' link <br>
* Scroll to the bottom of the page and you should see a link for 'Jupyter Lab' <br>
* Click on the 'Jupyter Lab' link and this should bring up a new tab as shown below:
![PICT4](./images/jupyter1.png)
<br><br>
- In Jupyter, Click on File..New Launcher and then Terminal (at bottom of screen under 'Other' <br>
* In terminal screen, enter the following:

```
kinit -kt /etc/security/keytab/dataproc.service.keytab dataproc/$(hostname -f)
```
<br>
- You can then close the the terminal screen.

### 3.5.3 Run the 'ReadData.ipynb' Notebook...
- From the Jupyter Lab tab you created above, 
* doublce click on the 'ReadData.ipynb' file as shown below...<br>
* Then click on the icon on the right that says 'Python 3' with a circle next to it...<br>
* A dialog box that says 'Select Kernel' will appear, choose 'PySpark' and hit select
![PICT5](./images/jupyter1.png)
* In the second cell, change &lt;your-project-name-here&gt;to the your project name<br>
![PICT5](./images/jupyter2.png)

* In this example, the project name is 'biglake-demov4' as shown below:<br>
![PICT6](./images/jupyter8.png)


- You can now run all cells.  
* From the 'Run..Run all Cells' menu.   <br>
* Below cell 2, you should see an error because the Marketing User does not have access to certain columns: <br>
![PICT7](./images/jupyter5.png)
<br>
* Remove the comments in the line '#.select("Gross_Revenue", "Month", "Country")' and the line above<br>
* Also, change 'df.show(10)' to 'df.show(100)'<br>
* Then run all cells again. <br>
* This time, you should see data for both the 'United States' and 'Australia' in cell 3.<br>
<br>

### 4. To destroy the deployment

You can (a) shutdown the project altogether in GCP Cloud Console or (b) use Terraform to destroy. Use (b) at your own risk as its a little glitchy while (a) is guaranteed to stop the billing meter pronto.
<br>
Needs to run in cloud shell from ~/biglake-finegrained-demo/demo
```
cd ~/biglake-finegrained-demo/demo
terraform destroy \
  -var="project_id=${PROJECT_ID}" \
  -var="project_nbr=${PROJECT_NBR}" \
  -var="org_id=${ORG_ID}" \
  -var="location=${LOCATION}" \
  -var="usa_username=${USA_USERNAME}" \
  -var="aus_username=${AUS_USERNAME}" \
  -var="mkt_username=${MKT_USERNAME}" \
  --auto-approve
 ```

