//
// Created by denn nevera on 2019-07-20.
//


#include "Function.h"
#include "PluginPaths.h"
#include "ofxsLog.h"

namespace imetalling {

    std::mutex Function::mutex_;
    Function::PipelineCache Function::pipelineCache_ = Function::PipelineCache();

    bool Function::WAIT_UNTIL_COMPLETED = false;

    id<MTLComputePipelineState> make_pipeline(id<MTLDevice>& device, const std::string& kernel_name) {

      id<MTLComputePipelineState> pipelineState = nil;
      id<MTLLibrary>              metalLibrary;     // Metal library
      id<MTLFunction>             kernelFunction;   // Compute kernel

      NSError* err;

      auto libpath =  get_metallib_path();

      if (libpath.empty()){
        if (!(metalLibrary    = [device newDefaultLibrary]))
        {
          OFX::Log::error(true, " *** Function::make_pipeline error: new default library cannot be created...");
          return nil;
        }
      }
      else
      if (!(metalLibrary    = [device newLibraryWithFile:@(libpath.c_str()) error:&err]))
      {
        OFX::Log::error(true, " *** Function::make_pipeline error: new library %s cannot be created...", libpath.c_str());
        return nil;
      }

      if (!(kernelFunction  = [metalLibrary newFunctionWithName:[NSString stringWithUTF8String:kernel_name.c_str()]]))
      {
        OFX::Log::error(true, " *** Function::make_pipeline error: new kernel function %s cannot be created for %s lib...", kernel_name.c_str(), libpath.c_str());
        [metalLibrary TEXTURE_RELEASE];
        return nil;
      }


      if (!(pipelineState  = [device newComputePipelineStateWithFunction:kernelFunction error:&err]))
      {
        OFX::Log::error(true, " *** Function::make_pipeline error: new pipeline state cannot be created for %...", kernel_name.c_str());
        [metalLibrary TEXTURE_RELEASE];
        [kernelFunction TEXTURE_RELEASE];
        return nil;
      }

      //Release resources
      [metalLibrary TEXTURE_RELEASE];
      [kernelFunction TEXTURE_RELEASE];

      return pipelineState;
    }

    Function::Function(const void *command_queue, const std::string& kernel_name, bool wait_until_completed):
            wait_until_completed_(wait_until_completed),
            command_queue_(command_queue),
            kernel_name_(kernel_name)
    {
      std::unique_lock<std::mutex> lock(Function::mutex_);

      id<MTLCommandQueue>            queue  = get_command_queue();
      id<MTLDevice>                  device = get_device();

      const auto it = Function::pipelineCache_.find(queue);

      if (it == Function::pipelineCache_.end())
      {
        if (!(pipelineState_  = make_pipeline(device, kernel_name_)))
        {
          return;
        }
        Function::pipelineCache_[queue][kernel_name_] = pipelineState_;
      }
      else
      {

        const auto kernel_pit = it->second.find(kernel_name_);

        if (kernel_pit == it->second.end()) {
          if (!(pipelineState_  = make_pipeline(device, kernel_name_)))
          {
            return;
          }
          Function::pipelineCache_[queue][kernel_name_] = pipelineState_;
        }
        else {
          pipelineState_ = kernel_pit->second;
        }
      }
    }

    id<MTLComputePipelineState> Function::get_pipeline() {
      return pipelineState_;
    }

    void Function::execute(const FunctionHandler& block){

      id<MTLCommandQueue> queue = static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue_);

      id <MTLCommandBuffer> commandBuffer = [queue commandBuffer];

      id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
      [computeEncoder setComputePipelineState:pipelineState_];

      id<MTLTexture> texture = block(computeEncoder);

      auto grid = get_compute_size(texture);

      [computeEncoder dispatchThreadgroups:grid.threadGroups threadsPerThreadgroup: grid.threadsPerThreadgroup];
      [computeEncoder endEncoding];

      if (wait_until_completed_ || WAIT_UNTIL_COMPLETED) {
        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder synchronizeTexture:texture slice:0 level:0];
        [blitEncoder endEncoding];
      }

      [commandBuffer commit];

      if (wait_until_completed_ || WAIT_UNTIL_COMPLETED)
        [commandBuffer waitUntilCompleted];
    }

    GridSize Function::get_threads_per_threadgroup(int w, int h, int d) {
      return MTLSizeMake(4, 4, d == 1 ? 1 : 4);
    }

    GridSize Function::get_thread_groups(int w, int h, int d) {
      auto tpg = get_threads_per_threadgroup(w, h, d);
      return MTLSizeMake( (NSUInteger)(w/tpg.width), (NSUInteger)(h == 1 ? 1 : h/tpg.height), (NSUInteger)(d == 1 ? 1 : d/tpg.depth));
    }

    Function::ComputeSize Function::get_compute_size(const Texture &texture) {
      if ((int)texture.depth==1) {
        auto exeWidth = [pipelineState_ threadExecutionWidth];
        auto threadGroupCount = MTLSizeMake(exeWidth, 1, 1);
        auto threadGroups     = MTLSizeMake((texture.width + exeWidth - 1)/exeWidth, texture.height, 1);
        return  {
                .threadsPerThreadgroup = threadGroupCount,
                .threadGroups = threadGroups
        };

      } else {
        auto threadsPerThreadgroup = get_threads_per_threadgroup((int)texture.width,(int)texture.height,(int)texture.depth) ;
        auto threadgroups  = get_thread_groups((int)texture.width,(int)texture.height,(int)texture.depth);
        return  {
                .threadsPerThreadgroup = threadsPerThreadgroup,
                .threadGroups = threadgroups
        };
      }
    }

    Texture Function::make_texture(size_t width, size_t height, size_t depth) {
      return Function::make_texture(command_queue_, width, height, depth);
    }

    Texture Function::make_texture(const void *command_queue, size_t width, size_t height, size_t depth) {

      id<MTLCommandQueue> queue = static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue);

      if (height == 1 && depth == 1){
        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor new];

        descriptor.textureType = MTLTextureType1D;
        descriptor.width  = (NSUInteger)width;
        descriptor.height = 1;
        descriptor.depth  = 1;
        descriptor.pixelFormat = MTLPixelFormatR32Float;
        descriptor.usage = MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsagePixelFormatView|MTLTextureUsageRenderTarget;

        return [queue.device newTextureWithDescriptor:descriptor];
      }
      else if (depth == 1) {
        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor
                texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA32Float
                                             width:width
                                            height:height
                                         mipmapped:false];

        descriptor.storageMode = MTLStorageModeManaged;

        return [queue.device newTextureWithDescriptor:descriptor];
      }
      else {

        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor new];

        descriptor.textureType = MTLTextureType3D;
        descriptor.width  = (NSUInteger)width;
        descriptor.height = (NSUInteger)height;
        descriptor.depth  = (NSUInteger)depth;
        descriptor.pixelFormat = MTLPixelFormatRGBA32Float;
        descriptor.arrayLength = 1;
        descriptor.mipmapLevelCount = 1;
        descriptor.storageMode = MTLStorageModeManaged;

        return [queue.device newTextureWithDescriptor:descriptor];
      }
    }

    Function::~Function() {}
}
