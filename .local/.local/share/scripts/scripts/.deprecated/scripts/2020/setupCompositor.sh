mkdir -p $HOME/Documents/Programs
cd $HOME/Documents/Programs
git clone https://github.com/chjj/compton
cd compton && sudo make && sudo make docs && sudo make install
