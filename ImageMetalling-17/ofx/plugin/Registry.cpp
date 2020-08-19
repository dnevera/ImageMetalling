//
// Created by denn nevera on 19/08/2020.
//

#include "Factory.h"

#define PLUGIN_BUNDLE_INSTALATION_PATH "/Library/OFX/Plugins/IMFalseColor.ofx.bundle"
#define METAL_LIB_PATH "Contents/MacOS/Metallib/ImageMetalling.metallib"

void OFX::Plugin::getPluginIDs(PluginFactoryArray& p_FactoryArray)
{
  static imetalling::falsecolor::Factory factory(
          imetalling::falsecolor::id,
          imetalling::falsecolor::name,
          imetalling::falsecolor::description
  );
  p_FactoryArray.push_back(&factory);
}

namespace imetalling {
    /**
     * Must be defined in certain plugin
     * @return
     */
    extern std::string get_metallib_path() {
      return PLUGIN_BUNDLE_INSTALATION_PATH "/" METAL_LIB_PATH;
    }

    extern std::string get_installation_path(){
      return PLUGIN_BUNDLE_INSTALATION_PATH "/";
    }
}