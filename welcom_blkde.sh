#!/bin/bash

echo "#####################"
echo " Welcom To the Linux Builder"
echo " By Nakada Tokumei "
echo "#####################"

user_uid=$(id -u)
user_gid=$(id -g)
docker_name="linux_builder_${user_uid}_${user_gid}"
workspace_dir=""

launch_docker="false"
terminate_docker="false"


function update_workspace_path() {
	if [ -f $HOME/.linux_builder/directory ];then
        	workspace_dir=`cat $HOME/.linux_builder/directory`
	fi
}

function run_docker() {
    echo 'sudo docker run -h linux_builder --name ${docker_name} -it -d -v $workspace_dir:/home/linuxbuild/workspace -v /dev/:/dev -v /run/udev:/run/udev linux_builder:24.04 /bin/bash'
    sudo docker run -h linux_builder --name ${docker_name} -it -d -v $workspace_dir:/home/linuxbuild/workspace -v /dev/:/dev -v /run/udev:/run/udev linux_builder:24.04 /bin/bash
}

function set_docker_env() {
	sudo docker exec -it ${docker_name} userdel -r ubuntu
	sudo docker exec -it ${docker_name} groupdel ubuntu
	sudo docker exec -it ${docker_name} groupadd -g ${user_gid} linuxbuild
	sudo docker exec -it ${docker_name} useradd -u ${user_uid} -g ${user_gid} -ms /bin/bash linuxbuild
	sudo docker exec -it ${docker_name} chown ${user_uid}:${user_gid} /home/linuxbuild
	sudo docker exec -it ${docker_name} sh -c 'echo "export LC_ALL=en_US.UTF-8" >> /home/linuxbuild/.bashrc'
	sudo docker exec -it ${docker_name} sh -c 'echo "export LANG=en_US.UTF-8" >> /home/linuxbuild/.bashrc'
}

function exec_docker() {
	echo "sudo docker exec -it -u ${user_uid}:${user_gid} -w /home/linuxbuild ${docker_name} /bin/bash"
	sudo docker exec -it -u ${user_uid}:${user_gid} -w /home/linuxbuild ${docker_name} /bin/bash
}

function kill_docker() {
	sudo docker kill ${docker_name}
	sudo docker rm ${docker_name}
}

function start_docker() {
	running_container=`sudo docker ps -a | awk '{print $NF}' | grep -w ${docker_name}`
	if [ $launch_docker != "false" ]; then
		if [ "$running_container" = "" ]; then
			update_workspace_path
			run_docker
			set_docker_env
		fi
		exec_docker
	fi

	if [ $terminate_docker != "false" ]; then
		if [ "$running_container" != "" ]; then
			kill_docker
		else
			echo "Failed to kill: Docker not exist."
		fi
	fi
}


if [ $# != 0 ]; then
	while true; do
		case "$1" in
			-k|--kill)
				launch_docker="false"
				terminate_docker="true"
				break
				;;
			*)
				echo "Launching Docker..."
				launch_docker="true"
				;;
		esac
		shift

		if [ "$1" = "" ]; then
			break
		fi
	done
else
	launch_docker="true"
fi

start_docker

