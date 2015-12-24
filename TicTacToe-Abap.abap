
REPORT z_tic_tac_toe.


INCLUDE icons.
DATA: w_vern LIKE trdir-vern,
w_version TYPE p DECIMALS 2,
w_tab_size LIKE qf00-ran_int,
gf_tick TYPE c,
gf_round TYPE i.
DATA: BEGIN OF gs_win_ln,
row_id TYPE c,
column TYPE c,
icon TYPE icons-text,
button TYPE char10,
END OF gs_win_ln,
gt_win_ln LIKE TABLE OF gs_win_ln.

DATA: BEGIN OF gt_output OCCURS 0,
column01 TYPE char4,
column02 TYPE char4,
column03 TYPE char4,
cell TYPE lvc_t_styl,
END OF gt_output.
DATA: w_main TYPE scrfname VALUE 'CC_MAIN',
w_errors TYPE scrfname VALUE 'CC_ERRORS',
grid1 TYPE REF TO cl_gui_alv_grid.
DATA: w_text_ln1(72) TYPE c,
w_text_ln2(72) TYPE c.
DATA: fl_win TYPE char04.
DATA: "pb_multi_select TYPE icons-text,
pl_o TYPE icons-text VALUE icon_oo_class,
pl_x TYPE icons-text VALUE icon_dummy,
pb_name TYPE char4.
DATA: gf_comp_player TYPE icons-text VALUE icon_dummy.
CONSTANTS: c_player1 TYPE icons-text VALUE icon_oo_class,
c_player2 TYPE icons-text VALUE icon_dummy.

FIELD-SYMBOLS <pb> TYPE any.
*=================================================[SELECTION SCREEN]===*
*... selections for processing of worklists:
SELECTION-SCREEN BEGIN OF BLOCK mainbl WITH FRAME TITLE text-w01.
PARAMETERS: p_size TYPE i DEFAULT 3 NO-DISPLAY.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) w_svern.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK mainbl.
* Game Screen Using Push Buttons that looks nicer than an ALV
SELECTION-SCREEN:
BEGIN OF SCREEN 200 AS WINDOW TITLE title,
PUSHBUTTON 2(5) pba1 USER-COMMAND pba1,
PUSHBUTTON 8(5) pba2 USER-COMMAND pba2,
PUSHBUTTON 14(5) pba3 USER-COMMAND pba3.
SELECTION-SCREEN:
PUSHBUTTON /2(5) pbb1 USER-COMMAND pbb1,
PUSHBUTTON 8(5) pbb2 USER-COMMAND pbb2,
PUSHBUTTON 14(5) pbb3 USER-COMMAND pbb3.
SELECTION-SCREEN:
PUSHBUTTON /2(5) pbc1 USER-COMMAND pbc1,
PUSHBUTTON 8(5) pbc2 USER-COMMAND pbc2,
PUSHBUTTON 14(5) pbc3 USER-COMMAND pbc3.
SELECTION-SCREEN:
SKIP 1,
PUSHBUTTON /8(5) reset USER-COMMAND reset,
COMMENT /5(30) comment,
END OF SCREEN 200.
*==============================================[AT SELECTION-SCREEN]===*
AT SELECTION-SCREEN.
* Game Logic
  PERFORM processing_logic.
  IF sy-ucomm = 'RESET'.
* Init Global variables
    PERFORM set_values.
  ENDIF.
  IF fl_win = pl_o.
    comment = 'Player O won'.
  ELSEIF fl_win = pl_x.
    comment = 'Player X won'.
  ENDIF.
*===================================================[INITIALIZATION]===*
INITIALIZATION.
  DATA: is_its TYPE c. "sap_bool.
  CALL FUNCTION 'GUI_IS_ITS'
    IMPORTING
      return = is_its.
* Gets report detail for version number
  SELECT SINGLE vern FROM trdir
  INTO w_vern
  WHERE name = sy-repid.
  WRITE w_vern TO w_svern.
  CONDENSE w_svern.
  CONCATENATE 'TickTacTow Build' w_svern
  INTO w_svern SEPARATED BY space.
* Init Global variables
  PERFORM set_values.
  reset = 'Reset'.
*---------------------------------------------------------------------*
* MAIN *
*---------------------------------------------------------------------*
START-OF-SELECTION.
  CALL SCREEN 200.

END-OF-SELECTION.
*&---------------------------------------------------------------------*
*& Form check_valid_v
*&---------------------------------------------------------------------*
FORM check_valid_v CHANGING p_win.
  DATA: lf_value TYPE char04,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  DO p_size TIMES.
    lf_column = sy-index.
    CLEAR: lf_countx, lf_count0.
    CONDENSE lf_column.
    CONCATENATE 'COLUMN0' lf_column INTO lf_column.
    ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
* Check amount of 'X' & '0's
    CLEAR lf_value.
    lf_lines = 0.
    lf_max = 3.
    LOOP AT gt_output.
      lf_value = <column>.
      IF lf_value = pl_o.
        ADD 1 TO lf_count0.
      ENDIF.
      IF lf_value = pl_x.
        ADD 1 TO lf_countx.
      ENDIF.
    ENDLOOP.
    IF lf_countx = 3.
      p_win = pl_x.
      PERFORM set_win_line USING lf_column 1 'ICON_INCOMPLETE'. "Pl X
      PERFORM set_win_line USING lf_column 2 'ICON_INCOMPLETE'. "Pl X
      PERFORM set_win_line USING lf_column 3 'ICON_INCOMPLETE'. "Pl X
      EXIT.
    ENDIF.
    IF lf_count0 = 3.
      p_win = pl_o.
      PERFORM set_win_line USING lf_column 1 'ICON_OO_OBJECT'. "PL O
      PERFORM set_win_line USING lf_column 2 'ICON_OO_OBJECT'. "PL O
      PERFORM set_win_line USING lf_column 3 'ICON_OO_OBJECT'. "PL O
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM. " check_valid_v
*&---------------------------------------------------------------------*
*& Form check_valid_d
*&---------------------------------------------------------------------*
FORM check_valid_d CHANGING p_win.
  DATA: lf_value TYPE char04,
  lf_rightdown TYPE c,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  p_win = ' '.
  DO 2 TIMES.
    CLEAR: lf_countx, lf_count0, lf_index.
    IF sy-index = 1.
      lf_rightdown = 'X'.
    ELSE.
      lf_rightdown = space.
      lf_index = p_size + 1.
    ENDIF.
    LOOP AT gt_output.
      IF lf_rightdown = 'X'.
        ADD 1 TO lf_index.
      ELSE.
        SUBTRACT 1 FROM lf_index.
      ENDIF.
      lf_column = lf_index.
      CONDENSE lf_column.
      CONCATENATE 'COLUMN0' lf_column INTO lf_column.
      ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
      lf_value = <column>.

      IF lf_value = pl_o.
        ADD 1 TO lf_count0.
      ENDIF.
      IF lf_value = pl_x.
        ADD 1 TO lf_countx.
      ENDIF.
    ENDLOOP.
    IF lf_countx = 3.
      p_win = pl_x.
      IF lf_rightdown = 'X'.
        PERFORM set_win_line USING 'COLUMN01' '1' 'ICON_INCOMPLETE'. "Pl X
        PERFORM set_win_line USING 'COLUMN02' '2' 'ICON_INCOMPLETE'. "Pl X
        PERFORM set_win_line USING 'COLUMN03' '3' 'ICON_INCOMPLETE'. "Pl X
      ELSE.
        PERFORM set_win_line USING 'COLUMN01' '3' 'ICON_INCOMPLETE'. "Pl X
        PERFORM set_win_line USING 'COLUMN02' '2' 'ICON_INCOMPLETE'. "Pl X
        PERFORM set_win_line USING 'COLUMN03' '1' 'ICON_INCOMPLETE'. "Pl X
      ENDIF.
      EXIT.
    ENDIF.
    IF lf_count0 = 3.
      p_win = pl_o.
      IF lf_rightdown = 'X'.
        PERFORM set_win_line USING 'COLUMN01' '1' 'ICON_OO_OBJECT'. "PL O
        PERFORM set_win_line USING 'COLUMN02' '2' 'ICON_OO_OBJECT'. "PL O
        PERFORM set_win_line USING 'COLUMN03' '3' 'ICON_OO_OBJECT'. "PL O
      ELSE.
        PERFORM set_win_line USING 'COLUMN01' '3' 'ICON_OO_OBJECT'. "PL O
        PERFORM set_win_line USING 'COLUMN02' '2' 'ICON_OO_OBJECT'. "PL O
        PERFORM set_win_line USING 'COLUMN03' '1' 'ICON_OO_OBJECT'. "PL O
      ENDIF.
      EXIT.
    ENDIF.
  ENDDO.

ENDFORM. " check_valid_d
*&---------------------------------------------------------------------*
*& Form check_valid_h
*&---------------------------------------------------------------------*
FORM check_valid_h CHANGING p_win.

  DATA: lf_value TYPE c,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i,
  lf_tabix LIKE sy-tabix.
  FIELD-SYMBOLS <column> TYPE any.
  p_win = ' '.
  LOOP AT gt_output.
    CLEAR: lf_countx, lf_count0.
    lf_tabix = sy-tabix.
    IF gt_output-column01 = pl_x.
      ADD 1 TO lf_countx.
    ENDIF.
    IF gt_output-column02 = pl_x.
      ADD 1 TO lf_countx.
    ENDIF.
    IF gt_output-column03 = pl_x.
      ADD 1 TO lf_countx.
    ENDIF.
    IF gt_output-column01 = pl_o.
      ADD 1 TO lf_count0.
    ENDIF.
    IF gt_output-column02 = pl_o.
      ADD 1 TO lf_count0.
    ENDIF.
    IF gt_output-column03 = pl_o.
      ADD 1 TO lf_count0.
    ENDIF.
    IF lf_countx = 3.
      p_win = pl_x.
      PERFORM set_win_line USING 'COLUMN01' lf_tabix 'ICON_INCOMPLETE'. "Pl X
      PERFORM set_win_line USING 'COLUMN02' lf_tabix 'ICON_INCOMPLETE'. "Pl X
      PERFORM set_win_line USING 'COLUMN03' lf_tabix 'ICON_INCOMPLETE'. "Pl X
      EXIT.
    ENDIF.
    IF lf_count0 = 3.
      p_win = pl_o.
      PERFORM set_win_line USING 'COLUMN01' lf_tabix 'ICON_OO_OBJECT'. "PL O
      PERFORM set_win_line USING 'COLUMN02' lf_tabix 'ICON_OO_OBJECT'. "PL O
      PERFORM set_win_line USING 'COLUMN03' lf_tabix 'ICON_OO_OBJECT'. "PL O
      EXIT.
    ENDIF.
  ENDLOOP.

ENDFORM. " check_valid_h

*&---------------------------------------------------------------------*
*& Form check_overall
*&---------------------------------------------------------------------*
FORM check_overall CHANGING p_row_no
p_column_no
p_win.
  ADD 1 TO gf_round.
  REFRESH gt_win_ln.
  CLEAR gs_win_ln.
  CHECK p_win = space.
  PERFORM check_valid_v CHANGING p_win.
  CHECK p_win = space.
  PERFORM check_valid_h CHANGING p_win.
  CHECK p_win = space.
  PERFORM check_valid_d CHANGING p_win.
ENDFORM. " check_overall
*&---------------------------------------------------------------------*
*& Form SET_VALUES
*&---------------------------------------------------------------------*
FORM set_values .
* Size of game
  p_size = 3.
  w_tab_size = 3.
  REFRESH gt_output.
  CLEAR gt_output.
  CLEAR comment.
  gf_tick = 'X'.
  gf_round = 1.
  fl_win = space.
  APPEND gt_output.
  APPEND gt_output.
  APPEND gt_output.
* Refresh Button Icons
  PERFORM set_button_icons.
ENDFORM. " SET_VALUES
*&---------------------------------------------------------------------*
*& Form COMP_PLAY
*&---------------------------------------------------------------------*
FORM comp_play CHANGING p_row_no
p_column_no
p_win.
  DATA: l_played,
  l_play_v,
  l_play_h,
  l_play_d,
  l_play,
  l_block.
  IF gf_round LE 2. "Opening move Alpa
    PERFORM comp_play_round1 CHANGING l_played.
  ENDIF.
** Try and Win
  IF l_played = space.
    CLEAR: l_play_v, l_play_h, l_play_d, l_play.
* First check the play when called again. In case the orher
* Player has won.
* Check all lines where the computer player has two in a row to win
    PERFORM comp_play_v CHANGING l_play_v l_play l_block.
    PERFORM comp_play_h CHANGING l_play_h l_play l_block.
    PERFORM comp_play_d CHANGING l_play_d l_play l_block.
* Now play a wining line
    l_play = 'X'.
    IF l_play_v = 'X'.
      PERFORM comp_play_v CHANGING l_played l_play l_block.
    ENDIF.
    IF l_play_h = 'X'.
      PERFORM comp_play_h CHANGING l_played l_play l_block.
    ENDIF.
    IF l_play_d = 'X'.
      PERFORM comp_play_d CHANGING l_played l_play l_block.
    ENDIF.
  ENDIF.
** Try and block player from winning
  IF l_played = space.
    CLEAR: l_play_v, l_play_h, l_play_d, l_play.
    l_block = 'X'.
* Check where player has two in a row
    PERFORM comp_play_v CHANGING l_play_v l_play l_block.
    PERFORM comp_play_h CHANGING l_play_h l_play l_block.
    PERFORM comp_play_d CHANGING l_play_d l_play l_block.
* Block where there is two in a row
    l_play = 'X'.
    IF l_play_v = 'X'.
      PERFORM comp_play_v CHANGING l_played l_play l_block.
    ENDIF.
    IF l_play_h = 'X'.
      PERFORM comp_play_h CHANGING l_played l_play l_block.
    ENDIF.
    IF l_play_d = 'X'.
      PERFORM comp_play_d CHANGING l_played l_play l_block.
    ENDIF.
    IF gf_round = 3. "Opening move Alpa
      PERFORM comp_play_round1 CHANGING l_played.
    ENDIF.
** Computer to play open corner if not played yet
    IF l_played = space.
      PERFORM corner_play CHANGING l_played.
    ENDIF.
** Random play if still not played
    IF l_played = space.
      PERFORM play_random CHANGING l_played.
    ENDIF.
  ENDIF.
* Checks if win
  PERFORM check_overall CHANGING p_row_no
  p_column_no
  p_win.
ENDFORM. " COMP_PLAY
*&---------------------------------------------------------------------*
*& Form comp_play_v
*&---------------------------------------------------------------------*
FORM comp_play_v CHANGING p_played p_play p_block.
  DATA: lf_value TYPE char04,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  CHECK p_played = space.
  DO p_size TIMES.
    CHECK p_played = space.
    lf_column = sy-index.
    CLEAR: lf_countx, lf_count0.
    CONDENSE lf_column.
    CONCATENATE 'COLUMN0' lf_column INTO lf_column.
    ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
* Check amount of 'X' & '0's
    CLEAR lf_value.
    lf_lines = 0.
    lf_max = 3.
    LOOP AT gt_output.
      lf_value = <column>.
      IF lf_value = pl_o.
        ADD 1 TO lf_count0.
      ENDIF.
      IF lf_value = pl_x.
        ADD 1 TO lf_countx.
      ENDIF.
    ENDLOOP.
* Other player has two vertical. Try and block the other player
    IF lf_countx = 2 AND gf_comp_player = pl_o AND p_block = 'X'.
      LOOP AT gt_output.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
* Other player has two vertical. Try and block the other player
    ELSEIF lf_count0 = 2 AND gf_comp_player = pl_x AND p_block = 'X'.
      LOOP AT gt_output.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
* Computer Player is Player X and has two vertical X, Play 3d box
    ELSEIF lf_countx = 2 AND gf_comp_player = pl_x AND p_block = ' '.
      LOOP AT gt_output.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
* Computer Player is Player O and has two vertical O, Play 3d box
    ELSEIF lf_count0 = 2 AND gf_comp_player = pl_o AND p_block = ' '.
      LOOP AT gt_output.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDDO.
ENDFORM. " comp_play_v
*&---------------------------------------------------------------------*
*& Form PLAY_RANDOM
*&---------------------------------------------------------------------*
FORM play_random CHANGING p_played.
  DO 3 TIMES.
    READ TABLE gt_output INDEX sy-index.
    CHECK p_played = space.
    CASE space.
      WHEN gt_output-column01.
        gt_output-column01 = gf_comp_player.
        p_played = 'X'.
      WHEN gt_output-column02.
        gt_output-column02 = gf_comp_player.
        p_played = 'X'.
      WHEN gt_output-column03.
        gt_output-column03 = gf_comp_player.
        p_played = 'X'.
    ENDCASE.
    MODIFY gt_output INDEX sy-index.
  ENDDO.

ENDFORM. " PLAY_RANDOM
*&---------------------------------------------------------------------*
*& Form SET_WIN_LINE
*&---------------------------------------------------------------------*
FORM set_win_line USING p_column
p_row_no
p_player.

  DATA: lf_column TYPE c,
  lf_row_no TYPE c.
  CASE p_column.
    WHEN 'COLUMN01'.
      lf_column = 1.
    WHEN 'COLUMN02'.
      lf_column = 2.
    WHEN 'COLUMN03'.
      lf_column = 3.
  ENDCASE.
  CASE p_row_no.
    WHEN 1.
      lf_row_no = 'A'.
    WHEN 2.
      lf_row_no = 'B'.
    WHEN 3.
      lf_row_no = 'C'.
  ENDCASE.
  CLEAR gs_win_ln.
  CONCATENATE 'PB' lf_row_no lf_column
  INTO gs_win_ln-button.
  gs_win_ln-row_id = lf_row_no.
  gs_win_ln-column = lf_column.
  gs_win_ln-icon = p_player.
  APPEND gs_win_ln TO gt_win_ln.
ENDFORM. " SET_WIN_LINE
*&---------------------------------------------------------------------*
*& Form COMP_PLAY_H
*&---------------------------------------------------------------------*
FORM comp_play_h CHANGING p_played p_play p_block.

  DATA: lf_value TYPE char04,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  CHECK p_played = space.
  DO 3 TIMES.
    READ TABLE gt_output INDEX sy-index.
    CHECK p_played = space.
    CLEAR: lf_countx, lf_count0.
    IF gt_output-column01 = c_player1.
      ADD 1 TO lf_count0.
    ENDIF.
    IF gt_output-column02 = c_player1.
      ADD 1 TO lf_count0.
    ENDIF.
    IF gt_output-column03 = c_player1.
      ADD 1 TO lf_count0.
    ENDIF.
    IF gt_output-column01 = c_player2.
      ADD 1 TO lf_countx.
    ENDIF.
    IF gt_output-column02 = c_player2.
      ADD 1 TO lf_countx.
    ENDIF.
    IF gt_output-column03 = c_player2.
      ADD 1 TO lf_countx.
    ENDIF.
* Flag open cell with comp player tick
    IF lf_countx = 2 AND gf_comp_player = pl_o AND p_block = 'X'.
      CASE space.
        WHEN gt_output-column01.
          gt_output-column01 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column02.
          gt_output-column02 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column03.
          gt_output-column03 = gf_comp_player.
          p_played = 'X'.
      ENDCASE.
    ELSEIF lf_count0 = 2 AND gf_comp_player = pl_x AND p_block = 'X'.
      CASE space.
        WHEN gt_output-column01.
          gt_output-column01 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column02.
          gt_output-column02 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column03.
          gt_output-column03 = gf_comp_player.
          p_played = 'X'.
      ENDCASE.
    ELSEIF lf_count0 = 2 AND gf_comp_player = pl_o AND p_block = ' '.
      CASE space.
        WHEN gt_output-column01.
          gt_output-column01 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column02.
          gt_output-column02 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column03.
          gt_output-column03 = gf_comp_player.
          p_played = 'X'.
      ENDCASE.
    ELSEIF lf_countx = 2 AND gf_comp_player = pl_x AND p_block = ' '.
      CASE space.
        WHEN gt_output-column01.
          gt_output-column01 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column02.
          gt_output-column02 = gf_comp_player.
          p_played = 'X'.
        WHEN gt_output-column03.
          gt_output-column03 = gf_comp_player.
          p_played = 'X'.
      ENDCASE.
    ENDIF.
    IF p_played = 'X' AND p_play = 'X'.
      MODIFY gt_output INDEX sy-index.
    ENDIF.
  ENDDO.
ENDFORM. " COMP_PLAY_H
*&---------------------------------------------------------------------*
*& Form CHECK_PLAY_V
*&---------------------------------------------------------------------*
FORM check_play_v CHANGING p_play.
  DATA: lf_value TYPE c,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  DO p_size TIMES.
    lf_column = sy-index.
    CLEAR: lf_countx, lf_count0, p_play.
    CONDENSE lf_column.
    CONCATENATE 'COLUMN0' lf_column INTO lf_column.
    ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
* Check amount of 'X' & '0's
    CLEAR lf_value.
    lf_lines = 0.
    lf_max = 3.
    LOOP AT gt_output.
      lf_value = <column>.
      IF lf_value = '0'.
        ADD 1 TO lf_count0.
      ENDIF.
      IF lf_value = 'X'.
        ADD 1 TO lf_countx.
      ENDIF.
    ENDLOOP.
    IF gf_comp_player = 'X'.
      IF lf_countx = 2.
        p_play = 'X'.
      ENDIF.
    ELSE.
      IF lf_count0 = 2.
        p_play = 'X'.
      ENDIF.
    ENDIF.
  ENDDO.
ENDFORM. " CHECK_PLAY_V
*&---------------------------------------------------------------------*
*& Form COMP_PLAY_D
*&---------------------------------------------------------------------*
FORM comp_play_d CHANGING p_played p_play p_block.
  DATA: lf_value TYPE char04,
  lf_rightdown TYPE c,
  lf_index LIKE sy-tabix,
  lf_column(8) TYPE c,
  lf_lines TYPE i,
  lf_max TYPE i,
  lf_count0 TYPE i,
  lf_countx TYPE i.
  FIELD-SYMBOLS <column> TYPE any.
  CHECK p_played = space.
  DO 2 TIMES.
    CLEAR: lf_countx, lf_count0, lf_index.
    CHECK p_played = space.
    IF sy-index = 1.
      lf_rightdown = 'X'.
    ELSE.
      lf_rightdown = space.
      lf_index = p_size + 1.
    ENDIF.
    LOOP AT gt_output.
      IF lf_rightdown = 'X'.
        ADD 1 TO lf_index.
      ELSE.
        SUBTRACT 1 FROM lf_index.
      ENDIF.
      lf_column = lf_index.
      CONDENSE lf_column.
      CONCATENATE 'COLUMN0' lf_column INTO lf_column.
      ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
      lf_value = <column>.

      IF lf_value = pl_o.
        ADD 1 TO lf_count0.
      ENDIF.
      IF lf_value = pl_x.
        ADD 1 TO lf_countx.
      ENDIF.
    ENDLOOP.
* Two diagonoly for other player, computer plays block
    IF lf_count0 = 2 AND gf_comp_player = pl_x AND p_block = 'X'.
      IF lf_rightdown = 'X'.
        CLEAR: lf_index.
      ELSE.
        lf_index = '4'.
      ENDIF.
      LOOP AT gt_output.
        IF lf_rightdown = 'X'.
          ADD 1 TO lf_index.
        ELSE.
          SUBTRACT 1 FROM lf_index.
        ENDIF.
        lf_column = lf_index.
        CONDENSE lf_column.
        CONCATENATE 'COLUMN0' lf_column INTO lf_column.
        ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output INDEX sy-tabix.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
* Two diagonoly for computer now play 3d box
    ELSEIF lf_countx = 2 AND gf_comp_player = pl_x AND p_block = ' '.
      IF lf_rightdown = 'X'.
        CLEAR: lf_index.
      ELSE.
        lf_index = '4'.
      ENDIF.
      LOOP AT gt_output.
        IF lf_rightdown = 'X'.
          ADD 1 TO lf_index.
        ELSE.
          SUBTRACT 1 FROM lf_index.
        ENDIF.
        lf_column = lf_index.
        CONDENSE lf_column.
        CONCATENATE 'COLUMN0' lf_column INTO lf_column.
        ASSIGN COMPONENT lf_column OF STRUCTURE gt_output TO <column>.
        IF <column> = space.
          IF p_play = 'X'.
            <column> = gf_comp_player.
            MODIFY gt_output INDEX sy-tabix.
          ENDIF.
          p_played = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDDO.

ENDFORM. " COMP_PLAY_D
*&---------------------------------------------------------------------*
*& Form COMP_PLAY_ROUND1
*&---------------------------------------------------------------------*
FORM comp_play_round1 CHANGING p_played.
  DATA: min LIKE bseg-wrbtr,
  max LIKE bseg-wrbtr,
  amount LIKE bseg-wrbtr,
  lf_rnum TYPE i.
******************* Notes **********************************************
* For the future if the computer can calculate what the next logical
* move will be for the human player by checking all rounds ahead that
* will result in a win. Case of two then there is two logical next
* moves Play one that leaves user to only play one of the logical moves.
*
************************************************************************


* Get random number between 1 and 4
  min = 1.
  max = 4.
  CALL FUNCTION 'RANDOM_P'
    EXPORTING
      rnd_min   = min
      rnd_max   = max
    IMPORTING
      rnd_value = amount.
  lf_rnum = amount.
  IF gf_round = 1.
    CASE lf_rnum.
      WHEN 1 OR 2.
        READ TABLE gt_output INDEX 1.
        IF lf_rnum = 1.
          gt_output-column01 = gf_comp_player.
        ELSE.
          gt_output-column03 = gf_comp_player.
        ENDIF.
        MODIFY gt_output INDEX 1.
        p_played = 'X'.
      WHEN 3 OR 4.
        READ TABLE gt_output INDEX 3.
        IF lf_rnum = 3.
          gt_output-column01 = gf_comp_player.
        ELSE.
          gt_output-column03 = gf_comp_player.
        ENDIF.
        MODIFY gt_output INDEX 1.
        p_played = 'X'.
    ENDCASE.
  ELSEIF gf_round = 2.
* Play opposite corner from that wich player played
    READ TABLE gt_output INDEX 1.
    IF gt_output-column01 = c_player1.
      READ TABLE gt_output INDEX 3.
      gt_output-column03 = gf_comp_player.
      MODIFY gt_output INDEX 3.
      p_played = 'X'.
    ENDIF.
    CHECK p_played = space.
    IF gt_output-column03 = c_player1.
      READ TABLE gt_output INDEX 3.
      gt_output-column01 = gf_comp_player.
      MODIFY gt_output INDEX 3.
      p_played = 'X'.
    ENDIF.
    CHECK p_played = space.
    READ TABLE gt_output INDEX 3.
    IF gt_output-column01 = c_player1.
      READ TABLE gt_output INDEX 1.
      gt_output-column01 = gf_comp_player.
      MODIFY gt_output INDEX 1.
      p_played = 'X'.
    ENDIF.
    CHECK p_played = space.
    IF gt_output-column03 = c_player1.
      READ TABLE gt_output INDEX 1.
      gt_output-column01 = gf_comp_player.
      MODIFY gt_output INDEX 1.
      p_played = 'X'.
    ELSEIF gf_round = 3.
* Play opposite corner from that wich computer played
      READ TABLE gt_output INDEX 1.
      IF gt_output-column01 = gf_comp_player.
        READ TABLE gt_output INDEX 3.
        gt_output-column03 = gf_comp_player.
        MODIFY gt_output INDEX 3.
        p_played = 'X'.
      ENDIF.
      CHECK p_played = space.
      IF gt_output-column03 = gf_comp_player.
        READ TABLE gt_output INDEX 3.
        gt_output-column01 = gf_comp_player.
        MODIFY gt_output INDEX 3.
        p_played = 'X'.
      ENDIF.
      CHECK p_played = space.
      READ TABLE gt_output INDEX 3.
      IF gt_output-column01 = gf_comp_player.
        READ TABLE gt_output INDEX 1.
        gt_output-column01 = gf_comp_player.
        MODIFY gt_output INDEX 1.
        p_played = 'X'.
      ENDIF.
      CHECK p_played = space.
      IF gt_output-column03 = gf_comp_player.
        READ TABLE gt_output INDEX 1.
        gt_output-column01 = gf_comp_player.
        MODIFY gt_output INDEX 1.
        p_played = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM. " COMP_PLAY_ROUND1
*&---------------------------------------------------------------------*
*& Form CORNER_PLAY
*&---------------------------------------------------------------------*
FORM corner_play CHANGING p_played.
** Top row's Corners
  READ TABLE gt_output INDEX 1.
  CASE space.
    WHEN gt_output-column01.
      gt_output-column01 = gf_comp_player.
      p_played = 'X'.
    WHEN gt_output-column03.
      gt_output-column03 = gf_comp_player.
      p_played = 'X'.
  ENDCASE.
  MODIFY gt_output INDEX 1.
** Bottom Row's corners
  CHECK p_played = space.
  READ TABLE gt_output INDEX 3.
  CASE space.
    WHEN gt_output-column01.
      gt_output-column01 = gf_comp_player.
      p_played = 'X'.
    WHEN gt_output-column03.
      gt_output-column03 = gf_comp_player.
      p_played = 'X'.
  ENDCASE.
  MODIFY gt_output INDEX 3.

ENDFORM. " CORNER_PLAY
*&---------------------------------------------------------------------*
*& Form PROCESSING_LOGIC
*&---------------------------------------------------------------------*
FORM processing_logic .
  DATA: lf_icon TYPE char04,
  lf_row_no TYPE i,
  lf_column TYPE i.
  CHECK sy-ucomm <> 'RESET'.
  pb_name = sy-ucomm.
  ASSIGN (pb_name) TO <pb>.
  IF sy-subrc = 0.
    CHECK <pb> IS INITIAL.
* WRITE icon_oo_class AS ICON TO <pb>(4).
  ENDIF.
  lf_icon = pl_o.
* WRITE icon_dummy AS ICON TO pba1(4).
  CASE pb_name.
* Row A (Top)
    WHEN 'PBA1'.
      gt_output-column01 = lf_icon.
      MODIFY gt_output INDEX 1
      TRANSPORTING column01.
    WHEN 'PBA2'.
      gt_output-column02 = lf_icon.
      MODIFY gt_output INDEX 1
      TRANSPORTING column02.
    WHEN 'PBA3'.
      gt_output-column03 = lf_icon.
      MODIFY gt_output INDEX 1
      TRANSPORTING column03.
* Row B (Middle)
    WHEN 'PBB1'.
      gt_output-column01 = lf_icon.
      MODIFY gt_output INDEX 2
      TRANSPORTING column01.
    WHEN 'PBB2'.
      gt_output-column02 = lf_icon.
      MODIFY gt_output INDEX 2
      TRANSPORTING column02.
    WHEN 'PBB3'.
      gt_output-column03 = lf_icon.
      MODIFY gt_output INDEX 2
      TRANSPORTING column03.
* Row C (Bottom)
    WHEN 'PBC1'.
      gt_output-column01 = lf_icon.
      MODIFY gt_output INDEX 3
      TRANSPORTING column01.
    WHEN 'PBC2'.
      gt_output-column02 = lf_icon.
      MODIFY gt_output INDEX 3
      TRANSPORTING column02.
    WHEN 'PBC3'.
      gt_output-column03 = lf_icon.
      MODIFY gt_output INDEX 3
      TRANSPORTING column03.
  ENDCASE.
* Checks if win
  PERFORM check_overall CHANGING lf_row_no
  lf_column
  fl_win.
  IF fl_win = space.
* Computer Play if no win
    PERFORM comp_play CHANGING lf_row_no
    lf_column
    fl_win.
  ENDIF.
* Refresh Button Icons
  PERFORM set_button_icons.
ENDFORM. " PROCESSING_LOGIC
*&---------------------------------------------------------------------*
*& Form SET_BUTTON_ICONS
*&---------------------------------------------------------------------*
FORM set_button_icons .
  FIELD-SYMBOLS <button>.
  LOOP AT gt_output.
    CASE sy-tabix.
      WHEN 1.
        WRITE gt_output-column01 AS ICON TO pba1.
        WRITE gt_output-column02 AS ICON TO pba2.
        WRITE gt_output-column03 AS ICON TO pba3.
      WHEN 2.
        WRITE gt_output-column01 AS ICON TO pbb1.
        WRITE gt_output-column02 AS ICON TO pbb2.
        WRITE gt_output-column03 AS ICON TO pbb3.
      WHEN 3.
        WRITE gt_output-column01 AS ICON TO pbc1.
        WRITE gt_output-column02 AS ICON TO pbc2.
        WRITE gt_output-column03 AS ICON TO pbc3.
    ENDCASE.
  ENDLOOP.

  IF fl_win IS NOT INITIAL.
    LOOP AT gt_win_ln INTO gs_win_ln.
      ASSIGN (gs_win_ln-button) TO <button>.
      CHECK sy-subrc = 0.
      WRITE (gs_win_ln-icon) AS ICON TO <button>.
    ENDLOOP.
  ENDIF.
ENDFORM. " SET_BUTTON_ICONS 

