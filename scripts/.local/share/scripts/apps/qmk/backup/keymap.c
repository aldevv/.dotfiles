#include QMK_KEYBOARD_H

#include "sendstring_colemak.h"
/* CM_O */
/* https://github.com/qmk/qmk_firmware/blob/master/quantum/keymap_extras/sendstring_colemak.h */

/* #include "latam_colemak.h" */
#include "keymap_colemak.h"
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


//TODO LEADER MEY
//https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_leader_key
//
//TODO PERMISSIVE HOLD
//https://beta.docs.qmk.fm/using-qmk/software-features/tap_hold
//
//TODO
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_combo
//
//TODO
//https://beta.docs.qmk.fm/using-qmk/software-features/feature_tap_dance
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
    WK0
};

enum layer_number {
  _COLEMAK = 0,
  _LOWER,
  _RAISE,
  _ADJUST,
};


/* ========= */
/* MODS */
/* ========= */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/mod_tap */
/* for left control and shift when holding but esc when tapping */
/* MT(MOD_LCTL | MOD_LSFT, KC_ESC) */
/* there are also shortcuts for these */
/* LALT_T(kc) */

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

//https://beta.docs.qmk.fm/using-qmk/software-features/feature_layers
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

/* QWERTY
 * ,-----------------------------------------.                    ,-----------------------------------------.
 * | ESC  |   1  |   2  |   3  |   4  |   5  |                    |   6  |   7  |   8  |   9  |   0  |  ~   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |                    |   Y  |   U  |   I  |   O  |   P  |  -   |
 * |------+------+------+------+------+------|                    |------+------+------+------+------+------|
 * |LCTRL |   A  |   S  |   D  |   F  |   G  |-------.    ,-------|   H  |   J  |   K  |   L  |   ;  |  '   |
 * |------+------+------+------+------+------|   [   |    |    ]  |------+------+------+------+------+------|
 * |LShift|   Z  |   X  |   C  |   V  |   B  |-------|    |-------|   N  |   M  |   ,  |   .  |   /  |RShift|
 * `-----------------------------------------/       /     \      \-----------------------------------------'
 *                   |LOWER | LGUI | Alt  | /Space  /       \Enter \  |BackSP| RGUI |RAISE |
 *                   |      |      |      |/       /         \      \ |      |      |      |
 *                   `-------------------''-------'           '------''--------------------'
 */

  /* KC_ESC,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,                     KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_GRV, \ */
 /* [_QWERTY] = LAYOUT( \ */
 [_COLEMAK] = LAYOUT( \
  KC_GRV,   WK1,    WK2,     WK3,     WK4,      WK5,                     WK6,     WK7,     WK8,     WK9,     WK0,     KC_RBRC, \
  KC_TAB,   KC_Q,   KC_W,    KC_E,    KC_R,    KC_T,                     KC_Y,    KC_U,    KC_I,    KC_O,    ES_NTIL,    KC_LBRC, \
  KC_LCTRL, KC_A,   KC_S,    KC_D,    KC_F,    KC_G,                     KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, \
  KC_LSPO,  KC_Z,   KC_X,    KC_C,    KC_V,    KC_B, KC_LBRC,   KC_LEAD, KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, RSFT_T(CM_RPRN),\
              OSL(_RAISE),KC_LGUI, LALT_T(KC_ENT), KC_RCTRL,   KC_BSPC, LT(_LOWER,KC_SPC), ROPT_T(KC_DEL), OSL(_LOWER) \
),

 /* /1* [_QWERTY] = LAYOUT( \ */
 /*  KC_ESC,   KC_1,   KC_2,    KC_3,    KC_4,    KC_5,                     KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_GRV, \ */
 /*  KC_TAB,   KC_Q,   KC_W,    KC_E,    KC_R,    KC_T,                     KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_MINS, \ */
 /*  KC_LCTRL, KC_A,   KC_S,    KC_D,    KC_F,    KC_G,                     KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT, \ */
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
  _______, _______, _______, _______, _______, _______,                   _______, _______, _______,_______, _______, _______,\
  _______, KC_EXLM, KC_AT,   KC_HASH, KC_DLR,  KC_PERC,                   KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_MINS, \
  _______, KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                      KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_BSLS, \
  _______, KC_NUBS, RSFT(KC_NUBS), _______, _______, _______, _______, _______, KC_PIPE, KC_GRAVE, KC_PLUS, KC_LCBR, KC_RCBR, _______, \
                             _______, _______, _______, KC_ALGR, _______,  _______, _______, _______\
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
  _______, _______, _______, _______, _______, _______,                     _______, _______, _______, _______, _______, KC_PSCREEN, \
  KC_F11,   KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,                       KC_F6,   KC_F7,   KC_F8,   KC_F9,  KC_F10,  KC_F12, \
  _______, KC_BRID, KC_BRIU, KC_MUTE, KC_VOLD, KC_VOLU,                     KC_LEFT, KC_DOWN, KC_UP, KC_RGHT,   XXXXXXX, XXXXXXX, \
  _______, _______, _______, _______, KC_MEDIA_SELECT, _______,   _______, _______, KC_PLUS, KC_EQL,  KC_LBRC, KC_RBRC, _______, _______, \
                             _______, _______, _______,  _______, _______,  _______, _______, _______ \
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
  [_ADJUST] = LAYOUT( \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,                   XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,                   XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,                   XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, \
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,\
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

//SSD1306 OLED update loop, make sure to enable OLED_DRIVER_ENABLE=yes in rules.mk
#ifdef OLED_DRIVER_ENABLE


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

void oled_task_user(void) {
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
}

#endif // OLED_DRIVER_ENABLE

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

/* There's also a couple of mod shortcuts you can use: */
/* SS_LCTL(string) */
/* SS_LSFT(string) */
/* SS_LALT(string) or SS_LOPT(string) */
/* SS_LGUI(string), SS_LCMD(string) or SS_LWIN(string) */
/* SS_RCTL(string) */
/* SS_RSFT(string) */
/* SS_RALT(string), SS_ROPT(string) or SS_ALGR(string) */
/* SS_RGUI(string), SS_RCMD(string) or SS_RWIN(string) */
/* https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros */

// MY HOLD AND TAP TIMINGS
uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LALT_T(KC_ENT):
            return TAPPING_TERM - 10;
        /* case LT(1, KC_GRV): */
        /*     return 130; */
        default:
            return TAPPING_TERM;
    }
}

// MY SIMPLE MACROS
// for colemak codes
//#include "sendstring_colemak.h"
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (record->event.pressed) {
#ifdef OLED_DRIVER_ENABLE
    set_keylog(keycode, record);
#endif
    // set_timelog();

        switch (keycode) {
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

// LEADER KEY
// for colemak codes
LEADER_EXTERNS();

void matrix_scan_user(void) {
    LEADER_DICTIONARY() {
      leading = false;
      leader_end();

    SEQ_ONE_KEY(KC_W) {
        // Anything you can do in a macro.
        SEND_STRING(SS_ALGR("w"));
      /* register_code(KC_LGUI); */
      /* register_code(KC_S); */
      /* unregister_code(KC_S); */
      /* unregister_code(KC_LGUI) */

    }
    SEQ_ONE_KEY(KC_O) {
        /* SEND_STRING(); */
      register_code(CM_6);
    }
    /* SEQ_TWO_KEYS(KC_E, KC_D) { */
    /*   SEND_STRING(SS_LGUI("r") "cmd\n" SS_LCTL("c")); */
      /* did_leader_succeed = true; */
    /* } */
    leader_end();
  }
}

/* void leader_start(void) { */
/*   // sequence started */
/* } */

/* void leader_end(void) { */
  // sequence ended (no success/failuer detection)
/* } */
