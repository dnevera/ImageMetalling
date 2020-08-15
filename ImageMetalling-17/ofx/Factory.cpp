//
// Created by denn nevera on 15/04/2020.
//

#include "Factory.h"

#include "FactoryUtils.h"
#include "ofxsLog.h"
#include <string>
#include <algorithm>

namespace imetalling {

    Factory::Factory(const std::string& id,
                     const std::string& prev_id,
                     const std::string& name,
                     const std::string& capture):
            OFX::PluginFactoryHelper<Factory>(id, versionMajor, versionMinor),
            id_(id),
            name_(name),
            capture_(capture)
    {
    }

    void Factory::describe(OFX::ImageEffectDescriptor &desc) {

      // Basic labels

      desc.setVersion(
              versionMajor,
              versionMinor,
              0,
              1,
              id_);

      std::string _pluginName(name_);
      _pluginName.append(" ");
      _pluginName.append(std::to_string(versionMajor));
      _pluginName.append(".");
      _pluginName.append(std::to_string(versionMinor));

      std::string _pluginTitle(name_);
      _pluginTitle.append(" ");
      _pluginTitle.append(std::to_string(versionMajor));
      _pluginTitle.append(".");
      _pluginTitle.append(std::to_string(versionMinor));

      desc.setLabels(_pluginName, _pluginTitle, capture_);
      desc.setPluginGrouping(grouping);
      desc.setPluginDescription(capture_);

      // Add the supported contexts, only filter at the moment
      desc.addSupportedContext(OFX::eContextFilter);
      desc.addSupportedContext(OFX::eContextGeneral);

      // Add supported pixel depths
      desc.addSupportedBitDepth(OFX::eBitDepthFloat);

      // Set a few flags
      desc.setSingleInstance(false);
      desc.setHostFrameThreading(false);
      desc.setTemporalClipAccess(false);
      desc.setRenderTwiceAlways(false);

      desc.setSupportsMultipleClipPARs(supportsMultipleClipPARs);
      desc.setSupportsMultiResolution(supportsMultiResolution);
      desc.setSupportsTiles(supportsTiles);
      desc.setRenderThreadSafety(OFX::eRenderFullySafe);

#ifdef __APPLE__
      desc.setSupportsMetalRender(true);
#endif

      // Indicates that the plugin output does not depend on location or neighbours of a given pixel.
      // Therefore, this plugin could be executed during LUT generation.
      desc.setNoSpatialAwareness(true);

    }

    void Factory::describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) {

    }

    void Factory::load() {
      PluginFactory::load();
    }

}