/*
This is the c configuration file for the keymap

Copyright 2012 Jun Wako <wakojun@gmail.com>
Copyright 2015 Jack Humbert

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma once

//#define USE_MATRIX_I2C

/* Select hand configuration */

 // #define SPLIT_USB_DETECT
#define MASTER_LEFT
// #define MASTER_RIGHT
// needed to flash with make lily58:mine-def:avrdude-split-left with only left side connected
// needed to flash with make lily58:mine-def:avrdude-split-right with only right side connected
// then it can detect the master alone
// #define EE_HANDS  // this is so that any of both sides can be master
// #define SPLIT_WPM_ENABLE

#define OLED_DRIVER

#define USE_SERIAL_PD2

#define TAPPING_FORCE_HOLD
#define TAPPING_TERM_PER_KEY
#define LEADER_PER_KEY_TIMING
#define LEADER_TIMEOUT 400
#define COMBO_COUNT 4
#define COMBO_TERM 160
#define TAPPING_TERM 165
/* #define */
// KC_TRNS for no tap mod
// it doesn't read the colemak redefinitions

// KC_8 = (
// KC_9 = )
/* #define LSPO_KEYS KC_LSFT, KC_LSFT, KC_8 */
/* #define RSPC_KEYS KC_RSFT, KC_LSFT, KC_9 */
// quot = [
// bsls = ]
/* #define LSPO_KEYS KC_LSFT, KC_LSFT, KC_QUOT */
/* #define RSPC_KEYS KC_RSFT, KC_LSFT, KC_BSLS */
// quot = {
// bsls = }
#define LSPO_KEYS KC_LSFT, KC_TRNS, KC_QUOT
#define RSPC_KEYS KC_RSFT, KC_TRNS, KC_BSLS
