//
// Created by denn nevera on 2019-07-20.
//

#pragma once

#include "GpuConfig.h"

#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>
#include <functional>

namespace dehancer {

#ifdef __DEHANCER_USING_METAL__
    typedef std::function<id<MTLTexture> (id<MTLComputeCommandEncoder>& compute_encoder)> FunctionHandler;
#define DEHANCER_RELEASE release
#endif

    class Function {

    public:

        struct ComputeSize {
            GridSize threadsPerThreadgroup;
            GridSize threadGroups;
        };

        static bool WAIT_UNTIL_COMPLETED;

    public:

        Function(const void *command_queue, const std::string& kernel_name, bool wait_until_completed = WAIT_UNTIL_COMPLETED);

        virtual ~Function();

        virtual GridSize get_threads_per_threadgroup(int w, int h, int d);
        virtual GridSize get_thread_groups(int w, int h, int d);
        virtual ComputeSize get_compute_size(const Texture &texture);

#ifdef __DEHANCER_USING_METAL__

        id<MTLComputePipelineState> get_pipeline();

        inline id<MTLCommandQueue> get_command_queue() {
          return static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue_);
        }

        inline id<MTLCommandQueue> get_command_queue() const {
            return static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue_);
        }

        inline id<MTLDevice> get_device() {
          return get_command_queue().device;
        }

        void execute(const FunctionHandler& block);
#endif

        Texture make_texture(size_t width, size_t height, size_t depth = 1);
        static Texture make_texture(const void *command_queue, size_t width, size_t height, size_t depth = 1);

        virtual void enable_wait_completed(bool enable) { wait_until_completed_ = enable; };
        virtual bool get_wait_completed() { return wait_until_completed_;}

    protected:
        bool wait_until_completed_;
        const void *command_queue_;
        std::string kernel_name_;

#ifdef __DEHANCER_USING_METAL__
    public:
        typedef std::unordered_map<std::string, id<MTLComputePipelineState>> PipelineKernel;
        typedef std::unordered_map<id<MTLCommandQueue>, PipelineKernel> PipelineCache;

    private:

        std::vector<MTLTextureDescriptor*> text_descriptors_;
        id<MTLComputePipelineState> pipelineState_;
        static PipelineCache pipelineCache_;
        static std::mutex mutex_;
#endif

    };
}