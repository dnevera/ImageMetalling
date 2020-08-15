#import "Kernel.h"
#include <sys/time.h>

struct timezone tz;

namespace imetalling {

    namespace time_utils {

        timeval now()
        {
            timeval tv1;
            gettimeofday(&tv1, &tz);
            return tv1;
        }

        float duration(timeval tv1)
        {
            timeval tv2,dtv;

            gettimeofday(&tv2, &tz);

            dtv.tv_sec= tv2.tv_sec -tv1.tv_sec;

            dtv.tv_usec=tv2.tv_usec-tv1.tv_usec;

            if(dtv.tv_usec<0) { dtv.tv_sec--; dtv.tv_usec+=1000000; }

            return (float(dtv.tv_sec)*1000000.0f+float(dtv.tv_usec))/1000000.0f;

        }
    }
}

namespace imetalling {

    Kernel::Kernel(
            const void *command_queue,
            const std::string &kernel_name,
            const Texture& source,
            const Texture& destination,
            bool wait_until_completed
    ):
            Function(command_queue,kernel_name,wait_until_completed),
            source_(source),
            destination_(destination)
    {
    }

#ifdef __DEHANCER_USING_METAL__

    void Kernel::setup(CommandEncoder &commandEncoder) {
        if (optionsHandler) {
            optionsHandler(commandEncoder);
        }
    };


    void Kernel::process() {

        execute([this](auto& computeEncoder){

            [computeEncoder setTexture:get_source() atIndex:0];

            if (auto dest = get_destination())
                [computeEncoder setTexture:dest atIndex:1];

            this->setup(computeEncoder);

            return get_destination() ? get_destination() : get_source();
        });

    }
#else
    void Kernel::process() {
      OFX::Log::error(true, " ********** Plugin::Kernel have not been implemented yet...");
    }
#endif

    GridSize Kernel::get_thread_groups(int w, int h, int d) {
#ifdef __DEHANCER_USING_METAL__
        NSUInteger exeWidth = [get_pipeline() threadExecutionWidth];
        return MTLSizeMake((w + exeWidth - 1)/exeWidth, (NSUInteger)h, 1);
#else
        return {0,0,0};
#endif
    }

    GridSize Kernel::get_threads_per_threadgroup(int w, int h, int d) {
#ifdef __DEHANCER_USING_METAL__
        return MTLSizeMake([get_pipeline() threadExecutionWidth], 1, 1);
#else
        return {0,0,0};
#endif
    }

    Kernel::~Kernel() {
    }
}
