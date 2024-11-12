#include QMK_KEYBOARD_H

#include "sendstring_latam_colemak.h"
/* CM_O */
/* https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/sendstring_colemak.h */

/* latam colemak is LCM, default colemak is CM */
#include "latam_colemak.h"
/* #include "keymap_colemak.h" */
// CM_0
//https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/keymap_colemak.h

#include "keymap_spanish.h"
// ES_0
//https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/keymap_spanish.h

#ifdef PROTOCOL_LUFA
  #include "lufa.h"
  #include "split_util.h"
#endif
#ifdef SSD1306OLED
  #include "ssd1306.h"
#endif

//TODO PERMISSIVE HOLD
//https://beta.docs.qmk.fm/using-qmk/software-features/tap_hold
//
//TODO emojis
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_unicode
//
//TODO layers
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
//
//TODO AUTO SHIFT
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_auto_shift
//
//TODO DYNAMIC MACROS
//https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_dynamic_macros
//
//TODO MOUSE KEYS
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_pointing_device
//https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_mouse_keys
//TODO OLED (NOT READ YET)
//TODOhttps://beta.docs.qmk.fm/using-qmk/hardware-features/displays/feature_oled_driver

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

enum layer_number {
  _COLEMAK = 0,
  _MAC,
  _LOWER,
  _RAISE,
  _ADJUST,
};

/* // you need to add the combo count to config.h each time you add a combo */
/* // */
/* // you can toggle them by defining to a key CMB_TOG */
/* enum combos { */
/*   ZQ_CAPS, */
/*   JK_TAB, */
/*    ZC_COPY, */
/*   XV_PASTE, */
/* }; */
/**/
/* const uint16_t PROGMEM zq_combo[] = {KC_Z, KC_Q, COMBO_END}; */
/* const uint16_t PROGMEM jk_combo[] = {LCM_J, LCM_K, COMBO_END}; */
/* const uint16_t PROGMEM copy_combo[] = {KC_Z, KC_C, COMBO_END}; */
/* const uint16_t PROGMEM paste_combo[] = {KC_X, KC_V, COMBO_END}; */
/**/
/* void process_combo_event(uint16_t combo_index, bool pressed) { */
/*   switch(combo_index) { */
/*     case ZC_COPY: */
/*       if (pressed) { */
/*         tap_code16(LCTL(KC_C)); */
/*       } */
/*       break; */
/*     case XV_PASTE: */
/*       if (pressed) { */
/*         tap_code16(LCTL(KC_V)); */
/*       } */
/*       break; */
/*   } */
/* } */
/**/
/* combo_t key_combos[COMBO_COUNT] = { */
/*   [ZQ_CAPS] = COMBO(zq_combo, KC_CAPS), */
/*   [JK_TAB] = COMBO(jk_combo, KC_TAB), */
/*   [ZC_COPY] = COMBO_ACTION(copy_combo), */
/*   [XV_PASTE] = COMBO_ACTION(paste_combo), */
/* }; */

/* typedef struct { */
/*     bool is_press_action; */
/*     uint8_t state; */
/* } tap; */
/**/
/* // optional, for the most advanced use cases */
/* enum { */
/*     SINGLE_TAP = 1, */
/*     SINGLE_HOLD, */
/*     DOUBLE_TAP, */
/*     DOUBLE_HOLD, */
/*     DOUBLE_SINGLE_TAP, // Send two single taps */
/*     TRIPLE_TAP, */
/*     TRIPLE_HOLD */
/* }; */
/**/
/* // Tap dance enums */
/* enum { */
/*     X_CTL, */
/*     TD_DC, // . -> : */
/*     TD_CS, // , -> ; */
/*     TD_CIRC_PLUS, // ¿ -> par */
/*     TD_CLOSE_RELOAD, */
/*     TD_PAR, // ¿ -> par */
/*     TD_PLUS, // - -> + */
/* }; */
/**/
/* //https://beta.docs.qmk.fm/using-qmk/software-features/feature_tap_dance */
/* // for every tap dance, make one of these */
/* uint8_t cur_dance(tap_dance_state_t *state); */
/* void dc_finished(tap_dance_state_t *state, void *user_data); */
/* void dc_reset(tap_dance_state_t *state, void *user_data); */
/* void cs_finished(tap_dance_state_t *state, void *user_data); */
/* void cs_reset(tap_dance_state_t *state, void *user_data); */
/* void web_finished(tap_dance_state_t *state, void *user_data); */
/* void web_reset(tap_dance_state_t *state, void *user_data); */
/* void CIRC_PLUS(tap_dance_state_t *state, void *user_data); */
/**/
/* ========= */
/* MODS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/mod_tap */
/* for left control and shift when holding but esc when tapping */
/* MT(MOD_LCTL | MOD_LSFT, KC_ESC) */
/* there are also shortcuts for these */
/* LALT_T(kc) */

//space cadets (shift taps) are in config.h

/* ========= */
/* LAYERS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers */
/* OSL avtivates mapping until next key is pressed */
/* ========= */
/* MAPPINGS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/simple-keycodes/keycodes_basic */
/* https://en.wikipedia.org/wiki/QWERTY#/media/File:KB_United_States.svg */
/* KC_BSLS = } */
/* KC_MINS = ' */
/* KC_RALT = RIGHTALT  */
/* KC_ALGR = Alt-gr  */
/* KC_NUBS = <  */
/* KC_LSPO = LEFT SHIFT WHEN HOLD, ( WHEN TAPPED */
/* KC_RSPC = right SHIFT WHEN HOLD, ) WHEN TAPPED */
/* KC_LEAD = leaderkey  */
/* create macro for \ */


enum custom_keycodes {
  CTL_C = LT(10, LCM_C),
  CTL_V = LT(10, LCM_V),
};

//https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

/* QWERTY
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * | ESC  |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  |  ~   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |                    |   Y  |   U  |   I  |   O  |   P  |  -   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |LCTL |   A  |   S  |   D  |   F  |   G  |-------.    ,-------|   H  |   J  |   K  |   L  |   ;  |  '   |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   N  |   M  |   ,  |   .  |   /  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */

 // OSL() layer for one keypress
 // TG() toggles layer
 // KC_LEAD, for leader, enable it in rules.mk as well, also uncomment the leader sectio

 [_COLEMAK] = LAYOUT( \
        CAPS_EMU,   WK1,    WK2,     WK3,     WK4,      WK5,                   WK6,     WK7,       WK8,     WK9,      WK0,    LGUI(LCM_W), \
      KC_TAB,   LCM_Q,   LCM_W,    LCM_F,    LCM_P,    LCM_G,                 LCM_J,    LCM_L,    LCM_U,    LCM_Y,    LCM_NTIL, KC_LBRC, \
      KC_ESC, LCM_A,   LCM_R,    LCM_S,    LCM_T,    LCM_D,                   LCM_H,    LCM_N,    LCM_E,    LCM_I,    LCM_O, LCM_QUOT, \
  SC_LSPO,  LCM_Z,   LCM_X,    LCM_C,    LCM_V,    LCM_B, OSL(_MAC), KC_AMPR, LCM_K,    LCM_M,    LCM_COMM, LCM_DOT,  LCM_MINS, SC_RSPC,\
              KC_LGUI, OSL(_RAISE), LALT_T(KC_ENT), CTL_T(KC_DEL),      KC_BSPC, LT(_LOWER,KC_SPC), ROPT_T(KC_F5), LT(_ADJUST, KC_DEL) \
),


 [_MAC] = LAYOUT( \
        CAPS_EMU,   WK1,    WK2,     WK3,     WK4,      WK5,                   WK6,     WK7,       WK8,     WK9,      WK0,    LGUI(LCM_W), \
      KC_TAB,   LCM_Q,   LCM_W,    LCM_F,    LCM_P,    LCM_G,                 LCM_J,    LCM_L,    LCM_U,    LCM_Y,    LCM_NTIL, KC_LBRC, \
      KC_ESC, LCM_A,   LCM_R,    LCM_S,    LCM_T,    LCM_D,                   LCM_H,    LCM_N,    LCM_E,    LCM_I,    LCM_O, LCM_QUOT, \
  SC_LSPO,  LCM_Z,   LCM_X,      CTL_C,   CTL_V,    LCM_B, OSL(_MAC), KC_AMPR, LCM_K,    LCM_M,    LCM_COMM, LCM_DOT,  LCM_MINS, SC_RSPC,\
              KC_LGUI, OSL(_RAISE), LALT_T(KC_ENT), CTL_T(KC_DEL),      KC_BSPC, LT(_LOWER,KC_SPC), ROPT_T(KC_F5), LT(_ADJUST, KC_DEL) \
),



 /* /1* [_QWERTY] = LAYOUT( \ */
 /*  KC_ESC,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,                     KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_GRV, \ */
 /*  KC_TAB,   KC_Q,   KC_W,    KC_E,    KC_R,    KC_T,                     KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_MINS, \ */
 /*  KC_LCTL, KC_A,   KC_S,    KC_D,    KC_F,    KC_G,                     KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, \ */
 /*  KC_LSFT,  KC_Z,   KC_X,    KC_C,    KC_V,    KC_B, KC_LBRC,  KC_RBRC,  KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH,  KC_RSFT, \ */
 /*              MO(_LOWER),KC_LGUI, KC_LALT, LT(_LOWER,KC_SPC),  LT(_RAISE,KC_ENT),  KC_BSPC, KC_RGUI, MO(_RAISE) \ */
/* ), */
/* LOWER
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   !  |   @  |   #  |   $  |   %  |                    |   ^  |   &  |   *  |   (  |   )  |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |   1  |   2  |   3  |   4  |   5  |-------.    ,-------|   6  |   7  |   8  |   9  |   0  |      |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|   |  |   `  |   +  |   {  |   }  |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */
[_LOWER] = LAYOUT( \
  _______, _______, _______, _______, _______, _______,                          _______, _______, _______,_______, _______, _______,\
  _______, KC_EXLM, KC_AT,   KC_HASH, KC_DLR,  KC_PERC,                          KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, LCM_GRV, \
  _______, KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                             KC_6,    KC_7,    KC_8,    KC_9,    KC_0,  LCM_IQUE, \
  _______, LCM_LABK, LCM_AT, LCM_RABK, LCM_CIRC, LCM_TILD, _______,    _______, LCM_BSLS, LCM_PIPE, COMM_SPC, LCM_DOT , LCM_PLUS, _______, \
                             _______, _______, _______, _______,                  _______,  _______, _______, _______\
),
/* RAISE
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |                    |  F7  |  F8  |  F9  | F10  | F11  | F12  |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------.    ,-------|      | Left | Down |  Up  |Right |      |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|   +  |   =  |   [  |   ]  |   \  |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */

[_RAISE] = LAYOUT( \
          _______, _______, _______, _______, _______, _______,                         _______, _______, _______, _______, _______, _______, \
           XXXXXXX,   KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,                           KC_F6,   KC_F7,   KC_F8,   KC_F9,  KC_F10,  XXXXXXX, \
           XXXXXXX, XXXXXXX, XXXXXXX, KC_F11, KC_F12, LSFT(KC_PSCR),                         KC_LEFT, KC_DOWN, KC_UP, KC_RGHT, XXXXXXX, XXXXXXX, \
  _______, XXXXXXX, KC_MEDIA_SELECT, KC_MEDIA_PLAY_PAUSE, LALT(KC_F4),_______,_______,  _______, XXXXXXX, XXXXXXX,  SCLN_END, COLN_END, _______, _______, \
                             _______, _______, _______,  _______,               _______, RCTL_T(KC_SPC),  LT(_ADJUST,KC_SPC), _______ \
),

/* ADJUST
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |                    |      |      |      |      |      |      |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------.    ,-------|      |      |      |      |      |      |
 * |------+------+------+------+------+------|       |    |       |------+------+------+------+------+------|
 * |      |      |      |      |      |      |-------|    |-------|      |      |      |      |      |      |
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `----------------------------'           '------''--------------------'
 */
// keycodes https://docs.qmk.fm/#/faq_keymap?id=what-keycodes-can-i-use
  [_ADJUST] = LAYOUT( \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,                    XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  KC_SYSTEM_POWER, KC_SYSTEM_SLEEP, XXXXXXX, KC_BRID, KC_BRIU, XXXXXXX,             XXXXXXX, XXXXXXX, KC_INS, XXXXXXX, XXXXXXX, XXXXXXX, \
  KC_CAPS, XXXXXXX, KC_MUTE, KC_VOLD, KC_VOLU, KC_CLEAR,         KC_HOME, KC_PGDN, KC_PGUP, KC_END, XXXXXXX, KC_LSFT, \
  _______, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, _______,\
                             _______, _______, _______, _______, _______,  _______, _______, _______ \
  )
};


// Setting ADJUST layer RGB back to default
void update_tri_layer_RGB(uint8_t layer1, uint8_t layer2, uint8_t layer3) {
  if (IS_LAYER_ON(layer1) && IS_LAYER_ON(layer2)) {
    layer_on(layer3);
  } else {
    layer_off(layer3);
  }
}

//SSD1306 OLED update loop, make sure to enable OLED_ENABLE=yes in rules.mk
#ifdef OLED_ENABLE

oled_rotation_t oled_init_user(oled_rotation_t rotation) {
    if (!is_keyboard_master()) {
      // for left master exchange the return values
        return OLED_ROTATION_180;
      }
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

/* check the alt tab advanced to see fun stuff */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros */

/* you can use timers */

/* Software Timers */

/* It's possible to start timers and read values for time-specific events. Here's an example: */

/* static uint16_t key_timer; */
/* key_timer = timer_read(); */
/* ​ */
/* if (timer_elapsed(key_timer) < 100) { */
/*   // do something if less than 100ms have passed */
/* } else { */
/*   // do something if 100ms or more have passed */
/* } */

/* for colemak: #include "sendstring_colemak.h" */


// MY SIMPLE MACROS
bool is_caps_emu_active = false;
uint16_t key_timer;
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (record->event.pressed) {
#ifdef OLED_ENABLE
    set_keylog(keycode, record);
#endif
    // set_timelog();

        switch (keycode) {
            case CTL_C:
              SEND_STRING(SS_LCTL("c"));
            case CTL_V:
              SEND_STRING(SS_LCTL("v"));
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

// MY HOLD AND TAP TIMINGS
uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {

    /* case TD(TD_PLUS): */
    /*     return TAPPING_TERM + 40; */

  case SC_LSPO:
    return TAPPING_TERM + 30;
  case SC_RSPC:
    /* return TAPPING_TERM - 50; */
    return TAPPING_TERM + 30;
  case LT(_LOWER, KC_SPC):

    /* return TAPPING_TERM - 10; */
    //NOTE: important one
    return TAPPING_TERM + 40;  // 20 was not so bad

  case LALT_T(KC_ENT):
    /* return TAPPING_TERM - 10; */
    //NOTE: important one
    return TAPPING_TERM + 20;

  /* case TD(TD_HTTP_TYPE): */
  /*     return TAPPING_TERM + 50; */
  /* case LT(1, KC_GRV): */
  /*     return 130; */
  default:
    return TAPPING_TERM;
  }
}

// ============
// LEADER KEY
// ============
// for colemak codes
/* LEADER_EXTERNS(); */
/**/
/* void matrix_scan_user(void) { */
/*     LEADER_DICTIONARY() { */
/*       leading = false; */
/*       leader_end(); */
/**/
/*     SEQ_ONE_KEY(LCM_M) { */
/*         SEND_STRING("255.255.255."); */
/*     } */
/**/
/*     SEQ_ONE_KEY(LCM_H) { */
/*         SEND_STRING("https:" SS_LSFT("77")); */
/*     } */
/*     SEQ_TWO_KEYS(KC_LSPO, LCM_H) { */
/*         SEND_STRING("https:" SS_LSFT("77") "github.com" SS_LSFT("7")); */
/*     } */
/**/
/*       // register_code(KC_LGUI); */
/*       // register_code(KC_S); */
/*       // unregister_code(KC_S); */
/*       // unregister_code(KC_LGUI) */
/*     SEQ_ONE_KEY(KC_LEAD) { */
/*         // SEND_STRING(); */
/*         SEND_STRING("jbernal" SS_ALGR("2") "unal.edu.co"); */
/*     } */
/*     SEQ_ONE_KEY(LCM_C) { */
/*         //TEMPORAL */
/*         // setxkbmap latam -variant colemak */
/*         SEND_STRING("rfgxebma" SS_TAP(X_P) " iagam " SS_TAP(X_MINS) "vapuakg cyifmae\n"); */
/**/
/*     } */
/*     SEQ_TWO_KEYS(KC_RSPC, LCM_C) { */
/*         //PERMANENT */
/*         // sudo localectl set-x11-keymap latam pc104 colemak && sudo localectl set-keymap colemak */
/*         SEND_STRING("rlsy iycaifcgi rfg" SS_TAP(X_MINS) "x11" SS_TAP(X_MINS) "efjma" SS_TAP(X_P) " iagam " SS_TAP(X_P) "c104 cyifmae " SS_LSFT("77") " rlsy iycaifcgi rfg" SS_TAP(X_MINS) "efjma" SS_TAP(X_P) " cyifmae\n"); */
/*     } */
/*     // SEQ_TWO_KEYS(KC_E, KC_D) { */
/*      // SEND_STRING(SS_LGUI("r") "cmd\n" SS_LCTL("c")); */
/*       // did_leader_succeed = true; */
/*     // } */
/*     leader_end(); */
/*   } */
/* } */

/* void leader_start(void) { */
/*   // sequence started */
/* } */

/* void leader_end(void) { */
  // sequence ended (no success/failuer detection)
/* } */


