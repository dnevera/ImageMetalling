//
// Created by denn nevera on 2019-11-20.
//

#include "FactoryUtils.h"

namespace imetalling {

    OFX::RGBAParamDescriptor *define_rgba(OFX::ImageEffectDescriptor &desc,
                                                 const std::string &name,
                                                 const std::string &label,
                                                 const std::string &hint,
                                                 OFX::PageParamDescriptor *page,
                                                 OFX::GroupParamDescriptor *group,
                                                 double def,
                                                 double min,
                                                 double max) {
        OFX::RGBAParamDescriptor *param = desc.defineRGBAParam(name);

        param->setLabel(label);
        param->setHint(hint);
        param->setDefault(def, def, def, 1);
        param->setDisplayRange(min, min, min, min, max, max, max, max);

        if (group)
            param->setParent(*group);

        if (page) {
            page->addChild(*param);
        }

        return param;
    }


    OFX::StrChoiceParamDescriptor *define_string_selector(
            OFX::ImageEffectDescriptor &desc,
            const std::string &name,
            const std::string &label,
            const std::string &hint,
            OFX::PageParamDescriptor *page,
            OFX::GroupParamDescriptor *group
    ) {

        OFX::StrChoiceParamDescriptor *list = desc.defineStrChoiceParam(name);

        list->setAnimates(false);
        list->setEvaluateOnChange(true);
        list->setLabels(label, label, label);
        list->setHint(hint);
        //list->setScriptName(name);
        list->setParent(*group);
        list->setIsPersistant(false);

        page->addChild(*list);

        return list;
    }

    OFX::ChoiceParamDescriptor *define_selector(
            OFX::ImageEffectDescriptor &desc,
            const std::string &name,
            const std::string &label,
            const std::string &hint,
            OFX::PageParamDescriptor *page,
            OFX::GroupParamDescriptor *group
    ) {

        OFX::ChoiceParamDescriptor *list = desc.defineChoiceParam(name);

        list->setAnimates(true);
        list->setEvaluateOnChange(true);
        list->setLabels(label, label, label);
        list->setHint(hint);
        list->setParent(*group);
        list->setIsPersistant(false);
        list->setDefault(0);

        page->addChild(*list);

        return list;
    }

    OFX::DoubleParamDescriptor *define_slider(OFX::ImageEffectDescriptor &desc,
                                                     const std::string &name,
                                                     const std::string &label,
                                                     const std::string &hint,
                                                     OFX::PageParamDescriptor *page,
                                                     OFX::GroupParamDescriptor *group,
                                                     double def,
                                                     double min,
                                                     double max,
                                                     double inc,
                                                     bool evaluate
    ) {

        OFX::DoubleParamDescriptor *param = desc.defineDoubleParam(name);

        param->setLabels(label, label, label);
        param->setHint(hint);
        param->setDefault(def);
        param->setRange(min, max);
        param->setIncrement(inc);
        param->setDisplayRange(min, max);
        param->setDoubleType(OFX::eDoubleTypeScale);
        param->setEvaluateOnChange(evaluate);

        if (group)
            param->setParent(*group);

        if (page)
            page->addChild(*param);

        return param;
    }

    OFX::IntParamDescriptor *define_int_value(OFX::ImageEffectDescriptor &desc,
                                                     const std::string &name,
                                                     const std::string &label,
                                                     const std::string &hint,
                                                     OFX::PageParamDescriptor *page,
                                                     OFX::GroupParamDescriptor *group,
                                                     int def,
                                                     bool evaluate
    ) {

        OFX::IntParamDescriptor *param = desc.defineIntParam(name);

        param->setLabels(label, label, label);
        param->setHint(hint);
        param->setDefault(def);
        param->setEvaluateOnChange(evaluate);

        if (group)
            param->setParent(*group);

        if (page)
            page->addChild(*param);

        return param;
    }
}