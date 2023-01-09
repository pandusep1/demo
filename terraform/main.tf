

// variable "github_token" {
//   default = "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"
// }
// provider "github" {
//   token = var.github_token
// }

// #GCS bucket
// resource "google_storage_bucket" "gcs" {
//  name="pcibktcentene"
//  project= "pcialyana"
//  location = "us-central1"
//  storage_class = "STANDARD"
// }
// //  gitcloudbuild
// resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
//   location = "global"

//   trigger_template {
//     branch_name = "main"
//     repo_name   = "github_alyana-vandana_git-repo"
//   }

//   build {
//     step {
//       name = "gcr.io/cloud-builders/gsutil"
//       args = ["cp", "-r", ".", "gs://pcibktcentene"]
//     }
//   }
// }


// // #clone github to bucket
// // resource "null_resource" "clone_repo" {
// //     provisioner "local-exec" {
// //     command = "git clone https://${var.github_token}:x-oauth-basic@github.com/Alyana-Vandana/git-repo /home/vandana_alyana/demo1/dags"
// // }
// // }

// // # Use the gsutil tool to copy the files from the local directory to your bucket
// // resource "null_resource" "copy_to_bucket" {
// //   provisioner "local-exec" {
// //     # command = "gsutil cp -r /home/vandana_alyana/Iac/git gs://pcibktcentene"
// //    command = "gsutil cp -r /home/vandana_alyana/demo1/dags gs://${google_storage_bucket.gcs.name} "

// //   }
 
// // }

// // resource "null_resource" "clone_repo" {

// //   provisioner "local-exec" {

// //     command = " git clone https://Alyana-Vandana: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@github.com/Alyana-Vandana/git-repo.git/Centene1.py | gsutil cp - gs://pcibktcentene/Centene1.py"

// //   }
// // provisioner "local-exec" {

// //     command = " git clone https://Alyana-Vandana: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@github.com/Alyana-Vandana/git-repo.git/centeneScriptForRate.py | gsutil cp - gs://pcibktcentene/centeneScriptForRate.py"

// //   }
// // }

// #bigquery 
// resource "google_bigquery_dataset" "gbq" {
//   dataset_id  = "pci_dataset"
//   project= "pcialyana"
//   friendly_name  = "dataset_for_centene"
//   description = "This dataset is public"
//   location  = "US"
// }

// resource "google_bigquery_dataset" "gbqfinal" {
//   dataset_id  = "centene_final"
//   project= "pcialyana"
//   friendly_name  = "final_dataset"
//   description = "This dataset is public"
//   location  = "US"
// }

// #creating composer environment
// resource "google_composer_environment" "composerenv" {
// name = "centenecomposer"
// region = "us-central1"
// config {
// node_config {
// service_account = "terraformsa@pcialyana.iam.gserviceaccount.com"
// }
// software_config {
//     # image_version = "composer-1.19.15-airflow-1.10.15"
//     image_version = "composer-1.19.15-airflow-2.3.4"

//     airflow_config_overrides = {
        
//         core-dagbag_import_timeout = "500"
//         core-dag_file_processor_timeout = "500"
//         logging-logging_level ="DEBUG"
//         email-email_backend="airflow.utils.email.send_email_smtp"

//       }
//    }

//    }

// }
// # #uploading object (scriptfile)
// # resource "google_storage_bucket_object" "scriptfile" {

// #     name="centeneScriptForRate.py"
// #     source = "centeneScriptForRate.py"
// #     bucket = "pcibktcentene"
// # }

// #uploading object (dagfile)
// # resource "google_storage_bucket_object" "dagfile" {

// #     name="dags/Centene1.py"
// #     source = "Centene1.py"
// #     # bucket = "us-central1-centenecomposer-b5adfee2-bucket"
    
// #     bucket = "us-central1-centenecomposer-87fdcd84-bucket"
// # }
// // provider "google" {
// //   credentials = file("/home/vandana_alyana/terra/pcigcp-369509-7a5ff0f4d91c.json")
// //   project     = "pcigcp-369509"
// //   region      = "US"
// // }

// // provider "google" {
// //   credentials = file("$(System.ArtifactsDirectory)/terraform/pcigcp-369509-fcc6ace87823.json")
// //   project     = "pcigcp-369509"
// //   region      = "US"
// // }


// resource "google_storage_transfer_job" "transfer_job1" {
//   description = "Transfer job to copy object from source bucket to destination bucket"
//   project     = "pcialyana"

//   transfer_spec {
//     gcs_data_source {
//       bucket_name = "pcibktcentene"
//       }
//     gcs_data_sink {
//       bucket_name = "us-central1-centenecomposer-8f649370-bucket"
      
//     }
 
//     object_conditions {
//         include_prefixes = ["dags/Centene1.py"]
//         # object_prefix = "us-central1-centenecomposer-87fdcd84-bucket/dags"
//       }
//   }
// }

  
    
// #  transfer_options {
// #     delete_objects_from_source_after_transfer = false
// #     delete_objects_unique_in_sink              = true
// #     overwrite_objects_unique_in_sink           = true
// #   }




// #creating cluster(for ratefiles)
// resource "google_dataproc_cluster" "centeneCluster" {
//   name   = "mycluster"
//  region = "us-central1"
// }

//-------newcode------------

variable "github_token" {
  default = "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"
}
provider "github" {
  token = var.github_token
}

#GCS bucket
resource "google_storage_bucket" "gcs" {
 name="pcibktcentene"
 project= "pcialyana"
 location = "us-central1"
 storage_class = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
}

resource "null_resource" "clone_repo" {
    provisioner "local-exec" {
        command = " git clone https://Alyana-Vandana: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@github.com/Alyana-Vandana/git-repo.git/Centene1.py | gsutil cp - gs://pcibktcentene/Centene1.py"
        }
}

#bigquery 
resource "google_bigquery_dataset" "gbq" {
  dataset_id  = "pci_dataset"
  project= "pcialyana"
  friendly_name  = "dataset_for_centene"
  description = "This dataset is public"
  location  = "US"
}

resource "google_bigquery_dataset" "gbqfinal" {
  dataset_id  = "centene_final"
  project= "pcialyana"
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
service_account = "terraformsa@pcialyana.iam.gserviceaccount.com"
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
resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
  location = "global"
  name ="trigger2"
  trigger_template {
    branch_name = "main"
    repo_name   = "github_alyana-vandana_git-repo"
  }

  build {
    step {
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "-r", ".", "gs://pcibktcentene"]
    }
  }
}

# cloud_function to capture the response
resource "google_cloudfunctions_function" "getcomposerbkt" {
  name     = "getcomposerbkt"
  region   = "us-central1"
  runtime  = "python38"
  source_archive_bucket = "pcibktcentene"
  source_archive_object = "function-source (1).zip"
  entry_point = "hello_world"
  https_trigger_url = "https://us-central1-pcialyana.cloudfunctions.net/getcomposerbkt"
  trigger_http =true

  depends_on = [
    google_cloudbuild_trigger.copy-repo-to-gcs
  ]
}
resource "google_cloudfunctions_function_iam_binding" "invoker" {
  cloud_function = google_cloudfunctions_function.getcomposerbkt.name
  region = google_cloudfunctions_function.getcomposerbkt.region
  role = "roles/cloudfunctions.invoker"
  members = [
    "allUsers",
  ]
}

data "http" "function_response" {
  url = google_cloudfunctions_function.getcomposerbkt.https_trigger_url
  depends_on = [
    google_cloudfunctions_function.getcomposerbkt
  ]
}

output "function_output" {
value = substr(data.http.function_response.body, 0, -1)
}

# resource "google_storage_bucket_object" "object" {
#     bucket = "${data.http.function_response.body}"
#     name   = "main.tf"
#     source = "main.tf"
#     depends_on = [
#         data.http.function_response
#         ]
# }


// provider "google" {
//   credentials = file("/home/vandana_alyana/cfdemotrail/pcialyana-450155134070.json")
//   project     = "pcialyana"
//   region      = "US"
// }

resource "google_storage_transfer_job" "transfer_job2" {
  description = "Transfer job to copy object from source bucket to destination bucket"
  project     = "pcialyana"

  transfer_spec {
    gcs_data_source {
      bucket_name = "pcibktcentene"
      }
    gcs_data_sink {
      bucket_name = "${data.http.function_response.body}"
      
    }
  
    object_conditions {
      include_prefixes = ["dags/Centene1.py"]
    }
  }
    # object_conditions {
    #     # include_prefixes = ["dags/Centene1.py"]
    #     include_prefixes = ["Centene1.py"]
    #     # object_prefix = "us-central1-centenecomposer-87fdcd84-bucket/dags"
    #   }
  }

# #creating cluster(for ratefiles)
# resource "google_dataproc_cluster" "centeneCluster" {
#   name   = "mycluster"
#  region = "us-central1"
# }

