//
// Created by denn nevera on 2019-07-20.
//

#pragma once

#import "Function.h"
#include <string>

namespace imetalling {

    /**
     * Класс процесига вычслительных ядер определяющих фильтрацию текущего фрейма
     */
    class Kernel: public Function {

    public:

        /// Сконструировать ядро
        /// \param command_queue - очеред команд
        /// \param kernel_name - имя метода MLS
        /// \param source - исходный фрейм
        /// \param destination - целевой фрейм после процессинга
        /// \param wait_until_completed - флаг ожидания завершения процсессинга
        Kernel(
                const void *command_queue,
                const std::string& kernel_name,
                const Texture& source,
                const Texture& destination,
                bool wait_until_completed = WAIT_UNTIL_COMPLETED
        );

        /// Опциональный хендлер
        FunctionHandler options_handler = nil;

        /// Запустить процессинг
        virtual void process();

        /// Установить текущие параметры ядра
        /// \param commandEncoder
        virtual void setup(CommandEncoder &commandEncoder);

        GridSize get_threads_per_threadgroup(int width, int height, int depth) override ;
        GridSize get_thread_groups(int width, int height, int depth) override ;

        /// Получить текущий источник
        /// \return
        [[nodiscard]] virtual Texture get_source() const { return source_;};

        /// Получить текущую целевую текстуру
        /// \return
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
