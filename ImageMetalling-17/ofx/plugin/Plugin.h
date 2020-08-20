//
// Created by denn nevera on 16/08/2020.
//

#pragma once

#include "Interaction.h"
#include "ofxsImageEffect.h"

namespace imetalling::falsecolor {

    /**
     * После обработки всех интерактивных сюжетов связанных с дейстивями пользователя
     * или изменения состояния нужно запустить операцию рендеринга
     */
    class Plugin : public Interaction
    {
    public:
        explicit Plugin(OfxImageEffectHandle p_Handle);

        /// Ещё один из необходимых методов API, который нам надо реализовать
        /// \param p_Args
        void render(const OFX::RenderArguments& p_Args) override ;

    };
}
