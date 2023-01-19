
// #GCS bucket
// resource "google_storage_bucket" "gcs" {
//  name="pcibktcentene"
//  project= "pcialyana"
//  location = "us-central1"
//  storage_class = "STANDARD"
//  uniform_bucket_level_access = true
//  public_access_prevention = "enforced"
// }
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
//    google_storage_bucket.gcs
//   ]
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

// # cloud_function to capture the response
// resource "google_cloudfunctions_function" "getcomposerbkt" {
//   name     = "getcomposerbkt"
//   service_account_email ="terraformsa@pcialyana.iam.gserviceaccount.com"
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
//     "serviceAccount:terraformsa@pcialyana.iam.gserviceaccount.com",
//     "user:Alyana.Vandana@brillio.com"
    
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

// #creating a cloudbuild trigger
// resource "google_cloudbuild_trigger" "copy-repo-to-gcs1" {
//   location = "global"
//   name ="trigger6779"
//   trigger_template {
//     branch_name = "main"
//     repo_name   = "github_alyana-vandana_git-repo"
//   }

//   build {
//     step {
//       name = "gcr.io/cloud-builders/gsutil"
//       // args = ["cp", "-r", ".", "gs://${data.http.function_response.body}"]
//       args = ["-m", "cp", "-r", ".", "gs://us-central1*"]

    
//     }
//   }
//   depends_on = [
//    data.http.function_response
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


// resource "google_project_iam_member" "project_iam_admin" {
//   project ="dogwood-canto-375110"
//   role = "roles/resourcemanager.projectIamAdmin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }


#enabling API'S
variable "services" {
  type = list(string)
  default = ["storage.googleapis.com", "datastore.googleapis.com"]
}

resource "google_project_service" "multiple_services" {
  count = length(var.services)
  service = element(var.services, count.index)
}

// resource "google_project_iam_member" "storage_admin" {
//   project ="dogwood-canto-375110"
//   role = "roles/storage.admin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }

// resource "google_project_iam_member" "composer_admin" {
//   project = "dogwood-canto-375110"
//   role = "roles/composer.admin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }

// resource "google_project_iam_member" "bigquery_admin" {
//   project ="dogwood-canto-375110"
//   role = "roles/bigquery.admin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }

// resource "google_project_iam_member" "cloud_build_admin" {
//   project = "dogwood-canto-375110"
//   role = "roles/cloudbuild.admin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }

// resource "google_project_iam_member" "cloud_dataproc_admin" {
//   project = "dogwood-canto-375110"
//   role = "roles/dataproc.admin"
//   member = "serviceAccount:terraformcicd@dogwood-canto-375110.iam.gserviceaccount.com"
// }





#GCS bucket
resource "google_storage_bucket" "gcs" {
 name="pcibkt"
 project= "dogwood-canto-375110"
 location = "us-central1"
 storage_class = "STANDARD"
 uniform_bucket_level_access = true
 public_access_prevention = "enforced"

}

// #cloudbuild to cp the code from github to gcs
// resource "google_cloudbuild_trigger" "copy-repo-to-gcs" {
//   location = "global"
//   name ="triggerCF"
//   trigger_template {
//     branch_name = "main"
//     repo_name   = "github_alyana-vandana_git-repo"
//   }

//   build {
//     step {
//       name = "gcr.io/cloud-builders/gsutil"
//       args = ["cp", "-r", ".", "gs://pcibkt"]  
//     }
//   }
//   depends_on = [
//    google_storage_bucket.gcs
//   ]
// }

#creating composer environment
resource "google_composer_environment" "composerenv" {
name = "mycomposer"
project= "dogwood-canto-375110"
region = "us-central1"
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


// # cloud_function to capture the response
// resource "google_cloudfunctions_function" "getcomposerbkt" {
//   name     = "getcomposerbkt"
//   service_account_email ="terraformsa@pcialyana.iam.gserviceaccount.com"
//   region   = "us-central1"
//   runtime  = "python38"
//   source_archive_bucket = "pcibkt"
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
//     "serviceAccount:terraformsa@pcialyana.iam.gserviceaccount.com",
//     "user:Alyana.Vandana@brillio.com"
    
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
      // args = ["cp", "-r", ".", "gs://${data.http.function_response.body}"]
      args = ["-m", "cp", "-r", ".", "gs://us-central1*"]

    
    }
  }

}

#bigquery 
resource "google_bigquery_dataset" "gbq" {
  dataset_id  = "pci_dataset"
  project= "dogwood-canto-375110"
  friendly_name  = "dataset_for_centene"
  description = "This dataset is public"
  location  = "US"

  
}

resource "google_bigquery_dataset" "gbqfinal" {
  dataset_id  = "centene_final"
  project= "dogwood-canto-375110"
  friendly_name  = "final_dataset"
  description = "This dataset is public"
  location  = "US"
 
}









