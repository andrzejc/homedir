# Make sure .ssh exists and has proper permissions
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
	mkdir "$SSH_DIR"
	chmod 700 "$SSH_DIR"
fi

# Start ssh-agent if asked locally
SSH_ENV="$SSH_DIR/environment"

function start_agent {
	echo "Initialising new SSH agent..."
	ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
	chmod 600 "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
}

# Demand explicit ssh-agent autorun! this was annoying!
if [ "x$SSH_AGENT_ENABLE_AUTORUN" = "x1" ]
then
	if [ -f "${SSH_ENV}" ]
	then
		. "${SSH_ENV}" > /dev/null
		ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
			start_agent;
		}
	else
		start_agent;
	fi
fi

