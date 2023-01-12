
// //-------newcode------------


// #GCS bucket
// resource "google_storage_bucket" "gcs" {
//  name="pcibktcentene"
//  project= "pcialyana"
//  location = "us-central1"
//  storage_class = "STANDARD"
//  uniform_bucket_level_access = true
//  public_access_prevention = "enforced"
// }

// #creating a cloudbuild trigger
// resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
//   location = "global"
//   name ="trigger6778"
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
//   depends_on = [
//     google_storage_bucket.gcs
//   ]
// }

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
// depends_on = [
//   google_cloudbuild_trigger.copy-repo-to-gcs
// ]
// }


// # cloud_function to capture the response
// resource "google_cloudfunctions_function" "getcomposerbkt" {
//   name     = "getcomposerbkt"
//   region   = "us-central1"
//   runtime  = "python38"
//   source_archive_bucket = "pcibktcentene"
//   source_archive_object = "function-source (1).zip"
//   entry_point = "hello_world"
//   https_trigger_url = "https://us-central1-pcialyana.cloudfunctions.net/getcomposerbkt"
//   trigger_http =true

//   depends_on = [
//     # google_cloudbuild_trigger.copy-repo-to-gcs
//     google_composer_environment.composerenv
//   ]

// }
// resource "google_cloudfunctions_function_iam_binding" "invoker" {
//   cloud_function = google_cloudfunctions_function.getcomposerbkt.name
//   region = google_cloudfunctions_function.getcomposerbkt.region
//   role = "roles/cloudfunctions.invoker"
//   members = [
//     "allUsers",
//   ]
// }

// data "http" "function_response" {
//   url = google_cloudfunctions_function.getcomposerbkt.https_trigger_url
//   depends_on = [
//     google_cloudfunctions_function.getcomposerbkt
//   ]
// }

// output "function_output" {
// value = substr(data.http.function_response.body, 0, -1)
// }

// # resource "google_storage_bucket_object" "object" {
// #     bucket = "${data.http.function_response.body}"
// #     name   = "main.tf"
// #     source = "main.tf"
// #     depends_on = [
// #         data.http.function_response
// #         ]
// # }


// // provider "google" {
// //   credentials = file("/home/vandana_alyana/cfdemotrail/pcialyana-450155134070.json")
// //   project     = "pcialyana"
// //   region      = "US"
// // }

// resource "google_storage_transfer_job" "transfer_job2" {
//   description = "Transfer job to copy object from source bucket to destination bucket"
//   project     = "pcialyana"

//   transfer_spec {
//     gcs_data_source {
//       bucket_name = "pcibktcentene"
//       }
//     gcs_data_sink {
//       bucket_name = "${data.http.function_response.body}"
      
//     }
  
//     object_conditions {
//       include_prefixes = ["dags/Centene1.py"]
//     }
//   }
//   depends_on = [
//     data.http.function_response
//   ]
//   }

// # #creating cluster(for ratefiles)
// # resource "google_dataproc_cluster" "centeneCluster" {
// #   name   = "mycluster"
// #  region = "us-central1"
// # }

#GCS bucket
resource "google_storage_bucket" "gcs" {
 name="pcibktcentene"
 project= "pcialyana"
 location = "us-central1"
 storage_class = "STANDARD"
 uniform_bucket_level_access = true
 public_access_prevention = "enforced"
}
resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
  location = "global"
  name ="trigger6778"
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
  depends_on = [
   google_storage_bucket.gcs
  ]
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

# cloud_function to capture the response
resource "google_cloudfunctions_function" "getcomposerbkt" {
  name     = "getcomposerbkt"
  service_account_email ="terraformsa@pcialyana.iam.gserviceaccount.com"
  region   = "us-central1"
  runtime  = "python38"
  source_archive_bucket = "pcibktcentene"
  source_archive_object = "function-source (1).zip"
  entry_point = "hello_world"
  https_trigger_url = "https://us-central1-pcialyana.cloudfunctions.net/getcomposerbkt"
  trigger_http =true

  depends_on = [
    # google_cloudbuild_trigger.copy-repo-to-gcs
    google_composer_environment.composerenv
  ]

}
resource "google_cloudfunctions_function_iam_binding" "invoker" {
  cloud_function = google_cloudfunctions_function.getcomposerbkt.name
  region = google_cloudfunctions_function.getcomposerbkt.region
  role = "roles/cloudfunctions.invoker"
  members = [
    "allUsers",
    "serviceAccount:terraformsa@pcialyana.iam.gserviceaccount.com",
    "Alyana.Vandana@brillio.com"
    
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

#creating a cloudbuild trigger
resource "google_cloudbuild_trigger" "copy-repo-to-gcs1" {
  location = "global"
  name ="trigger6779"
  trigger_template {
    branch_name = "main"
    repo_name   = "github_alyana-vandana_git-repo"
  }

  build {
    step {
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "-r", ".", "gs://${data.http.function_response.body}"]
    }
  }
  depends_on = [
   data.http.function_response
  ]
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





