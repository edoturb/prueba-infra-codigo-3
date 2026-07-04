# Configuración del Proveedor AWS Academy
provider "aws" {
  region = "us-east-1"
}

# Configuración de Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Módulo de Red (Base de la infraestructura usada en la prueba)
module "network" {
  source = "./modules/network" # O la ruta/repositorio que usó el Grupo 5

  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
}

# Recurso de Seguridad gestionado en el Escenario 3
resource "aws_security_group" "sg_web" {
  name        = "sg_web"
  description = "Security Group para Servidor Web"
  vpc_id      = "vpc-0e74ea0052495acba"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
