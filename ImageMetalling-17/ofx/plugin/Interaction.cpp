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

      if (paramExists(controls::false_color_enabled_check_box))
        m_false_color_enabled = fetchBooleanParam(controls::false_color_enabled_check_box);
    }

    bool
    Interaction::isIdentity(const OFX::IsIdentityArguments &args, OFX::Clip *&p_IdentityClip, double &p_IdentityTime) {
      return ImageEffect::isIdentity(args, p_IdentityClip, p_IdentityTime);
    }

    void Interaction::changedParam(const OFX::InstanceChangedArgs &args, const std::string &param_name) {
      ImageEffect::changedParam(args, param_name);
    }
}
