//
// Created by denn nevera on 2019-08-31.
//

#pragma once

#include "ofxCore.h"
#include "ofxsImageEffect.h"
#include "ofxsProcessing.h"

namespace imetalling{

    /**
     * Прокси объект к данным фрейма хостовой системы.
     * В данном случае OFX.
     */
    class Image {
    private:
        std::shared_ptr<OFX::Image> image_;
        const OfxRectI    bounds_;

    public:
        const int width;
        const int height;

        Image(OFX::Image* image);
        Image(const std::shared_ptr<OFX::Image>& image);
        Image(const Image& image);

        OFX::Image* get_ofx_image() { return image_.get(); };
        const OFX::Image* get_ofx_image() const { return image_.get(); };

        float* get_pixel_data();
        const float* get_pixel_data() const ;
    };
}

