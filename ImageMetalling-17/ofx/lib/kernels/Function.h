//
// Created by denn nevera on 2019-07-20.
//

#pragma once

#include "GpuConfig.h"

#include <vector>
#include <unordered_map>
#include <mutex>
#include <functional>

namespace imetalling {

    typedef std::function<id<MTLTexture> (id<MTLComputeCommandEncoder>& compute_encoder)> FunctionHandler;

    /**
     * Function определяет доступ к функции GPU через слой Metal SDK.
     * Набором методов начинаем намекать на переносимость между хостовыми API.
     */
    class Function {

    public:

        struct ComputeSize {
            GridSize threadsPerThreadgroup;
            GridSize threadGroups;
        };

        static bool WAIT_UNTIL_COMPLETED;

    public:

        /// Конструктор функции исполнения GPU
        /// \param command_queue
        /// \param kernel_name
        /// \param wait_until_completed
        Function(const void *command_queue,
                 const std::string& kernel_name,
                 bool wait_until_completed = WAIT_UNTIL_COMPLETED);

        virtual ~Function();

        /// Определить сколько ядер GPU запускаем в группе
        /// \param width - ширина картинки
        /// \param height - высота
        /// \param depth - количество слоев
        /// \return размер сетки вычисления
        virtual GridSize get_threads_per_threadgroup(int width, int height, int depth);

        /// Определить сколько ядер групп ядер запускаем на GPU
        /// \param width - ширина картинки
        /// \param height - высота
        /// \param depth - количество слоев
        /// \return размер сетки вычисления
        virtual GridSize get_thread_groups(int width, int height, int depth);

        /// Получить выичислительные параметры для диспетчера ядер GPU
        /// \param texture
        /// \return размерность вычислений
        virtual ComputeSize get_compute_size(const Texture &texture);

        /// Получить ссылку на текущий пайпайн очереди команд
        /// \return pipeline
        id<MTLComputePipelineState> get_pipeline();

        /// Получить ссылку на очередь команд
        /// \return command queue
        inline id<MTLCommandQueue> get_command_queue() {
          return static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue_);
        }

        /// Получить ссылку на очередь команд
        /// \return command queue
        inline id<MTLCommandQueue> get_command_queue() const {
            return static_cast<id<MTLCommandQueue>>( (__bridge id) command_queue_);
        }
        /// Получить ссылку на контекст устройства
        /// \return MTL device
        inline id<MTLDevice> get_device() {
          return get_command_queue().device;
        }

        /// Запустить очередь команд на GPU
        /// \param block
        void execute(const FunctionHandler& block);

        /// Создать тектсуру привязанную к текущему устройству
        /// \param width - ширина картинки
        /// \param height - высота
        /// \param depth - количество слоев
        /// \return ссылка на текстуру
        Texture make_texture(size_t width, size_t height, size_t depth = 1);

        /// Создать тектсуру привязанную к устройству очереди команд
        /// \param command_queue
        /// \param width - ширина картинки
        /// \param height - высота
        /// \param depth - количество слоев
        /// \return ссылка на текстуру
        static Texture make_texture(const void *command_queue, size_t width, size_t height, size_t depth = 1);

        /// Установить ожидание завершения выполнения очереди команд на GPU
        /// \param enable
        virtual void enable_wait_completed(bool enable) { wait_until_completed_ = enable; };

        /// Получить флаг ожидания очереди команд
        /// \return статус
        virtual bool get_wait_completed() { return wait_until_completed_;}

    protected:
        bool wait_until_completed_;
        const void *command_queue_;
        std::string kernel_name_;

    public:
        typedef std::unordered_map<std::string, id<MTLComputePipelineState>> PipelineKernel;
        typedef std::unordered_map<id<MTLCommandQueue>, PipelineKernel> PipelineCache;

    private:

        std::vector<MTLTextureDescriptor*> text_descriptors_;
        id<MTLComputePipelineState> pipelineState_;
        static PipelineCache pipelineCache_;
        static std::mutex mutex_;

    };
}