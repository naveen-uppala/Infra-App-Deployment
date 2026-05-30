container_port=80
targetgroup_name="<+serviceVariables.containername>-tg"
VpcId="<+serviceVariables.VpcId>"
listenerArn="<+serviceVariables.listenerArn>"
priorityNumber="<+serviceVariables.priorityNumber>"
pathName="/<+serviceVariables.containername>*"
region="<+serviceVariables.region>"
