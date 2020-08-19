//
// Created by denn nevera on 2019-08-31.
//

#include "Image.h"

namespace imetalling {

    Image::Image(const imetalling::Image &image):
    image_(image.image_),
    bounds_(image.bounds_),
    width(image.width),
    height(image.height)
    {}

    Image::Image(const std::shared_ptr<OFX::Image>& image):
    image_(image),
    bounds_(image ? image->getBounds() : (OfxRectI){0,0,0,0}),
    width(bounds_.x2 - bounds_.x1),
    height(bounds_.y2 - bounds_.y1)
    {
    }

    Image::Image(OFX::Image* image):
            image_(image),
            bounds_(image ? image->getBounds() : (OfxRectI){0,0,0,0}),
            width(bounds_.x2 - bounds_.x1),
            height(bounds_.y2 - bounds_.y1)
    {
    }

    float* Image::get_pixel_data() {
        return static_cast<float *>(image_ ? image_->getPixelData() : nullptr);
    }

    const float* Image::get_pixel_data() const {
        return static_cast<const float *>(image_ ? image_->getPixelData() : nullptr);
    }
}