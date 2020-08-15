//
//  DeviceCache.h
//  XPC Service
//
//  Created by Apple on 1/24/18.
//  Copyright (c) 2019 Apple Inc. All rights reserved.
//

#pragma once

#include "GpuConfig.h"
#include "dehancer/Common.h"

namespace imetalling {

    struct gpu_device_cache {
    public:
        gpu_device_cache();

        virtual void* get_device(uint64_t id) ;
        virtual void* get_default_device() ;
        virtual void* get_command_queue(uint64_t id) ;
        virtual void* get_default_command_queue() ;
        virtual void return_command_queue(const void *q)  ;

        virtual ~gpu_device_cache() = default;
        
    private:
        void* device_cache_;
    };

    class DeviceCache: public dehancer::Singleton<gpu_device_cache>{
       public:
           DeviceCache() = default;
       };
}
