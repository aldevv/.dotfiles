/* Copyright 2016 Jack Humbert
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Sendstring lookup tables for Colemak layouts

#pragma once

#include "latam_colemak.h"

// clang-format off

const uint8_t ascii_to_keycode_lut[128] PROGMEM = {
    // NUL   SOH      STX      ETX      EOT      ENQ      ACK      BEL
    XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,
    // BS    TAB      LF       VT       FF       CR       SO       SI
    KC_BSPC, KC_TAB,  KC_ENT,  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,
    // DLE   DC1      DC2      DC3      DC4      NAK      SYN      ETB
    XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,
    // CAN   EM       SUB      ESC      FS       GS       RS       US
    XXXXXXX, XXXXXXX, XXXXXXX, KC_ESC,  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,

    //       !        "        #        $        %        &        '
    KC_SPC,  LCM_1,   LCM_2, LCM_3,   LCM_4,   LCM_5,   LCM_6,   LCM_QUOT,
    // (     )        *        +          ,        -          .        /
   LCM_8,   LCM_9,   LCM_PLUS, LCM_PLUS, LCM_COMM, LCM_MINS, LCM_DOT, LCM_7,
    // 0     1        2        3        4        5        6        7
   LCM_0,   LCM_1,   LCM_2,   LCM_3,   LCM_4,   LCM_5,   LCM_6,   LCM_7,
    // 8     9        :        ;        <           =        >        ?
   LCM_8,   LCM_9,   LCM_DOT, LCM_COMM, LCM_LABK, LCM_0, LCM_LABK, LCM_ACUT,
    // @     A        B        C        D        E        F        G
   LCM_2,   LCM_A,   LCM_B,   LCM_C,   LCM_D,   LCM_E,   LCM_F,   LCM_G,
    // H     I        J        K        L        M        N        O
   LCM_H,   LCM_I,   LCM_J,   LCM_K,   LCM_L,   LCM_M,   LCM_N,   LCM_O,
    // P     Q        R        S        T        U        V        W
   LCM_P,   LCM_Q,   LCM_R,   LCM_S,   LCM_T,   LCM_U,   LCM_V,   LCM_W,
    // X     Y        Z        [        \        ]           ^        _
   LCM_X,   LCM_Y,   LCM_Z,   LCM_LCBR,LCM_QUOT, LCM_RCBR, LCM_LCBR, LCM_MINS,
    // `     a        b        c        d        e        f        g
   LCM_RCBR, LCM_A,   LCM_B,   LCM_C,   LCM_D,   LCM_E,   LCM_F,   LCM_G,
    // h     i        j        k        l        m        n        o
   LCM_H,   LCM_I,   LCM_J,   LCM_K,   LCM_L,   LCM_M,   LCM_N,   LCM_O,
    // p     q        r        s        t        u        v        w
   LCM_P,   LCM_Q,   LCM_R,   LCM_S,   LCM_T,   LCM_U,   LCM_V,   LCM_W,
    // x     y        z        {        |        }        ~              ñ
   LCM_X,   LCM_Y,   LCM_Z,   LCM_LCBR, LCM_RCBR, LCM_RCBR, LCM_NTIL,  LCM_NTIL
};
