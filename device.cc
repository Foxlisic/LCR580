// Обновить экран
void update()
{
    int a, b, xc, yc;
    switch (videomode)
    {
        case 0:

            for (y = 0; y < 200; y++)
            for (x = 0; x < 320; x += 8)
            {
                int color;

                xc = x - 32;
                yc = y - 4;

                if (x >= 32 && y >= 4 && x < 288 && y < 196)
                {
                    a = memory[0x4000 + (xc>>3) + yc*32];
                    b = memory[0x5800 + (xc>>3) + (yc>>3)*32];

                    for (int i = 0; i < 8; i++)
                    {
                        color = ((a & 0x80) ? b : (b >> 4)) & 7;
                        pset(x+i,y,dac[color]);
                        a <<= 1;
                    }
                }
                else {

                    for (int i = 0; i < 8; i++) pset(x+i,y,dac[video_border]);
                }
            }

            break;
    }
}

// Сканирование нажатой клавиши
// https://ru.wikipedia.org/wiki/Скан-код
char keyboard(int scancode, int press)
{
    char ascii = 0;
    switch (scancode)
    {
        // Коды клавиш A-Z
        case SDL_SCANCODE_A: ascii = kbs ? 'A' : 'a'; break;
        case SDL_SCANCODE_B: ascii = kbs ? 'B' : 'b'; break;
        case SDL_SCANCODE_C: ascii = kbs ? 'C' : 'c'; break;
        case SDL_SCANCODE_D: ascii = kbs ? 'D' : 'd'; break;
        case SDL_SCANCODE_E: ascii = kbs ? 'E' : 'e'; break;
        case SDL_SCANCODE_F: ascii = kbs ? 'F' : 'f'; break;
        case SDL_SCANCODE_G: ascii = kbs ? 'G' : 'g'; break;
        case SDL_SCANCODE_H: ascii = kbs ? 'H' : 'h'; break;
        case SDL_SCANCODE_I: ascii = kbs ? 'I' : 'i'; break;
        case SDL_SCANCODE_J: ascii = kbs ? 'J' : 'j'; break;
        case SDL_SCANCODE_K: ascii = kbs ? 'K' : 'k'; break;
        case SDL_SCANCODE_L: ascii = kbs ? 'L' : 'l'; break;
        case SDL_SCANCODE_M: ascii = kbs ? 'M' : 'm'; break;
        case SDL_SCANCODE_N: ascii = kbs ? 'N' : 'n'; break;
        case SDL_SCANCODE_O: ascii = kbs ? 'O' : 'o'; break;
        case SDL_SCANCODE_P: ascii = kbs ? 'P' : 'p'; break;
        case SDL_SCANCODE_Q: ascii = kbs ? 'Q' : 'q'; break;
        case SDL_SCANCODE_R: ascii = kbs ? 'R' : 'r'; break;
        case SDL_SCANCODE_S: ascii = kbs ? 'S' : 's'; break;
        case SDL_SCANCODE_T: ascii = kbs ? 'T' : 't'; break;
        case SDL_SCANCODE_U: ascii = kbs ? 'U' : 'u'; break;
        case SDL_SCANCODE_V: ascii = kbs ? 'V' : 'v'; break;
        case SDL_SCANCODE_W: ascii = kbs ? 'W' : 'w'; break;
        case SDL_SCANCODE_X: ascii = kbs ? 'X' : 'x'; break;
        case SDL_SCANCODE_Y: ascii = kbs ? 'Y' : 'y'; break;
        case SDL_SCANCODE_Z: ascii = kbs ? 'Z' : 'z'; break;

        // Цифры
        case SDL_SCANCODE_1: ascii = kbs ? '!' : '1'; break;
        case SDL_SCANCODE_2: ascii = kbs ? '@' : '2'; break;
        case SDL_SCANCODE_3: ascii = kbs ? '#' : '3'; break;
        case SDL_SCANCODE_4: ascii = kbs ? '$' : '4'; break;
        case SDL_SCANCODE_5: ascii = kbs ? '%' : '5'; break;
        case SDL_SCANCODE_6: ascii = kbs ? '%' : '6'; break;
        case SDL_SCANCODE_7: ascii = kbs ? '^' : '7'; break;
        case SDL_SCANCODE_8: ascii = kbs ? '*' : '8'; break;
        case SDL_SCANCODE_9: ascii = kbs ? '(' : '9'; break;
        case SDL_SCANCODE_0: ascii = kbs ? ')' : '0'; break;

        // Специальные символы
        case SDL_SCANCODE_GRAVE:        ascii = 0; break;
        case SDL_SCANCODE_MINUS:        ascii = 0; break;
        case SDL_SCANCODE_EQUALS:       ascii = 0; break;
        case SDL_SCANCODE_BACKSLASH:    ascii = 0; break;
        case SDL_SCANCODE_LEFTBRACKET:  ascii = 0; break;
        case SDL_SCANCODE_RIGHTBRACKET: ascii = 0; break;
        case SDL_SCANCODE_SEMICOLON:    ascii = 0; break; // ;:
        case SDL_SCANCODE_APOSTROPHE:   ascii = 0; break; // '"
        case SDL_SCANCODE_COMMA:        ascii = 0; break; // ,<
        case SDL_SCANCODE_PERIOD:       ascii = 0; break; // .>
        case SDL_SCANCODE_SLASH:        ascii = 0; break; // /?
        case SDL_SCANCODE_BACKSPACE:    ascii = 0; break; // SS+0 BS
        case SDL_SCANCODE_SPACE:        ascii = 0x20; break;
        case SDL_SCANCODE_TAB:          ascii = 9;  break; // SS+CS
        case SDL_SCANCODE_CAPSLOCK:     ascii = 0; break; // SS+2 CAP (DANGER)
        case SDL_SCANCODE_LSHIFT:       kbs = press; break;
        case SDL_SCANCODE_RSHIFT:       kbs = press; break;
        case SDL_SCANCODE_LCTRL:        ascii = 0; break;
        case SDL_SCANCODE_LALT:         ascii = 0; break;
        case SDL_SCANCODE_RCTRL:        ascii = 0; break;
        case SDL_SCANCODE_RALT:         ascii = 0; break;
        case SDL_SCANCODE_RETURN:       ascii = 0x0A;   break;
        case SDL_SCANCODE_ESCAPE:       ascii = 0x1B;   break;
        case SDL_SCANCODE_NUMLOCKCLEAR: ascii = 0;     break;
        case SDL_SCANCODE_KP_DIVIDE:    ascii = '/';    break; // /
        case SDL_SCANCODE_KP_ENTER:     ascii = 0x0A;   break;
        case SDL_SCANCODE_KP_MULTIPLY:  ascii = '*';    break; // *
        case SDL_SCANCODE_KP_MINUS:     ascii = '-';    break; // -
        case SDL_SCANCODE_KP_PLUS:      ascii = '+';    break; // +
        case SDL_SCANCODE_KP_PERIOD:    ascii = '.';    break;
        case SDL_SCANCODE_SCROLLLOCK:   ascii = 0;      break;

        case SDL_SCANCODE_UP:           break; // SS+7
        case SDL_SCANCODE_DOWN:         break; // SS+6
        case SDL_SCANCODE_LEFT:         break; // SS+5
        case SDL_SCANCODE_RIGHT:        break; // SS+8

        // Keypad
        case SDL_SCANCODE_KP_0: ascii = '0'; break;
        case SDL_SCANCODE_KP_1: ascii = '1'; break;
        case SDL_SCANCODE_KP_2: ascii = '2'; break;
        case SDL_SCANCODE_KP_3: ascii = '3'; break;
        case SDL_SCANCODE_KP_4: ascii = '4'; break;
        case SDL_SCANCODE_KP_5: ascii = '5'; break;
        case SDL_SCANCODE_KP_6: ascii = '6'; break;
        case SDL_SCANCODE_KP_7: ascii = '7'; break;
        case SDL_SCANCODE_KP_8: ascii = '8'; break;
        case SDL_SCANCODE_KP_9: ascii = '9'; break;

        case SDL_SCANCODE_F1:  break;
        case SDL_SCANCODE_F2:  break;
        case SDL_SCANCODE_F3:  break;
        case SDL_SCANCODE_F4:  break;
        case SDL_SCANCODE_F5:  break;
        case SDL_SCANCODE_F6:  break;
        case SDL_SCANCODE_F7:  break;
        case SDL_SCANCODE_F8:  break;
        case SDL_SCANCODE_F9:  break;
        case SDL_SCANCODE_F10: break;
        case SDL_SCANCODE_F11: break;
        case SDL_SCANCODE_F12: break;
    }
    return ascii;
}
