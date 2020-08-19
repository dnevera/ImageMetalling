//
// Created by denn nevera on 2019-08-30.
//

#include "Image2Texture.h"
#include "ofxsLog.h"

namespace imetalling {

    Image2Texture::~Image2Texture() {
      if (texture_) {
        [texture_ TEXTURE_RELEASE];
        texture_ = nullptr;

#ifdef PRINT_DEBUG
        OFX::Log::print("**** Image2Texture::~Image2Texture[%p] texture size: %i %i",
                        get_command_queue(),
                        width_,
                        height_
        );
#endif

      }
    }

    Image2Texture::Image2Texture(void *command_queue, const imetalling::Image &image, bool wait_until_completed ):
            Image2Texture(command_queue, image.get_pixel_data(), image.width, image.height, wait_until_completed) {}

    Image2Texture::Image2Texture(
            void *command_queue,
            const float *input,
            size_t width,
            size_t height, bool wait_until_completed ) :
            Function(command_queue, "kernel_buffer_to_texture", wait_until_completed),
            width_(width),
            height_(height),
            texture_(nil)
    {

      if (input == nullptr)
        return ;

      texture_ = make_texture(width_, height_);

      if (texture_ == nil) {
#ifdef PRINT_DEBUG
        OFX::Log::print("**** Image2Texture::Image2Texture[%p] texture size: %i %i ERROR!",
                        command_queue,
                        width_,
                        height_
        );
#endif
        return;
      }

#ifdef PRINT_DEBUG
      OFX::Log::print("**** Image2Texture::Image2Texture[%p] texture size: %i %i",
                      command_queue,
                      width_,
                      height_
      );
#endif

      auto srcDeviceBuf = reinterpret_cast<id<MTLBuffer> >((__bridge id)const_cast<float *>(input));

      execute([this, srcDeviceBuf](id <MTLComputeCommandEncoder> &compute_encoder) {

          [compute_encoder setBuffer:srcDeviceBuf offset: 0 atIndex: 0];
          [compute_encoder setTexture:texture_ atIndex:0];
          [compute_encoder setBytes:&width_ length:sizeof(int) atIndex:2];
          [compute_encoder setBytes:&height_ length:sizeof(int) atIndex:3];

          return texture_;
      });
    }
}