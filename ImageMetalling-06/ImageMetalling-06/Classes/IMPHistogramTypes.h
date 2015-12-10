//
//  IMPHistogramBuffers.h
//  ImageMetalling-05
//
//  Created by denis svinarchuk on 29.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPHistogramBuffers_h
#define IMPHistogramBuffers_h

#include <stdlib.h>
#include "DPCore3.h"
#include "IMPHistogramConstatnts.h"

//
// Чтобы не заморачиваться сложносочиненными отношениями с памятью в Swift
// складируем все линейные (с непрерывным размещением значений переменных памяти)
// струрктуры данных в одном месте.
//
// По идее этот заголовок можно было бы разделить между MSL наших кернел-функций и Swift кодом,
// но мы будем использовать специальный тип atomic_uint для выполнения неблокируемго счета
// и я пока не нашел удобного способа сбриджевать структуры содержащие это тип между MSL/Objc/Swift
// без выдачи ошибок компилятором. Поэтому просто пробублируем определение.
//


///
/// Контейнер для складывания результатов счета бинов интенсивностей представленных целыми числами.
/// Предполагаеся, что контейнер хранит как минимум 4 массива распределений в различных каналах различных цветовых пространств.
/// Например, для RGB можно хранить channel[0-2] распределения r/g/b соответственно, в channel[3] можно хранить распределения яркостного канала.
/// В качестве яркостного канала можно использовать канал Y из YCbCr, однозначно определяемый из пространства RGB простым скалярным
/// перемножением и наоборот.
/// Для Цветовых пространств HSV/HSL/CIELab/YUV/YCbCr и т.п. будет неопределен.
///
typedef struct {
    uint channel[kIMP_HistogramChannels][kIMP_HistogramSize];
}IMPHistogramBuffer;

///
/// Буфер частичных расчитанных гистограм.
///
typedef IMPHistogramBuffer IMPHistogramPartialBuffers[kIMP_HistogramSize];


#endif /* IMPHistogramBuffers_h */
