//
// Created by denn nevera on 2019-07-17.
//

#include "Processor.h"
#include "Defaults.h"
#include "kernels/FalseColorKernel.h"
#include "kernels/PassKernel.h"

namespace imetalling {

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
            source_(source->fetchImage(args.time)),
            destination_(destination->fetchImage(args.time)),
            source_container_(nullptr),
            destination_container_(nullptr)
    {

      // Setup Metal render arguments
      setGPURenderArgs(args);

      // Set the render window
      setRenderWindow(args.renderWindow);

#ifdef PRINT_DEBUG
        OFX::Log::print("**** Plugin::Process[%p] size = %fx%f",
                        _pMetalCmdQ,
                        source_.width, source_.height
        );
#endif

      source_container_ = std::make_unique<imetalling::Image2Texture>(_pMetalCmdQ, source_);
      destination_container_ = std::make_unique<imetalling::Image2Texture>(_pMetalCmdQ, destination_);

      OFX::BitDepthEnum dstBitDepth = destination->getPixelDepth();
      OFX::PixelComponentEnum dstComponents = destination->getPixelComponents();

      OFX::BitDepthEnum srcBitDepth = source->getPixelDepth();
      OFX::PixelComponentEnum srcComponents = source->getPixelComponents();

      // Check to see if the bit depth and number of components are the same
      if ((srcBitDepth != dstBitDepth) || (srcComponents != dstComponents)) {
        OFX::throwSuiteStatusException(kOfxStatErrValue);
      }

      setDstImg(destination_.get_ofx_image());
    }

    void Processor::processImagesMetal() {

      try {

        if (enabled_)
          FalseColorKernel(_pMetalCmdQ,
                           source_container_->get_texture(),
                           destination_container_->get_texture()).process();
        else
          PassKernel(_pMetalCmdQ,
                           source_container_->get_texture(),
                           destination_container_->get_texture()).process();


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