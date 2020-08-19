//
// Created by denn nevera on 12/05/2020.
//

#pragma once
#include <string>
#include <vector>
#include <cstdint>

#ifdef __APPLE__
#import <simd/simd.h>
#endif

namespace imetalling {

    /**
     * Настройка умолчаний
     */
    struct Defaults {
        ///
        /// Таблица трансформации уровней сигнала исходного изображения в карту False Color
        ///
        static std::vector<simd::float3> false_color_map;
    };
}