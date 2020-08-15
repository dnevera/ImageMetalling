//
// Created by denn nevera on 27/03/2020.
//

#pragma once

#include <string>

namespace dehancer {

    /**
      * MUST BE defined in certain plugin module
      * @return metal lib path.
      */
    extern std::string get_metallib_path();

    /**
     * Must be defined in certain plugin
     * @return string
     */
    extern std::string get_installation_path();
}
