CLASS zcl_ztmapp_journal_n DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ZTMAPP_JOURNAL_N IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  data:wa_final TYPE ztt_api_master.

  DELETE FROM ztt_api_master.   .


  ENDMETHOD.
ENDCLASS.
