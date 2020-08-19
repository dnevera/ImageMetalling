//
// Created by denn nevera on 2019-08-30.
//

#pragma once

#include "GpuConfig.h"
#include "kernels/Function.h"
#include "Image.h"

namespace imetalling {

    /**
     * Фцнктор размещения текущего фрейма в текстуре Metal
     */
    class Image2Texture : public Function {

    public:
        Image2Texture(void *command_queue,
                      const float *input,
                      size_t width,
                      size_t height, bool wait_until_completed = WAIT_UNTIL_COMPLETED);

        Image2Texture(void *command_queue,
                      const Image& image, bool wait_until_completed = WAIT_UNTIL_COMPLETED);

        Texture get_texture() { return texture_; };

        ~Image2Texture() override ;

    private:
        size_t  width_;
        size_t  height_;
        Texture texture_;
    };
}