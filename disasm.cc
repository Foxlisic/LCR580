// -----------------------------------------------------------------------------
// Disassembly.2000
int     ds_ad;             // Текущая временная позиция разбора инструкции
int     ds_size;           // Размер инструкции
char    ds_opcode[16];
char    ds_operand[32];
char    ds_prefix[16];
int     ds_string[64];     // Адреса в строках
int     ds_change[16];
// -----------------------------------------------------------------------------

enum Regs16Ref
{
    R___ = 0,
    R_BC = 1,
    R_DE = 2,
    R_HL = 3,
    R_SP = 4,
    R_AF = 5,
    R_WD = 6
};

const char* ds_reg8[3*8] =
{
    "b", "c", "d", "e", "h",   "l",   "(hl)", "a",
    "b", "c", "d", "e", "ixh", "ixl", "$",    "a",
    "b", "c", "d", "e", "iyh", "iyl", "$",    "a"
};

const char* ds_reg16[3*4] =
{
    "bc", "de", "hl", "sp",
    "bc", "de", "ix", "sp",
    "bc", "de", "iy", "sp"
};

const char* ds_reg16af[3*4] =
{
    "bc", "de", "hl", "af",
    "bc", "de", "ix", "af",
    "bc", "de", "iy", "af"
};

const char* ds_cc[8] =
{
    "nz", "z", "nc", "c",
    "po", "pe", "p", "m"
};

const char* ds_bits[8] =
{
    "rlc", "rrc", "rl", "rr",
    "sla", "sra", "sll", "srl",
};

const int ds_im[8] = {0, 0, 1, 2, 0, 0, 1, 2};

const char* ds_mnemonics[256] = {

    /* 00 */    "nop",  "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "rlca",
    /* 08 */    "ex",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "rrca",
    /* 10 */    "djnz", "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "rla",
    /* 18 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "rra",
    /* 20 */    "jr",   "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "daa",
    /* 28 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "cpl",
    /* 30 */    "jr",   "ld",   "ld",   "inc",  "inc",  "dec",  "ld",   "scf",
    /* 38 */    "jr",   "add",  "ld",   "dec",  "inc",  "dec",  "ld",   "ccf",

    /* 40 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 48 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 50 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 58 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 60 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 68 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",
    /* 70 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "halt",  "ld",
    /* 78 */    "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",   "ld",

    /* 80 */    "add",  "add",  "add",  "add",  "add",  "add",  "add",  "add",
    /* 88 */    "adc",  "adc",  "adc",  "adc",  "adc",  "adc",  "adc",  "adc",
    /* 90 */    "sub",  "sub",  "sub",  "sub",  "sub",  "sub",  "sub",  "sub",
    /* 98 */    "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",  "sbc",
    /* A0 */    "and",  "and",  "and",  "and",  "and",  "and",  "and",  "and",
    /* A8 */    "xor",  "xor",  "xor",  "xor",  "xor",  "xor",  "xor",  "xor",
    /* B0 */    "or",   "or",   "or",   "or",   "or",   "or",   "or",   "or",
    /* B8 */    "cp",   "cp",   "cp",   "cp",   "cp",   "cp",   "cp",   "cp",

    /* C0 */    "ret",   "pop", "jp",   "jp",   "call", "push", "add",  "rst",
    /* C8 */    "ret",   "ret", "jp",   "$",    "call", "call", "adc",  "rst",
    /* D0 */    "ret",   "pop", "jp",   "out",  "call", "push", "sub",  "rst",
    /* D8 */    "ret",   "exx", "jp",   "in",   "call", "$",    "sbc",  "rst",
    /* E0 */    "ret",   "pop", "jp",   "ex",   "call", "push", "and",  "rst",
    /* E8 */    "ret",   "jp",  "jp",   "ex",   "call", "$",    "xor",  "rst",
    /* F0 */    "ret",   "pop", "jp",   "di",   "call", "push", "or",   "rst",
    /* F8 */    "ret",   "ld",  "jp",   "ei",   "call", "$",    "cp",   "rst"
};

const char ds_registers16[256] = {

    /* 00 */    R___,   R_WD,   R_BC,   R___,   R___,   R___,   R___,   R___,
    /* 08 */    R___,   R___,   R_BC,   R___,   R___,   R___,   R___,   R___,
    /* 10 */    R___,   R_WD,   R_DE,   R___,   R___,   R___,   R___,   R___,
    /* 18 */    R___,   R___,   R_DE,   R___,   R___,   R___,   R___,   R___,
    /* 20 */    R___,   R_WD,   R_WD,   R___,   R___,   R___,   R___,   R___,
    /* 28 */    R___,   R___,   R_WD,   R___,   R___,   R___,   R___,   R___,
    /* 30 */    R___,   R_WD,   R_WD,   R___,   R___,   R___,   R_HL,   R___,
    /* 38 */    R___,   R___,   R_WD,   R___,   R___,   R___,   R___,   R___,
    /* 40 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 48 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 50 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 58 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 60 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 68 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 70 */    R_HL,   R_HL,   R_HL,   R_HL,   R_HL,   R_HL,   R___,   R_HL,
    /* 78 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 80 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 88 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 90 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* 98 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* A0 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* A8 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* B0 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* B8 */    R___,   R___,   R___,   R___,   R___,   R___,   R_HL,   R___,
    /* C0 */    R_SP,   R_SP,   R___,   R___,   R___,   R___,   R___,   R___,
    /* C8 */    R_SP,   R___,   R___,   R___,   R___,   R___,   R___,   R___,
    /* D0 */    R_SP,   R_SP,   R___,   R___,   R___,   R___,   R___,   R___,
    /* D8 */    R_SP,   R___,   R___,   R___,   R___,   R___,   R___,   R___,
    /* E0 */    R_SP,   R_SP,   R___,   R___,   R___,   R___,   R___,   R___,
    /* E8 */    R_SP,   R_HL,   R___,   R___,   R___,   R___,   R___,   R___,
    /* F0 */    R_SP,   R_SP,   R___,   R___,   R___,   R___,   R___,   R___,
    /* F8 */    R_SP,   R___,   R___,   R___,   R___,   R___,   R___,   R___
};

// -----------------------------------------------------------------------------

// Прочитать байт дизассемблера
int ds_fetch_byte()
{
    int b = memory[ds_ad];
    ds_ad = (ds_ad + 1) & 0xffff;
    ds_size++;
    return b;
}

// Прочитать слово дизассемблера
int ds_fetch_word()
{
    int l = ds_fetch_byte();
    int h = ds_fetch_byte();
    return (h << 8) | l;
}

// Проверка, куда ведет условная инструкция
int ds_cond_check(int a)
{
    int _a  = memory[a];
    int _b  = memory[a + 1];
    int _r8 = (_b & 0x80 ? -1 : 1);
    int _wd = memory[a] + 256*memory[a];
    int _sp = memory[lcr580->sp] + 256*memory[lcr580->sp+1];

    char _cond[8] = {
        (char)(lcr580->af & 0x4000 ? 0 : 1), // NZ
        (char)(lcr580->af & 0x4000 ? 1 : 0), // Z
        (char)(lcr580->af & 0x0100 ? 0 : 1), // NC
        (char)(lcr580->af & 0x0100 ? 1 : 0), // C
        (char)(lcr580->af & 0x0400 ? 0 : 1), // PO
        (char)(lcr580->af & 0x0400 ? 1 : 0), // PE
        (char)(lcr580->af & 0x8000 ? 0 : 1), // P
        (char)(lcr580->af & 0x8000 ? 1 : 0), // M
    };

    switch (_a)
    {
        // DJNZ
        case 0x10: return (lcr580->bc & 0xFF00) != 1 ?  : 0;

        // JR
        case 0x18: return _r8;

        // JR nz, z, nc, c
        case 0x20: case 0x28:
        case 0x30: case 0x38:
            return _cond[(_a >> 3) & 3] ? _r8 : 0;

        // RET cc
        case 0xC0: case 0xC8:
        case 0xD0: case 0xD8:
        case 0xE0: case 0xE8:
        case 0xF0: case 0xF8:
            return _cond[(_a >> 3) & 7] ? (_sp < a ? -1 : 1) : 0;

        // JP|CALL cc
        case 0xC2: case 0xC4: case 0xCA: case 0xCC:
        case 0xD2: case 0xD4: case 0xDA: case 0xDC:
        case 0xE2: case 0xE4: case 0xEA: case 0xEC:
        case 0xF2: case 0xF4: case 0xFA: case 0xFC:
            return _cond[(_a >> 3) & 7] ? (_wd < a ? -1 : 1) : 0;
    }

    return 0;
}

// Сформировать операнд (IX|IY+d)
void ixy_disp(int prefix)
{
    int df = ds_fetch_byte();

    if (df & 0x80) {
        sprintf(ds_prefix, "(%s-$%02x)", (prefix == 1 ? "ix" : "iy"), 1 + (df ^ 0xff));
    } else if (df) {
        sprintf(ds_prefix, "(%s+$%02x)", (prefix == 1 ? "ix" : "iy"), df);
    } else {
        sprintf(ds_prefix, "(%s)", (prefix == 1 ? "ix" : "iy"));
    }
}

// Прочитать относительный операнд
int ds_fetch_rel()
{
    int r8 = ds_fetch_byte();
    return ((r8 & 0x80) ? r8 - 0x100 : r8) + ds_ad;
}

// -----------------------------------------------------------------------------

// Дизассемблирование 1 линии
int disasm(int addr, int oppad = 0)
{
    int op, df;
    int prefix = 0;

    ds_opcode[0]  = 0;
    ds_prefix[0]  = 0;
    ds_ad   = addr;
    ds_size = 0;

    for (int i = 0; i < 32; i++) ds_operand[i] = 0;

    // -----------------------------------------------------------------
    // Считывание опкода и префиксов
    // -----------------------------------------------------------------

    do {

        op = ds_fetch_byte();
        if (op == 0xDD)      prefix = 1;
        else if (op == 0xFD) prefix = 2;
    }
    while (op == 0xDD || op == 0xFD);

    // -----------------------------------------------------------------
    // Разбор опкода и операндов
    // -----------------------------------------------------------------

    if (op == 0xED) {

        op = ds_fetch_byte();

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);
        int f = (op & 0x30) >> 4;

        // 01xx x000
        if      ((op & 0xc7) == 0x40) { sprintf(ds_opcode, "in");  sprintf(ds_operand, "%s, (c)", a == 6 ? "?" : ds_reg8[a]); }
        else if ((op & 0xc7) == 0x41) { sprintf(ds_opcode, "out"); sprintf(ds_operand, "(c), %s", a == 6 ? "0" : ds_reg8[a]); }
        // 01xx x010
        else if ((op & 0xc7) == 0x42) { sprintf(ds_opcode, op & 8 ? "adc" : "sbc"); sprintf(ds_operand, "hl, %s", ds_reg16[f]); }
        // 01xx b011
        else if ((op & 0xcf) == 0x43) { sprintf(ds_opcode, "ld"); sprintf(ds_operand, "($%04x), %s", ds_fetch_word(), ds_reg16[f]); }
        else if ((op & 0xcf) == 0x4b) { sprintf(ds_opcode, "ld"); sprintf(ds_operand, "%s, ($%04x)", ds_reg16[f], ds_fetch_word()); }
        // 01xx x10b
        else if ((op & 0xc7) == 0x44) { sprintf(ds_opcode, "neg"); }
        else if (op == 0x4d) sprintf(ds_opcode, "reti");
        else if ((op & 0xc7) == 0x45) { sprintf(ds_opcode, "retn"); }
        // 01xx x110
        else if ((op & 0xc7) == 0x46) { sprintf(ds_opcode, "im"); sprintf(ds_operand, "%x", ds_im[a]); }
        else switch (op) {

            case 0x47: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "i, a"); break;
            case 0x4f: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "r, a"); break;
            case 0x57: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "a, i"); break;
            case 0x5f: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "a, r"); break;
            case 0x67: sprintf(ds_opcode, "rrd"); break;
            case 0x6f: sprintf(ds_opcode, "rld"); break;

            case 0xa0: sprintf(ds_opcode, "ldi"); break;
            case 0xa1: sprintf(ds_opcode, "cpi"); break;
            case 0xa2: sprintf(ds_opcode, "ini"); break;
            case 0xa3: sprintf(ds_opcode, "outi"); break;
            case 0xa8: sprintf(ds_opcode, "ldd"); break;
            case 0xa9: sprintf(ds_opcode, "cpd"); break;
            case 0xaa: sprintf(ds_opcode, "ind"); break;
            case 0xab: sprintf(ds_opcode, "outd"); break;

            case 0xb0: sprintf(ds_opcode, "ldir"); break;
            case 0xb1: sprintf(ds_opcode, "cpir"); break;
            case 0xb2: sprintf(ds_opcode, "inir"); break;
            case 0xb3: sprintf(ds_opcode, "otir"); break;
            case 0xb8: sprintf(ds_opcode, "lddr"); break;
            case 0xb9: sprintf(ds_opcode, "cpdr"); break;
            case 0xba: sprintf(ds_opcode, "indr"); break;
            case 0xbb: sprintf(ds_opcode, "otdr"); break;

            default:

                sprintf(ds_opcode, "undef?"); break;
        }
    }
    else if (op == 0xCB) {

        if (prefix) ixy_disp(prefix);
        op = ds_fetch_byte();

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);

        // 00xxxrrr SHIFT
        if ((op & 0xc0) == 0x00) {

            sprintf(ds_opcode, "%s", ds_bits[a]);

            if (prefix && b == 6) {
                sprintf(ds_operand, "%s", ds_prefix);
            } else {
                sprintf(ds_operand, "%s", ds_reg8[b + prefix*8]);
            }
        }
        else {

            if ((op & 0xc0) == 0x40) sprintf(ds_opcode, "bit");
            if ((op & 0xc0) == 0x80) sprintf(ds_opcode, "res");
            if ((op & 0xc0) == 0xc0) sprintf(ds_opcode, "set");

            sprintf(ds_operand, "%x, %s", a, prefix ? ds_prefix : ds_reg8[b]);
        }

    } else {

        // Имя опкода
        sprintf(ds_opcode, "%s", ds_mnemonics[op]);

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);

        // Имя HL в зависимости от префикса
        char hlname[4];
        if (prefix == 0) sprintf(hlname, "hl");
        if (prefix == 1) sprintf(hlname, "ix");
        if (prefix == 2) sprintf(hlname, "iy");

        // Инструкции перемещения LD
        if (op >= 0x40 && op < 0x80) {

            if (a == 6 && b == 6) {
                /* halt */
            }
            // Префиксированные
            else if (prefix) {

                // Прочитать +disp8
                ixy_disp(prefix);

                // Декодирование
                if (a == 6) {
                    sprintf(ds_operand, "%s, %s", ds_prefix, ds_reg8[b]);
                } else if (b == 6) {
                    sprintf(ds_operand, "%s, %s", ds_reg8[a], ds_prefix);
                } else {
                    sprintf(ds_operand, "%s, %s", ds_reg8[8*prefix + a], ds_reg8[8*prefix + b]);
                }
            }
            else { sprintf(ds_operand, "%s, %s", ds_reg8[a], ds_reg8[b]); }
        }
        // Арифметико-логика
        else if (op >= 0x80 && op < 0xc0) {

            if (prefix) {

                if (b == 6) {

                    ixy_disp(prefix);
                    sprintf(ds_operand, "%s", ds_prefix);

                } else {
                    sprintf(ds_operand, "%s", ds_reg8[8*prefix + b]);
                }
            } else {
                sprintf(ds_operand, "%s", ds_reg8[b]);
            }
        }
        // LD r16, **
        else if (op == 0x01 || op == 0x11 || op == 0x21 || op == 0x31) {

            df = ds_fetch_word();
            sprintf(ds_operand, "%s, $%04x", ds_reg16[4*prefix + ((op & 0x30) >> 4)], df);
        }
        // 00xx x110 LD r8, i8
        else if ((op & 0xc7) == 0x06) {

            if (a == 6 && prefix) {
                ixy_disp(prefix);
                sprintf(ds_operand, "%s, $%02x", ds_prefix, ds_fetch_byte());
            } else {
                sprintf(ds_operand, "%s, $%02x", ds_reg8[8*prefix + a], ds_fetch_byte());
            }
        }
        // 00_xxx_10x
        else if ((op & 0xc7) == 0x04 || (op & 0xc7) == 0x05) {

            if (a == 6 && prefix) {
                ixy_disp(prefix);
                sprintf(ds_operand, "%s", ds_prefix);
            } else {
                sprintf(ds_operand, "%s", ds_reg8[8*prefix + a]);
            }
        }
        // 00xx x011
        else if ((op & 0xc7) == 0x03) {
            sprintf(ds_operand, "%s", ds_reg16[4*prefix + ((op & 0x30) >> 4)]);
        }
        // 00xx 1001
        else if ((op & 0xcf) == 0x09) {
            sprintf(ds_operand, "%s, %s", ds_reg16[4*prefix+2], ds_reg16[4*prefix + ((op & 0x30) >> 4)]);
        }
        else if (op == 0x02) sprintf(ds_operand, "(bc), a");
        else if (op == 0x08) sprintf(ds_operand, "af, af'");
        else if (op == 0x0A) sprintf(ds_operand, "a, (bc)");
        else if (op == 0x12) sprintf(ds_operand, "(de), a");
        else if (op == 0x1A) sprintf(ds_operand, "a, (de)");
        else if (op == 0xD3) sprintf(ds_operand, "($%02x), a", ds_fetch_byte());
        else if (op == 0xDB) sprintf(ds_operand, "a, ($%02x)", ds_fetch_byte());
        else if (op == 0xE3) sprintf(ds_operand, "(sp), %s", hlname);
        else if (op == 0xE9) sprintf(ds_operand, "(%s)", hlname);
        else if (op == 0xEB) sprintf(ds_operand, "de, %s", hlname);
        else if (op == 0xF9) sprintf(ds_operand, "sp, %s", hlname);
        else if (op == 0xC3 || op == 0xCD) sprintf(ds_operand, "$%04x", ds_fetch_word());
        else if (op == 0x22) { b = ds_fetch_word(); sprintf(ds_operand, "($%04x), %s", b, hlname); }
        else if (op == 0x2A) { b = ds_fetch_word(); sprintf(ds_operand, "%s, ($%04x)", hlname, b); }
        else if (op == 0x32) { b = ds_fetch_word(); sprintf(ds_operand, "($%04x), a", b); }
        else if (op == 0x3A) { b = ds_fetch_word(); sprintf(ds_operand, "a, ($%04x)", b); }
        else if (op == 0x10 || op == 0x18) { sprintf(ds_operand, "$%04x", ds_fetch_rel()); }
        // 001x x000 JR c, *
        else if ((op & 0xe7) == 0x20) sprintf(ds_operand, "%s, $%04x", ds_cc[(op & 0x18)>>3], ds_fetch_rel());
        // 11xx x000 RET *
        else if ((op & 0xc7) == 0xc0) sprintf(ds_operand, "%s", ds_cc[a]);
        // 11xx x010 JP c, **
        // 11xx x100 CALL c, **
        else if ((op & 0xc7) == 0xc2 || (op & 0xc7) == 0xc4) sprintf(ds_operand, "%s, $%04x", ds_cc[a], ds_fetch_word());
        // 11xx x110 ALU A, *
        else if ((op & 0xc7) == 0xc6) sprintf(ds_operand, "$%02x", ds_fetch_byte());
        // 11xx x111 RST #
        else if ((op & 0xc7) == 0xc7) sprintf(ds_operand, "$%02x", op & 0x38);
        // 11xx 0x01 PUSH/POP r16
        else if ((op & 0xcb) == 0xc1) sprintf(ds_operand, "%s", ds_reg16af[ ((op & 0x30) >> 4) + prefix*4 ] );
    }

    int ds_opcode_len  = strlen(ds_opcode);
    int ds_operand_len = strlen(ds_operand);
    int ds_opcode_pad  = ds_opcode_len < 5 ? 5 : ds_opcode_len + 1;
    int ds_operand_pad = oppad > ds_operand_len ? oppad : ds_operand_len;

    // Привести в порядок
    for (int i = 0; i <= ds_opcode_pad; i++) {
         ds_opcode[i] = i < ds_opcode_len ? toupper(ds_opcode[i]) : (i == ds_opcode_pad-1 ? 0 : ' ');
     }

    for (int i = 0; i <= ds_operand_pad; i++) {
        ds_operand[i] = i < ds_operand_len ? toupper(ds_operand[i]) : (i == ds_operand_pad-1 ? 0 : ' ');
    }

    return ds_size;
}
