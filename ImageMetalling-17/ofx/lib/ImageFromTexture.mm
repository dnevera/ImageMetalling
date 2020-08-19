//
// Created by denn nevera on 2019-08-31.
//

#include "ImageFromTexture.h"

namespace imetalling {

    ImageFromTexture::ImageFromTexture(void *command_queue, imetalling::Image &image, const Texture texture, bool wait_until_completed ):
            ImageFromTexture(command_queue, image.get_pixel_data(), texture, wait_until_completed)
    {

    }

    ImageFromTexture::ImageFromTexture(void *command_queue, float *output, const Texture texture, bool wait_until_completed ):
    Function(command_queue, "kernel_texture_to_buffer", wait_until_completed)
    {

        auto srcDeviceBuf = reinterpret_cast<id<MTLBuffer> >((__bridge id)const_cast<float *>(output));

        if (srcDeviceBuf == nullptr)
            return ;

        if (texture == nil)
            return ;
        
        execute([this, srcDeviceBuf, texture](id <MTLComputeCommandEncoder> &compute_encoder) {

            [compute_encoder setTexture:texture atIndex:0];
            [compute_encoder setBuffer:srcDeviceBuf offset: 0 atIndex: 0];

            return texture;
        });
    }
}