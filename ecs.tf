resource "aws_ecs_cluster" "default" {
  name = "ecs-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = "task"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name = "cws-instrumentation-init"
      image = "datadog/cws-instrumentation:latest"
      essential = false
      user = "0"
      command = [
        "/cws-instrumentation",
        "setup",
        "--cws-volume-mount",
        "/cws-instrumentation-volume"
      ]
      mountPoints = [
        {
          sourceVolume = "cws-instrumentation-volume"
          containerPath = "/cws-instrumentation-volume"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "cws-init"
        }
      }
    },
    {
      name = "datadog-agent"
      image = "datadog/agent:latest"
      essential = true
      environment = [
        {
          name = "DD_API_KEY"
          value = var.datadog_api_key
        },
        {
          name = "DD_SITE"
          value = "us5.datadoghq.com"
        },
        {
          name = "ECS_FARGATE"
          value = "true"
        },
        {
          name = "DD_RUNTIME_SECURITY_CONFIG_ENABLED"
          value = "true"
        },
        {
          name = "DD_RUNTIME_SECURITY_CONFIG_EBPFLESS_ENABLED"
          value = "true"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "/probe.sh"
        ]
        interval = 30
        timeout = 5
        retries = 2
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "datadog-agent"
        }
      }
    },
    {
      name = "${var.project_name}-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ],
      entry_point = [
        "/cws-instrumentation-volume/cws-instrumentation",
        "trace",
        "--",
        ["nginx","-g","daemon off;"]
      ]
      mountPoints = [
        {
          sourceVolume = "cws-instrumentation-volume"
          containerPath = "/cws-instrumentation-volume"
          readOnly = true
        }
      ]
      linux_parameters = {
        capabilities = {
          add = ["SYS_PTRACE"]
        }
      }
      dependsOn = [
        {
          containerName = "datadog-agent"
          condition = "HEALTHY"
        },
        {
          containerName = "cws-instrumentation-init"
          condition = "SUCCESS"
        }
      ]
    }
  ])
  volume {
    name = "cws-instrumentation-volume"
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.default.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [data.aws_subnets.existing.ids[0], data.aws_subnets.existing.ids[1]]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = 80
  }
  depends_on = [
    aws_lb_listener.http,
    aws_ecs_cluster.default,
    aws_ecs_task_definition.app_task,
    aws_iam_role_policy_attachment.attach_task_policy_to_role,
    aws_iam_role_policy_attachment.attach_execution_policy_to_role,
    aws_security_group.ecs_tasks
  ]
}
