#include <stdatomic.h>
#include QMK_KEYBOARD_H
#include "latam_colemak.h" // colemak keys
#include "keymap_spanish.h" // ñ
#ifdef PROTOCOL_LUFA
#include "lufa.h"
#include "split_util.h"
#endif

extern uint8_t is_master;

// macros
enum my_macros {
  WK1 = SAFE_RANGE,
  WK2,
  WK3,
  WK4,
  WK5,
  WK6,
  WK7,
  WK8,
  WK9,
  WK0,
  COMM_SPC,
  SCLN_END,
  COLN_END,
  CAPS_EMU,
};

/*
enum custom_keycodes {
  CTL_C = LT(10, LCM_C),
  CTL_V = LT(10, LCM_V),
};
*/

enum layer_number {
  _COLEMAK = 0,
  _LOWER,
  _RAISE,
  _ADJUST,
  _COLEMAK_EMU,
  _MAC,
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

 // OSL() layer for one keypress
 // TG() toggles layer
 // KC_LEAD, for leader, enable it in rules.mk as well, also uncomment the leader sectio


/* COLEMAK
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |  EMU |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  | MUTE |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   F  |   P  |   G  |                    |   J  |   L  |   U  |   Y  |   Ñ  |  ´   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | CAPS |   A  |   R  |   S  |    T  |  D  |-------.    ,-------|   H  |   N  |   E  |   I  |   O  |  '   |
 * |------+------+------+------+------+------| QWERTY|    |  MAC  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   K  |   M  |   ,  |   .  |   -  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |ADJUST| RAISE| CTRL | / ALT  /       \ LGUI \  | Space| ROPT |ADJUST |
 *                   | F11  |      |BackSP|/ DEL  /         \      \ | Lower|      | F12  |
 *                   `-------------------''-------'           '------''--------------------'
 */
 [_COLEMAK] = LAYOUT(
  CAPS_EMU,  WK1,    WK2,     WK3,     WK4,      WK5,                                 WK6,      WK7,      WK8,      WK9,      WK0,       KC_MUTE,
  KC_TAB,    LCM_Q,  LCM_W,   LCM_F,   LCM_P,    LCM_G,                               LCM_J,    LCM_L,    LCM_U,    LCM_Y,    LCM_NTIL,  KC_LBRC,
  KC_ESC,    LCM_A,  LCM_R,   LCM_S,   LCM_T,    LCM_D,                               LCM_H,    LCM_N,    LCM_E,    LCM_I,    LCM_O,     LCM_QUOT,
  SC_LSPO,   LCM_Z,  LCM_X,   LCM_C,   LCM_V,    LCM_B, DF(_COLEMAK_EMU),  DF(_MAC),  LCM_K,    LCM_M,    LCM_COMM, LCM_DOT,  LCM_MINS,  SC_RSPC,
          LT(_ADJUST, KC_F11), OSL(_RAISE), CTL_T(KC_BSPC), LALT_T(KC_DEL),   LGUI_T(KC_ENT), LT(_LOWER,KC_SPC), ROPT_T(KC_F5), MO(_ADJUST)
),

/* LOWER
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |                    |  F7  |  F8  |  F9  | F10  | F11  | F12  |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |   `  |   !  |   @  |   #  |   $  |   %  |-------.    ,-------|   ^  |   &  |   *  |   (  |   )  |   ~  |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|      |   _  |   +  |   {  |   }  |   |  |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   | LAlt | LGUI |LOWER | /Space  /       \Enter \  |RAISE |BackSP| RGUI |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */
 [_LOWER] = LAYOUT(
   _______, _______, _______, _______, _______, _______,                         _______,   _______,   _______,   _______,   _______,  _______,
   _______, KC_EXLM, KC_AT,   KC_HASH,  KC_DLR,   KC_PERC,                       KC_CIRC,   KC_AMPR,   KC_ASTR,   KC_LPRN,   KC_RPRN,  LCM_GRV,
   _______, KC_1,    KC_2,    KC_3,     KC_4,     KC_5,                          KC_6,      KC_7,      KC_8,      KC_9,      KC_0,     LCM_IQUE,
   _______, LCM_LABK, LCM_AT, LCM_RABK, LCM_CIRC, LCM_TILD, _______,    _______, LCM_BSLS,  LCM_PIPE,  COMM_SPC,  LCM_DOT ,  LCM_PLUS, _______,
               _______, _______, LCTL(KC_BSPC), LCTL(KC_DEL),                  _______,  _______, _______, _______
 ),
/* RAISE
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |   `  |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |-------.    ,-------|      | Left | Down |  Up  |Right |      |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |  F7  |  F8  |  F9  | F10  | F11  | F12  |-------|    |-------|   +  |   -  |   =  |   [  |   ]  |   \  |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   | LAlt | LGUI |LOWER | /Space  /       \Enter \  |RAISE |BackSP| RGUI |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */

 [_RAISE] = LAYOUT(
   _______,  _______,  _______,          _______,              _______,      _______,                            _______,  _______,  _______,   _______,   _______,  _______,
   XXXXXXX,  KC_F1,    KC_F2,            KC_F3,                KC_F4,        KC_F5,                              KC_F6,    KC_F7,    KC_F8,     KC_F9,     KC_F10,   XXXXXXX,
   XXXXXXX,  XXXXXXX,  XXXXXXX,          KC_F11,               KC_F12,       LSFT(KC_PSCR),                      KC_LEFT,  KC_DOWN,  KC_UP,     KC_RGHT,   XXXXXXX,  XXXXXXX,
   _______,  XXXXXXX,  KC_MEDIA_SELECT,  KC_MEDIA_PLAY_PAUSE,  LALT(KC_F4),  _______,        _______,  _______,  XXXXXXX,  XXXXXXX,  SCLN_END,  COLN_END,  _______,  _______,
                              _______, _______, _______,  _______,               _______, RCTL_T(KC_SPC),  LT(_ADJUST,KC_SPC), _______
 ),
/* ADJUST
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------.    ,-------|      |      |RGB ON| HUE+ | SAT+ | VAL+ |
 * |------+------+------+------+------+------|       |    |       |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|      |      | MODE | HUE- | SAT- | VAL- |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   | LAlt | LGUI |LOWER | /Space  /       \Enter \  |RAISE |BackSP| RGUI |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */
  [_ADJUST] = LAYOUT(
  KC_SYSTEM_POWER,   XXXXXXX,          XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX,                       XXXXXXX,   XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX, \
  XXXXXXX,           KC_SYSTEM_SLEEP,  XXXXXXX,  KC_BRID,  KC_BRIU,  XXXXXXX,                       XXXXXXX,   XXXXXXX,  KC_INS,   XXXXXXX,  XXXXXXX,  XXXXXXX, \
  KC_CAPS,           XXXXXXX,          KC_MUTE,  KC_VOLD,  KC_VOLU,  KC_CLEAR,                      KC_HOME,   KC_PGDN,  KC_PGUP,  KC_END,   XXXXXXX,  KC_LSFT, \
  _______,           XXXXXXX,          XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX,   XXXXXXX,  XXXXXXX,   XXXXXXX,  XXXXXXX,  XXXXXXX,  XXXXXXX,  _______,\
                                                _______, _______, _______, _______,           _______,  _______, _______, _______ \
  ),
/* QWERTY
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * | ESC  |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  |  `   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |                    |   Y  |   U  |   I  |   O  |   P  |  -   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |LCTRL |   A  |   S  |   D  |   F  |   G  |-------.    ,-------|   H  |   J  |   K  |   L  |   ;  |  '   |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   N  |   M  |   ,  |   .  |   /  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   | LAlt | LGUI |LOWER | /Space  /       \Enter \  |RAISE |BackSP| RGUI |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */

 [_COLEMAK_EMU] = LAYOUT(
  CAPS_EMU,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,                          KC_6,    KC_7,    KC_8,    KC_9,    KC_0,     KC_GRV,
  KC_TAB,     KC_Q,   KC_W,    KC_F,    KC_P,    KC_G,                          KC_J,    KC_L,    KC_U,    KC_Y,    KC_SCLN,  KC_LBRC,
  KC_ESC,     KC_A,   KC_R,    KC_S,    KC_T,    KC_D,                          KC_H,    KC_N,    KC_E,    KC_I,    KC_O,     KC_QUOT,
  SC_LSPO,    KC_Z,   KC_X,    KC_C,    KC_V,    KC_B, DF(_COLEMAK),  KC_BSLS, KC_K,    KC_M,    KC_COMM, KC_DOT,   KC_MINS,  SC_RSPC,
  LT(_ADJUST, KC_F11), OSL(_RAISE), CTL_T(KC_BSPC), LALT_T(KC_DEL),   LGUI_T(KC_ENT), LT(_LOWER,KC_SPC), ROPT_T(KC_F5), LT(_ADJUST, KC_F12)
 ),

/* COLEMAK
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |  EMU |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  | MUTE |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   F  |   P  |   G  |                    |   J  |   L  |   U  |   Y  |   Ñ  |  ´   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | CAPS |   A  |   R  |   S  |    T  |  D  |-------.    ,-------|   H  |   N  |   E  |   I  |   O  |  '   |
 * |------+------+------+------+------+------| QWERTY|    |  MAC  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   K  |   M  |   ,  |   .  |   -  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |ADJUST| RAISE| LGUI | / ALT  /       \ CTRL \  | Space| ROPT |ADJUST |
 *                   | F11  |      |BackSP|/ DEL  /         \      \ | Lower|      | F12  |
 *                   `-------------------''-------'           '------''--------------------'
 */
 [_MAC] = LAYOUT(
  CAPS_EMU,  WK1,    WK2,     WK3,     WK4,      WK5,                                     WK6,      WK7,      WK8,      WK9,      WK0,       KC_MUTE,
  KC_TAB,    LCM_Q,  LCM_W,   LCM_F,   LCM_P,    LCM_G,                                   LCM_J,    LCM_L,    LCM_U,    LCM_Y,    LCM_NTIL,  KC_LBRC, 
  KC_ESC,    LCM_A,  LCM_R,   LCM_S,   LCM_T,    LCM_D,                                   LCM_H,    LCM_N,    LCM_E,    LCM_I,    LCM_O,     LCM_QUOT,
  SC_LSPO,   LCM_Z,  LCM_X,   LCM_C,   LCM_V,    LCM_B, DF(_COLEMAK_EMU),  DF(_COLEMAK),  LCM_K,    LCM_M,    LCM_COMM, LCM_DOT,  LCM_MINS,  SC_RSPC,
          LT(_ADJUST, KC_F11), OSL(_RAISE), LGUI_T(KC_BSPC), LALT_T(KC_DEL),   LCTL_T(KC_ENT), LT(_LOWER,KC_SPC), ROPT_T(KC_F5), LT(_ADJUST, KC_F12)
 )
};


//SSD1306 OLED update loop, make sure to enable OLED_ENABLE=yes in rules.mk
#ifdef OLED_ENABLE

oled_rotation_t oled_init_user(oled_rotation_t rotation) {
  if (!is_keyboard_master())
    return OLED_ROTATION_180;  // flips the display 180 degrees if offhand
  return rotation;
}

// When you add source files to SRC in rules.mk, you can use functions.
const char *read_layer_state(void);
const char *read_logo(void);
void set_keylog(uint16_t keycode, keyrecord_t *record);
const char *read_keylog(void);
const char *read_keylogs(void);

// const char *read_mode_icon(bool swap);
// const char *read_host_led_state(void);
// void set_timelog(void);
// const char *read_timelog(void);

bool oled_task_user(void) {
  if (is_keyboard_master()) {
    // If you want to change the display of OLED, you need to change here
    oled_write_ln(read_layer_state(), false);
    oled_write_ln(read_keylog(), false);
    oled_write_ln(read_keylogs(), false);
    //oled_write_ln(read_mode_icon(keymap_config.swap_lalt_lgui), false);
    //oled_write_ln(read_host_led_state(), false);
    //oled_write_ln(read_timelog(), false);
  } else {
    oled_write(read_logo(), false);
  }
    return false;
}
#endif // OLED_ENABLE


// NOTE: MACROS

// PERMISSIVE HOLD
// https://beta.docs.qmk.fm/using-qmk/software-features/tap_hold
//
// emojis
// https://beta.docs.qmk.fm/using-qmk/software-features/feature_unicode
//
// layers
// https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
//
// AUTO SHIFT
// https://beta.docs.qmk.fm/using-qmk/software-features/feature_auto_shift
//
// DYNAMIC MACROS
// https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_dynamic_macros
//
// MOUSE KEYS
// https://beta.docs.qmk.fm/using-qmk/software-features/feature_pointing_device
// https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_mouse_keys


// Setting ADJUST layer RGB back to default
/* void update_tri_layer_RGB(uint8_t layer1, uint8_t layer2, uint8_t layer3) { */
/*   if (IS_LAYER_ON(layer1) && IS_LAYER_ON(layer2)) { */
/*     layer_on(layer3); */
/*   } else { */
/*     layer_off(layer3); */
/*   } */
/* } */

bool is_caps_emu_active = false;
uint16_t key_timer;
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (record->event.pressed) {
#ifdef OLED_ENABLE
    set_keylog(keycode, record);
#endif
    // set_timelog();

    switch (keycode) {
    /*
    case CTL_C:
      SEND_STRING(SS_LCTL("c"));
    case CTL_V:
      SEND_STRING(SS_LCTL("v"));
      */
    case WK1:
      SEND_STRING(SS_LGUI("1"));
      return false; // Skip all further processing of this key
    case WK2:
      SEND_STRING(SS_LGUI("2"));
      return false; // Skip all further processing of this key
    case WK3:
      SEND_STRING(SS_LGUI("3"));
      return false; // Skip all further processing of this key
    case WK4:
      SEND_STRING(SS_LGUI("4"));
      return false; // Skip all further processing of this key
    case WK5:
      SEND_STRING(SS_LGUI("5"));
      return false; // Skip all further processing of this key
    case WK6:
      SEND_STRING(SS_LGUI("6"));
      return false; // Skip all further processing of this key
    case WK7:
      SEND_STRING(SS_LGUI("7"));
      return false; // Skip all further processing of this key
    case WK8:
      SEND_STRING(SS_LGUI("8"));
      return false; // Skip all further processing of this key
    case WK9:
      SEND_STRING(SS_LGUI("9"));
      return false; // Skip all further processing of this key
    case WK0:
      SEND_STRING(SS_LGUI("0"));
      return false; // Skip all further processing of this key
    case COMM_SPC:
      SEND_STRING(", ");
      return false; // Skip all further processing of this key
    case SCLN_END:
      tap_code16(KC_END);
      tap_code16(LCM_SCLN);
      return false; // Skip all further processing of this key
    case COLN_END:
      tap_code16(KC_END);
      tap_code16(LCM_COLN);
      return false; // Skip all further processing of this key
    case CAPS_EMU:
      if (!is_caps_emu_active) {
        register_code16(KC_LSFT);
        is_caps_emu_active = true;
      } else {
        unregister_code16(KC_LSFT);
        is_caps_emu_active = false;
      }
      return false;
      /* case KC_ENTER: */
      // Play a tone when enter is pressed
      /* PLAY_SONG(tone_qwerty); */
      /* return true; // Let QMK send the enter press/release events */
    default:
      return true; // Process all other keycodes normally
    }
  }
  return true;
}

uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LGUI_T(KC_ENT):
            return TAPPING_TERM;
        case SC_LSPO:
            return TAPPING_TERM - 10;
        case SC_RSPC:
            return TAPPING_TERM - 40;

        case LT(_LOWER,KC_SPC):
            return TAPPING_TERM - 10;

        case CTL_T(KC_BSPC):
            return TAPPING_TERM - 50;
        default:
            return TAPPING_TERM;
    }
}
