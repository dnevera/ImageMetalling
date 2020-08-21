//
// Created by denn nevera on 19/08/2020.
//

#pragma once

namespace imetalling::falsecolor {

    /***
     * Публикуемые глобальные свайства OFX плагина
     */

    constexpr const char *id = "com.imetalling.false_color";
    constexpr const char *name = "IM False Color";
    constexpr const char *description = "Image Metalling False Color OFX Plugin is a tool for exposure monitoring and shot matching.";
    constexpr const char *grouping = "Image Metalling";
    constexpr const int  versionMajor = 1;
    constexpr const int  versionMinor = 0;

    namespace controls {
        /**
         * Идентификатор чекбокса используется при создании контейнера сьюта (Factory)
         * и для получения текущего значения в наследниках ImageEffect, например
         */
        constexpr const char *false_color_enabled_check_box = "false_color_enabled_check_box";
    }

}