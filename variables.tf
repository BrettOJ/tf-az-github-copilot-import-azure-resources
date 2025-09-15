variable "resource_group" { 
    type = string 
    description = "Name of the resource group"
}
variable "name_prefix"    { 
    type = string
     default = "" 
     description = "Prefix for resource names"
}
variable "location_fallback" { 
    type = string 
    default = null
    description = "Fallback location if not resolvable from ARM"
}
