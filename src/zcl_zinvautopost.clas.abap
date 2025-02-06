CLASS zcl_zinvautopost DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ZINVAUTOPOST IMPLEMENTATION.


 METHOD if_oo_adt_classrun~main.

DATA: DAY TYPE ztt_customerbill-billcycle,
      DATE TYPE datum.
      DATE = cl_abap_context_info=>get_system_date( ) .
      DATA: DAY_P TYPE P.

  DAY_P = DATE MOD 7.

  IF DAY_P > 1.
     DAY_P = DAY_P - 1.
  ELSE.
     DAY_P = DAY_P + 6.
  ENDIF.
  DAY = DAY_P.


select * FROM zc_invnew
WHERE Billcycle = 'D'
into TABLE @data(it_main).

select * FROM zc_invnew
WHERE Billcycle = 'W'
AND   billfre   = @DAY
APPENDING  TABLE @it_main.

select * FROM zc_invnew
WHERE Billcycle = 'M'
AND   billfre   = @SY-datum+6(2)
APPENDING  TABLE @it_main.


*loop at it_main ASSIGNING FIELD-SYMBOL(<fs_main>).
*CONCATENATE '00' <fs_main>-Kunnr INTO <fs_main>-Kunnr.
*ENDLOOP.


loop at it_main ASSIGNING FIELD-SYMBOL(<fs_main>).
   select SalesOrder AS SDDocument
        from I_SalesOrder
*        FOR ALL ENTRIES IN @IT_MAIN
        WHERE SoldToParty = @<fs_main>-Kunnr             "in "('0000000163','0000000164')" a~OverallSDProcessStatus <> 'C'
        AND   OverallSDProcessStatus NE 'C'
        into table @data(it_final) .

  if it_final[] is NOT INITIAL.
     MODIFY ENTITIES OF I_BillingDocumentTP
     ENTITY BillingDocument
     EXECUTE CreateFromSDDocument AUTO FILL CID
     WITH
     VALUE  #(
     ( %param = VALUE #( _reference = VALUE #( FOR ls_final IN it_final (
                                            SDDocument = ls_final-sddocument"'0000000161'
                        %control = VALUE #( SDDocument = if_abap_behv=>mk-on ) )
      )

     %control = VALUE #( _reference = if_abap_behv=>mk-on ) ) ) )

     RESULT DATA(lt_result_modify)
     FAILED DATA(ls_failed_modify)
     REPORTED DATA(ls_reported_modify).
 endif.
   if lt_result_modify[] is NOT INITIAL.
    COMMIT ENTITIES BEGIN
     RESPONSE OF I_BillingDocumentTP
     FAILED DATA(ls_failed_commit)
     REPORTED DATA(ls_reported_commit).

    CONVERT KEY OF I_BillingDocumentTP FROM lt_result_modify[ 1 ]-%param-%pid TO DATA(ls_billingdocument).

    COMMIT ENTITIES END.
   endif.
    clear: it_final[],it_final.
ENDLOOP.

  ENDMETHOD.
ENDCLASS.
