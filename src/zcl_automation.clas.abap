CLASS zcl_automation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
   INTERFACES if_oo_adt_classrun .



  PROTECTED SECTION.
  PRIVATE SECTION.



ENDCLASS.



CLASS ZCL_AUTOMATION IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*  <<<<<<<<<<<<<<< PO Create >>>>>>>>>>>>>>
   DATA: purchase_orders      TYPE TABLE FOR CREATE i_purchaseordertp_2,
          purchase_order       LIKE LINE OF purchase_orders,
          purchase_order_items TYPE TABLE FOR CREATE i_purchaseordertp_2\_purchaseorderitem,
          purchase_order_item  LIKE LINE OF purchase_order_items,
          lv_matnr             TYPE matnr.
  types:BEGIN OF ty_so,
        plant type werks_d,
        END OF ty_so.

    DATA :
           purchase_order_description TYPE c LENGTH 40,
           it_so TYPE STANDARD TABLE OF ty_so,
           wa_so type ty_so.

    DATA(n1) = 0.
    DATA(n2) = 0.

*<<<<<<<<<<<<<<< GET Logic From Master >>>>>>>>>>>>>>>>
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

if it_main[] is not INITIAL.
select a~SalesOrder,
       a~SalesOrderItem,
       c~PurchaseRequisition,
       c~PurchaseRequisitionItem,
       d~Supplier,
       d~Material,
       D~Plant,
       D~RequestedQuantity AS OrderedQuantity
        from I_SalesOrderItem as a
        INNER join I_SalesOrder as b on b~SalesOrder = a~SalesOrder
                                     and b~OverallSDProcessStatus <> 'C'
        left OUTER join I_SalesOrderScheduleLine as c  on a~SalesOrder = c~SalesOrder
                                                      and a~SalesOrderItem = c~SalesOrderItem
        left OUTER JOIN I_PurchaseRequisitionItemAPI01 as d on c~PurchaseRequisition = d~PurchaseRequisition
                                                           and c~PurchaseRequisitionItem = d~PurchaseRequisitionItem
        for ALL ENTRIES IN @it_main
        WHERE b~SoldToParty = @it_main-Kunnr
        and   b~CreationDate = @sy-datum
        into table @data(it_final) .

        delete it_final WHERE PurchaseRequisition is INITIAL.

      loop at it_final ASSIGNING FIELD-SYMBOL(<fs_final>).
      clear:purchase_orders[], purchase_orders,
            purchase_order_items[],purchase_order_items,lv_matnr.
      DATA: lv_ebeln TYPE ebeln.

      n1 += 1.
      purchase_order =  VALUE #( %cid = |My%CID_{ n1 }|
      purchaseordertype      = 'NB'
      companycode            = '0194'
      purchasingorganization = '9401'
      purchasinggroup        = '30'
      supplier               = '1000000001'"<fs_final>-Supplier
      PurchaseOrderDate      = cl_abap_context_info=>get_system_date( )
                   %control = VALUE #(
                                   purchaseordertype      = cl_abap_behv=>flag_changed
                                   companycode            = cl_abap_behv=>flag_changed
                                   purchasingorganization = cl_abap_behv=>flag_changed
                                   purchasinggroup        = cl_abap_behv=>flag_changed
                                   supplier               = cl_abap_behv=>flag_changed
                                   PurchaseOrderDate      = cl_abap_behv=>flag_changed
                                                            ) ).
      APPEND purchase_order TO purchase_orders.

      n2 += 1.

      purchase_order_item = VALUE #(  %cid_ref = |My%CID_{ n1 }|
      %target = VALUE #( ( %cid = |My%CID_ITEM{ n2 }|
      material          = <fs_final>-Material
      plant             = <fs_final>-Plant
      InvoiceIsGoodsReceiptBased = 'X'
      orderquantity     = <fs_final>-OrderedQuantity
      purchaseorderitem = '00010'
      netpriceamount    = '0.1'"<fs_final>-rate "'5'
*      PurchasingItemIsFreeOfCharge = 'X'
      GoodsReceiptIsNonValuated = 'X'
      DocumentCurrency  = 'USD'
      PurchaseRequisition = <fs_final>-PurchaseRequisition
      PurchaseRequisitionItem = <fs_final>-PurchaseRequisitionItem
*      Batch             = 'TEST999111'
                        %control = VALUE #( material          = cl_abap_behv=>flag_changed
                                            plant             = cl_abap_behv=>flag_changed
                                            orderquantity     = cl_abap_behv=>flag_changed
                                            purchaseorderitem = cl_abap_behv=>flag_changed
                                            InvoiceIsGoodsReceiptBased = cl_abap_behv=>flag_changed
                                            netpriceamount    = cl_abap_behv=>flag_changed
*                                            PurchasingItemIsFreeOfCharge = cl_abap_behv=>flag_changed
                                            GoodsReceiptIsNonValuated = cl_abap_behv=>flag_changed
                                            DocumentCurrency  = cl_abap_behv=>flag_changed
                                            PurchaseRequisition = cl_abap_behv=>flag_changed
                                            PurchaseRequisitionItem = cl_abap_behv=>flag_changed
*                                            Batch    = cl_abap_behv=>flag_changed
                                                            ) ) )  ).
      APPEND purchase_order_item TO purchase_order_items.

      "Purchase Order Header Data
      MODIFY ENTITIES OF i_purchaseordertp_2
      ENTITY purchaseorder
      CREATE FROM purchase_orders
      CREATE BY \_purchaseorderitem
      FROM purchase_order_items
      MAPPED DATA(mapped_po_headers)
      REPORTED DATA(reported_po_headers)
      FAILED DATA(failed_po_headers).


 if failed_po_headers is INITIAL.

 COMMIT ENTITIES BEGIN RESPONSE OF i_purchaseordertp_2 FAILED DATA(Lt_failed_data) REPORTED DATA(lt_reported1).
 COMMIT ENTITIES END.
 WAIT UP TO 2 SECONDS.



 endif.
      ENDLOOP..

endif.



*<<<<<<<<<<<<<<<<<<<<<   Create GRN   >>>>>>>>>>>>>>>>>>>>>>>>>>>

*     <<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>

select PurchaseOrder,
       PurchaseOrderItem
       from I_PurOrdAccountAssignmentAPI01
       FOR ALL ENTRIES IN @it_final
       WHERE SalesOrder = @it_final-SalesOrder
       and   SalesOrderItem = @it_final-SalesOrderItem
       into table @data(it_pur) .

    if it_pur[] is not INITIAL.
       select a~PurchaseOrder,
       a~PurchaseOrderItem,
       a~Material,
       a~Plant,
       a~NetPriceQuantity
*       a~ItemWeightUnit
       from I_PurchaseOrderItemAPI01 as a
       INNER join I_PurchaseOrderAPI01 as b on a~PurchaseOrder = b~PurchaseOrder
       FOR ALL ENTRIES IN @it_pur
       WHERE B~CreationDate = @sy-datum
       and   a~PurchaseOrder = @it_pur-PurchaseOrder
       and   a~PurchaseOrderItem = @it_pur-PurchaseOrderItem
       INTO TABLE @data(I_PODATA).

     endif.


DATA st_date TYPE d.

 LOOP AT I_PODATA INTO DATA(member).


      MODIFY ENTITIES OF i_materialdocumenttp
       ENTITY MaterialDocument
       CREATE FROM VALUE #( ( %cid = 'CID_001'
       goodsmovementcode          = '01'
       postingdate                = sy-datum "creation_date
       documentdate               = sy-datum
       %control-goodsmovementcode = cl_abap_behv=>flag_changed
       %control-postingdate       = cl_abap_behv=>flag_changed
       %control-documentdate      = cl_abap_behv=>flag_changed
       ) )

         ENTITY MaterialDocument
         CREATE BY \_MaterialDocumentItem
         FROM VALUE #( (
         %cid_ref                   = 'CID_001'
         %target                    = VALUE #( ( %cid = 'CID_ITM_001'
         plant                      = member-plant
         material                   = member-Material
         GoodsMovementType          = '101'
         storagelocation            = '94US'
         QuantityInEntryUnit        = member-NetPriceQuantity
         entryunit                  = space"member-ItemWeightUnit
         GoodsMovementRefDocType    = 'B'
*         Batch                      = member-Batch
         PurchaseOrder              = member-PurchaseOrder
         PurchaseOrderItem          = member-PurchaseOrderItem"'00010'
         %control-plant             = cl_abap_behv=>flag_changed
         %control-material          = cl_abap_behv=>flag_changed
         %control-GoodsMovementType = cl_abap_behv=>flag_changed
         %control-storagelocation   = cl_abap_behv=>flag_changed
         %control-QuantityInEntryUnit     = cl_abap_behv=>flag_changed
         %control-entryunit               = cl_abap_behv=>flag_changed
         %control-Batch                   = cl_abap_behv=>flag_changed
         %control-PurchaseOrder           = cl_abap_behv=>flag_changed
         %control-PurchaseOrderItem       = cl_abap_behv=>flag_changed
         %control-GoodsMovementRefDocType = cl_abap_behv=>flag_changed
         ) )

         ) )
         MAPPED DATA(ls_create_mapped)
         FAILED DATA(ls_create_failed)
         REPORTED DATA(ls_create_reported).

         if ls_create_reported is INITIAL.

 COMMIT ENTITIES BEGIN RESPONSE OF i_materialdocumenttp FAILED DATA(Lt_failed_grn) REPORTED DATA(lt_reported_grn).
 COMMIT ENTITIES END.
 WAIT UP TO 2 SECONDS.
 endif.

      ENDLOOP.
*<<<<<<<<<<<<<<<<<<<<<<<<< Invoice >>>>>>>>>>>>>>>>>>>>>>
loop at it_final INTO data(w_final).
 wa_so-plant = w_final-Plant.
 COLLECT wa_so into it_so.
  clear:wa_so,w_final.
ENDLOOP.

*data(it_temp) = it_final[].


loop at it_main ASSIGNING FIELD-SYMBOL(<fs_main>).
  IF <fs_main>-status = 'X'.
   if it_final[] is NOT INITIAL.
    select a~SalesOrder AS SDDocument,
           b~plant

        from I_SalesOrder as a
        left OUTER join I_SALESORDERITEM as b on a~SalesOrder = b~SalesOrder
        FOR ALL ENTRIES IN @IT_FINAL
        WHERE a~SoldToParty = @<fs_main>-Kunnr             "in "('0000000163','0000000164')" a~OverallSDProcessStatus <> 'C'
        AND   a~OverallSDProcessStatus <> 'C'
        AND   a~SalesOrder = @it_final-SalesOrder
        into table @data(it_temp).
if it_temp[] is NOT INITIAL.
loop at it_so INTO wa_so.
    clear:it_final[],w_final.
    loop at it_temp INTO data(wa_temp) WHERE Plant = wa_so-plant.
     MOVE-CORRESPONDING wa_temp to w_final.
     APPEND w_final to it_final.
     clear:w_final,wa_temp.
    ENDLOOP.


    if it_final[] is NOT INITIAL.
       MODIFY ENTITIES OF I_BillingDocumentTP
     ENTITY BillingDocument
     EXECUTE CreateFromSDDocument AUTO FILL CID
     WITH
     VALUE  #(
     ( %param = VALUE #( _reference = VALUE #( FOR ls_final IN it_final (
                                            SDDocument = ls_final-SalesOrder"'0000000161'
                        %control = VALUE #( SDDocument = if_abap_behv=>mk-on ) )
      )

     %control = VALUE #( _reference = if_abap_behv=>mk-on ) ) ) )


     RESULT DATA(lt_result_modify)
     FAILED DATA(ls_failed_modify)
     REPORTED DATA(ls_reported_modify).

     if lt_result_modify[] is NOT INITIAL.
    COMMIT ENTITIES BEGIN
     RESPONSE OF I_BillingDocumentTP
     FAILED DATA(ls_failed_commit)
     REPORTED DATA(ls_reported_commit).

    CONVERT KEY OF I_BillingDocumentTP FROM lt_result_modify[ 1 ]-%param-%pid TO DATA(ls_billingdocument).

    COMMIT ENTITIES END.
   endif.
endif.

endloop.
endif.
endif.
 ELSE.
   select a~SalesOrder AS SDDocument,
           b~plant

        from I_SalesOrder as a
        left OUTER join I_SALESORDERITEM as b on a~SalesOrder = b~SalesOrder
        FOR ALL ENTRIES IN @IT_FINAL
        WHERE a~SoldToParty = @<fs_main>-Kunnr             "in "('0000000163','0000000164')" a~OverallSDProcessStatus <> 'C'
        AND   a~OverallSDProcessStatus <> 'C'
        AND   a~SalesOrder = @it_final-SalesOrder
        into table @it_temp.




   if it_temp[] is NOT INITIAL.
    LOOP AT it_temp INTO DATA(WA_FINAL).
     MODIFY ENTITIES OF I_BillingDocumentTP
     ENTITY BillingDocument
     EXECUTE CreateFromSDDocument AUTO FILL CID
     WITH
     VALUE  #(
     ( %param = VALUE #( _reference = VALUE #( (
                                            SDDocument = WA_FINAL-SDDocument"'0000000161'
                        %control = VALUE #( SDDocument = if_abap_behv=>mk-on ) )
      )

     %control = VALUE #( _reference = if_abap_behv=>mk-on ) ) ) )


     RESULT lt_result_modify
     FAILED ls_failed_modify
     REPORTED ls_reported_modify.

     if lt_result_modify[] is NOT INITIAL.
    COMMIT ENTITIES BEGIN RESPONSE OF I_BillingDocumentTP FAILED ls_failed_commit REPORTED ls_reported_commit.
    CONVERT KEY OF I_BillingDocumentTP FROM lt_result_modify[ 1 ]-%param-%pid TO ls_billingdocument.

    COMMIT ENTITIES END.
   endif.



    ENDLOOP.
 endif.

 ENDIF.

*    clear: it_inv[],it_inv.
ENDLOOP.





  ENDMETHOD.
ENDCLASS.
