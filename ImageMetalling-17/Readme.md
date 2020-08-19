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
- EXPAT
- ZLIB 
- Iconv
- CURL
- Qt5.13
- BLAS
- LAPACK
- dispatchq: https://github.com/imetalling/capy-dispatchq
- ed25519cpp: https://github.com/dnevera/ed25519cpp
- base64cpp: https://github.com/dnevera/base64cpp
- imetalling-common-cpp: https://github.com/imetalling/imetalling-common-cpp
- armadillo-code: https://github.com/imetalling/armadillo-code
- dehancer-maths-cpp: https://github.com/imetalling/imetalling-maths-cpp 
- dehancer-xmp-cpp: https://github.com/imetalling/imetalling-xmp-cpp
- rxcpp: https://github.com/ReactiveX/RxCpp
  
