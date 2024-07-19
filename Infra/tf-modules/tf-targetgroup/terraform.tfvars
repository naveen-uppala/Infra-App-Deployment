container_port=80
targetgroup_name="<+serviceVariables.containername>-tg"
VpcId="vpc-00383e29bb7567ac7"
listenerArn="arn:aws:elasticloadbalancing:us-east-2:381492302819:listener/app/ecs-frontend-alb/dc1d7ecb532fb743/52ebf23aa09c8ef5"
priorityNumber="<+serviceVariables.PortNumber>"
pathName="/<+serviceVariables.containername>*"
region="<+serviceVariables.region>"
