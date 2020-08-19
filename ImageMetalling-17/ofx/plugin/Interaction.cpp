//
// Created by denn nevera on 16/08/2020.
//

#include "Interaction.h"
#include "Factory.h"

namespace imetalling::falsecolor {
    Interaction::Interaction(OfxImageEffectHandle handle,
                             const std::string &plugin_id):
            ImageEffect(handle)
    {

      m_destination_clip = fetchClip(kOfxImageEffectOutputClipName);
      m_source_clip = fetchClip(kOfxImageEffectSimpleSourceClipName);

      if (paramExists(controls::false_color_enabled_check_box))
        m_false_color_enabled = fetchBooleanParam(controls::false_color_enabled_check_box);
    }

    bool
    Interaction::isIdentity(const OFX::IsIdentityArguments &args, OFX::Clip *&p_IdentityClip, double &p_IdentityTime) {
      return false;
    }

    void Interaction::changedParam(const OFX::InstanceChangedArgs &args, const std::string &param_name) {
    }
}
