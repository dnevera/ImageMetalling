//
// Created by denn nevera on 15/04/2020.
//

#pragma once

#include "ofxsImageEffect.h"
#include "ofxsInteract.h"
#include "ofxsLog.h"

#include "Names.h"

namespace imetalling::falsecolor {

    class Factory : public OFX::PluginFactoryHelper<Factory> {

    public:
        Factory(const std::string &plugin_id,
                const std::string &plugin_name,
                const std::string &plugin_description);

        void load() override;

        void unload() override {}

        void describe(OFX::ImageEffectDescriptor &desc) override;

        void describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) override;

        OFX::ImageEffect* createInstance(OfxImageEffectHandle p_Handle, OFX::ContextEnum p_Context) override ;

    private:
        std::string id_;
        std::string name_;
        std::string description_;
    };
}
