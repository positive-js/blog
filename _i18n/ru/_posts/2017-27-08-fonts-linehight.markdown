---
layout: post
title:  "Deep dive CSS: font metrics, line-height and vertical-align"
date:   2017-09-03
description: font metrics, line-height and vertical-align
categories:
- CSS
- fonts
- 30 мин чтения
permalink: css-font-metrics-line-height-and-vertical-align
---

```line-height``` и ```vertical-align``` — это простые свойства CSS. Настолько простые, что большинство из нас уверены, что понимают, как они работают и как их использовать. К сожалению, это не так — на самом деле они, пожалуй, являются самыми сложными свойствами, поскольку играют важную роль в создании малоизвестной особенности CSS под названием **«строчный контекст форматирования»** (inline formatting context).

Например, ```line-height``` можно задать в виде длины или безразмерного значения, но его значение по умолчанию — ```normal``` (стандартное). Хорошо, но что значит «стандартное»? Зачастую пишут, что это (как правило) 1, или, может быть, 1,2. Даже в [спецификации CSS нет четкого ответа на данный вопрос](https://www.w3.org/TR/CSS2/visudet.html#propdef-line-height).

Нам известно, что безразмерное значение ```line-height``` зависит от значения ```font-size```, но проблема в том, что ```font-size: 100px``` выглядит по-разному для разных гарнитур. В связи с этим возникает вопрос: всегда ли ```line-height``` будет одинаковым или может различаться? Действительно ли это значение находится в промежутке от 1 до 1,2? А как ```vertical-align``` влияет на ```line-height```?

Давайте углубимся в не самый простой механизм CSS...

## Начнем с разговора о ```font-size``` 

Рассмотрим этот простой HTML-код с тегом ```<p>```, содержащим три элемента ```<span>```, каждый из которых со своим font-family:

```html
<p>
    <span class="a">Ba</span>
    <span class="b">Ba</span>
    <span class="c">Ba</span>
</p>
```

```css
p  { font-size: 100px }
.a { font-family: Helvetica }
.b { font-family: Gruppo }
.c { font-family: Catamaran }
```

При использовании одного и того же ```font-size``` в разных гарнитурах высота получается различной:

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/font-size.png){: .center}

Даже если нам известно об этой особенности, почему ```font-size: 100px``` не создает элементы высотой 100px? Я измерил эти значения: Helvetica — 115px, Gruppo — 97px и Catamaran — 164px.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/font-size-line-height.png){: .center}

Хотя на первый взгляд это выглядит несколько странно, все вполне ожидаемо — **причина в самом шрифте**.Как это работает:
* Шрифт задает свой [em-квадрат](http://designwithfontforge.com/en-US/The_EM_Square.html) (em-square) (он же UPM, units per em — единиц на кегельную площадку) — своего рода площадку, в рамках которой будет рисоваться каждый символ. В этом квадрате для измерения используются относительные единицы, и, как правило, для него принимаются размеры 1000 единиц. Хотя также бывает 1024, 2048 или иное количество единиц.
* В зависимости от количества относительных единиц задаются метрики шрифтов, такие как высота верхних и нижних выносных элементов (ascender/descender), прописных и строчных букв. Некоторые значения могут выходить за рамки em-квадрата.
* В браузере относительные единицы масштабируются до необходимого ```font-size```.

Возьмем шрифт Catamaran и откроем его в [FontForge](https://fontforge.github.io/en-US/) для получения метрик:
* em-квадрат принят за 1000 единиц;
* высота верхних выносных элементов составляет 1100 единиц, а нижних — 540. 

После нескольких проверок выяснилось, что браузеры на Mac OS используют значения HHead Ascent/Descent, а на Windows — Win Ascent/Descent (эти значения могут различаться). Помимо этого, высота прописных букв Capital Height составляет 680 единиц, а строчных X height — 485.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/font-forge-metrics.png){: .center}

Таким образом, шрифт Catamaran использует 1100 + 540 единиц в em-квадрате, состоящем из 1000 единиц, и поэтому при размере font-size: 100px получается высота 164px. Данная вычисленная высота определяет **область содержимого (content-area) элемента** (этот термин будет использоваться далее по тексту). Можете считать область содержимого областью, к которой применяется свойство ```background```.

Можно также предположить, что высота прописных букв составляет 68px (680 единиц), а строчных (x-высота) — 49px (485 единиц). В результате 1ex = 49px и 1em = 100px, а не 164px (к счастью, em зависит от ```font-size```, а не от вычисленной высоты).

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/upm-px-equivalent.png){: .center}

Прежде чем нырнуть глубже, рассмотрим основные моменты, с которыми придется столкнуться. Элемент ```<p>``` при отображении на экране может состоять из нескольких строк с соответствующей шириной. Каждая строка состоит из одного или нескольких строчных элементов (inline elements)(HTML-тегов или анонимных строчных элементов для текстового содержимого) и называется контейнером строки (line-box). **Высота контейнера строки зависит от высот его дочерних элементов**. То есть браузер вычисляет высоту каждого строчного элемента, а по ней — высоту контейнера строки (от самой верхней до самой нижней точки ее дочерних элементов). В результате высоты контейнера строки всегда достаточно, чтобы вместить все его дочерние элементы (по умолчанию).

_Каждый HTML-элемент на самом деле представляет собой стопку контейнеров строки. Если вам известна высота всех контейнеров строки, то известна и высота элемента._

При изменении приведенного выше HTML-кода следующим образом:
```html
<p>
    Good design will be better.
    <span class="a">Ba</span>
    <span class="b">Ba</span>
    <span class="c">Ba</span>
    We get to make a consequence.
</p>
```
будет сгенерировано три контейнера строки:
* в первом и последнем будет по одному анонимному строчному элементу (текстовое содержимое);
* во втором будет два анонимных строчных элемента и 3 элемента ```<span>```.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/line-boxes.png){: .center}

Отчетливо видно, что второй контейнер строки больше остальных по высоте из-за вычисленной области содержимого его дочерних элементов, точнее того, который использует шрифт Catamaran.

**Сложным моментом в создании контейнера строки является то, что мы, по сути, не можем ни увидеть, ни управлять им через CSS.** Даже применение фона к ```::first-line``` не помогает отобразить высоту первого контейнера строки.

## ```line-height```: о проблемах и прочих вопросах

До этого момента я ввел два понятия — область содержимого и контейнер строки. Если вы внимательно читали, то заметили, что высота контейнера строки вычисляется на основании высоты его дочерних элементов, но не говорил, что на основании высоты области содержимого его дочерних элементов. А это большая разница.

Даже если это может показаться странным, **у строчного элемента есть две различных высоты: высота области содержимого и высота виртуальной области (virtual-area)** (я сам придумал термин «виртуальная область», поскольку эту высоту мы увидеть не можем; в спецификации этого термина вы не найдете).
* Высота области содержимого определяется метриками шрифта (как мы уже видели ранее).
* Высота виртуальной области (virtual-area) представляет собой ```line-height```, и это — высота, которая **используется для вычисления высоты контейнера строки**.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/line-height.png){: .center}

Кроме того, сказанное опровергает распространенное мнение о том, что ```line-height``` — это расстояние между базовыми линиями (baseline). В CSS это не так.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/line-height-yes-no.png){: .center}

_В других редакторских программах это может быть расстоянием между базовыми линиями. Например, в Word и Photoshop это так и есть. Основная разница в том, что в CSS это расстояние есть и для первой строки_.

Вычисленная разница в высоте между виртуальной областью и областью содержимого называется интерлиньяж (leading). Одна половина интерлиньяжа добавляется сверху к области содержимого, а вторая — снизу. Поэтому область содержимого всегда находится по центру виртуальной области.

В зависимости от вычисленного значения ```line-height``` (виртуальная область) может быть равной, больше или меньше области содержимого. Если виртуальная область меньше, то значение интерлиньяжа отрицательное и контейнер строки визуально меньше своих дочерних элементов по высоте.

Есть и другие виды строчных элементов:
* замещаемые строчные элементы (```<img>```, ```<input>```, ```<svg>``` и т. д.);
* ```inline-block``` и все элементы типа ```inline-*```;
* строчные элементы, которые задействованы в особом контексте форматирования (например, в элементе flexbox все flex-компоненты блокофицируются).

Для таких особых строчных элементов высота рассчитывается на основе их свойств ```height```, ```margin``` и ```border```. Если для height указано значение auto, то применяется ```line-height```, и высота области содержимого равна line-height.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/line-height-inline-block.png){: .center}

И все же проблема остается прежней: каково значение normal для ```line-height```? Ответ на этот вопрос, как и в случае вычисления области содержимого, нужно искать среди метрик шрифта.
Итак, вернемся к FontForge. Размер em-квадрата для Catamaran равняется 1000, но мы наблюдаем много значений для верхних и нижних выносных элементов:

* Общие значения Ascent/Descent: высота верхнего выносного элемента — 770, нижнего — 230. Используются для создания символов (таблица «OS/2»).
* Метрики Ascent/Descent: высота верхнего выносного элемента — 1100, нижнего — 540. Используются для определения высоты области содержимого (таблицы «hhea» и «OS/2»).
* Метрика Line Gap (междустрочный интервал). Используется для определения ```line-height: normal```, данное значение прибавляется к метрикам Ascent/Descent (таблица «hhea»).

В нашем случае шрифт Catamaran определяет, что междустрочный интервал равен 0 единиц, и, таким образом, ```line-height: normal``` будет равняться области содержимого, которая составляет 1640 единиц или 1,64.

В качестве сравнения: для шрифта Arial em-квадрат равен 2048 единиц, высота верхнего выносного элемента — 1854, нижнего — 434, междустрочный интервал — 67. Таким образом, при ```font-size: 100px``` область содержимого составит 112px (1117 единиц), а значение ```line-height: normal``` — 115px (1150 единиц или 1,15). Все эти метрики индивидуальны для каждого шрифта и задаются дизайнером шрифта.

Следовательно, задавать ```line-height: 1``` неэффективно. Напомню вам, что безразмерные значения зависят от ```font-size```, а не от области содержимого, а то, что размер области содержимого превышает размер виртуальной области, является причиной множества наших проблем.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/line-height-1.png){: .center}

Но причина не только в ```line-height: 1```. Если уж на то пошло, из 1117 шрифтов, установленных на моем компьютере (да, я установил все шрифты из Google Web Fonts), у 1059 шрифтов, то есть в 95%, вычисленный показатель ```line-height``` больше 1. Вообще, их вычисленный показатель ```line-height``` варьируется от 0,618 до 3,378. (Вам не показалось — 3,378!)

Небольшие подробности по поводу расчета ```line-box```:

* Для строчных элементов — padding и border увеличивают область фона, но не высоту области содержимого (и не высоту контейнера строки). Поэтому область содержимого — это не всегда то, что видно на экране. От ```margin-top``` и ```margin-bottom``` нет никакого эффекта.
* Для замещаемых строчных элементов, элементов типа ```inline-block``` и блокофицированных строчных элементов — ```padding```, ```margin``` и ```border``` увеличивают ```height``` и, следовательно, высоту области содержимого и контейнера строки.

## vertical-align: то свойство, которое управляет всем
Я еще не останавливался подробно на свойстве ```vertical-align```, хотя оно является основным фактором для вычисления высоты контейнера строки. Можно даже сказать, что ```vertical-align``` может играть ведущую роль в строчном контексте форматирования.

Его значение по умолчанию — ```baseline```. Помните такие метрики шрифта, как высота верхнего и нижнего выносных элементов (ascender/descender)? Эти значения определяют, где находится базовая линия и, следовательно, соотношение между верхней и нижней частями. Поскольку соотношение между верхним и нижним выносными элементами редко бывает 50/50, это может приводить к неожиданным результатам, например с элементами того же уровня.

Начнем с такого кода:

```html
<p>
    <span>Ba</span>
    <span>Ba</span>
</p>
```
```css
p {
    font-family: Catamaran;
    font-size: 100px;
    line-height: 200px;
}
```

Тег ```<p>``` с двумя одноуровневыми элементами ```<span>```, наследующими ```font-family```, ```font-size``` и фиксированную ```line-height```. Базовые линии совпадают, и высота контейнера строки равна их ```line-height```.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/vertical-align-baseline.png){: .center}


Но что, если у второго элемента ```font-size``` будет меньше?
```css
span:last-child {
    font-size: 50px;
}
```
Как бы странно это ни звучало, выравнивание базовой линии, выставленной по умолчанию, может привести к увеличению высоты (!) контейнера строки, как показано на рисунке ниже. Напоминаю, что высота контейнера строки рассчитывается от самой верхней до самой нижней точки его дочерних элементов.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/vertical-align-baseline-nok.png){: .center}

Это могло бы стать доводом в пользу безразмерных значений ```line-height```, но иногда требуются фиксированные значения для создания идеального вертикального ритма. Честно говоря, независимо от того, что вы выберете, у вас всегда будут проблемы с выравниванием строки.

Рассмотрим еще один пример. Тег ```<p>``` с ```line-height: 200px```, который содержит один единственный ```<span>```, наследующий его ```line-height```

```html
<p>
    <span>Ba</span>
</p>
```
```css
p {
    line-height: 200px;
}
span {
    font-family: Catamaran;
    font-size: 100px;
}
```

Какова высота контейнера строки? Мы могли бы предположить, что 200px, но это не так. Проблема в том, что у ```<p>``` есть свое собственное, отличающееся значение ```font-family``` (по умолчанию это serif). Базовые линии тега ```<p>``` и ```<span>```, по всей вероятности, находятся на разной высоте, и поэтому высота контейнера строки больше, чем предполагалось. Это вызвано тем, что браузеры производят вычисление, считая, что каждый контейнер строки начинается с символа нулевой ширины, который в спецификации называется «strut».

_Невидимый символ с видимым эффектом._

Итак, у нас все та же проблема, что и в случае с одноуровневыми элементами.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/vertical-align-strut.png){: .center}

С выравниванием по базовой линии все плохо, но, может, нас спасет ```vertical-align: middle```? Как сказано в спецификации, ```middle``` «выравнивает контейнер по вертикальной средней точке (midpoint) с базовой линией родительского контейнера плюс половина x-высоты первичного элемента». Соотношение базовых линий, равно как и x-высот (x-height), может быть различным, поэтому на выравнивание по ```middle``` тоже нельзя положиться. А хуже всего тот факт, что в большинстве сценариев ```middle``` никогда не бывает по-настоящему «по центру». На это влияет слишком много факторов, которые нельзя задать через CSS (x-высота, соотношение верхнего и нижнего выносных элементов и др.).

Помимо этого, есть еще четыре значения, которые в некоторых случаях могут оказаться полезными:

* ```vertical-align: top / bottom``` — выравнивание по верхней или нижней границе контейнера строки;
* ```vertical-align: text-top / text-bottom``` — выравнивание по верхней или нижней границе области содержимого.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/vertical-align-top-bottom-text.png){: .center}

Но будьте внимательны: во всех случаях выравнивается виртуальная область, то есть невидимая высота. Рассмотрим простой пример с использованием ```vertical-align: top```. Невидимая ```line-height``` может давать странный, но ожидаемый результат.

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/vertical-align-top-virtual-height.png){: .center}


И наконец, ```vertical-align``` также принимает числовые значения, которые смещают контейнер выше или ниже относительно базовой линии. Этот последний вариант может пригодиться.

## CSS восхитителен

Мы обсудили вопрос взаимодействия ```line-height``` и ```vertical-align```, но сейчас вопрос в том, можно ли управлять метриками шрифта через CSS? Если кратко, то нет. Хотя я бы этого очень хотел. В любом случае, думаю, настало время немного развлечься. Метрики шрифта являются постоянными величинами, поэтому хоть что-то у нас должно получиться.

Что, если, например, нам нужен текст шрифтом Catamaran с высотой прописных букв ровно 100px? Вроде выполнимо, так что давайте произведем некоторые расчеты.

Прежде всего укажем все метрики шрифта как пользовательские свойства CSS, а затем вычислим ```font-size```, при котором высота прописных букв будет равняться 100px.

```css
p {
    /* метрики шрифта */
    --font: Catamaran;
    --fm-capitalHeight: 0.68;
    --fm-descender: 0.54;
    --fm-ascender: 1.1;
    --fm-linegap: 0;

    /* необходимый размер шрифта для высоты прописных букв */
    --capital-height: 100;

    /* применить font-family */
    font-family: var(--font);

    /* рассчитать размер шрифта для получения высоты прописных букв, равной необходимому размеру шрифта */
    --computedFontSize: (var(--capital-height) / var(--fm-capitalHeight));
    font-size: calc(var(--computedFontSize) * 1px);
}
```

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/css-metrics-capital-height.png){: .center}

Довольно просто, не так ли? Но как быть, если нам нужно, чтобы текст был визуально по центру, а оставшееся пространство равномерно распределялось сверху и снизу от буквы «B»? Для этого необходимо рассчитать ```vertical-align``` на основании соотношения между верхним и нижним выносными элементами.

Сначала вычислим ```line-height: normal``` и высоту области содержимого:

```css
p {
    …
    --lineheightNormal: (var(--fm-ascender) + var(--fm-descender) + var(--fm-linegap));
    --contentArea: (var(--lineheightNormal) * var(--computedFontSize));
}
```

Затем нам потребуются:
* расстояние от низа прописной буквы до нижнего края;
* расстояние от верха прописной буквы до верхнего края.

Примерно так:
```css
p {
    …
    --distanceBottom: (var(--fm-descender));
    --distanceTop: (var(--fm-ascender) - var(--fm-capitalHeight));
}
```

Теперь можем вычислить ```vertical-align``` как разницу между этими расстояниями, умноженную на вычисленное значение ```font-size``` (Это значение нужно применить к строчному дочернему элементу).

```css
p {
    …
    --valign: ((var(--distanceBottom) - var(--distanceTop)) * var(--computedFontSize));
}
span {
    vertical-align: calc(var(--valign) * -1px);
}
```
И наконец, задаем необходимое значение ```line-height``` и вычисляем его, сохраняя вертикальное выравнивание:
```css
p {
    …
    /* необходимая высота строки */
    --line-height: 3;
    line-height: calc(((var(--line-height) * var(--capital-height)) - var(--valign)) * 1px);
}
```

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/css-metrics-results-line-height.png){: .center}

Теперь довольно просто добавить графический элемент той же высоты, что и буква «B»:
```css
span::before {
    content: '';
    display: inline-block;
    width: calc(1px * var(--capital-height));
    height: calc(1px * var(--capital-height));
    margin-right: 10px;
    background: url('https://cdn.pbrd.co/images/yBAKn5bbv.png');
    background-size: cover;
}
```

![image]({{ site.url }}{{ site.baseurl }}/assets/images/line-height/css-metrics-results-icon.png){: .center}

Напоминаю, что этот тест показан исключительно для демонстрации, и полагаться на его результаты не стоит. Причин тут много:
* Если метрики шрифта непостоянны, то расчеты в браузере постоянными не будут. ¯\(ツ)/¯
* Если шрифт не загрузился, то метрики резервного шрифта, по всей вероятности, будут другими, и работать со множеством значений быстро станет невозможно.

## Подведем итоги

Рабочие примеры:
* [JSBin](http://jsbin.com/hogavos/edit?html,css,output)
* [gist](https://gist.github.com/Fost/9e9d575a9bd4bdc1aa610afefda62917)

Что мы выяснили:
* Строчный (inline) контекст форматирования действительно сложен для понимания.
* У всех строчных элементов есть две высоты:
  * высота области содержимого (которая зависит от метрик шрифта);
  * высота виртуальной области (```line-height```);
  * ни одну из них совершенно точно нельзя визуализировать (разве что вы занимаетесь инструментальными средствами разработки и решили исправить этот недочет, — тогда было бы просто чудесно).
* ```line-height: normal``` зависит от метрик шрифта.
* из-за line-height: n виртуальная область может стать меньше области содержимого.
* на ```vertical-align``` особо полагаться не стоит.
* высота контейнера строки вычисляется при помощи свойств ```line-height``` и ```vertical-align``` его дочерних элементов.
* Мы не можем просто получить или задать метрики шрифта через CSS.

Но я все равно люблю CSS :)

## Полезные ссылки
* метрики шрифта: [FontForge](https://fontforge.github.io/en-US/), [opentype.js](http://opentype.js.org/font-inspector.html)
* [вычислить ```line-height: normal``` и некоторые пропорции в браузере](http://brunildo.org/test/aspect-lh-table2.html);
* [Ahem](https://www.w3.org/Style/CSS/Test/Fonts/Ahem/) — специальный шрифт, чтобы понять, как это работает
* более глубокое формальное объяснение [строчного контекста форматирования](http://meyerweb.com/eric/css/inline-format.html)
* будущая спецификация по данной теме для помощи с вертикальным выравниванием: [Line Grid module](https://drafts.csswg.org/css-line-grid/)
* метрики шрифта, [API Уровень 1](https://drafts.css-houdini.org/font-metrics-api-1/), сборник интересных идей (Гудини)

## Оригинал статьи,
[Vincent De Oliveira](https://iamvdo.me/en/blog/css-font-metrics-line-height-and-vertical-align)