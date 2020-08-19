//
// Created by denn nevera on 2019-07-20.
//

#pragma once

#import "Function.h"
#include <string>

namespace imetalling {

    class Kernel: public Function {

    public:

        Kernel(
                const void *command_queue,
                const std::string& kernel_name,
                const Texture& source,
                const Texture& destination,
                bool wait_until_completed = WAIT_UNTIL_COMPLETED
        );

        FunctionHandler optionsHandler = nil;

        virtual void process();

        virtual void setup(CommandEncoder &commandEncoder);

        GridSize get_threads_per_threadgroup(int w, int h, int d) override ;

        GridSize get_thread_groups(int w, int h, int d) override ;

        [[nodiscard]] virtual Texture get_source() const { return source_;};
        [[nodiscard]] virtual Texture get_destination() const { return destination_ ? destination_ : source_;}

        ~Kernel() override ;

    private:
        Texture source_;
        Texture destination_;
    };

    namespace time_utils {
        timeval now();
        float duration(timeval tv1);
    }
}
