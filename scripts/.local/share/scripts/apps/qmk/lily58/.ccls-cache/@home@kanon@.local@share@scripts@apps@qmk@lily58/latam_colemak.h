/* Copyright 2015-2016 Jack Humbert
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

#pragma once

#include "keymap.h"

// clang-format off

/*
 * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
 * │ ` │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │       │
 * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
 * │     │ Q │ W │ F │ P │ G │ J │ L │ U │ Y │ ; │ [ │ ] │  \  │
 * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┤
 * │      │ A │ R │ S │ T │ D │ H │ N │ E │ I │ O │ ' │        │
 * ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴────────┤
 * │        │ Z │ X │ C │ V │ B │ K │ M │ , │ . │ / │          │
 * ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
 * │    │    │    │                        │    │    │    │    │
 * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
 */
/* MISSING
   -------
  - KC_MIN
  - KC_EQL
  - KC_NUBS
*/

// Row 1
#define LCM_PIPE KC_GRV  // |
#define LCM_1    KC_1    // 1
#define LCM_2    KC_2    // 2
#define LCM_3    KC_3    // 3
#define LCM_4    KC_4    // 4
#define LCM_5    KC_5    // 5
#define LCM_6    KC_6    // 6
#define LCM_7    KC_7    // 7
#define LCM_8    KC_8    // 8
#define LCM_9    KC_9    // 9
#define LCM_0    KC_0    // 0
#define LCM_ACUT KC_LBRC  // ´
#define LCM_MINS KC_SLSH // -
// to change
#define LCM_PLUS KC_RBRC  // +

// Row 2
#define LCM_Q    KC_Q    // Q
#define LCM_W    KC_W    // W
#define LCM_F    KC_E    // F
#define LCM_P    KC_R    // P
#define LCM_G    KC_T    // G
#define LCM_J    KC_Y    // J
#define LCM_L    KC_U    // L
#define LCM_U    KC_I    // U
#define LCM_Y    KC_O    // Y
#define LCM_NTIL KC_P    // Ñ

// Row 3
#define LCM_A      KC_A    // A
#define LCM_R      KC_S    // R
#define LCM_S      KC_D    // S
#define LCM_T      KC_F    // T
#define LCM_D      KC_G    // D
#define LCM_H      KC_H    // H
#define LCM_N      KC_J    // N
#define LCM_E      KC_K    // E
#define LCM_I      KC_L    // I
#define LCM_O      KC_SCLN // O
#define LCM_QUOT   KC_MINS // '
#define LCM_LCBR   KC_QUOT // {
#define LCM_RCBR   KC_BSLS // }
// Row 4
#define LCM_Z    KC_Z    // Z
#define LCM_X    KC_X    // X
#define LCM_C    KC_C    // C
#define LCM_V    KC_V    // V
#define LCM_B    KC_B    // B
#define LCM_K    KC_N    // K
#define LCM_M    KC_M    // M
#define LCM_COMM KC_COMM // ,
#define LCM_DOT  KC_DOT  // .

 /*
 * LOWER symbols
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   !  |   "  |   #  |   $  |   %  |                    |   &  |   /  |   (  |   )  |   =  |  '   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   1  | 2/@  |   3  |   4  |   5  |-------.    ,-------|   6  |   7  |   8  |   9  |   0  |  }   |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |   <  |   >  |      |      |      |-------|    |-------|      |      |      |      |      |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */
// modifiers to try for algr key
// ROPT(), ALGR(), RALT()

// Row 1 ALGR
#define LCM_TILD ALGR(LCM_NTIL)  // ~
#define LCM_AT   ALGR(LCM_2)    // @
#define LCM_CIRC ALGR(LCM_LCBR)    // ^ */
#define LCM_GRV  ALGR(LCM_RCBR)  // `
#define LCM_BSLS ALGR(LCM_QUOT) // \ (backslash)

// Row 1
#define LCM_EXLM S(LCM_1)    // !
#define LCM_DQUO S(LCM_2)    // "
#define LCM_HASH S(LCM_3)    // #
#define LCM_DLR  S(LCM_4)    // $
#define LCM_PERC S(LCM_5)    // %
#define LCM_AMPR S(LCM_6)    // &
#define LCM_SLSH S(LCM_7)    // /
#define LCM_LPRN S(LCM_8)    // (
#define LCM_RPRN S(LCM_9)    // )
#define LCM_EQL S(LCM_0)     // =
#define LCM_ASTR S(LCM_PLUS) // *

// Row 2

#define LCM_LBRC S(LCM_LCBR) // [
#define LCM_RBRC S(LCM_RCBR) // ]

// Row 3

/* #define CM_DQUO S(CM_QUOT) // " */
// Row 4
#define LCM_LABK KC_NUBS // <
#define LCM_RABK S(LCM_LABK)  // >
#define LCM_COLN S(LCM_DOT) // :
#define LCM_SCLN S(LCM_COMM)    // ;
#define LCM_UNDS S(LCM_MINS) // _
#define LCM_QUES S(LCM_ACUT) // ?
/* #define LCM_IEXL KC_EQL // ¿ */
#define LCM_IEXL KC_PLUS //
#define LCM_IQUE KC_EQL // ¿

// DEPRECATED
#define KC_CM_Q    CM_Q
#define KC_CM_W    CM_W
#define KC_CM_F    CM_F
#define KC_CM_P    CM_P
#define KC_CM_G    CM_G
#define KC_CM_J    CM_J
#define KC_CM_L    CM_L
#define KC_CM_U    CM_U
#define KC_CM_Y    CM_Y
#define KC_CM_SCLN CM_SCLN
#define KC_CM_A    CM_A
#define KC_CM_R    CM_R
#define KC_CM_S    CM_S
#define KC_CM_T    CM_T
#define KC_CM_D    CM_D
#define KC_CM_H    CM_H
#define KC_CM_N    CM_N
#define KC_CM_E    CM_E
#define KC_CM_I    CM_I
#define KC_CM_O    CM_O
#define KC_CM_Z    CM_Z
#define KC_CM_X    CM_X
#define KC_CM_C    CM_C
#define KC_CM_V    CM_V
#define KC_CM_B    CM_B
#define KC_CM_K    CM_K
#define KC_CM_M    CM_M
#define KC_CM_COMM CM_COMM
#define KC_CM_DOT  CM_DOT
#define KC_CM_SLSH CM_SLSH
