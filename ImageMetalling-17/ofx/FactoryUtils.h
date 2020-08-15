//
// Created by denn nevera on 2019-11-20.
//

#pragma once

#include <ofxCore.h>
#include <ofxsImageEffect.h>

namespace imetalling {

    OFX::RGBAParamDescriptor *define_rgba(OFX::ImageEffectDescriptor &desc,
                                          const std::string &name,
                                          const std::string &label,
                                          const std::string &hint,
                                          OFX::PageParamDescriptor *page,
                                          OFX::GroupParamDescriptor *group,
                                          double def,
                                          double min,
                                          double max);

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
                                              bool evaluate);

    OFX::IntParamDescriptor *define_int_value(OFX::ImageEffectDescriptor &desc,
                                              const std::string &name,
                                              const std::string &label,
                                              const std::string &hint,
                                              OFX::PageParamDescriptor *page,
                                              OFX::GroupParamDescriptor *group,
                                              int def,
                                              bool evaluate
    );

    OFX::ChoiceParamDescriptor *define_selector(
            OFX::ImageEffectDescriptor &desc,
            const std::string &name,
            const std::string &label,
            const std::string &hint,
            OFX::PageParamDescriptor *page,
            OFX::GroupParamDescriptor *group
    );

    OFX::StrChoiceParamDescriptor *define_string_selector(
            OFX::ImageEffectDescriptor &desc,
            const std::string &name,
            const std::string &label,
            const std::string &hint,
            OFX::PageParamDescriptor *page,
            OFX::GroupParamDescriptor *group
    );
}