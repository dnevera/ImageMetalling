//
// Created by denn nevera on 15/04/2020.
//

#pragma once

#include "FactoryUtils.h"
#include "ofxsImageEffect.h"
#include "ofxsInteract.h"
#include "ofxsLog.h"

namespace imetalling {

    constexpr const char *grouping = "ImageMetalling";
    constexpr const int versionMajor = 1;
    constexpr const int versionMinor = 0;
    constexpr const bool supportsTiles = false;
    constexpr const bool supportsMultiResolution = false;
    constexpr const bool supportsMultipleClipPARs = false;

    class Factory : public OFX::PluginFactoryHelper<Factory> {
    public:
        Factory(const std::string &id,
                const std::string& prev_id,
                const std::string &name,
                const std::string &capture);

        void load() override;

        void unload() override {}

        void describe(OFX::ImageEffectDescriptor &desc) override;

        void describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) override;

    private:
        std::string id_;
        std::string name_;
        std::string capture_;
    };
}
