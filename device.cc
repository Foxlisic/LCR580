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
                        color = ((a & 0x80) ? b : (b >> 3)) & 7;
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
