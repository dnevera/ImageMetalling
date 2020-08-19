//
// Created by denn nevera on 16/08/2020.
//

#pragma once

#include "ofxsLog.h"
#include "ofxsImageEffect.h"
#include <string>

namespace imetalling::falsecolor {

    /**
     * @brief The plugin that does our work
     * */
    class Interaction : public OFX::ImageEffect {

    public:
        explicit Interaction(OfxImageEffectHandle handle,
                             const std::string &plugin_id);

        /* Override is identity */
        bool isIdentity(
                const OFX::IsIdentityArguments& args,
                OFX::Clip*& p_IdentityClip,
                double& p_IdentityTime) override;

        /* Override changedParam */
        void changedParam(
                const OFX::InstanceChangedArgs& args,
                const std::string& param_name) override;

    protected:
        OFX::Clip* m_destination_clip = nullptr;
        OFX::Clip* m_source_clip = nullptr;

        OFX::BooleanParam* m_false_color_enabled = nullptr;

    };
}
