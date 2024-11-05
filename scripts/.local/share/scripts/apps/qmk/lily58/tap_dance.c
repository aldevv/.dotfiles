typedef struct {
  bool is_press_action;
  uint8_t state;
} tap;

// optional, for the most advanced use cases
enum {
  SINGLE_TAP = 1,
  SINGLE_HOLD,
  DOUBLE_TAP,
  DOUBLE_HOLD,
  DOUBLE_SINGLE_TAP, // Send two single taps
  TRIPLE_TAP,
  TRIPLE_HOLD
};

// Tap dance enums
enum {
  X_CTL,
  TD_DC,        // . -> :
  TD_CS,        // , -> ;
  TD_CIRC_PLUS, // ¿ -> par
  TD_CLOSE_RELOAD,
  TD_PAR,  // ¿ -> par
  TD_PLUS, // - -> +
};

// https://beta.docs.qmk.fm/using-qmk/software-features/feature_tap_dance
//  for every tap dance, make one of these
uint8_t cur_dance(tap_dance_state_t *state);
void dc_finished(tap_dance_state_t *state, void *user_data);
void dc_reset(tap_dance_state_t *state, void *user_data);
void cs_finished(tap_dance_state_t *state, void *user_data);
void cs_reset(tap_dance_state_t *state, void *user_data);
void web_finished(tap_dance_state_t *state, void *user_data);
void web_reset(tap_dance_state_t *state, void *user_data);
void CIRC_PLUS(tap_dance_state_t *state, void *user_data);

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

    /* case TD(TD_PLUS): */
    /*     return TAPPING_TERM + 40; */

  case KC_LSPO:
    return TAPPING_TERM - 20;
  case KC_RSPC:
    return TAPPING_TERM - 50;
  case LT(_LOWER, KC_SPC):
    return TAPPING_TERM - 10;

  /* case TD(TD_HTTP_TYPE): */
  /*     return TAPPING_TERM + 50; */
  /* case LT(1, KC_GRV): */
  /*     return 130; */
  default:
    return TAPPING_TERM;
  }
}

// ============
// DANCE TAPS
// ============
/* Return an integer that corresponds to what kind of tap dance should be
 * executed.
 *
 * How to figure out tap dance state: interrupted and pressed.
 *
 * Interrupted: If the state of a dance dance is "interrupted", that means that
 * another key has been hit under the tapping term. This is typically indicitive
 * that you are trying to "tap" the key.
 *
 * Pressed: Whether or not the key is still being pressed. If this value is
 * true, that means the tapping term has ended, but the key is still being
 * pressed down. This generally means the key is being "held".
 *
 * One thing that is currenlty not possible with qmk software in regards to tap
 * dance is to mimic the "permissive hold" feature. In general, advanced tap
 * dances do not work well if they are used with commonly typed letters. For
 * example "A". Tap dances are best used on non-letter keys that are not hit
 * while typing letters.
 *
 * Good places to put an advanced tap dance:
 *  z,q,x,j,k,v,b, any function key, home/end, comma, semi-colon
 *
 * Criteria for "good placement" of a tap dance key:
 *  Not a key that is hit frequently in a sentence
 *  Not a key that is used frequently to double tap, for example 'tab' is often
 * double tapped in a terminal, or in a web form. So 'tab' would be a poor
 * choice for a tap dance. Letters used in common words as a double. For example
 * 'p' in 'pepper'. If a tap dance function existed on the letter 'p', the word
 * 'pepper' would be quite frustating to type.
 *
 * For the third point, there does exist the 'DOUBLE_SINGLE_TAP', however this
 * is not fully tested
 *
 */

// dont touch this
uint8_t cur_dance(tap_dance_state_t *state) {
  if (state->count == 1) {
    if (state->interrupted || !state->pressed)
      return SINGLE_TAP;
    // Key has not been interrupted, but the key is still held. Means you want
    // to send a 'HOLD'.
    else
      return SINGLE_HOLD;
  } else if (state->count == 2) {
    // DOUBLE_SINGLE_TAP is to distinguish between typing "pepper", and actually
    // wanting a double tap action when hitting 'pp'. Suggested use case for
    // this return value is when you want to send two keystrokes of the key, and
    // not the 'double tap' action/macro.
    if (state->interrupted)
      return DOUBLE_SINGLE_TAP;
    else if (state->pressed)
      return DOUBLE_HOLD;
    else
      return DOUBLE_TAP;
  }

  // Assumes no one is trying to type the same letter three times (at least not
  // quickly). If your tap dance key is 'KC_W', and you want to type "www."
  // quickly - then you will need to add an exception here to return a
  // 'TRIPLE_SINGLE_TAP', and define that enum just like 'DOUBLE_SINGLE_TAP'
  if (state->count == 3) {
    if (state->interrupted || !state->pressed)
      return TRIPLE_TAP;
    else
      return TRIPLE_HOLD;
  } else
    return 8; // Magic number. At some point this method will expand to work for
              // more presses
}

// Create an instance of 'tap', finished and reset for each dance
static tap dctap_state = {.is_press_action = true, .state = 0};

void dc_finished(tap_dance_state_t *state, void *user_data) {
  dctap_state.state = cur_dance(state);
  switch (dctap_state.state) {
  case SINGLE_TAP:
    register_code(LCM_DOT);
    break;
    /* case SINGLE_HOLD: register_code(KC_LCTL); break; */
    /* case DOUBLE_TAP: register_code(LCM_COLN); break; */
    /* case DOUBLE_HOLD: register_code(KC_LALT); break; */

    // Last case is for fast typing. Assuming your key is `f`:
    // For example, when typing the word `buffer`, and you want to make sure
    // that you send `ff` and not `Esc`. In order to type `ff` when typing fast,
    // the next character will have to be hit within the `TAPPING_TERM`, which
    // by default is 200ms.
    /* case DOUBLE_SINGLE_TAP: tap_code(KC_X); register_code(KC_X); */
  }
}

void dc_reset(tap_dance_state_t *state, void *user_data) {
  switch (dctap_state.state) {
  case SINGLE_TAP:
    unregister_code(LCM_DOT);
    break;
  case SINGLE_HOLD:
    unregister_code(KC_LCTL);
    break;
  case DOUBLE_TAP:
    unregister_code(KC_ESC);
    break;
  case DOUBLE_HOLD:
    unregister_code(KC_LALT);
  case DOUBLE_SINGLE_TAP:
    unregister_code(KC_X);
  }
  dctap_state.state = 0;
}

void CIRC_PLUS(tap_dance_state_t *state, void *user_data) {
  // for ACTION_TAP_DANCE_FN you CANT use a switch, it only runs after a count
  switch (state->count) {
  case 1:
    tap_code16(ROPT(LCM_O));
    break;
  case 2:
    tap_code(LCM_PLUS);
    break;
  }
}

void HTTP_TYPE(tap_dance_state_t *state, void *user_data) {
  // for ACTION_TAP_DANCE_FN you CANT use a switch, it only runs after a count
  switch (state->count) {
  case 1:
    tap_code16(LCM_NTIL);
    break;
  case 2:
    SEND_STRING("https:");
    tap_code16(LCM_SLSH);
    tap_code16(LCM_SLSH);
    reset_tap_dance(state);
    break;
  }
}

/* ========================================================== */
/* tap_code registers a key and unregisters it instantly */

/* theres also */

/* tap_code16(LCTL(KC_C)); */

// for more functions like tap_code :
// https://beta.docs.qmk.fm/using-qmk/advanced-keycodes/feature_macros#advanced-example
// use advanced when you need register and unregister
// for basic doubles do action_tap_dance_double(key1, key2)
//
// FOR DANCE_FN only BASIC keycodes work, no modifiers

tap_dance_action_t tap_dance_actions[] = {
    /* [TD_CS] = ACTION_TAP_DANCE_DOUBLE(LCM_COMM, LCM_SCLN), */
    /* [TD_PLUS] = ACTION_TAP_DANCE_DOUBLE(LCM_NTIL, LCM_PLUS), */
    /* [TD_CIRC_PLUS] = ACTION_TAP_DANCE_FN(CIRC_PLUS), */
    /* [TD_DC] = ACTION_TAP_DANCE_FN_ADVANCED(NULL, dc_finished, dc_reset), */
};

/* ACTION_TAP_DANCE_LAYER_MOVE(kc, layer):
 * Sends the kc keycode when tapped once, or moves to layer.
 * (this functions like the TO layer keycode). */

/* ACTION_TAP_DANCE_LAYER_TOGGLE(kc, layer):
 * Sends the kc keycode when tapped once, or toggles the state of layer.
 * (this functions like the TG layer keycode). */

/* DEPRECATED  for the new way to add a different tapping term for each key */
/* ACTION_TAP_DANCE_FN_ADVANCED_TIME */
