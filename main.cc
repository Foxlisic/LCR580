#include <SDL2/SDL.h>
#include <verilated.h>
#include "obj_dir/Vlcr580.h"
// ----------------------------------------------------
SDL_Surface*        screen_surface;
SDL_Window*         sdl_window;
SDL_Renderer*       sdl_renderer;
SDL_PixelFormat*    sdl_pixel_format;
SDL_Texture*        sdl_screen_texture;
SDL_Event           evt;
Uint32*             screen_buffer;
SDL_Rect            dstRect;
// ----------------------------------------------------
int scale  = 4;
int width  = 320;
int height = 200;
int length = 20;
int videomode    = 0;
int video_border = 0;
int _hs = 0, _vs = 0;
int x   = 0, y   = 0;
int dump      = 0;
int dump_init = 0;
int kbs = 0, kbascii = 0, irq_vect = 0;
uint8_t memory[65536];
// ----------------------------------------------------
Vlcr580* lcr580;
// ----------------------------------------------------
void pset(int, int, Uint32);
void update();
char keyboard(int, int);
void call_irq(int);
// ----------------------------------------------------
#include "data.h"
#include "disasm.cc"
#include "device.cc"
// ----------------------------------------------------
int main(int argc, char** argv)
{
    FILE* fp;

    int pticks = 0, nticks, ia = 1;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) {
        exit(1);
    }

    while (ia < argc)
    {
        if (argv[ia][0] == '-')
        {
            switch (argv[ia][1])
            {
                case 'd': dump = 1; dump_init = 1; break; // Только инструкции
                case 'D': dump = 2; dump_init = 2; break; // Расширенный дамп
            }

        } else {

            fp = fopen(argv[ia], "rb");
            if (fp) {
                fread(memory, 1, 65536, fp);
                fclose(fp);
            }
        }

        ia++;
    }

    // Инициализация и сброс процессора
    lcr580 = new Vlcr580;
    lcr580->ce      = 1;
    lcr580->reset_n = 0;
    lcr580->clock   = 0; lcr580->eval();
    lcr580->clock   = 1; lcr580->eval();
    lcr580->reset_n = 1;

    int wc = SDL_WINDOWPOS_CENTERED;
    int ws = SDL_WINDOW_SHOWN;
    int wp = SDL_RENDERER_PRESENTVSYNC;
    int wf = SDL_PIXELFORMAT_BGRA32;
    int wt = SDL_TEXTUREACCESS_STREAMING;

    SDL_ClearError();
    sdl_window   = SDL_CreateWindow("LCR580", wc, wc, scale*width, scale*height,ws);
    sdl_renderer = SDL_CreateRenderer(sdl_window, -1, wp);
    sdl_screen_texture = SDL_CreateTexture(sdl_renderer, wf, wt, width, height);
    SDL_SetTextureBlendMode(sdl_screen_texture, SDL_BLENDMODE_NONE);
    screen_buffer = (Uint32*) malloc(width*height*sizeof(Uint32));

    dstRect.x = 0;
    dstRect.y = 0;
    dstRect.w = scale * width;
    dstRect.h = scale * height;

    for (;;)
    {
        // Прием событий
        while (SDL_PollEvent(& evt))
        {
            int keyc = evt.key.keysym.scancode;
            int keyt;

            switch (evt.type)
            {
                // Выход из приложения
                case SDL_QUIT: {

                    free(screen_buffer);
                    SDL_DestroyTexture(sdl_screen_texture);
                    SDL_FreeFormat(sdl_pixel_format);
                    SDL_DestroyRenderer(sdl_renderer);
                    SDL_DestroyWindow(sdl_window);
                    SDL_Quit();
                    return 0;
                }

                // Нажать на клавишу
                case SDL_KEYDOWN:

                    if (keyt = keyboard(keyc, 1)) {
                        kbascii = keyt;
                        call_irq(1);
                    }

                    break;

                // Отжать клавишу как Б-г
                case SDL_KEYUP: keyboard(keyc, 0); break;
            }
        }

        int count = 0;

        // Выполнение кадра
        do {

            for (int i = 0; i < 16384; i++) {

                // Базовый интерфейс ввода-вывода
                if (lcr580->we) {
                    memory[lcr580->address] = lcr580->out;
                }

                lcr580->in = memory[lcr580->address];

                // Запись в порт
                if (lcr580->port_we)
                switch (lcr580->address)
                {
                    case 0x00: videomode    = lcr580->out; break;
                    case 0xFE: video_border = lcr580->out & 7; break;
                }

                // Чтение из порта
                if (lcr580->port_rd)
                switch (lcr580->address)
                {
                    case 0xFE: lcr580->port_in = kbascii; break;
                }

                // Отладчик
                if (dump && lcr580->m0)
                {
                    disasm(lcr580->address, 8);
                    printf("  %04X [%02X] %04X %04X %04X %04X :: %s %s\n", lcr580->address, lcr580->in, lcr580->bc, lcr580->de, lcr580->hl, lcr580->af, ds_opcode, ds_operand);
                    if (lcr580->in == 0x76) dump = 0;

                } else if (dump == 2) {
                    printf("- %04X [%02X] %c\n", lcr580->address, lcr580->in, lcr580->we ? 'w' : ' ');
                }

                // Исполнение инструкции
                lcr580->clock = 1; lcr580->eval();
                lcr580->clock = 0; lcr580->eval();

                // Возможны прерывания
                if (lcr580->iff1 && irq_vect) {

                    dump = dump_init;
                    int vect = 0;

                    if      (irq_vect & 1) { vect = 1; irq_vect &= ~1; }
                    else if (irq_vect & 2) { vect = 2; irq_vect &= ~2; }
                    else if (irq_vect & 4) { vect = 3; irq_vect &= ~4; }
                    else if (irq_vect & 8) { vect = 4; irq_vect &= ~8; }

                    if (vect) {
                        lcr580->irq  = 1 - lcr580->irq;
                        lcr580->vect = vect;
                    }
                }

                count++;
            }

            nticks = SDL_GetTicks();
        }
        while (nticks - pticks < length);

        pticks = nticks;

        call_irq(2);
        update();

        // Обновление экрана
        SDL_UpdateTexture(sdl_screen_texture, NULL, screen_buffer, width * sizeof(Uint32));
        SDL_SetRenderDrawColor  (sdl_renderer, 0, 0, 0, 0);
        SDL_RenderClear         (sdl_renderer);
        SDL_RenderCopy          (sdl_renderer, sdl_screen_texture, NULL, & dstRect);
        SDL_RenderPresent       (sdl_renderer);
        SDL_Delay(1);
    }
}

// Установка точки
void pset(int x, int y, Uint32 cl)
{
    if (x < 0 || y < 0 || x >= width || y >= height) {
        return;
    }

    screen_buffer[width*y + x] = cl;
}

// Вызов вектора прерывания
void call_irq(int vect)
{
    irq_vect |= (1 << (vect - 1));
}
