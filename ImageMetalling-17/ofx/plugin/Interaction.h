//
// Created by denn nevera on 16/08/2020.
//

#pragma once

#include "ofxsLog.h"
#include "ofxsImageEffect.h"
#include <string>

namespace imetalling::falsecolor {

    /**
     * @brief Все что мы делаем с картинкой определыем тут.
     * В нашем случае задаем один параметр - включен или выключен False Color monitor.
     * */
    class Interaction : public OFX::ImageEffect {

    public:
        explicit Interaction(OfxImageEffectHandle handle,
                             const std::string &plugin_id);

        /**
         * Вернуть false если состояние и настройки изменились или true если таки изменились
         * */
        bool isIdentity(
                const OFX::IsIdentityArguments& args,
                OFX::Clip*& p_IdentityClip,
                double& p_IdentityTime) override;

        /**
         * Тут может быть определена какая-то логика связанная с установкой или вычислениями свойств плагина
         * при изменения параметров как состороны пользоватля (изменилось состояние контрола в панели),
         * или со стороны хостовой системы (сменился кадр клипа)
         * */
        void changedParam(
                const OFX::InstanceChangedArgs& args,
                const std::string& param_name) override;

    protected:
        /// немного схалявим и не будем скрывать некоторые данные
        /// обкладывать геттерами, например

        OFX::Clip* m_destination_clip = nullptr;
        OFX::Clip* m_source_clip = nullptr;

        OFX::BooleanParam* m_false_color_enabled = nullptr;

    };
}
