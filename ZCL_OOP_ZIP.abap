*&---------------------------------------------------------------------*
*& Report  ZCL_OOP_ZIP
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zcl_oop_zip.

CLASS: gcl_data_process DEFINITION DEFERRED.

DATA: go_data_proc  TYPE REF TO gcl_data_process.

*----------------------------------------------------------------------*
*       CLASS gcl_data_process DEFINITION
*----------------------------------------------------------------------*
CLASS gcl_data_process DEFINITION.

  PUBLIC SECTION.

    METHODS:
*   Instance class constructor
    constructor
    EXCEPTIONS
      ex_file_sel_err
      ex_file_upload,

*   Zip the files
    zip_file
      EXCEPTIONS
        ex_bin_conv_error
        ex_zip_error,

*   Download the Zip file to the PC folder
    download_file
      EXPORTING
        y_filesize TYPE i
      EXCEPTIONS
        ex_dwld_error.

  PRIVATE SECTION.

    TYPES:

    BEGIN OF ps_bin_file,
      name TYPE string,
      size TYPE i,
      data TYPE solix_tab,
    END OF ps_bin_file.

    DATA: pt_bindata        TYPE STANDARD TABLE OF ps_bin_file,
          pt_filetab        TYPE filetable,
          pv_dest_filepath  TYPE string,
          pt_zip_bin_data   TYPE STANDARD TABLE OF raw255,
          pv_zip_size       TYPE i.

    METHODS:
*   Select the files to be zipped
    select_files
      EXCEPTIONS
        ex_file_sel_err,

*   Select the destination file
    save_file_dialog.

ENDCLASS.                    "gcl_data_process DEFINITION

*----------------------------------------------------------------------*
*       CLASS gcl_data_process IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS gcl_data_process IMPLEMENTATION.

  METHOD select_files.

    DATA: lv_ret_code TYPE i,
          lv_usr_axn  TYPE i.

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING
        window_title            = 'Select file'
        multiselection          = 'X'
      CHANGING
        file_table              = me->pt_filetab
        rc                      = lv_ret_code
        user_action             = lv_usr_axn
      EXCEPTIONS
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        not_supported_by_gui    = 4
        OTHERS                  = 5
           ).
    IF sy-subrc <> 0 OR
       lv_usr_axn = cl_gui_frontend_services=>action_cancel.
      RAISE ex_file_sel_err.
    ENDIF.

  ENDMETHOD.                    "select_files

  METHOD constructor.

    DATA: lwa_file    TYPE file_table,
          lv_filename TYPE string,
          lwa_bindata TYPE me->ps_bin_file.

*   Select the files
    me->select_files( EXCEPTIONS ex_file_sel_err = 1 ).
    IF sy-subrc <> 0.
      RAISE ex_file_sel_err.
    ENDIF.

*   Loop on the selected files & populate the internal table
    LOOP AT me->pt_filetab INTO lwa_file.
      lv_filename = lwa_file-filename.
*     Upload the PDF data in binary format
      cl_gui_frontend_services=>gui_upload(
        EXPORTING
          filename                = lv_filename
          filetype                = 'BIN'
        IMPORTING
          filelength              = lwa_bindata-size
        CHANGING
          data_tab                = lwa_bindata-data
        EXCEPTIONS
          file_open_error         = 1
          file_read_error         = 2
          no_batch                = 3
          gui_refuse_filetransfer = 4
          invalid_type            = 5
          no_authority            = 6
          unknown_error           = 7
          bad_data_format         = 8
          header_not_allowed      = 9
          separator_not_allowed   = 10
          header_too_long         = 11
          unknown_dp_error        = 12
          access_denied           = 13
          dp_out_of_memory        = 14
          disk_full               = 15
          dp_timeout              = 16
          not_supported_by_gui    = 17
          error_no_gui            = 18
          OTHERS                  = 19
             ).
      IF sy-subrc <> 0.
        RAISE ex_file_upload.
      ENDIF.

*     Get the filename
      CALL FUNCTION 'SO_SPLIT_FILE_AND_PATH'
        EXPORTING
          full_name     = lv_filename
        IMPORTING
          stripped_name = lwa_bindata-name
        EXCEPTIONS
          x_error       = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
*       SUBRC check is not reqd.
      ENDIF.

*     Add the PDF data to the internal table
      APPEND lwa_bindata TO me->pt_bindata.

    ENDLOOP.

  ENDMETHOD.                    "constructor

  METHOD zip_file.

    DATA: lo_zip          TYPE REF TO cl_abap_zip,
          lv_xstring      TYPE xstring,
          lv_zip_xstring  TYPE xstring.

    FIELD-SYMBOLS: <lwa_bindata> TYPE me->ps_bin_file.

    CREATE OBJECT lo_zip. "Create instance of Zip Class

    LOOP AT me->pt_bindata ASSIGNING <lwa_bindata>.

*     Convert the data from Binary format to XSTRING
      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
        EXPORTING
          input_length = <lwa_bindata>-size
        IMPORTING
          buffer       = lv_xstring
        TABLES
          binary_tab   = <lwa_bindata>-data
        EXCEPTIONS
          failed       = 1
          OTHERS       = 2.
      IF sy-subrc <> 0.
        RAISE ex_bin_conv_error.
      ENDIF.

*     Add file to the zip folder
      lo_zip->add(  name    = <lwa_bindata>-name
                    content = lv_xstring ).
    ENDLOOP.

*   Get the binary stream for ZIP file
    lv_zip_xstring = lo_zip->save( ).

*   Convert the XSTRING to Binary table
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_zip_xstring
      IMPORTING
        output_length = me->pv_zip_size
      TABLES
        binary_tab    = me->pt_zip_bin_data.

  ENDMETHOD.                    "zip_file
  METHOD download_file.

    DATA: lv_dest_path TYPE string.

*   Get the Zip filepath
    me->save_file_dialog( ).

    CHECK me->pv_dest_filepath IS NOT INITIAL.

*   Download the Zip file
    cl_gui_frontend_services=>gui_download(
      EXPORTING
        bin_filesize              = me->pv_zip_size
        filename                  = me->pv_dest_filepath
        filetype                  = 'BIN'
      IMPORTING
        filelength                = y_filesize
      CHANGING
        data_tab                  = me->pt_zip_bin_data
      EXCEPTIONS
        file_write_error          = 1
        no_batch                  = 2
        gui_refuse_filetransfer   = 3
        invalid_type              = 4
        no_authority              = 5
        unknown_error             = 6
        header_not_allowed        = 7
        separator_not_allowed     = 8
        filesize_not_allowed      = 9
        header_too_long           = 10
        dp_error_create           = 11
        dp_error_send             = 12
        dp_error_write            = 13
        unknown_dp_error          = 14
        access_denied             = 15
        dp_out_of_memory          = 16
        disk_full                 = 17
        dp_timeout                = 18
        file_not_found            = 19
        dataprovider_exception    = 20
        control_flush_error       = 21
        not_supported_by_gui      = 22
        error_no_gui              = 23
        OTHERS                    = 24
           ).
    IF sy-subrc <> 0.
      RAISE ex_dwld_error.
    ENDIF.

  ENDMETHOD.                    "download_file
  METHOD save_file_dialog.

    DATA: lv_filename TYPE string,
          lv_path     TYPE string.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title         = 'Select the File Save Location'
        file_filter = '(*.zip)|*.zip|'
      CHANGING
        filename             = lv_filename
        path                 = lv_path
        fullpath             = me->pv_dest_filepath
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4
           ).
    IF sy-subrc <> 0.
*     SUBRC check is not reqd.
    ENDIF.

  ENDMETHOD.                    "save_file_dialog

ENDCLASS.                    "gcl_data_process IMPLEMENTATION

START-OF-SELECTION.

* Get the local instance of file processing class
  CREATE OBJECT go_data_proc
    EXCEPTIONS
      ex_file_sel_err = 1
      ex_file_upload  = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error Uploading files' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* Add the selected files to the ZIP folder
  go_data_proc->zip_file(
  EXCEPTIONS
    ex_bin_conv_error = 1
    ex_zip_error = 2  ).

  IF sy-subrc <> 0.
    MESSAGE 'Error Zipping the files' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

END-OF-SELECTION.

  DATA: gv_filesize TYPE i.

* Download the file to the selected folder
  go_data_proc->download_file(
    IMPORTING
      y_filesize = gv_filesize
    EXCEPTIONS
      ex_dwld_error = 1 ).
  IF sy-subrc <> 0.
    MESSAGE 'Error downloading the Zip file' TYPE 'E'.
  ELSE.
    MESSAGE s000(ykg_test) WITH gv_filesize 'bytes downloaded'(001).
  ENDIF.