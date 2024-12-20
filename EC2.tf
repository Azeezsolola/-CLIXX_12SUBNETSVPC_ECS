locals {
  env = var.environment
  account_to_deploy = var.ACCOUNTS[local.env]
  account_arn = "arn:aws:iam::${local.account_to_deploy}:role/Engineer"
}


#-------------------------------Creating VPC------------------------------------------------------------
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

   tags = {
    Name = "MYSTACKVPC"
  }
}


#-------------------------------Creating private subnet to host clixx  -------------------------------------

resource "aws_subnet" "privatesubnetclixx1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatesubnet-clixx"
  }
}



#-----------------------------Creating private subnet2 to host clixx --------------------------------------

resource "aws_subnet" "privatesubnetclixx2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatesubnet-clixx2"
  }
}


#------------------------------Creating public subnet for load balancer ------------------------------------

resource "aws_subnet" "publicsubnet1loadbalancer" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/23"
  availability_zone = "us-east-1a"
  tags = {
    Name = "publicsubnet_loadbalancer1"
  }
}




#-----------------------------Creating public subnet 2 for load Balancer ------------------------------------

resource "aws_subnet" "publicsubnet2loadbalancer" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.4.0/23"
  availability_zone = "us-east-1b"
  tags = {
    Name = "publicsubnet_loadbalancer2"
  }
}



#----------------------------Creating private subnet for RDS Database ----------------------------------------
resource "aws_subnet" "privatesubnetrds1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.8.0/22"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privateclixx_rds1"
  }
}

#---------------------------Creating privatesubnet 2 for rds database ----------------------------------------
resource "aws_subnet" "privatesubnetrds2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.16.0/22"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privateclixx_rds2"
  }
}


#------------------------------Creating private subnet for oracle database 1 -------------------------------
resource "aws_subnet" "privatesubnetoracleDB1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privateoracle_db1"
  }
}


#--------------------------Creating private subnet for oracle database 2--------------------------------------
resource "aws_subnet" "privatesubnetoracleDB2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privateoracle_db2"
  }
}


#-----------------------------creating private subnet for java application databse 1 ----------------------------------
resource "aws_subnet" "privatesubnetjavaDB1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.22.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatejava_rds1"
  }
}


#-----------------------------Creating private subnet for java applaication database 2---------------------------------
resource "aws_subnet" "privatesubnetjavaDB2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.23.0/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatejava_rds2"
  }
}


#----------------------------Creating private subnet for java server 1------------------------------------------------
resource "aws_subnet" "privatesubnetjavaserver1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.24.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatjavaserver1"
  }
}

#---------------------------Creating private subnet for java server 2----------------------------------------------
resource "aws_subnet" "privatesubnetjavaserver2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.25.0/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatjavaserver2"
  }
}

#---------------------------Creating internet gateway -----------------------------------------------------------
resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet_gatewayclixx"
  }
}


#------------------------- Fetching Elastic IP information to attach to NAT GATEWAY -----------------------------------------
data "aws_eips" "example" {
  filter {
    name   = "tag:Name"
    values = ["STACKEIP-CLIXX"]
  }
}



output "EIP" {
  value = data.aws_eips.example.allocation_ids
}


#-------------------------Creating NAT GATEWAY in public subnet ---------------------------------------------------------
resource "aws_nat_gateway" "NATGATE" {
  allocation_id = data.aws_eips.example.allocation_ids[0]
  subnet_id     = aws_subnet.publicsubnet1loadbalancer.id

  tags = {
    Name = "STACKNATGATEWAY"
  }
  depends_on = [aws_internet_gateway.internetgateway]
}



#----------------------------Creating route table for public subnets ----------------------------------------------
resource "aws_route_table" "pubroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgateway.id
  }

 

  tags = {
    Name = "Publicroutetable"
  }
}

output "routetab" {
  value = aws_route_table.pubroutetable.id
}


#-------------------------------Creating private route table for private subnets --------------------------------
resource "aws_route_table" "privroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGATE.id
  }

  tags = {
    Name = "Privateroutetable"
  }
}

#-------------------------------Associating Public route table to public subnet1-----------------------------------

resource "aws_route_table_association" "ass1" {
  subnet_id      = aws_subnet.publicsubnet1loadbalancer.id
  route_table_id = aws_route_table.pubroutetable.id
}

#------------------------------Associating Public route table to public subnet 2 ------------------------------------
resource "aws_route_table_association" "ass2" {
  subnet_id      = aws_subnet.publicsubnet2loadbalancer.id
  route_table_id = aws_route_table.pubroutetable.id
}

#------------------------------Associating Private route table to private subnet 1-----------------------------
resource "aws_route_table_association" "ass3" {
  subnet_id      = aws_subnet.privatesubnetclixx1.id
  route_table_id = aws_route_table.privroutetable.id
}

#------------------------------Associating Private route table to private subnet 2-----------------------------
resource "aws_route_table_association" "ass4" {
  subnet_id      = aws_subnet.privatesubnetclixx2.id
  route_table_id = aws_route_table.privroutetable.id
}

#------------------------------Associating Private route table to private subnet 3-----------------------------
resource "aws_route_table_association" "ass5" {
  subnet_id      = aws_subnet.privatesubnetrds1.id
  route_table_id = aws_route_table.privroutetable.id
}


#------------------------------Associating Private route table to private subnet 4-----------------------------
resource "aws_route_table_association" "ass6" {
  subnet_id      = aws_subnet.privatesubnetrds2.id
  route_table_id = aws_route_table.privroutetable.id
}


#----------------------------Associating Private route tabel to private subnet 5---------------------------
resource "aws_route_table_association" "ass7" {
  subnet_id      = aws_subnet.privatesubnetoracleDB1.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 6---------------------------
resource "aws_route_table_association" "ass8" {
  subnet_id      = aws_subnet.privatesubnetoracleDB2.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 6---------------------------
resource "aws_route_table_association" "ass9" {
  subnet_id      = aws_subnet.privatesubnetjavaDB1.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 7------------------------
resource "aws_route_table_association" "ass10" {
  subnet_id      = aws_subnet.privatesubnetjavaDB2.id
  route_table_id = aws_route_table.privroutetable.id
}

#---------------------------Associating Private route table to private subnet 8---------------------------
resource "aws_route_table_association" "ass11" {
  subnet_id      = aws_subnet.privatesubnetjavaserver1.id
  route_table_id = aws_route_table.privroutetable.id
}

#---------------------------Associating Private route table to private subnet 9---------------------------
resource "aws_route_table_association" "ass12" {
  subnet_id      = aws_subnet.privatesubnetjavaserver2.id
  route_table_id = aws_route_table.privroutetable.id
}


#--------------------------Creating security group for load Balancer -------------------------------------
resource "aws_security_group" "loadBalancer-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "loadbalancer_Securitygroup"
  description = "Load balancer Security Group"
}

output "loadbalancerid" {
  value = aws_security_group.loadBalancer-sg.id
}


#----------------------------Creating Security group for RDS AND EFS -----------------------------------
resource "aws_security_group" "RDSEFS-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "RDS-AND-EFS_Securitygroup"
  description = "RDS and EFS Security Group"
}

output "RDSEFSid" {
  value = aws_security_group.RDSEFS-sg.id
}

#------Adding rules to the rds datatbase SG-----------------------------------------------------------------

resource "aws_security_group_rule" "msqlrds1" {
  security_group_id        = aws_security_group.RDSEFS-sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.clixxapp-sg.id
}

#------------------------Adding Rules to Load Balancer Security Group -------------------------------------
resource "aws_security_group_rule" "httpslb" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "ecs_agent_ingress" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 32768
  to_port           = 65535
  cidr_blocks       = ["10.0.0.0/16"] # Adjust to your VPC CIDR
}


#-----------------------------------Creating Security Group for CliXX Application server-----------------------
resource "aws_security_group" "clixxapp-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "clixxapplication_Securitygroup"
  description = "Clixx Instance security group"
}

output "CLIXXSGid" {
  value = aws_security_group.clixxapp-sg.id
}

#-----------------------------Adding ZRules to the Clixx Server security group------------------------------------

resource "aws_security_group_rule" "http1" {
  security_group_id        = aws_security_group.clixxapp-sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.loadBalancer-sg.id
}



#--------------------------Creating Target Group ------------------------------------------
resource "aws_lb_target_group" "instance_target_group" {
  name     = "newclixx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id 

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 120
    interval            = 300
    path                = "/" 
    protocol            = "HTTP"
  }

  tags = {
    Environment = "Development"
  }
}




#--------------------------Creating Load balancer -------------------------------------------------
resource "aws_lb" "test" {
  name               = "autoscalinglb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadBalancer-sg.id]
  subnets            = [aws_subnet.publicsubnet1loadbalancer.id ,aws_subnet.publicsubnet2loadbalancer.id]
  enable_deletion_protection = false
  tags = {
    Environment = "Development"
  }
}



#------------------Calling SSM to store load balancer ARN in ssm parameter store --------------------------
resource "aws_ssm_parameter" "loadbalancerssm" {
  name        = "/myapp/config/loadbalancerarn"  
  description = "Load Balancer Arn"
  type        = "String"    
  value       = aws_lb.test.dns_name 

  tags = {
    Environment = "Dev" 
  }
}

#------------------------------Pulling certificate to attach to load Balancer lsitnenr ----------------------
data "aws_acm_certificate" "amazon_issued" {
  domain      = "*.clixx-azeez.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

output "mycerts" {
  value = data.aws_acm_certificate.amazon_issued.arn
}


#------------------------------ attaching target group to load balancer and add certs to listner -------------------
resource "aws_lb_listener" "http" {
  
  load_balancer_arn = aws_lb.test.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = data.aws_acm_certificate.amazon_issued.arn

  default_action {
    type = "forward"

    
      target_group_arn = aws_lb_target_group.instance_target_group.arn
    
  }
}





#----------------------------Create RDS Subnet group-----------------------------------------------------------
resource "aws_db_subnet_group" "groupdb" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.privatesubnetrds1.id,aws_subnet.privatesubnetrds2.id]

  tags = {
    Name = "My_DB_Subnet_Group"
  }
}


#------------------------Restoring RDS Database from snapshot------------------------------------------------------

resource "aws_db_instance" "restored_db" {
  identifier          = "wordpressdbclixx-ecs"
  snapshot_identifier = "arn:aws:rds:us-east-1:495599767034:snapshot:wordpressdbclixx-ecs"  
  instance_class      = "db.m6gd.large"        
  allocated_storage    = 20                     
  engine             = "mysql"                
  username           = "wordpressuser"
  password           = "W3lcome123"         
  db_subnet_group_name = aws_db_subnet_group.groupdb.name  
  vpc_security_group_ids = [aws_security_group.RDSEFS-sg.id] 
  skip_final_snapshot     = true
  publicly_accessible  = true
  
  tags = {
    Name = "wordpressdb"
  }
}


#--------------------CAlling ssm to store RDS database ----------------------------------------------------------

resource "aws_ssm_parameter" "dbidentifier" {
  name        = "/myapp/config/dbidentifier"  
  description = "DB Identifier"
  type        = "String"    
  value       = aws_db_instance.restored_db.identifier  

  tags = {
    Environment = "Dev" 
  }
}

#-----------------Getting the DB login details from ssm parammeter----------------------------------------------------
data "aws_ssm_parameter" "name" {
  name = "/myapp/dbname"
}

data "aws_ssm_parameter" "username" {
  name = "/myapp/dbusername"
}


data "aws_ssm_parameter" "endpoint" {
  name = "/myapp/dbendpoint"
}

data "aws_ssm_parameter" "password" {
  name = "/myapp/dbpassword"
}



#-------------------------------Creating Key Pair----------------------------------------------------------------------
resource "aws_key_pair" "Stack_KP" {
  key_name   = "stackkp"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}


# IAM Role for ECS EC2 Instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "Clixx-ECS-Instance-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Creating Policy for Role
resource "aws_iam_policy" "ecs_role" {
  name        = "Clixx-ECS-Instance-Policy"
  description = "Policy to allow ECS Instance role to register with ECS, interact with ELB, and pull images from ECR"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          # EC2 permissions
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:Describe*",

          # Elastic Load Balancing permissions
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",

          # ECS permissions
          "ecs:Poll",
          "ecs:DiscoverPollEndpoint",
          "ecs:SubmitTaskStateChange",
          "ecs:RegisterContainerInstance", 
          "ecs:DiscoverPollEndpoint",      
          "ecs:SubmitContainerStateChange", 
          "ecs:StartTelemetrySession",      
          "ecs:UpdateContainerInstancesState", 
          "ecs:DescribeTasks",
          "ecs:DescribeContainerInstances",
          "ecs:DeregisterContainerInstance",
          "ecs:StartTask",
          "ecs:StopTask",
          "ecs:ListClusters",
          "ecs:ListTasks",

          # Logging permissions
          "logs:CreateLogStream",           
          "logs:PutLogEvents",     
          "logs:DescribeLogStreams", 
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          # S3 permissions for ECS
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::aws-ecs-*",      
          "arn:aws:s3:::aws-ecs-logs-*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          # ECR permissions for pulling images
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}


# Attach the policy to ECS instance role
resource "aws_iam_role_policy_attachment" "ecs_instance_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.ecs_role.arn
}





#------Pulling information about a role that was already created. This role isassumed by ec2 to perform an action-----------------------
data "aws_iam_role" "ecs-role" {
  name = "ecsInstanceRole"
}

output "ecs-instancerole" {
  value = data.aws_iam_role.ecs-role.id
}

#----------------------Creating ECS Cluster--------------------------------------------------------
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

#-------Creating instance profile which contain the iam role to be assumed by the ec2 instance ---------------------------

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}


#----------------Creating Execution role.Execution Role This role allows ECS to pull Docker images from Amazon ECR (Elastic Container Registry) and write logs to CloudWatch.------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_policy" {
  name       = "ecs-execution-policy"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_execution_role.name]
}


# Creating Policy for Role
resource "aws_iam_policy" "ecs_role2" {
  name        = "Clixx-ecspoly"
  description = "Policy to allow ECS Instance role to register with ECS, interact with ELB, and pull images from ECR"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecs:StartTelemetrySession",
          "ecs:SubmitTaskStateChange",
          "ecs:UpdateContainerInstancesState"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_policy_attachment" "ecs_execution_policy2" {
  name       = "ecs-execution-policy"
  policy_arn = aws_iam_policy.ecs_role2.arn
  roles      = [aws_iam_role.ecs_execution_role.name]
}

#-------------------Creating Task role.Role that containers use to access AWS services.---------------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}


#------Attaching s3 full access policy for the task role----------------------------------------

resource "aws_iam_policy_attachment" "ecs_task_policy_attachment" {
  name       = "ecs-task-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  
  roles      = [aws_iam_role.ecs_task_role.name]
}


#---------------------Creating Task Definition-----------------------------------------------
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecs-task-definition"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
  network_mode             = "bridge"  
  requires_compatibilities = ["EC2"]  # "FARGATE" for serverless tasks, "EC2" for instance-backed
  cpu                      = "1024"
  memory                   = "3072"

  container_definitions = jsonencode([{
    name      = "Clixx-container"
    image     = "495599767034.dkr.ecr.us-east-1.amazonaws.com/clixx-repository:clixxnewimage"
    cpu       = 512
    memory    = 1536
    essential = true

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      interval    = 300
      timeout     = 59
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "MyECS-Task"
  }
}





#----------------------Creating Launch Template --------------------------------------------------------------------------
resource "aws_launch_template" "my_launch_template" {
  
  name          = "my-launch-template"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name = aws_key_pair.Stack_KP.key_name
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.clixxapp-sg.id]
  }

    iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }


    user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo yum install mysql -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
             
              echo "ECS_CLUSTER=ecs-cluster" | sudo tee /etc/ecs/ecs.config
              sleep 600

              lb_dns="https://terraform.clixx-azeez.com"
              output_variable=$(mysql -u wordpressuser -h wordpressdbclixx-ecs.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123 -sse "select option_value from wp_options where option_value like 'CliXX-APP-%';")
              echo "Output variable is: \$output_variable"

              if [ "\$output_variable" == "\$lb_dns" ]; then
                  echo "DNS Address is already in the table."
              else
                  echo "DNS Address is not in the table. Updating..."
                  mysql -u wordpressuser -h wordpressdbclixx-ecs.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123 <<SQL
                  UPDATE wp_options SET option_value = "https://terraform.clixx-azeez.com" WHERE option_value LIKE "CliXX-APP-%";
SQL
              fi
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "newinstance"
    }
  }
}


output "launch_template_id" {
  value = aws_launch_template.my_launch_template.id
}


#-------------------------Creating Autosacling Group-----------------------------------------------
resource "aws_autoscaling_group" "my_asg" {
  depends_on = [ aws_db_instance.restored_db ]
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"  
  }

  min_size     = 1
  max_size     = 3
  desired_capacity = 1
  vpc_zone_identifier = [aws_subnet.privatesubnetclixx1.id]

  tag {
    key                 = "Name"
    value               = "MyCliXXAutoScaling"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.instance_target_group.arn]
  
}


output "autoscaling_group_id" {
  value = aws_autoscaling_group.my_asg.id
}

#------------------------#Create ECS Service to Launch Tasks--------------------------------------------------

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id  
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn  
  desired_count   = 1  # Number of task instances to run

  launch_type     = "EC2"  # Specify EC2 as the launch type

  # Attach the load balancer to the ECS service
  load_balancer {
    target_group_arn = aws_lb_target_group.instance_target_group.arn
    container_name   = "Clixx-container"  # Name of the container in your task definition
    container_port   = 80              # Port the container listens on
  }


  depends_on = [
    aws_launch_template.my_launch_template,
    aws_lb_target_group.instance_target_group,  # Ensures load balancer target group is created first
    aws_lb_listener.http          # Ensures listener is created
  ]
}















data "aws_route53_zone" "selected" {
  name         = "clixx-azeez.com"
  
}

output "hostedzone" {
  value = data.aws_route53_zone.selected.zone_id

}




#----------------------CAlling ssm parameter to store names of the instances created by the autoscaling group----------------
resource "aws_ssm_parameter" "instancename" {
  
  name        = "/myapp/config/instancename"  
  description = "DB Identifier"
  type        = "String"    
  value       = "MyCliXXAutoScaling"  

  tags = {
    Environment = "Dev" 
  }
}

#---------------------Creating record in hosted zone--------------------------------------------
resource "aws_route53_record" "my_record" {
  allow_overwrite = true
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "terraform.clixx-azeez.com"
  type    = "CNAME"
  ttl     = 1500
  records = [aws_lb.test.dns_name]
}




#----------------------------Allowing All for outbound traffic ---------------------------------------

resource "aws_security_group_rule" "allow_all_outbound1" {
  security_group_id = aws_security_group.loadBalancer-sg.id  
  description = "Allow all outbound traffic"
  type              = "egress"
  protocol          = "-1" 
  from_port         = 0
  to_port           = 65535  
  cidr_blocks        = ["0.0.0.0/0"]  
}



resource "aws_security_group_rule" "allow_all_outbound2" {
  security_group_id = aws_security_group.clixxapp-sg.id  
  description = "Allow all outbound traffic"
  type              = "egress"
  protocol          = "-1" 
  from_port         = 0
  to_port           = 65535  
  cidr_blocks        = ["0.0.0.0/0"]  
}


resource "aws_security_group_rule" "allow_all_outbound3" {
  security_group_id = aws_security_group.RDSEFS-sg.id  
  description = "Allow all outbound traffic"
  type              = "egress"
  protocol          = "-1" 
  from_port         = 0
  to_port           = 65535  
  cidr_blocks        = ["0.0.0.0/0"]  
}


#-----------------------------Scaling Policy----------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  scaling_adjustment      = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  scaling_adjustment      = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

#-------------------------Creating Target Tracking Policy-----------------------------------------------
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  policy_type           = "TargetTrackingScaling"
  
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  
  target_tracking_configuration {
    target_value = 50.0  

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"  
    }
    
       
  }
}





