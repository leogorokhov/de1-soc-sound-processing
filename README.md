# de1-soc-sound-processing

# Порядок выполнения работы

1. В соответствии с мануалом **[Basic_DSP_Manual.pdf](https://drive.google.com/file/d/0B2DyhVuZZ3BFNGF4UUdYcF9VM1E/view?usp=drive_link&resourcekey=0-_VcvsV6Q6HLb75ICzzYVYA)** и используя файлы из **[SPDS_Lab_5_dop_materials](https://drive.google.com/drive/folders/14xESSVfZ9tlxH_1Yqp6mQU7SIRzjtjmz?usp=drive_link) ([SPDS_Lab_5_dop_materials_1](https://drive.google.com/file/d/0B2DyhVuZZ3BFdXQ1WmFFcUpmSkk/view?usp=drive_link&resourcekey=0-5XFoRHtqYJB-y4H4a0eCog)** и **[SPDS_Lab_5_dop_materials_2](https://drive.google.com/file/d/1BkU0Gp5OAaL8FDg1xfSwfqynIh94ngm4/view?usp=drive_link))**, создать проект, в котором сигнал с линейного входа от микрофона (или плеера) подается на линейный выход (наушники, динамики).

2. Добавить управление от кнопки, убирающее один из каналов или меняющее каналы местами.

3. Разработать генератор шума и добавить его к выходному звуку.

4. Выполнить прототипирование.

# Самостоятельная работа

5. Используя делитель частоты приведенный ниже (опционально, можно использовать PLL и самописные делители частоты), реализовать индикацию на светодиодной ленте и 7-сегментном индикаторе.

  ```Verilog
module sm_clk_divider
#(
    parameter shift  = 16,
              bypass = 0
)
(
    input           clkIn,
    input           rst_n,
    input   [ 3:0 ] divide,
    input           enable,
    output          clkOut
);
    wire [31:0] cntr;
    wire [31:0] cntrNext = cntr + 1;
    sm_register_we r_cntr(clkIn, rst_n, enable, cntrNext, cntr);

    assign clkOut = bypass ? clkIn 
                           : cntr[shift + divide];
endmodule
```


6. Выполнить задание по варианту (ваш вариант % 4 + 1):

  1) Реализовать FIR фильтр или какой-либо другой.

  2) Разработать диктофон (записывает звук, пока нажата кнопка, при нажатии другой кнопки – воспроизводит запись циклически).

  3) Реализовать регулировку громкости с использованием переключателей.

  4) Реализовать регулировку тональности звука от переключателей на плате.

2а. Альтернативное 2-му задание: Создать эквалайзер на светодиодной ленте.



