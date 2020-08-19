//
// Created by denn nevera on 19/08/2020.
//

#include "Factory.h"

void OFX::Plugin::getPluginIDs(PluginFactoryArray& p_FactoryArray)
{
  static imetalling::falsecolor::Factory factory(
          imetalling::falsecolor::id,
          imetalling::falsecolor::name,
          imetalling::falsecolor::description
  );
  p_FactoryArray.push_back(&factory);
}