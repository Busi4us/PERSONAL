

variable "public_cidrs" {
    type = list
    description = "Public subnet cidrs"
    default = ["10.0.1.0/24", "10.0.3.0/24"]
}


