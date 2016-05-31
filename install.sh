#!/bin/bash

set -e

echo "安装Koine Vim配置"

echo "备份已有的vim配置"
mv -f ~/.vim ~/.vim_old2

echo "从Github克隆配置"
git clone https://github.com/ygmpkk/vimconfig ~/.vim
ln -sf ~/.vim/vimrc ~/.vimrc

echo "正在安装Vim插件..." > ~/.vimprocess

vim -s ~/.vimprocess -c "PlugInstall" -c "q" -c "q"
rm -f ~/.vimprocess

echo "安装完成"
