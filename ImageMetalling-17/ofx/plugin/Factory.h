//
// Created by denn nevera on 15/04/2020.
//

#pragma once

#include "ofxsImageEffect.h"
#include "ofxsInteract.h"
#include "ofxsLog.h"

#include "Names.h"

namespace imetalling::falsecolor {

    /***
     * Наша конкретная реализация контейнера OFX
     */
    class Factory : public OFX::PluginFactoryHelper<Factory> {

    public:
        /// Конструктор сьюта
        /// \param plugin_id
        /// \param plugin_name
        /// \param plugin_description
        Factory(const std::string &plugin_id,
                const std::string &plugin_name,
                const std::string &plugin_description);

        /***
         * Единожды вызываемый при загрузке одного инстанса плугина.
         * Т.е. если у вас 10 нод или 100 клипов, то коненчо вызывется 10 и 100 раз, но только один раз на всю сессию.
         */
        void load() override;

        /***
         * Вызывается при удалении инстанса сьюта
         */
        void unload() override {}

        /***
         * Настройка параметров обмена данными между хостом и плагином
         * @param desc
         */
        void describe(OFX::ImageEffectDescriptor &desc) override;

        /***
         * Заполнение контекста конкретного плагина. Создания настроечных параметров, которые затем
         * отображаются в виде полей ввода, кнопок, слейдеров и прочих контролов в панели плагина хостовой программы.
         * @param desc
         * @param p_Context
         */
        void describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) override;

        /***
         * Создать обязательный инстанс основного эффекта плагина, с конкретным процессингом изображений.
         * @param p_Handle
         * @param p_Context
         * @return
         */
        OFX::ImageEffect* createInstance(OfxImageEffectHandle p_Handle, OFX::ContextEnum p_Context) override ;

    private:
        std::string id_;
        std::string name_;
        std::string description_;
    };
}
