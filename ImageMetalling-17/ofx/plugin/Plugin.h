//
// Created by denn nevera on 16/08/2020.
//

#pragma once

#include "Interaction.h"
#include "ofxsImageEffect.h"

namespace imetalling::falsecolor {

    class Plugin : public Interaction
    {
    public:
        explicit Plugin(OfxImageEffectHandle p_Handle);

        /* Override the render */
        void render(const OFX::RenderArguments& p_Args) override ;

    };
}
