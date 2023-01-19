
#variables


variable "project_name" {
  type = string
  default = "dogwood-canto-375110"
}

variable "location" {
  type = string
  default = "us-central1"
}

variable "bucket_name" {
  type= string
  default = "pcistagging"
  
}

variable "bigquery_name_stagging" {
  type= string
  default= "Staingdataset"
}

variable "bigquery_name_final" {
  type= string
  default= "finaldataset"
}


#enabling API'S
variable "services" {
  type = list(string)
  default = ["storage.googleapis.com", "datastore.googleapis.com","composer.googleapis.com","bigquery.googleapis.com"]
}

resource "google_project_service" "multiple_services" {
  count = length(var.services)
  service = element(var.services, count.index)
}

#GCS bucket
resource "google_storage_bucket" "gcs" {
 name="${var.bucket_name}"
 project= "${var.project_name}"
 location = "${var.location}"
 storage_class = "STANDARD"
 uniform_bucket_level_access = true
 public_access_prevention = "enforced"

}



#creating composer environment
resource "google_composer_environment" "composerenv" {
name = "mycomposer"
project= "${var.project_name}"
region ="${var.location}"
config {
node_config {
service_account = "terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
}
software_config {
    # image_version = "composer-1.19.15-airflow-1.10.15"
    image_version = "composer-1.19.15-airflow-2.3.4"

    airflow_config_overrides = {
        
        core-dagbag_import_timeout = "500"
        core-dag_file_processor_timeout = "500"
        logging-logging_level ="DEBUG"
        email-email_backend="airflow.utils.email.send_email_smtp"

      }
   }

   }
 

}



#creating a cloudbuild trigger
resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
  location = "global"
  name ="trigger"
  trigger_template {
    branch_name = "main"
    repo_name   = "github_alyana-vandana_git-repo"
  }

  build {
    step {
      name = "gcr.io/cloud-builders/gsutil"
      // args = ["cp", "-r", ".", "gs://${data.http.function_response.body}"]
      args = ["-m", "cp", "-r", ".", "gs://us-central1*"]

    
    }
  }

}

#bigquery 
resource "google_bigquery_dataset" "gbq" {
  dataset_id  = "pci_dataset"
   project= "${var.project_name}"
 location = "${var.location}"
  friendly_name  = "dataset_for_centene"
  description = "This dataset is public"
 

  
}

resource "google_bigquery_dataset" "gbqfinal" {
   dataset_id  = "centene_final"
   project= "${var.project_name}"
   location = "${var.location}"
   friendly_name  = "final_dataset"
   description = "This dataset is public"
  
 
}









