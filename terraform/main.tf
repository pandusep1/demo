

variable "github_token" {
  default = "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"
}
provider "github" {
  token = var.github_token
}

#GCS bucket
resource "google_storage_bucket" "gcs" {
 name="pcibktcentene"
 project= "pcigcp-369509"
 location = "us-central1"
 storage_class = "STANDARD"
}
// #clone github to bucket
// resource "null_resource" "clone_repo" {
//     provisioner "local-exec" {
//     command = "git clone https://${var.github_token}:x-oauth-basic@github.com/Alyana-Vandana/git-repo /home/vandana_alyana/demo1/dags"
// }
// }

// # Use the gsutil tool to copy the files from the local directory to your bucket
// resource "null_resource" "copy_to_bucket" {
//   provisioner "local-exec" {
//     # command = "gsutil cp -r /home/vandana_alyana/Iac/git gs://pcibktcentene"
//    command = "gsutil cp -r /home/vandana_alyana/demo1/dags gs://${google_storage_bucket.gcs.name} "

//   }
 
// }

resource "null_resource" "clone_repo" {

  provisioner "local-exec" {

    command = " git clone https://Alyana-Vandana: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@github.com/Alyana-Vandana/git-repo.git/Centene1.py | gsutil cp - gs://pcibktcentene/Centene1.py"

  }
provisioner "local-exec" {

    command = " git clone https://Alyana-Vandana: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@github.com/Alyana-Vandana/git-repo.git/centeneScriptForRate.py | gsutil cp - gs://pcibktcentene/centeneScriptForRate.py"

  }
}

#bigquery 
resource "google_bigquery_dataset" "gbq" {
  dataset_id  = "pci_dataset"
  project= "pcigcp-369509"
  friendly_name  = "dataset_for_centene"
  description = "This dataset is public"
  location  = "US"
}

resource "google_bigquery_dataset" "gbqfinal" {
  dataset_id  = "centene_final"
  project= "pcigcp-369509"
  friendly_name  = "final_dataset"
  description = "This dataset is public"
  location  = "US"
}

#creating composer environment
resource "google_composer_environment" "composerenv" {
name = "centenecomposer"
region = "us-central1"
config {
node_config {
service_account = "terraform-serviceac@pcigcp-369509.iam.gserviceaccount.com"
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
# #uploading object (scriptfile)
# resource "google_storage_bucket_object" "scriptfile" {

#     name="centeneScriptForRate.py"
#     source = "centeneScriptForRate.py"
#     bucket = "pcibktcentene"
# }

#uploading object (dagfile)
# resource "google_storage_bucket_object" "dagfile" {

#     name="dags/Centene1.py"
#     source = "Centene1.py"
#     # bucket = "us-central1-centenecomposer-b5adfee2-bucket"
    
#     bucket = "us-central1-centenecomposer-87fdcd84-bucket"
# }
// provider "google" {
//   credentials = file("/home/vandana_alyana/terra/pcigcp-369509-7a5ff0f4d91c.json")
//   project     = "pcigcp-369509"
//   region      = "US"
// }

// provider "google" {
//   credentials = file("$(System.ArtifactsDirectory)/terraform/pcigcp-369509-fcc6ace87823.json")
//   project     = "pcigcp-369509"
//   region      = "US"
// }


resource "google_storage_transfer_job" "transfer_job1" {
  description = "Transfer job to copy object from source bucket to destination bucket"
  project     = "pcigcp-369509"

  transfer_spec {
    gcs_data_source {
      bucket_name = "pcibktcentene"
      }
    gcs_data_sink {
      bucket_name = "us-central1-centenecomposer-d8049280-bucket"
      
    }
 
    object_conditions {
        include_prefixes = ["dags/Centene1.py"]
        # object_prefix = "us-central1-centenecomposer-87fdcd84-bucket/dags"
      }
  }
}

  
    
#  transfer_options {
#     delete_objects_from_source_after_transfer = false
#     delete_objects_unique_in_sink              = true
#     overwrite_objects_unique_in_sink           = true
#   }




#creating cluster(for ratefiles)
resource "google_dataproc_cluster" "centeneCluster" {
  name   = "mycluster"
 region = "us-central1"
}
