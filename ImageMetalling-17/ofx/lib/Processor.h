//
// Created by denn nevera on 2019-07-17.
//

#pragma once

#include "Image.h"
#include "Image2Texture.h"
#include "ImageFromTexture.h"
#include "ofxsImageEffect.h"

#include <string>
#include <vector>

namespace imetalling {

    class Processor : public OFX::ImageProcessor
    {

    public:

        /**
         * OFX процессор. По сути функтор запуска металических ядер от имени OFX.
         * В недрах подшотавливаем проксирование структур хостовой системы OFX в классы
         * Metal.
         * @param instance - ofx effect instance
         * @param source - source clip, OFX структура текущего исходного клипа
         * @param destination - destination clip, OFX структура текущего целевого клипа
         * @param args- ofx rendering args, параметры рендеринга
         */
        explicit Processor(
                OFX::ImageEffect* instance,
                OFX::Clip* source,
                OFX::Clip* destination,
                const OFX::RenderArguments& args,
                bool enabled
        );

        ~Processor() override ;

        /**
         * Process image with Metal
         */
        void processImagesMetal() override ;

    private:
        OFX::ImageEffect* interaction_;
        bool enabled_;
        bool wait_command_queue_;
        Image source_;
        Image destination_;
        std::unique_ptr<Image2Texture>  source_container_;
        std::unique_ptr<Image2Texture>  destination_container_;
    };
}

