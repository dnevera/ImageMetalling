## Сборка 

    cmake \
    -DPRINT_DEBUG=ON \
    -DQT_INSTALLER_PREFIX=/Users/<user>/Develop/QtInstaller \ 
    -DCMAKE_PREFIX_PATH=/Users/<user>/Develop/Qt/5.13.0/clang_64/lib/cmake \
    -DPLUGIN_INSTALLER_DIR=/Users/<user>/Desktop \
    -DCMAKE_INSTALL_PREFIX=/Library/OFX/Plugins

    где, 
    . QT_INSTALLER_PREFIX - каталог где валяется, возможно без дела, SDK от Qt Intaller Framework
    . CMAKE_PREFIX_PATH - добавить к cmake путям всякое из Qt SDK 
    . PLUGIN_INSTALLER_DIR - каталог куда будет собран Qt инсталятор
    . CMAKE_INSTALL_PREFIX - сюда и только сюда ставить OFX под mac os

## Необходимое (но избыточное!)  

- PkgConfig
- Qt5.13
- BLAS
- LAPACK
- dehancer-maths-cpp: https://github.com/imetalling/imetalling-maths-cpp 
- dehancer-common-cpp: https://github.com/imetalling/imetalling-common-cpp
- dehancer-external: https://github.com/dehancer/dehancer-external

## Структура проекта

- ofx - сборка OFX плагина
- .... lib - сборка всей металической либы, может быть определена как независимая от OFX часть, но нет мы не пойдем так далеко 
- ....... kernels - хостовая обертка для металических ядер
- ....... shaders - ядра Metal
- .... plugin - сборка OFX
- ....... installer - конфигурация Qt Installer
- .... resources - иконки и вот это всё
  
