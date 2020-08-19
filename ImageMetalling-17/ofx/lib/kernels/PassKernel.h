//
// Created by denn nevera on 2019-08-02.
//

#pragma once

#include "Kernel.h"

namespace imetalling {

    class PassKernel: public Kernel {

    public:
        PassKernel(const void *command_queue, const Texture &source, const Texture &destination,
                   bool wait_until_completed = WAIT_UNTIL_COMPLETED);
    };
}