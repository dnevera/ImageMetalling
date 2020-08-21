//
// Created by denn nevera on 15/04/2020.
//

#include "Factory.h"
#include "Plugin.h"

#include <string>
#include <algorithm>

namespace imetalling::falsecolor {

    Factory::Factory(const std::string& plugin_id,
                     const std::string& plugin_name,
                     const std::string& plugin_description):
            OFX::PluginFactoryHelper<Factory>(id, versionMajor, versionMinor),
            id_(plugin_id),
            name_(plugin_name),
            description_(plugin_description)
    {
    }

    void Factory::describe(OFX::ImageEffectDescriptor &desc) {


      /// Обязательно задать версию плагина
      desc.setVersion(
              versionMajor,
              versionMinor,
              0,
              1,
              id_);

      std::string _pluginName(name_);
      _pluginName.append(" ");
      _pluginName.append(std::to_string(versionMajor));
      _pluginName.append(".");
      _pluginName.append(std::to_string(versionMinor));

      std::string _pluginTitle(name_);
      _pluginTitle.append(" ");
      _pluginTitle.append(std::to_string(versionMajor));
      _pluginTitle.append(".");
      _pluginTitle.append(std::to_string(versionMinor));

      /// И его имя с пояснениями
      desc.setLabels(_pluginName, _pluginTitle, description_);

      /// Неплохобы привязать к группе
      desc.setPluginGrouping(grouping);

      /// И задать описание, что бы хостовая программа могла что-то о расширении показать пользователю
      desc.setPluginDescription(description_);

      /// Обязательно определить принадлежность к контексту.
      /// В нашем случае это фильтр
      desc.addSupportedContext(OFX::eContextFilter);
      desc.addSupportedContext(OFX::eContextGeneral);

      /// Задать тип пикселя, мы работаем только с float представлением
      desc.addSupportedBitDepth(OFX::eBitDepthFloat);

      /// Разрешить добавлять больше чем один инстанс
      desc.setSingleInstance(false);

      /// Не даем рриложению параллелить вычисления с кадрами
      desc.setHostFrameThreading(false);

      /// Не даем приложению произвольный доступ к данным клипа
      desc.setTemporalClipAccess(false);

      /// Не даем запускать рендеринг дважды
      desc.setRenderTwiceAlways(false);

      /// не даем разным клипам быть с разным соотношением сторон
      desc.setSupportsMultipleClipPARs(false);

      /// и разным разрешением
      desc.setSupportsMultiResolution(false);

      /// так же не даем дробить клипы для обработки (хотя в целом можно)
      desc.setSupportsTiles(false);

      /// говорим хостовой системе быть осторожной
      desc.setRenderThreadSafety(OFX::eRenderFullySafe);

      /// ну и самое главное говорим хосту создать очередь команд Metal!
      desc.setSupportsMetalRender(true);

      // Indicates that the plugin output does not depend on location or neighbours of a given pixel.
      // Therefore, this plugin could be executed during LUT generation.
      desc.setNoSpatialAwareness(true);

    }

    void Factory::describeInContext(OFX::ImageEffectDescriptor &desc, OFX::ContextEnum p_Context) {

      /// в текущем контексте, зачем-то нужно установить текущие свойсьва клипа
      /// частично дублирующие свойства дескриптора эффекта
      OFX::ClipDescriptor *srcClip = desc.defineClip(kOfxImageEffectSimpleSourceClipName);

      /// главное сказать что работаем с RGBA
      /// так проще отмапить данные в Metal текстуру
      srcClip->addSupportedComponent(OFX::ePixelComponentRGBA);
      srcClip->setTemporalClipAccess(false);
      srcClip->setSupportsTiles(false);
      srcClip->setIsMask(false);

      OFX::ClipDescriptor *dstClip = desc.defineClip(kOfxImageEffectOutputClipName);

      dstClip->addSupportedComponent(OFX::ePixelComponentRGBA);
      dstClip->setSupportsTiles(false);

      /// Создаем UI страницу панели управления OFX плагином
      OFX::PageParamDescriptor *page = desc.definePageParam("main_page");


      /// Можно добавить выпадающую группу в, которой размещаются котролы,
      /// но можно и не создавать - это вопрос "проектирования" UI/UX
      /// конкретной панели конкретного плагина, мы для примеры добавим
      OFX::GroupParamDescriptor* group = desc.defineGroupParam("falseColorGroup");

      /// Устанавливаем отображаемые свойства панели и группы
      group->setHint("False Color Group");
      group->setLabels("False Color", "False Color", "False Color");
      group->setOpen(true);

      /// Добавляем в группу чекбокс
      OFX::BooleanParamDescriptor *false_color_enabled = desc.defineBooleanParam(controls::false_color_enabled_check_box);
      false_color_enabled->setDefault(false);

      /// Видимые свойства чекбокса
      false_color_enabled->setLabels("False Colors (IRE, 16 zones)", "Check False Colors", "Check False Colors");

      /// При изменении состояния дать OFX сгенерить событие
      /// для запуска чтения аттрибутов структуры плагина и рендеринга
      false_color_enabled->setEvaluateOnChange(true);

      /// Привязываем к конкретной группе
      false_color_enabled->setParent(*group);

      /// Добавляем на страницу панели
      page->addChild(*false_color_enabled);

    }

    void Factory::load() {
      PluginFactory::load();
    }

    OFX::ImageEffect *Factory::createInstance(OfxImageEffectHandle handle, OFX::ContextEnum) {
      return new Plugin(handle);
    }

}