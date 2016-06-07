//
//  IMPPhotoEditor.swift
//  ImageMetalling-11
//
//  Created by denis svinarchuk on 02.06.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

import IMProcessing

///
/// Контейнер геометрических операцие над изобраением и 
/// расширений для анимационного дивжка UIDynamicAnimator
///
public class IMPPhotoEditor: IMPFilter, UIDynamicItem{
       
    //
    // Прикинемся винтажными инженерами и будем рассуждать в рамках объектов темной комнаты
    // 1. Фото-пластина (или фото-отпечаток, но пластина как-то еще винтажнее)
    // 2. Фото-ножницы
    // 3. Светлый стол или просмотровщик
    //
    // Фото пластину можно вращать премещать по ней проекцию изображения и увеличивать/уменьшать.
    // 
    // Ножницами резать то что напечатали. Пластину можно перемщать по смотровому столу. 
    // Стол оборудуем динамическими движками для более удобного перемещения. 
    //
    
    /// Трансформирующией операции
    lazy var photo:IMPTransformFilter = {
        return IMPTransformFilter(context: self.context)
    }()
    
    /// Отрезание лишнего
    lazy var cropFilter:IMPCropFilter = {
        return IMPCropFilter(context:self.context)
    }()

    public required init(context: IMPContext) {
        super.init(context: context)
        /// конструктор цепочки геометрических фильтров
        addFilter(photo)
        addFilter(cropFilter)
    }
    
    //
    // Коэффициент масштабирования трансформированного четерехугольника вписанного в модель 
    // фото-пластины
    //
    var currentCropFactor:Float = 1
    func updateCropFactor() {
        currentCropFactor = IMPPhotoPlate(aspect: aspect).scaleFactorFor(model: model)
        let minScale = IMPPhotoPlate(aspect: aspect).scaleFactorFor(model: IMPTransfromModel.with(model: model, angle: IMPTransfromModel.left45, scale:float3(1)))
        if currentCropFactor < minScale {
            currentCropFactor = minScale
        }
        currentCropFactor *= scale
    }
    
    //
    // Размер результирующей фото-пластиный
    //
    var currentCropRegion:IMPRegion {
        var offset  = (1 - currentCropFactor ) / 2
        let aspect  = crop.width/crop.height
        if  offset < 0 { offset = 0 }
        let offsetx = offset * aspect
        let offsety = offset
        return IMPRegion(left: offsetx+crop.left, right: offsetx+crop.right, top: offsety+crop.top, bottom: offsety+crop.bottom)
    }

    ///
    /// Фото-ножницы
    ///
    public var crop = IMPRegion() {
        didSet{
            cropFilter.region = currentCropRegion
        }
    }
    
    ///
    /// Цвет заливки полей пластины
    ///
    public var backgroundColor:IMPColor {
        get {
            return photo.backgroundColor
        }
        set {
            photo.backgroundColor = newValue
        }
    }
    
    ///
    /// Соотношение сторон пластины
    ///
    public var aspect:Float {
            return photo.aspect
    }
    
    ///
    /// Модель пластины в терминах матричных операций (тут уж винтажем не прикроемся...)
    ///
    public var model:IMPTransfromModel {
        return photo.model
    }
    
    ///
    /// Операция перемещения проекции по фотопластине
    ///
    public var translation:float2 {
        set{
            photo.translation = newValue
        }
        get {
            return photo.translation
        }
    }

    ///
    /// Угол поворота пластиный в пространстве
    ///
    public var angle:float3 {
        set {
            photo.angle = newValue
            updateCropFactor()
            cropFilter.region = currentCropRegion
        }
        get{
            return photo.angle
        }
    }

    ///
    /// Кожффициент увеличения
    ///
    public var scale:Float {
        set {
            photo.scale(factor: newValue)
            updateCropFactor()
            cropFilter.region = currentCropRegion
        }
        get{
            return photo.scale.x
        }
    }
    
    ///
    /// Полезный атрибут
    ///
    public var cropedFactor:Float {
        return IMPPhotoPlate(aspect: aspect).scaleFactorFor(model: model) * scale
    }
    
    ///
    /// Окно проекции в просмотровщике
    ///
    public var viewPort:CGRect? = nil

    ///
    /// Для вычисления выхода за границы нам нужно получить вектор сдвига
    ///
    public var outOfBounds:float2 {
        get {
            //
            // Создаем четырехугольник с установленным кропом и соотношением сторон
            //
            let cropQuad = IMPQuad(region:cropFilter.region, aspect: aspect, scale: 1)
            
            //
            // Содаем четырех-угольную модель пластины с учетом соотношения сторон и прикладываем к ней модель трансформации.
            // Снимаем у модели координаты вершин в формате структур четырех-угольник
            //
            let transformedQuad = IMPPhotoPlate(aspect: aspect).quad(model: model)
            
            //
            // Получаем смещение нашего кропа относительно трансформированной пластины -
            // по сути получаем величину движения на которое нам надо сдвинуть пластину на столе фото-ножниц
            //
            return IMPTransfromModel.with(angle: -angle).transform(point: transformedQuad.translation(quad: cropQuad))
        }
    }
    
    //// MARK - Поддержка протокола динамических айтемов движка UIDynamicAnimator
    
    ///
    /// Центр пластины привязываем к левому нижнему углу
    ///
    public var center:CGPoint {
        set{
            if let size = viewPort?.size {
                translation = float2(newValue.x.float,newValue.y.float) / (float2(size.width.float,size.height.float)/2)
            }
        }
        get {
            if let size = viewPort?.size {
                return CGPoint(x: translation.x.cgfloat*size.width/2, y: translation.y.cgfloat*size.height/2)
            }
            return CGPoint()
        }
    }
    
    ///
    /// Фиксируем относительный размер в относительных координатах для определения отношения 
    /// с другими объектами
    ///
    public var bounds:CGRect {
        get {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
    }
    
    ///
    /// Трансформации оставляем пустыми - будем управлять ими самостоятельно, тем более что UIDynamics 
    /// по факту работает только с поворотами
    ///
    public var transform = CGAffineTransform()
    
    
    ///
    /// Якорь, к которому цепляем viewPort просмотровщика
    ///
    public var anchor:CGPoint?  {
        get {
            guard let size = viewPort?.size else { return nil }
            
            var offset = -outOfBounds
            
            if abs(offset.x) > 0 || abs(offset.y) > 0 {
                
                offset = (self.translation+offset) * float2(size.width.float,size.height.float)/2
                
                return CGPoint(x: offset.x.cgfloat, y: offset.y.cgfloat)
            }
            
            return nil
        }
    }
}
