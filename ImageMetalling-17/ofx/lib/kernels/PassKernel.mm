//
// Created by denn nevera on 2019-08-02.
//

#include "PassKernel.h"

namespace imetalling {

    static std::string __profile_kernel("kernel_dehancer_pass");

    PassKernel::PassKernel(const void *command_queue, const Texture &source, const Texture &destination,
                           bool wait_until_completed) :
            Kernel(command_queue, __profile_kernel, source, destination, wait_until_completed)
    {
    }
}