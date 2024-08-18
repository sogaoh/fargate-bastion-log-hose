module "ecs_task_exec_role" {
  source = "../../../../../tf-modules/ecs-task-exec"

  ecs_task_exec_role_name = "bastion-ecs-task-exec-role"
}
