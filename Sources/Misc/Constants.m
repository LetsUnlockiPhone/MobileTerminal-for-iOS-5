//
// Constants.m
// Terminal

#import "Constants.h"


struct StrCtrlMap STRG_CTRL_MAP[] = {
    { @"!", {0xd} }, { @"return", {0xd} },
    { @"t", {0x9} },
    { @"home", {0x1B, 0x5B, 0x31, 0x7e} },
    { @"del", {0x1B, 0x5B, 0x33, 0x7e} },
    { @"end", {0x1B, 0x5B, 0x34, 0x7e} },
    { @"pgup", {0x1B, 0x5B, 0x35, 0x7e} },
    { @"pgdown", {0x1B, 0x5B, 0x36, 0x7e} },
    { @"^", {0x1B, 0x5B, 0x41} }, { @"up", {0x1B, 0x5B, 0x41} },
    { @"v", {0x1B, 0x5B, 0x42} }, { @"down", {0x1B, 0x5B, 0x42} },
    { @">", {0x1B, 0x5B, 0x43} }, { @"right", {0x1B, 0x5B, 0x43} },
    { @"<", {0x1B, 0x5B, 0x44} }, { @"left", {0x1B, 0x5B, 0x44} },
    { @"A", {0x1} },
    { @"B", {0x2} },
    { @"C", {0x3} },
    { @"D", {0x4} },
    { @"E", {0x5} },
    { @"F", {0x6} },
    { @"G", {0x7} },
    { @"H", {0x8} },
    { @"I", {0x9} },
    { @"J", {0xa} },
    { @"K", {0xb} },
    { @"L", {0xc} },
    { @"M", {0xd} },
    { @"N", {0xe} },
    { @"O", {0xf} },
    { @"P", {0x10} },
    { @"Q", {0x11} },
    { @"R", {0x12} },
    { @"S", {0x13} },
    { @"T", {0x14} },
    { @"U", {0x15} },
    { @"V", {0x16} },
    { @"W", {0x17} },
    { @"X", {0x18} },
    { @"Y", {0x19} },
    { @"Z", {0x1a} },
    { @"esc", {0x1B} },
    { nil, {0} },
};

NSString *ZONE_KEYS[] =
{
    @"n", @"ne", @"e", @"se", @"s", @"sw", @"w", @"nw", @"ln", @"lne", @"le",
    @"lse", @"ls", @"lsw", @"lw", @"lnw", @"2n", @"2ne", @"2e", @"2se", @"2s",
    @"2sw", @"2w", @"2nw", nil
};

NSString *DEFAULT_SWIPE_GESTURES[][2] =
{
    { @"n", @"\x1B[A" }, // up
    { @"ne", @"\x03" }, // ctrl-c
    { @"e", @"\x1B[C" }, // right
    { @"se", @"[CTRL]" }, // ctrl mode
    { @"s", @"\x1B[B" }, // down
    { @"sw", @"\x09" }, // tab
    { @"w", @"\x1B[D" }, // left
    { @"nw", @"\x1B" }, // esc
    { @"ln", @"" },
    { @"lne", @"" },
    { @"le", @"\x5" }, // ctrl-e
    { @"lse", @"" },
    { @"ls", @"\x0d" }, // return
    { @"lsw", @"" },
    { @"lw", @"\x1" }, // ctrl-a
    { @"lnw", @"" },
    { @"2n", @"[CONF]" }, // settings
    { @"2ne", @"" },
    { @"2e", @"[PREV]" }, // previous terminal
    { @"2se", @"" },
    { @"2s", @"[KEYB]" }, // keyboard
    { @"2sw", @"" },
    { @"2w", @"[NEXT]" }, // next terminal
    { @"2nw", @"" },
    { nil, nil }
};

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
