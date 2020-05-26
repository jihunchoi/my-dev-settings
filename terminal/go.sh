for cmd in git vim zsh tmux
do
    if ! type $cmd > /dev/null; then
        echo "You have to install $cmd first!"
        exit 1
    fi
done

# Install Vundle
git clone https://github.com/gmarik/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim

# Install oh-my-zsh
install_oh_my_zsh () {
    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sed "s/env zsh//g")"
}
install_oh_my_zsh

# Copy configuration files
cp -f ./zshrc $HOME/.zshrc
cp -f ./vimrc $HOME/.vimrc
cp -f ./tmux.conf $HOME/.tmux.conf
cp -f ./direnvrc $HOME/.direnvrc
cp -f ./zprofile $HOME/.zprofile

# Install Vundle plugins
vim +PluginInstall +qall

# Setup git
echo ""
echo "Let's do some git configurations."
echo "(You can just hit Ctrl+C if you don't want to, but in that case you have to manually run zsh or restart the terminal.)"
read -p "Email: " email
read -p "Name: " name
git config --global user.email $email
git config --global user.name $name

# Done!
echo ""
echo "Done! Here's what you have to do next (if you didn't do them yet)."
echo "1) Change your terminal settings to use solarized color scheme."
echo "2) Change your default terminal to zsh."

env zsh
