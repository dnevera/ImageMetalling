//
// Created by denn nevera on 2019-07-17.
//

#include "Processor.h"
#include "Defaults.h"
#include "kernels/FalseColorKernel.h"
#include "kernels/PassKernel.h"

namespace imetalling::falsecolor {

    Processor::Processor(
            OFX::ImageEffect *instance,
            OFX::Clip *source,
            OFX::Clip *destination,
            const OFX::RenderArguments &args,
            bool enabled
    ) :
            OFX::ImageProcessor(*instance),
            enabled_(enabled),
            interaction_(instance),
            wait_command_queue_(false),
            // захватить текущий кадр клипа из хостовой памяти OFX
            source_(source->fetchImage(args.time)),
            // создать целевой кадр клипа с областью памяти ужа заданной в OFX
            destination_(destination->fetchImage(args.time)),
            source_container_(nullptr),
            destination_container_(nullptr)
    {

      // Установить OFX аргументы рендерига на GPU
      setGPURenderArgs(args);

      // Установить окно рендерига
      setRenderWindow(args.renderWindow);

      // Разместить данные исходного кадра в текстуре Metal
      source_container_ = std::make_unique<imetalling::Image2Texture>(_pMetalCmdQ, source_);

      // Создать пустую текстуру целевого кадра в Metal
      destination_container_ = std::make_unique<imetalling::Image2Texture>(_pMetalCmdQ, destination_);

      // Поучить параметры упаковки данных в области памяти целевого кадра
      OFX::BitDepthEnum dstBitDepth = destination->getPixelDepth();
      OFX::PixelComponentEnum dstComponents = destination->getPixelComponents();

      // и исходного
      OFX::BitDepthEnum srcBitDepth = source->getPixelDepth();
      OFX::PixelComponentEnum srcComponents = source->getPixelComponents();

      // кинуть в хостовую систему сообщенме о том, что что-то пошло не так
      // и отменить рендеринг текущего кадра
      if ((srcBitDepth != dstBitDepth) || (srcComponents != dstComponents)) {
        OFX::throwSuiteStatusException(kOfxStatErrValue);
      }

      // установить в текущий контекст процессора указатель на область памяти целевого кадра
      setDstImg(destination_.get_ofx_image());
    }

    void Processor::processImagesMetal() {

      try {

        /***
         * Вроде как очевидно, что делаем: процессим в текщей очереди команд
         * текстуру
         */

        if (enabled_)
          FalseColorKernel(_pMetalCmdQ,
                           source_container_->get_texture(),
                           destination_container_->get_texture()).process();
        else
          PassKernel(_pMetalCmdQ,
                           source_container_->get_texture(),
                           destination_container_->get_texture()).process();


        /***
         * А потом перекидываем из контейнера в буфер хостового приложения
         */
        ImageFromTexture(_pMetalCmdQ,
                         destination_,
                         destination_container_->get_texture(),
                         wait_command_queue_);

      }
      catch (std::exception &e) {
        interaction_->sendMessage(OFX::Message::eMessageError, "#message0", e.what());
      }
    }

    Processor::~Processor() = default;
}