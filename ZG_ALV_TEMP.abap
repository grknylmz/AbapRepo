*&---------------------------------------------------------------------*
*& Report  ZG_ALV_TEMP
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zg_alv_temp.

TYPE-POOLS : truxs , slis .
DATA: fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     LIKE sy-repid,
      g_save TYPE c VALUE 'X',
      g_variant TYPE disvariant,
      gx_variant TYPE disvariant,
      g_exit TYPE c .


PERFORM build_fieldcatalog.
PERFORM display_alv_report.


*&---------------------------------------------------------------------*
*&      Form  build_fieldcatalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_fieldcatalog .


  DATA lv_colpos TYPE i .

  DEFINE add_fctalog.

    fieldcatalog-fieldname   = &1.
    fieldcatalog-seltext_m   = &2.
    fieldcatalog-col_pos = lv_colpos .
    lv_colpos = lv_colpos + 1 .
    append fieldcatalog to fieldcatalog.
    clear  fieldcatalog.


  END-OF-DEFINITION.


  add_fctalog    'PERNR'  'Personel No' .
  add_fctalog    'KISIM'  'Kýsým' .
  add_fctalog    'IZIN_NEDENI'  'Ýzin Nedeni' .
  add_fctalog    'BEGDA'  'Ýzin Baþlangýç Tarihi' .
  add_fctalog    'ENDDA'  'Ýzin Bitiþ Tarihi' .
  add_fctalog    'KISIM_SORUMLUSU'  'Kýsým Sorumlusu' .
  add_fctalog    'SEFI'  'Þefi' .
  add_fctalog    'URUN_YONETICISI'  'Ürün Yöneticisi' .
  add_fctalog    'PERSONEL_MUDURU'  'Personel Müdürü' .


ENDFORM.                    "build_fieldcatalog
*&---------------------------------------------------------------------*
*&      Form  display_alv_report
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM display_alv_report .

  gd_repid = sy-repid.
  gd_layout-box_fieldname = 'SEL'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = gd_repid
*     i_callback_top_of_page   = 'TOP-OF-PAGE' "see FORM
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      it_fieldcat              = fieldcatalog[]
      i_save                   = 'X'
      is_layout                = gd_layout
*     is_variant               = g_variant
    TABLES
      t_outtab                 = lt_izin_pusulasi
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    "display_alv_report

*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->RT_EXTAB   text
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'SET_PF_STATUS'  .

ENDFORM.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PV_UCOMM     text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_command USING pv_ucomm LIKE sy-ucomm
                 rs_selfield TYPE slis_selfield.
  IF pv_ucomm EQ 'Deneme'.
  ENDIF.

  rs_selfield-refresh    = 'X'.
  rs_selfield-col_stable = 'X' .
  rs_selfield-row_stable = 'X' .

ENDFORM.                    "user_command