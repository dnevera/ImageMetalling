//
//  DeviceCache.m
//  XPC Service
//
//  Created by Apple on 1/24/18.
//  Copyright (c) 2019 Apple Inc. All rights reserved.
//

///
/// TODO: platform specific
///

#include "DeviceCache.h"
#include "Log.h"

@class __FxMTLDeviceCacheItem__;

/**
 * Caching device command queue
 */
@interface MTLDeviceCache : NSObject
{
    NSMutableArray<__FxMTLDeviceCacheItem__*>*    deviceCaches;
}

+ (MTLDeviceCache*)deviceCache;

- (id<MTLDevice>)device;
- (id<MTLDevice>)deviceWithRegistryID:(uint64_t)registryID;
- (id<MTLCommandQueue>)commandQueueWithRegistryID:(uint64_t)registryID;
- (id<MTLCommandQueue>)commandQueue;
- (void)returnCommandQueueToCache:(id<MTLCommandQueue>)commandQueue;

@end


const NSUInteger    kMaxCommandQueues   = 16;
static NSString*    kKey_InUse          = @"InUse";
static NSString*    kKey_CommandQueue   = @"CommandQueue";

static MTLDeviceCache*   gDeviceCache    = nil;

@interface __FxMTLDeviceCacheItem__ : NSObject

@property (readonly)    id<MTLDevice>                           gpuDevice;
@property (retain)      NSMutableArray<NSMutableDictionary*>*   commandQueueCache;
@property (readonly)    NSLock*                                 commandQueueCacheLock;

- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (id<MTLCommandQueue>)getNextFreeCommandQueue;
- (void)returnCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (BOOL)containsCommandQueue:(id<MTLCommandQueue>)commandQueue;

@end

@implementation __FxMTLDeviceCacheItem__

- (instancetype)initWithDevice:(id<MTLDevice>)device;
{
    self = [super init];
    
    if (self != nil)
    {
        _gpuDevice = static_cast<id <MTLDevice>>([device retain]);
        
        _commandQueueCache = [[NSMutableArray alloc] initWithCapacity:kMaxCommandQueues];
        for (NSUInteger i = 0; (_commandQueueCache != nil) && (i < kMaxCommandQueues); i++)
        {
            NSMutableDictionary*   commandDict = [NSMutableDictionary dictionary];
            commandDict[kKey_InUse] = @NO;
            
            id<MTLCommandQueue> commandQueue    = [_gpuDevice newCommandQueue];
            commandDict[kKey_CommandQueue] = commandQueue;
            
            [_commandQueueCache addObject:commandDict];
            [commandQueue release];
        }
        
        if (_commandQueueCache != nil)
        {
            _commandQueueCacheLock = [[NSLock alloc] init];
        }
        
        if ((_gpuDevice == nil) || (_commandQueueCache == nil) || (_commandQueueCacheLock == nil))
        {
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_gpuDevice release];
    [_commandQueueCache release];
    [_commandQueueCacheLock release];

    [super dealloc];
}

- (id<MTLCommandQueue>)getNextFreeCommandQueue
{
    id<MTLCommandQueue> result  = nil;
    
    [_commandQueueCacheLock lock];
    NSUInteger  index   = 0;
    while ((result == nil) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueue    = _commandQueueCache[index];
        NSNumber*               inUse               = nextCommandQueue[kKey_InUse];
        if (![inUse boolValue])
        {
            nextCommandQueue[kKey_InUse] = @YES;
            result = nextCommandQueue[kKey_CommandQueue];
        }
        index++;
    }
    [_commandQueueCacheLock unlock];
    
    return result;
}

- (void)returnCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    [_commandQueueCacheLock lock];
    
    BOOL        found   = false;
    NSUInteger  index   = 0;
    while ((!found) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueuDict = _commandQueueCache[index];
        id<MTLCommandQueue>     nextCommandQueue    = nextCommandQueuDict[kKey_CommandQueue];
        if (nextCommandQueue == commandQueue)
        {
            found = YES;
            nextCommandQueuDict[kKey_InUse] = @NO;
        }
        index++;
    }
    
    [_commandQueueCacheLock unlock];
}

- (BOOL)containsCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    BOOL        found   = NO;
    NSUInteger  index   = 0;
    while ((!found) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueuDict = _commandQueueCache[index];
        id<MTLCommandQueue>     nextCommandQueue    = nextCommandQueuDict[kKey_CommandQueue];
        if (nextCommandQueue == commandQueue)
        {
            found = YES;
        }
        index++;
    }
    
    return found;
}

@end

@implementation MTLDeviceCache

+ (MTLDeviceCache*)deviceCache;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gDeviceCache = [[MTLDeviceCache alloc] init];
    });
    
    return gDeviceCache;
}

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();

        imetalling::log::print(" **** MTLCopyAllDevices: count = %i", [devices count]);


        deviceCaches = [[NSMutableArray alloc] initWithCapacity:devices.count];
        
        for (id<MTLDevice> nextDevice in devices)
        {
            imetalling::log::print(" **** MTLCopyAllDevices[%s]: id = %i size = %i, threads = %i",
                                   [nextDevice.name UTF8String],
                                   nextDevice.registryID,
                                   nextDevice.recommendedMaxWorkingSetSize,
                                   nextDevice.maxThreadsPerThreadgroup
            );

            __FxMTLDeviceCacheItem__*  newCacheItem    = [[[__FxMTLDeviceCacheItem__ alloc] initWithDevice:nextDevice]
                                                      autorelease];
            [deviceCaches addObject:newCacheItem];
        }
        
        [devices release];
    }
    
    return self;
}

- (void)dealloc
{
    [deviceCaches release];
    
    [super dealloc];
}

- (id<MTLDevice>)deviceWithRegistryID:(uint64_t)registryID
{
    for (__FxMTLDeviceCacheItem__* nextCacheItem in deviceCaches)
    {
        if (nextCacheItem.gpuDevice.registryID == registryID)
        {
            return nextCacheItem.gpuDevice;
        }
    }
    
    return nil;
}

- (id<MTLDevice>)device
{
    auto def_device = MTLCreateSystemDefaultDevice();

    for (__FxMTLDeviceCacheItem__* nextCacheItem in deviceCaches) {
        if (nextCacheItem.gpuDevice.registryID == def_device.registryID) {
            return nextCacheItem.gpuDevice;
        }
    }

    return nil;
}

- (id<MTLCommandQueue>)commandQueueWithRegistryID:(uint64_t)registryID;
{
    for (__FxMTLDeviceCacheItem__* nextCacheItem in deviceCaches)
    {
        if ((nextCacheItem.gpuDevice.registryID == registryID))
        {
            return [nextCacheItem getNextFreeCommandQueue];
        }
    }
    
    
    // Didn't find one, so create one with the right settings
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
    id<MTLDevice>   device  = nil;
    for (id<MTLDevice> nextDevice in devices)
    {
        if (nextDevice.registryID == registryID )
        {
            device = nextDevice;
            break;
        }
    }
    
    id<MTLCommandQueue>  result  = nil;
    if (device != nil)
    {
        __FxMTLDeviceCacheItem__*   newCacheItem    = [[[__FxMTLDeviceCacheItem__ alloc] initWithDevice:device]
                                                   autorelease];
        if (newCacheItem != nil)
        {
            [deviceCaches addObject:newCacheItem];
            result = [newCacheItem getNextFreeCommandQueue];
        }
    }
    [devices release];
    
    return result;
}

- (id<MTLCommandQueue>)commandQueue;
{
    auto def_device = MTLCreateSystemDefaultDevice();

    for (__FxMTLDeviceCacheItem__* nextCacheItem in deviceCaches)
    {
        if ((nextCacheItem.gpuDevice.registryID == def_device.registryID))
        {
            return [nextCacheItem getNextFreeCommandQueue];
        }
    }


    // Didn't find one, so create one with the right settings
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
    id<MTLDevice>   device  = nil;
    for (id<MTLDevice> nextDevice in devices)
    {
        if (nextDevice.registryID == def_device.registryID)
        {
            device = nextDevice;
            break;
        }
    }

    id<MTLCommandQueue>  result  = nil;
    if (device != nil)
    {
        __FxMTLDeviceCacheItem__*   newCacheItem    = [[[__FxMTLDeviceCacheItem__ alloc] initWithDevice:device]
                autorelease];
        if (newCacheItem != nil)
        {
            [deviceCaches addObject:newCacheItem];
            result = [newCacheItem getNextFreeCommandQueue];
        }
    }
    [devices release];

    return result;
}

- (void)returnCommandQueueToCache:(id<MTLCommandQueue>)commandQueue;
{
    for (__FxMTLDeviceCacheItem__* nextCacheItem in deviceCaches)
    {
        if ([nextCacheItem containsCommandQueue:commandQueue])
        {
            [nextCacheItem returnCommandQueue:commandQueue];
            break;
        }
    }
}

@end

namespace imetalling {

    gpu_device_cache::gpu_device_cache(): device_cache_([MTLDeviceCache deviceCache]) {}

    void*  gpu_device_cache::get_device(uint64_t reg_id) {
        return [static_cast<MTLDeviceCache*>(device_cache_) deviceWithRegistryID:reg_id];
    }

    void*  gpu_device_cache::get_default_device() {
        return [static_cast<MTLDeviceCache*>(device_cache_) device];
    }

    void* gpu_device_cache::get_command_queue(uint64_t reg_id) {
        return [static_cast<MTLDeviceCache*>(device_cache_) commandQueueWithRegistryID:reg_id];
    }

    void* gpu_device_cache::get_default_command_queue() {
        return [static_cast<MTLDeviceCache*>(device_cache_) commandQueue];
    }
    
    void gpu_device_cache::return_command_queue(const void *q) {
        [static_cast<MTLDeviceCache*>(device_cache_) returnCommandQueueToCache:static_cast<id<MTLCommandQueue>>(q)];
    }
}
