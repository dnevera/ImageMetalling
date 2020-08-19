//
// Created by denn nevera on 16/08/2020.
//

#include "Plugin.h"
#include "Names.h"
#include "Processor.h"

namespace imetalling::falsecolor {

    Plugin::Plugin(OfxImageEffectHandle p_Handle) :
            Interaction(p_Handle, id)
    {}


    void Plugin::render(const OFX::RenderArguments& args)
    {

      if (m_destination_clip && (m_destination_clip->getPixelDepth() == OFX::eBitDepthFloat)
          &&
          (m_destination_clip->getPixelComponents() == OFX::ePixelComponentRGBA))
      {
          Processor(this,
                    m_source_clip,
                    m_destination_clip,
                    args,
                    m_false_color_enabled->getValueAtTime(args.time)).process();
      }
      else
      {
        OFX::throwSuiteStatusException(kOfxStatErrUnsupported);
      }
    }
}
