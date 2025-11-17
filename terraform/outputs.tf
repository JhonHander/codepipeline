output "alb_staging_dns_name" {
  description = "DNS name of the staging load balancer"
  value       = aws_lb.staging.dns_name
}

output "alb_production_dns_name" {
  description = "DNS name of the production load balancer"
  value       = aws_lb.production.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_staging_name" {
  description = "ECS staging service name"
  value       = aws_ecs_service.staging.name
}

output "ecs_service_production_name" {
  description = "ECS production service name"
  value       = aws_ecs_service.production.name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.app.name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for manual approvals"
  value       = aws_sns_topic.pipeline_approvals.arn
}
