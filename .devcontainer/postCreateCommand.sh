USER=codespace
SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history"
sudo mkdir -p /commandhistory
sudo touch /commandhistory/.bash_history
sudo chown -R $USER /commandhistory
echo "$SNIPPET" >> "/home/$USER/.bashrc"