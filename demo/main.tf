/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
location                    = "${var.location}"
dataproc_temp_bucket        = "dataproc-temp-${var.project_nbr}"
vpc_nm                      = "default"
subnet_nm                   = "default"
subnet_cidr                 = "10.0.0.0/16"
dataset_name                = "biglake_dataset"
bq_connection               = "biglake-gcs"
}

provider "google" {
  project = local.project_id
  region  = local.location
}

####################################################################################
# Default Network
# The project was not created with the default network.  
# This creates just the network/subnets we need.
####################################################################################
resource "google_compute_network" "default_network" {
  project                 = var.project_id
  name                    = local.vpc_nm
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Subnet for dataproc cluster
resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = local.subnet_nm  
  ip_cidr_range = local.subnet_cidr
  region        = var.location
  network       = google_compute_network.default_network.id
  private_ip_google_access = true

  depends_on = [
    google_compute_network.default_network
  ]
}

/*
gcloud compute routers create nat-router-us-central1 \
    --network default \
    --region us-central1

resource "google_compute_router" "nat-router-us-central1" {
  name    = "nat-router-us-central1"
  region  = "${var.region1}"
  network  = "default"
}

resource "google_compute_router_nat" "nat-config1" {
  name                               = "nat-config1"
  router                             = "${google_compute_router.nat-router-us-central1.name}"
  region                             = "${var.region1}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

gcloud compute routers nats create nat-config \
    --router-region us-central1 \
    --router nat-router-us-central1 \
    --nat-all-subnet-ip-ranges \
     --auto-allocate-nat-external-ips
*/

/******************************************
2. Firewall rules creation
 *****************************************/

# Firewall rule for dataproc cluster
resource "google_compute_firewall" "subnet_firewall_rule" {
  project  = var.project_id
  name     = "subnet-firewall"
  network  = google_compute_network.default_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  source_ranges = [local.subnet_cidr]

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

resource "google_compute_router" "nat-router" {
  name    = "nat-router"
  region  = "${var.location}"
  network  = google_compute_network.default_network.id

  depends_on = [
    google_compute_firewall.subnet_firewall_rule
  ]
}

resource "google_compute_router_nat" "nat-config" {
  name                               = "nat-config"
  router                             = "${google_compute_router.nat-router.name}"
  region                             = "${var.location}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  depends_on = [
    google_compute_router.nat-router
  ]
}

/******************************************
3. Create groups and memberships
 *****************************************/

resource "null_resource" "create_groups" {
   for_each = {
      "us-sales" : "",
      "australia-sales" : ""
    }
  provisioner "local-exec" {
    command = <<-EOT
      thegroup=`gcloud identity groups describe ${each.key}@${var.org_id}  | grep -i "id:"  | cut -d':' -f2 |xargs`
      #create group if it doesn't exist
      if [ -z "$thegroup" ]; then
        gcloud identity groups create ${each.key}@${var.org_id} --organization="${var.org_id}" --group-type="security" 
      fi
    EOT
  }

}


resource "time_sleep" "wait_30_seconds" {

  create_duration = "30s"
  
  depends_on = [
    null_resource.create_groups
    ]

}

resource "null_resource" "create_memberships" {
   for_each = {
      "us-sales" : format("%s",var.usa_username),
      "australia-sales" : format("%s",var.aus_username)
    }
  provisioner "local-exec" {
    command = <<-EOT
      thegroup=`gcloud identity groups memberships list --group-email="${each.key}@${var.org_id}" | grep -i "id:"  | cut -d':' -f2 |xargs`
      #add member if not already a member
      if ! [[ "$thegroup" == *"${each.value}"* ]]; 
      then   
        gcloud identity groups memberships add --group-email="${each.key}@${var.org_id}" --member-email="${each.value}@${var.org_id}" 
      fi
    EOT
  }

  depends_on = [
    time_sleep.wait_30_seconds
  ]

}

resource "null_resource" "create_memberships_mkt" {
   for_each = {
      "us-sales" : format("%s",var.mkt_username),
      "australia-sales" : format("%s",var.mkt_username)
    }
  provisioner "local-exec" {
    command = <<-EOT
      thegroup=`gcloud identity groups memberships list --group-email="${each.key}@${var.org_id}" | grep -i "id:"  | cut -d':' -f2 |xargs`
      #add member if not already a member
      if ! [[ "$thegroup" == *"${each.value}"* ]]; 
      then   
        gcloud identity groups memberships add --group-email="${each.key}@${var.org_id}" --member-email="${each.value}@${var.org_id}" 
      fi
    EOT
  }

  depends_on = [
    null_resource.create_memberships
  ]

}

resource "google_project_iam_binding" "project_viewer" {
  project = var.project_id
  role    = "roles/viewer"

  members = [
    "user:${var.usa_username}@${var.org_id}",
    "user:${var.aus_username}@${var.org_id}",
    "user:${var.mkt_username}@${var.org_id}"
  ]
}

resource "google_project_iam_binding" "dataproc_admin" {
  project = var.project_id
  role    = "roles/dataproc.editor"

  members = [
    "user:${var.usa_username}@${var.org_id}",
    "user:${var.aus_username}@${var.org_id}",
    "user:${var.mkt_username}@${var.org_id}"
  ]
}


####################################################################################
# Create Customer GCS Bucket and GCS Objects
####################################################################################

resource "google_storage_bucket" "create_buckets" {
  for_each = {
    "aus" : "",
    "usa" : "",
    "mkt" : "",
  }
  name                              = "dataproc-bucket-${each.key}-${var.project_nbr}"
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true

}

resource "google_storage_bucket" "create_temp_buckets" {

  name                              = local.dataproc_temp_bucket
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true

}

resource "google_storage_bucket_object" "gcs_objects" {
  for_each = {
    "aus" : "",
    "usa" : "",
    "mkt" : "",
  }
  name        = "data/IceCreamSales.csv"
  source      = "./resources/IceCreamSales.csv"
  bucket      = "dataproc-bucket-${each.key}-${var.project_nbr}"
  depends_on = [google_storage_bucket.create_buckets]
}


resource "google_storage_bucket_iam_binding" "temp_dataproc_bucket_policy" {
  bucket = local.dataproc_temp_bucket
  role = "roles/storage.admin"
  members = [
          "user:${var.aus_username}@${var.org_id}",
          "user:${var.usa_username}@${var.org_id}",
          "user:${var.mkt_username}@${var.org_id}"
  ]

  depends_on = [google_storage_bucket.create_buckets]
}

resource "google_storage_bucket_iam_binding" "aus_dataproc_bucket_policy" {
  bucket = "dataproc-bucket-aus-${var.project_nbr}"
  role = "roles/storage.admin"
  members = ["user:${var.aus_username}@${var.org_id}"]

  depends_on = [google_storage_bucket.create_buckets]
}


resource "google_storage_bucket_iam_binding" "usa_dataproc_bucket_policy" {
  bucket = "dataproc-bucket-usa-${var.project_nbr}"
  role = "roles/storage.admin"
  members = ["user:${var.usa_username}@${var.org_id}"]

  depends_on = [google_storage_bucket.create_buckets]
}


resource "google_storage_bucket_iam_binding" "mkt_dataproc_bucket_policy" {
  bucket = "dataproc-bucket-mkt-${var.project_nbr}"
  role = "roles/storage.admin"
  members = ["user:${var.mkt_username}@${var.org_id}"]

  depends_on = [google_storage_bucket.create_buckets]
}


# Grant require worker role
resource "google_project_iam_member" "service_account_worker_role" {
  project  = var.project_id
  role     = "roles/dataproc.worker"
  member   = "serviceAccount:${var.project_nbr}-compute@developer.gserviceaccount.com"

}

####################################################################################
# Create Dataproc Personal Use CLusters
####################################################################################
# Create the cluster

/*
resource "null_resource" "usa_dataproc_cluster" {
  provisioner "local-exec" {
    command = format("gcloud dataproc clusters create %s-jupyter-usav3 --bucket %s --region %s --no-address --zone %s-a  --subnet %s  --single-node --master-machine-type n1-standard-8 --master-boot-disk-size 1000  --image-version 2.0-debian10 --project %s --scopes=https://www.googleapis.com/auth/iam --shielded-secure-boot --shielded-integrity-monitoring --shielded-vtpm --enable-component-gateway  --properties dataproc:dataproc.personal-auth.user=\"%s\" --optional-components JUPYTER,ZEPPELIN --initialization-actions gs://goog-dataproc-initialization-actions-%s/connectors/connectors.sh,gs://goog-dataproc-initialization-actions-%s/python/pip-install.sh --metadata spark-bigquery-connector-version=0.26.0,'PIP_PACKAGES=pandas prophet plotly'",
                     var.project_id,
                     local.bucket_nm,
                     var.location,
                     var.location,
                     local.subnet_nm,
                     var.project_id,
                     format("%s@%s", var.usa_username, var.org_id),
                     var.location,
                     var.location
                     )
  }

  depends_on = [
              google_compute_router_nat.nat-config,
              google_project_iam_member.service_account_worker_role
              ]
}
*/


resource "google_dataproc_cluster" "dataproc_clusters" {
  for_each = {
    "${var.aus_username}" : "aus",
    "${var.usa_username}" : "usa",
    "${var.mkt_username}" : "mkt",
  }
  name     = format("%s-dataproc-cluster", each.value)
  project  = var.project_id
  region   = var.location
  #graceful_decommission_timeout = "120s"
  cluster_config {
    staging_bucket = "dataproc-bucket-${each.value}-${var.project_nbr}"
    temp_bucket = local.dataproc_temp_bucket
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-8"
      disk_config {
        #boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = 1000
      }
    }
    
    preemptible_worker_config {
      num_instances = 0
    }
    endpoint_config {
        enable_http_port_access = "true"
    }
    # Override or set some custom properties
    software_config {
      image_version = "2.0-debian10"
      override_properties = {
        "dataproc:dataproc.personal-auth.user" = "${each.key}@${var.org_id}",
         "dataproc:dataproc.allow.zero.workers" = "true"
      }
      optional_components = [ "JUPYTER", "ZEPPELIN" ]
        
      
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${var.location}/connectors/connectors.sh"
      timeout_sec = 300
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${var.location}/python/pip-install.sh"
      timeout_sec = 300
    }

    gce_cluster_config {
      zone        = "${var.location}-a"
      subnetwork  = google_compute_subnetwork.subnet.id
      #service_account_scopes = ["cloud-platform"]
      service_account_scopes = ["https://www.googleapis.com/auth/iam"]
      internal_ip_only = true
      shielded_instance_config {
        enable_secure_boot          = true
        enable_vtpm                 = true
        enable_integrity_monitoring = true
        }
     metadata = {
        "spark-bigquery-connector-version" : "0.26.0",
        "PIP_PACKAGES" : "pandas prophet plotly"
        }   
    }
  }
  depends_on = [
              google_storage_bucket.create_buckets,
              google_compute_router_nat.nat-config,
              google_project_iam_member.service_account_worker_role
  ]  
}

#copy notebooks to location where jupyter expects them.
resource "google_storage_bucket_object" "gcs_objects_aus_dataproc" {
  for_each = {
    "./resources/IceCream.ipynb" : "notebooks/jupyter/IceCream.ipynb",
    "./resources/ReadData.ipynb" : "notebooks/jupyter/ReadData.ipynb"
  }
  name        = each.value
  source      = each.key
  bucket      = "dataproc-bucket-aus-${var.project_nbr}"
  depends_on = [google_dataproc_cluster.dataproc_clusters]
}

resource "google_storage_bucket_object" "gcs_objects_usa_dataproc" {
  for_each = {
    "./resources/IceCream.ipynb" : "notebooks/jupyter/IceCream.ipynb",
    "./resources/ReadData.ipynb" : "notebooks/jupyter/ReadData.ipynb"
  }
  name        = each.value
  source      = each.key
  bucket      = "dataproc-bucket-usa-${var.project_nbr}"
  depends_on = [google_dataproc_cluster.dataproc_clusters]
}

resource "google_storage_bucket_object" "gcs_objects_mkt_dataproc" {
  for_each = {
    "./resources/IceCream.ipynb" : "notebooks/jupyter/IceCream.ipynb",
    "./resources/ReadData.ipynb" : "notebooks/jupyter/ReadData.ipynb"
  }
  name        = each.value
  source      = each.key
  bucket      = "dataproc-bucket-mkt-${var.project_nbr}"
  depends_on = [google_dataproc_cluster.dataproc_clusters]
}

####################################################################################
# Create Taxonomy and Policy
####################################################################################

resource "google_data_catalog_taxonomy" "business_critical_taxonomy" {
  project  = var.project_id
  region   = var.location
  # Must be unique accross your Org
  display_name           = "Business-Critical-${var.project_nbr}"
  description            = "A collection of policy tags"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "financial_data_policy_tag" {
  taxonomy     = google_data_catalog_taxonomy.business_critical_taxonomy.id
  display_name = "Financial Data"
  description  = "A policy tag normally associated with low security items"

  depends_on = [
    google_data_catalog_taxonomy.business_critical_taxonomy,
  ]
}

resource "google_data_catalog_policy_tag_iam_member" "member" {
  for_each = {
    #making this user so that user_mkt doesn't get included
    #"group:us-sales@${var.org_id}" : "",
    #"group:australia-sales@${var.org_id}" : ""
    "user:${var.aus_username}@${var.org_id}" : "",
    "user:${var.usa_username}@${var.org_id}" : ""

  }
  policy_tag = google_data_catalog_policy_tag.financial_data_policy_tag.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = each.key
  depends_on = [
    google_data_catalog_policy_tag.financial_data_policy_tag,
  ]
}

####################################################################################
# Create Bigqyery Dataset and Table and Row Access Policy
####################################################################################

resource "google_bigquery_dataset" "bigquery_dataset" {
  dataset_id                  = local.dataset_name
  friendly_name               = local.dataset_name
  description                 = "Dataset for BigLake Demo"
  location                    = var.location
  delete_contents_on_destroy  = true

  depends_on = [google_storage_bucket_object.gcs_objects]
}

 resource "google_bigquery_connection" "connection" {
    connection_id = local.bq_connection
    project = var.project_id
    location = var.location
    cloud_resource {}
    depends_on = [google_bigquery_dataset.bigquery_dataset]
} 

resource "google_project_iam_member" "connectionPermissionGrant" {
    project = var.project_id
    role = "roles/storage.objectViewer"
    member = format("serviceAccount:%s", google_bigquery_connection.connection.cloud_resource[0].service_account_id)
}    

resource "google_bigquery_table" "biglakeTable" {
    ## If you are using schema autodetect, uncomment the following to
    ## set up a dependency on the prior delay.
    # depends_on = [time_sleep.wait_7_min]
    dataset_id = google_bigquery_dataset.bigquery_dataset.dataset_id
    table_id   = "IceCreamSales"
    project = var.project_id
    schema = <<EOF
    [
            {
                "name": "country",
                "type": "STRING"
            },
            {
                "name": "month",
                "type": "DATE"
                },
            {
                "name": "Gross_Revenue",
                "type": "FLOAT"
            },
            {
                "name": "Discount",
                "type": "FLOAT",
                "policyTags": {
                  "names": [
                    "${google_data_catalog_policy_tag.financial_data_policy_tag.id}"
                    ]
                }
            },
            {
                "name": "Net_Revenue",
                "type": "FLOAT",
                "policyTags": {
                  "names": [
                    "${google_data_catalog_policy_tag.financial_data_policy_tag.id}"
                    ]
                }
            }
    ]
    EOF
    external_data_configuration {
        ## Autodetect determines whether schema autodetect is active or inactive.
        autodetect = false
        source_format = "CSV"
        connection_id = google_bigquery_connection.connection.name

        csv_options {
            quote                 = "\""
            field_delimiter       = ","
            allow_quoted_newlines = "false"
            allow_jagged_rows     = "false"
            skip_leading_rows     = 1
        }

        source_uris = [
            "gs://dataproc-bucket-aus-${var.project_nbr}/data/IceCreamSales.csv",
        ]
    }
    deletion_protection = false
    depends_on = [
              google_bigquery_connection.connection,
              google_storage_bucket_object.gcs_objects,
              google_data_catalog_policy_tag_iam_member.member
              ]
}

resource "null_resource" "create_aus_filter" {
  provisioner "local-exec" {
    command = <<-EOT
      read -r -d '' QUERY << EOQ
      CREATE ROW ACCESS POLICY
        Australia_filter
        ON
        ${local.dataset_name}.IceCreamSales
        GRANT TO
        ("group:australia-sales@${var.org_id}")
        FILTER USING
        (Country="Australia")
      EOQ
      bq query --nouse_legacy_sql $QUERY
    EOT
  }

  depends_on = [google_bigquery_table.biglakeTable]
}

resource "null_resource" "create_us_filter" {
  provisioner "local-exec" {
    command = <<-EOT
      read -r -d '' QUERY << EOQ
      CREATE ROW ACCESS POLICY
        US_filter
        ON
        ${local.dataset_name}.IceCreamSales
        GRANT TO
        ("group:us-sales@${var.org_id}")
        FILTER USING
        (Country="United States")
      EOQ
      bq query --nouse_legacy_sql $QUERY
    EOT
  }

  depends_on = [null_resource.create_aus_filter]
}



