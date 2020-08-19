//
// Created by denn nevera on 15/04/2020.
//

#include "Factory.h"
#include "Plugin.h"

#include <string>
#include <algorithm>

namespace imetalling::falsecolor {

    Factory::Factory(const std::string& plugin_id,
                     const std::string& plugin_name,
                     const std::string& plugin_description):
            OFX::PluginFactoryHelper<Factory>(id, versionMajor, versionMinor),
            id_(plugin_id),
            name_(plugin_name),
            description_(plugin_description)
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

      desc.setLabels(_pluginName, _pluginTitle, description_);
      desc.setPluginGrouping(grouping);
      desc.setPluginDescription(description_);

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

      desc.setSupportsMetalRender(true);

      // Indicates that the plugin output does not depend on location or neighbours of a given pixel.
      // Therefore, this plugin could be executed during LUT generation.
      desc.setNoSpatialAwareness(true);

    }

    void Factory::describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) {

      OFX::ClipDescriptor *srcClip = desc.defineClip(kOfxImageEffectSimpleSourceClipName);

      srcClip->addSupportedComponent(OFX::ePixelComponentRGBA);
      srcClip->setTemporalClipAccess(false);
      srcClip->setSupportsTiles(supportsTiles);
      srcClip->setIsMask(false);

      OFX::ClipDescriptor *dstClip = desc.defineClip(kOfxImageEffectOutputClipName);

      dstClip->addSupportedComponent(OFX::ePixelComponentRGBA);
      dstClip->setSupportsTiles(supportsTiles);

      /// MARK - Page
      OFX::PageParamDescriptor *page = desc.definePageParam("main_page");


      /// MARK - Profile output group
      OFX::GroupParamDescriptor* group = desc.defineGroupParam("falseColorGroup");

      group->setHint("False Color Group");
      group->setLabels("False Color", "False Color", "False Color");
      group->setOpen(true);


      OFX::BooleanParamDescriptor *false_color_enabled = desc.defineBooleanParam(controls::false_color_enabled_check_box);
      false_color_enabled->setDefault(false);

      false_color_enabled->setLabels("False Colors (IRE, 16 zones)", "Check False Colors", "Check False Colors");

      false_color_enabled->setEvaluateOnChange(true);
      false_color_enabled->setParent(*group);
      page->addChild(*false_color_enabled);

    }

    void Factory::load() {
      PluginFactory::load();
    }

    OFX::ImageEffect *Factory::createInstance(OfxImageEffectHandle handle, OFX::ContextEnum) {
      return new Plugin(handle);
    }

}