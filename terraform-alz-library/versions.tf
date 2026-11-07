terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    alz = {
      source  = "Azure/alz"
      version = "~> 0.22"
    }
  }
}

provider "azapi" {}

# The custom library depends on platform/alz (see lib/alz_library_metadata.json), so no other library reference is needed
provider "alz" {
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}
