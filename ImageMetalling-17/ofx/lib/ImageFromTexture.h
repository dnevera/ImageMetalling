//
// Created by denn nevera on 2019-08-31.
//

#pragma once

#include "GpuConfig.h"
#include "kernels/Function.h"
#include "Image.h"

namespace imetalling {

    class ImageFromTexture: public Function {
    public:
        ImageFromTexture(void *command_queue, Image& image, const Texture texture, bool wait_until_completed = WAIT_UNTIL_COMPLETED);
        ImageFromTexture(void *command_queue, float *output, const Texture texture, bool wait_until_completed = WAIT_UNTIL_COMPLETED);
    };


}
