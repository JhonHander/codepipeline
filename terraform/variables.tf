variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "codepipe"
}

variable "github_connection_arn" {
  description = "ARN of the GitHub connection in CodeStar Connections"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo (e.g., JhonHander/codepipe)"
  type        = string
}

variable "github_branch" {
  description = "Branch to track"
  type        = string
  default     = "main"
}
