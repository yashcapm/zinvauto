CLASS lhc_zr_api_auto DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF post_s,
        user_id TYPE i,
        id      TYPE i,
        title   TYPE string,
        body    TYPE string,
      END OF post_s,

      post_tt TYPE TABLE OF post_s WITH EMPTY KEY,

      BEGIN OF post_without_id_s,
        user_id TYPE i,
        title   TYPE string,
        body    TYPE string,
      END OF post_without_id_s,

      BEGIN OF api_item,
        matnr TYPE matnr,
        posnr TYPE posnr,
        value TYPE zr_api_auto-requestedquantity,
      END OF api_item.

    TYPES: tt_str_tab TYPE STANDARD TABLE OF string WITH EMPTY KEY
           ,
           BEGIN OF ts_data,
             data TYPE string,
             tab  TYPE tt_str_tab,
           END OF ts_data.

    DATA: ls_receive  TYPE ts_data,
          lt_response TYPE ts_data.
    DATA: url      TYPE string.
    DATA:it_apiitm TYPE STANDARD TABLE OF  api_item,
         wa_apitem TYPE api_item.

    METHODS:
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zr_api_auto RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_api_auto RESULT result.

    METHODS autopost FOR MODIFY
      IMPORTING keys FOR ACTION zr_api_auto~autopost RESULT result.
    METHODS postdata FOR MODIFY
      IMPORTING keys FOR ACTION zr_api_auto~postdata .
    METHODS pocreate FOR MODIFY
      IMPORTING keys FOR ACTION zr_api_auto~pocreate RESULT result.
    METHODS grncreate FOR MODIFY
      IMPORTING keys FOR ACTION zr_api_auto~grncreate RESULT result.


    CONSTANTS:
      base_url     TYPE string VALUE 'https://lmiapi.estonetech.in/api/SAP_Integration/LMISapPurchaseOrder?Order_Id=308635',
      content_type TYPE string VALUE 'Content-type',
      json_content TYPE string VALUE 'application/json; charset=UTF-8'.


ENDCLASS.

CLASS lhc_zr_api_auto IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD autopost.
*  read TABLE keys WITH KEY %cid = '' INTO data(key_with_initial_cid).
*  ASSERT key_with_initial_cid is INITIAL.

    READ ENTITIES OF zr_api_auto IN LOCAL MODE
        ENTITY zr_api_auto
         ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(data_read)
        FAILED failed.
    DATA(variable) = lines( data_read ).
    IF variable > 1.
      DATA(msg) = 'You did not pass multiple Lines'.
      DATA(val) = 'X'.
    ENDIF.
*        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>
*    IF val NE 'X'.
      DATA(url) = |{ base_url }|.
      TRY.
          DATA(client) = create_client( url ).
        CATCH cx_static_check.
          "handle exception
      ENDTRY.
      TRY.
          DATA(response) = client->execute( if_web_http_client=>get )->get_text(  ).
        CATCH cx_web_http_client_error cx_web_message_error.
          "handle exception
      ENDTRY.

      DATA : lv_str1  TYPE string,
             lv_str2  TYPE string,
             lv_str3  TYPE string,
             lv_str4  TYPE string,
             lv_str5  TYPE string,
             lv_str6  TYPE string,
             lv_str7  TYPE string,
             lv_str8  TYPE string,
             lv_str9  TYPE string,
             lv_str10 TYPE string.
      SPLIT  response AT '},' INTO  lv_str1  lv_str2 lv_str3 lv_str4 lv_str5
                                             lv_str6  lv_str7 lv_str8 lv_str9 lv_str10.
      CLEAR:lv_str1,lv_str2,lv_str3.
      SPLIT lv_str4 AT ':"' INTO lv_str1 lv_str2.
      IF lv_str2 IS NOT INITIAL.
        DATA(zkunnr) = lv_str2+0(10).
      ELSE.
        zkunnr = '0020000000'.
      ENDIF.
      CLEAR:lv_str1 ,lv_str2 ,lv_str3, lv_str4, lv_str6,  lv_str7, lv_str8, lv_str9, lv_str10.
      SPLIT lv_str5 AT '":' INTO lv_str1 lv_str2 lv_str3 lv_str4 lv_str6  lv_str7 lv_str8 lv_str9 lv_str10.
      CLEAR:lv_str1 ,lv_str2 ,lv_str3, lv_str4.
      SPLIT lv_str6 AT ',' INTO  DATA(dose_id) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str7 AT ',' INTO  DATA(unit_price) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str8 AT ',' INTO  DATA(dose_transport_cost) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str9 AT ',' INTO  DATA(pass_through_cost) lv_str1.

      IF unit_price IS NOT INITIAL.
        wa_apitem-matnr = '5M'.
        wa_apitem-posnr = '10'.
*      IF unit_price = '0.000'.
        wa_apitem-value = '870'.
*      ELSE.
*        wa_apitem-value = unit_price.
*      ENDIF.
*Unit_Price
        APPEND wa_apitem TO it_apiitm.
        CLEAR:wa_apitem.
      ENDIF.

      READ TABLE data_read INTO DATA(d_val) INDEX 1.
    IF d_val-customerpricegroup = '02' OR d_val-customerpricegroup = '05'.
      IF dose_transport_cost IS NOT INITIAL.
      wa_apitem-matnr = '5T'.
      wa_apitem-posnr = '20'.
      wa_apitem-value = '12000'.  "dose_transport_cost
      APPEND wa_apitem TO it_apiitm.
      CLEAR:wa_apitem.
      ENDIF.
    ENDIF.



*    <<<<<<<<<<<<<<<<<<<<Create PR >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      DATA: purchase_requisitions      TYPE TABLE FOR CREATE i_purchaserequisitiontp,
            purchase_requisition       TYPE STRUCTURE FOR CREATE i_purchaserequisitiontp,
            purchase_requisition_items TYPE TABLE FOR CREATE i_purchaserequisitiontp\_purchaserequisitionitem,
            purchase_requisition_item  TYPE STRUCTURE FOR CREATE i_purchaserequisitiontp\\purchaserequisition\_purchaserequisitionitem,
            purchase_reqn_acct_assgmts TYPE TABLE FOR CREATE i_purchasereqnitemtp\_purchasereqnacctassgmt,
            purchase_reqn_acct_assgmt  TYPE STRUCTURE FOR CREATE i_purchasereqnitemtp\_purchasereqnacctassgmt,
            purchase_reqn_delivadds    TYPE TABLE FOR CREATE i_purchasereqnitemtp\_purchasereqndelivaddress,
            purchase_reqn_delivadd     TYPE STRUCTURE FOR CREATE i_purchasereqnitemtp\_purchasereqndelivaddress,
            delivery_date              TYPE i_purchasereqnitemtp-deliverydate,
            n                          TYPE i,
            i                          TYPE i,
            lt_temp TYPE TABLE of zr_api_auto,
            wa_temp TYPE zr_api_auto.
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>


*    LOOP AT data_read ASSIGNING FIELD-SYMBOL(<fs_read>).
      n += 1.
      "purchase requisition
      DATA(cid) = 'My%CID_' && '_' && n.
      purchase_requisition = VALUE #(   %cid                      = cid
                                        purchaserequisitiontype   = 'NB'
                               %control = VALUE #( purchaserequisitiontype = cl_abap_behv=>flag_changed )
                                        ) .
      APPEND purchase_requisition TO purchase_requisitions.

*      loop at data_read into data(w_read).
*       wa_temp-YY1_MfgBatchID_SDI = w_read-YY1_MfgBatchID_SDI.
*       wa_temp-plant              = w_read-Plant.
*       wa_temp-requestedquantity  = w_read-RequestedQuantity
*       .
*      endloop.

      LOOP AT data_read ASSIGNING FIELD-SYMBOL(<fs_read>).
        LOOP AT it_apiitm INTO wa_apitem.
*READ TABLE it_apiitm INTO wa_apitem INDEX 1.
          i += 1.
          purchase_requisition_item = VALUE #(
                                               %cid_ref = cid
                                               %target  = VALUE #(  (
                                                             %cid                         = |My%ItemCID_{ i }|
                                                             plant                        =  <fs_read>-plant "Plant 01 (DE)
                                                             accountassignmentcategory    = 'K'  "unknown
*                                                        PurchaseRequisitionItem       = wa_apitem-posnr
*                                                       purchasingdocumentitemcategory = '5'
*                                                       PurchaseRequisitionItemText =  . "retrieved automatically from maintained MaterialInfo
                                                             requestedquantity            = <fs_read>-requestedquantity
                                                             purchaserequisitionprice     = '1.00'
                                                             purreqnitemcurrency          = 'GBP'
                                                             material                     = wa_apitem-matnr
                                                             materialgroup               = '10001'
*                                                        Material                  = 'laptop'
*                                                       materialgroup              = 'system'
                                                             purchasinggroup             = '30'
                                                             purchasingorganization     = '9401'
                                                             deliverydate                = sy-datum   "delivery_date  "yyyy-mm-dd (at least 10 days)
                                                             createdbyuser               = sy-uname
*                                                           SupplierMaterialNumber         = 'Test'"<fs_read>-MaterialByCustomer
                                                              %control = VALUE #(
                                                              plant                     = cl_abap_behv=>flag_changed
                                                              accountassignmentcategory = cl_abap_behv=>flag_changed
*                                                          PurchaseRequisitionItem   = cl_abap_behv=>flag_changed
                                                              requestedquantity         = cl_abap_behv=>flag_changed
                                                              purchaserequisitionprice  = cl_abap_behv=>flag_changed
                                                              purreqnitemcurrency       = cl_abap_behv=>flag_changed
                                                              material                  = cl_abap_behv=>flag_changed
                                                              materialgroup             = cl_abap_behv=>flag_changed
                                                              purchasinggroup           = cl_abap_behv=>flag_changed
                                                              purchasingorganization    = cl_abap_behv=>flag_changed
                                                              deliverydate              = cl_abap_behv=>flag_changed
                                                              createdbyuser             = cl_abap_behv=>flag_changed
*                                                            SupplierMaterialNumber    = cl_abap_behv=>flag_changed
                                                              )


                                                             ) ) ).
          APPEND purchase_requisition_item TO purchase_requisition_items.

          "purchase requisition account assignment  'My%ItemCID_1'
          purchase_reqn_acct_assgmt = VALUE #(
                                               %cid_ref =  |My%ItemCID_{ i }|
                                               %target  = VALUE #( (
                                                            %cid       = |MyTargetCID_{ i }|
                                                            costcenter = '0194727605'
                                                            glaccount  = '0000583940'
                                %control = VALUE #(
                                              costcenter = cl_abap_behv=>flag_changed
                                              glaccount  = cl_abap_behv=>flag_changed )
                                                             ) ) ) .
          APPEND purchase_reqn_acct_assgmt TO purchase_reqn_acct_assgmts .

          purchase_reqn_delivadd = VALUE #( %cid_ref = |My%delCID_{ i }|
                                            %target = VALUE #( (
                                                      %cid  = |MydelitCID_{ i }|
                                                      addressid = '0000000317'
                                                      manualdeliveryaddressid = '0000000317'
                                                      careofname = 'CareofNameUpdatedq'
                                                      plant     = '9401'
                                                      purchasingdeliveryaddresstype = 'C'
                                                      correspondencelanguage = 'E'
                                            ) ) ).
          APPEND  purchase_reqn_delivadd TO purchase_reqn_delivadds.
          CLEAR:wa_apitem.
        ENDLOOP.
     ENDLOOP.
        "purchase requisition
        MODIFY ENTITIES OF i_purchaserequisitiontp
          ENTITY purchaserequisition
            CREATE FIELDS ( purchaserequisitiontype )
            WITH purchase_requisitions
          "purchase requisition item
          CREATE BY \_purchaserequisitionitem
            FIELDS ( plant
*                  purchaserequisitionitemtext
                    accountassignmentcategory
*                purchasingdocumentitemcategory
                    requestedquantity
                    baseunit
                    purchaserequisitionprice
                    purreqnitemcurrency
                    material
                    materialgroup
                    purchasinggroup
                    purchasingorganization
                    deliverydate

                  )
          WITH purchase_requisition_items
*        <<<<<<<<<<<<<<<<<<<<<<<<             >>>>>>>>>>>>>>>>>>>>>>>
    ENTITY purchaserequisitionitem
    CREATE BY \_purchasereqnacctassgmt
            FIELDS ( costcenter
                     glaccount
                     quantity
*                   BaseUnit
                     )
            WITH purchase_reqn_acct_assgmts
*        <<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>
        REPORTED DATA(reported_create_pr)
        MAPPED DATA(mapped_create_pr)
        FAILED DATA(failed_create_pr).
        READ ENTITIES OF i_purchaserequisitiontp
        ENTITY purchaserequisition
        ALL FIELDS WITH CORRESPONDING #( mapped_create_pr-purchaserequisition )
        RESULT DATA(pr_result)
        FAILED DATA(pr_failed)
        REPORTED DATA(pr_reported).

        DATA : update_lines TYPE TABLE FOR UPDATE zr_api_auto,
               update_line  TYPE STRUCTURE FOR UPDATE zr_api_auto.


        zbp_r_api_auto=>mapped_purchase_requisition-purchaserequisition = mapped_create_pr-purchaserequisition.
        LOOP AT keys INTO DATA(key).
          update_line-%tky                   = key-%tky.
*        update_line-purchaserequisitio    = 'X'.
          update_line-creationdate   = cl_abap_context_info=>get_system_date(  ).
          APPEND update_line TO update_lines.
        ENDLOOP.

        MODIFY ENTITIES OF zr_api_auto IN LOCAL MODE
               ENTITY zr_api_auto
                 UPDATE
                 FIELDS ( creationdate )
                 WITH update_lines
                 REPORTED reported
                 FAILED failed
                 MAPPED mapped.

        IF failed IS INITIAL.

          "Read the changed data for action result
          READ ENTITIES OF zr_api_auto IN LOCAL MODE
            ENTITY zr_api_auto
              ALL FIELDS WITH
              CORRESPONDING #( keys )
            RESULT DATA(result_read).
          "return result entities
          result = VALUE #( FOR result_order IN result_read ( %tky   = result_order-%tky
                                                              %param = result_order ) ).
        ENDIF.
*      ENDLOOP.
*    ELSE.
*      APPEND VALUE #( %tky = keys[ 1 ]-%tky
*                          %msg = new_message_with_text(
*                                   severity = if_abap_behv_message=>severity-error
*                                   text     = msg
*                                 )  )  TO reported-zr_api_auto.
*    ENDIF.
  ENDMETHOD.

  METHOD postdata.

    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_initial_cid).
    ASSERT key_with_initial_cid IS INITIAL.

    READ ENTITIES OF zr_api_auto IN LOCAL MODE
        ENTITY zr_api_auto
         ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(data_read)
        FAILED failed.


  ENDMETHOD.

  METHOD pocreate.
    READ ENTITIES OF zr_api_auto IN LOCAL MODE
           ENTITY zr_api_auto ALL FIELDS WITH CORRESPONDING #( keys ) RESULT FINAL(data_read).

    DATA(variable) = lines( data_read ).
    IF variable > 1.
      DATA(msg) = 'You did not pass multiple Lines'.
      DATA(val) = 'X'.
    ENDIF.

    IF val NE 'X'.
      DATA: purchase_orders      TYPE TABLE FOR CREATE i_purchaseordertp_2,
            purchase_order       LIKE LINE OF purchase_orders,
            purchase_order_items TYPE TABLE FOR CREATE i_purchaseordertp_2\_purchaseorderitem,
            purchase_order_item  LIKE LINE OF purchase_order_items,
            lv_matnr             TYPE matnr,
            update_lines         TYPE TABLE FOR UPDATE zr_api_auto,
            update_line          TYPE STRUCTURE FOR UPDATE zr_api_auto.
      DATA:it_po TYPE TABLE OF i_purchaseordertp_2,
           wa_po TYPE i_purchaseordertp_2.


      DATA :purchase_order_description TYPE c LENGTH 40.
      DATA(n1) = 0.
      DATA(n2) = 0.
*    <<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      DATA: lt_temp_key TYPE zgje_transaction_handler02=>tt_temp_key,
            ls_temp_key LIKE LINE OF lt_temp_key.

*    <<<<<<<<<<<<<<<<<< API Consume >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

      DATA(url) = |{ base_url }|.

      TRY.
          DATA(client) = create_client( url ).
        CATCH cx_static_check.
          "handle exception
      ENDTRY.
      TRY.
          DATA(response) = client->execute( if_web_http_client=>get )->get_text(  ).
        CATCH cx_web_http_client_error cx_web_message_error.
          "handle exception
      ENDTRY.

      DATA : lv_str1  TYPE string,
             lv_str2  TYPE string,
             lv_str3  TYPE string,
             lv_str4  TYPE string,
             lv_str5  TYPE string,
             lv_str6  TYPE string,
             lv_str7  TYPE string,
             lv_str8  TYPE string,
             lv_str9  TYPE string,
             lv_str10 TYPE string.
      SPLIT  response AT '},' INTO  lv_str1  lv_str2 lv_str3 lv_str4 lv_str5
                                             lv_str6  lv_str7 lv_str8 lv_str9 lv_str10.
      CLEAR:lv_str1,lv_str2,lv_str3.
      SPLIT lv_str4 AT ':"' INTO lv_str1 lv_str2.
      IF lv_str2 IS NOT INITIAL.
        DATA(zkunnr) = lv_str2+0(10).
      ELSE.
        zkunnr = '0020000000'.
      ENDIF.
      CLEAR:lv_str1 ,lv_str2 ,lv_str3, lv_str4, lv_str6,  lv_str7, lv_str8, lv_str9, lv_str10.
      SPLIT lv_str5 AT '":' INTO lv_str1 lv_str2 lv_str3 lv_str4 lv_str6  lv_str7 lv_str8 lv_str9 lv_str10.
      CLEAR:lv_str1 ,lv_str2 ,lv_str3, lv_str4.
      SPLIT lv_str6 AT ',' INTO  DATA(dose_id) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str7 AT ',' INTO  DATA(unit_price) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str8 AT ',' INTO  DATA(dose_transport_cost) lv_str1.
      CLEAR:lv_str1.
      SPLIT lv_str9 AT ',' INTO  DATA(pass_through_cost) lv_str1.

      IF unit_price IS NOT INITIAL.
        wa_apitem-matnr = '5M'.
        wa_apitem-posnr = '10'.
*      IF unit_price = '0.000'.
        wa_apitem-value = '1'.
*      ELSE.
*        wa_apitem-value = unit_price.
*      ENDIF.
*Unit_Price
        APPEND wa_apitem TO it_apiitm.
        CLEAR:wa_apitem.
      ENDIF.


      READ TABLE data_read INTO DATA(d_val) INDEX 1.
*    IF d_val-customerpricegroup = '02' OR d_val-customerpricegroup = '05'.
*      IF dose_transport_cost IS NOT INITIAL.
      wa_apitem-matnr = '5T'.
      wa_apitem-posnr = '20'.
      wa_apitem-value = '1'."dose_transport_cost.
      APPEND wa_apitem TO it_apiitm.
      CLEAR:wa_apitem.
*      ENDIF.
*    ENDIF.





*<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

      CLEAR:purchase_orders,purchase_order,
           purchase_order_items,purchase_order_item,
           lv_matnr,n1,n2.

*IF VAL NE 'X'.

*    LOOP AT data_read ASSIGNING FIELD-SYMBOL(<fs_final>).
      CLEAR:purchase_orders,purchase_order,
       purchase_order_items,purchase_order_item,
       lv_matnr.

      DATA: lv_ebeln TYPE ebeln.

      n1 += 1.
      purchase_order =  VALUE #( %cid = |My%CID_{ n1 }|
      purchaseordertype      = 'NB'
      companycode            = '0194'
      purchasingorganization = '9401'
      purchasinggroup        = '30'
      supplier               = '1000000001'"<fs_final>-Supplier
      purchaseorderdate      = cl_abap_context_info=>get_system_date( )
                   %control = VALUE #(
                                   purchaseordertype      = cl_abap_behv=>flag_changed
                                   companycode            = cl_abap_behv=>flag_changed
                                   purchasingorganization = cl_abap_behv=>flag_changed
                                   purchasinggroup        = cl_abap_behv=>flag_changed
                                   supplier               = cl_abap_behv=>flag_changed
                                   purchaseorderdate      = cl_abap_behv=>flag_changed
                                                            ) ).
      APPEND purchase_order TO purchase_orders.
      LOOP AT data_read ASSIGNING FIELD-SYMBOL(<fs_final>).
        LOOP AT it_apiitm INTO wa_apitem.
          SELECT SINGLE banfn
          FROM ztt_so_api
          WHERE  salesorder = @<fs_final>-salesorder
*        AND    salesorderitem = @<fs_final>-salesorderitem
          INTO @DATA(banfn).


          n2 += 1.

          purchase_order_item = VALUE #(  %cid_ref = |My%CID_{ n1 }|
          %target = VALUE #( ( %cid = |My%CID_ITEM{ n2 }|
          material          = wa_apitem-matnr
          plant             = <fs_final>-plant
          invoiceisgoodsreceiptbased = 'X'
          orderquantity     = <fs_final>-requestedquantity
          purchaseorderitem = wa_apitem-posnr
          netpriceamount    = wa_apitem-value
*      PurchasingItemIsFreeOfCharge = 'X'
*      goodsreceiptisnonvaluated = 'X'
          documentcurrency  = 'EUR'
          purchaserequisition = banfn
*       <fs_final>-purchaserequisition
          purchaserequisitionitem = wa_apitem-posnr
          suppliermaterialnumber =  <fs_final>-materialbycustomer
          yy1_salesorder_pdi     = <fs_final>-salesorder

*      Batch             = 'TEST999111'
                            %control = VALUE #( material          = cl_abap_behv=>flag_changed
                                                plant             = cl_abap_behv=>flag_changed
                                                orderquantity     = cl_abap_behv=>flag_changed
                                                purchaseorderitem = cl_abap_behv=>flag_changed
                                                invoiceisgoodsreceiptbased = cl_abap_behv=>flag_changed
                                                netpriceamount    = cl_abap_behv=>flag_changed
*                                            PurchasingItemIsFreeOfCharge = cl_abap_behv=>flag_changed
*                                            goodsreceiptisnonvaluated = cl_abap_behv=>flag_changed
                                                documentcurrency  = cl_abap_behv=>flag_changed
                                                purchaserequisition = cl_abap_behv=>flag_changed
                                                purchaserequisitionitem = cl_abap_behv=>flag_changed
                                                suppliermaterialnumber  = cl_abap_behv=>flag_changed
                                                yy1_salesorder_pdi      = cl_abap_behv=>flag_changed
*                                            Batch    = cl_abap_behv=>flag_changed
                                                                ) ) )  ).
          APPEND purchase_order_item TO purchase_order_items.
          CLEAR:purchase_order_item,wa_apitem.
        ENDLOOP..
      ENDLOOP.
      "Purchase Order Header Data
      MODIFY ENTITIES OF i_purchaseordertp_2
      ENTITY purchaseorder
      CREATE FROM purchase_orders
      CREATE BY \_purchaseorderitem
      FROM purchase_order_items
      MAPPED DATA(mapped_po_headers)
      REPORTED DATA(reported_po_headers)
      FAILED DATA(failed_po_headers).

      WAIT UP TO 2 SECONDS.

      zbp_r_api_auto=>mapped_purchase_order-purchaseorder = mapped_po_headers-purchaseorder.
      LOOP AT keys INTO DATA(key).

        update_line-%tky                   = key-%tky.
        update_line-ebeln                  = 'X'.
        APPEND update_line TO update_lines.
      ENDLOOP.
      SORT update_lines BY %tky.
      DELETE ADJACENT DUPLICATES FROM update_lines COMPARING %tky.

      MODIFY ENTITIES OF zr_api_auto IN LOCAL MODE
            ENTITY zr_api_auto
              UPDATE
                FIELDS ( ebeln )
                WITH update_lines
                REPORTED reported
                FAILED failed
                MAPPED mapped.

      IF failed IS INITIAL.
        "Read the changed data for action result
        READ ENTITIES OF zr_api_auto IN LOCAL MODE
          ENTITY zr_api_auto
            ALL FIELDS WITH
            CORRESPONDING #( keys )
          RESULT DATA(result_read).
        "return result entities
        result = VALUE #( FOR result_order IN result_read ( %tky   = result_order-%tky
                                                            %param = result_order ) ).
      ENDIF.
    ELSE.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                               %msg = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = msg
                                      )  )  TO reported-zr_api_auto.

    ENDIF.

  ENDMETHOD.

  METHOD create_client.
    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).
  ENDMETHOD.

  METHOD grncreate.

    DATA : update_lines TYPE TABLE FOR UPDATE zr_api_auto,
           update_line  TYPE STRUCTURE FOR UPDATE zr_api_auto,
           i            TYPE i,
           n1           TYPE i,
           n2           TYPE i.

    READ ENTITIES OF zr_api_auto IN LOCAL MODE
         ENTITY zr_api_auto ALL FIELDS WITH CORRESPONDING #( keys ) RESULT FINAL(data_read).

    DATA(variable) = lines( data_read ).
    IF variable > 1.
      DATA(msg) = 'You did not pass multiple Lines'.
      DATA(val) = 'X'.
    ENDIF.

    IF val NE 'X'.
      SELECT * FROM ztt_so_api
      FOR ALL ENTRIES IN @data_read
      WHERE salesorder = @data_read-salesorder
*    AND   salesorderitem = @data_read-salesorderitem
      INTO TABLE @DATA(it_tt).

      IF it_tt[] IS NOT INITIAL.
        SELECT purchaseorder,
     purchaseorderitem
     FROM i_purchaseorderitemapi01
     FOR ALL ENTRIES IN @it_tt
     WHERE purchaserequisition = @it_tt-banfn
     INTO TABLE @DATA(it_pur) .
      ENDIF.

      IF it_pur[] IS NOT INITIAL.
        SELECT a~purchaseorder,
        a~purchaseorderitem,
        a~material,
        a~plant,
        a~netpricequantity
*       a~ItemWeightUnit
        FROM i_purchaseorderitemapi01 AS a
        INNER JOIN i_purchaseorderapi01 AS b ON a~purchaseorder = b~purchaseorder
        FOR ALL ENTRIES IN @it_pur
        WHERE b~creationdate = @sy-datum
        AND   a~purchaseorder = @it_pur-purchaseorder
        AND   a~purchaseorderitem = @it_pur-purchaseorderitem
        INTO TABLE @DATA(i_podata).

      ENDIF.

      DATA st_date TYPE d.
      DATA: materialdocumenttps      TYPE TABLE FOR CREATE i_materialdocumenttp,
            materialdocumenttp       LIKE LINE OF materialdocumenttps,
            materialdocumenttps_item TYPE TABLE FOR CREATE i_materialdocumenttp\_materialdocumentitem,
            materialdocumenttp_item  LIKE LINE OF materialdocumenttps_item.
      CLEAR:  materialdocumenttps,materialdocumenttp,materialdocumenttps_item,materialdocumenttp_item,
              i,n1,n2.



      i += 1.

      materialdocumenttp =  VALUE #( %cid = |My%CID_{ i }|
      goodsmovementcode  = '01'
      postingdate                = sy-datum "creation_date
      documentdate               = sy-datum
     %control = VALUE #(
      goodsmovementcode = cl_abap_behv=>flag_changed
      postingdate       = cl_abap_behv=>flag_changed
      documentdate      = cl_abap_behv=>flag_changed
         ) ).
      APPEND  materialdocumenttp TO materialdocumenttps.

*      <<<<<<<<<<<<<<<< Item >>>>>>>>>>>>>>>>>>>>>>
      n1 += 1.
      LOOP AT   i_podata INTO DATA(member).

        n2 += 1.
        materialdocumenttp_item = VALUE #( %cid_ref = |My%CID_{ n1 }|
                %target = VALUE #( ( %cid = |My%CID_ITEM{ n2 }|
                plant                      = member-plant
                 material                   = member-material
                 goodsmovementtype          = '101'
                 storagelocation            = '94US'
                 quantityinentryunit        = member-netpricequantity
                 entryunit                  = space"member-ItemWeightUnit
                 goodsmovementrefdoctype    = 'B'
*         Batch                      = member-Batch
                 purchaseorder              = member-purchaseorder
                 purchaseorderitem          = member-purchaseorderitem
                     %control = VALUE #(
                     plant             = cl_abap_behv=>flag_changed
                 material          = cl_abap_behv=>flag_changed
                 goodsmovementtype = cl_abap_behv=>flag_changed
                 storagelocation   = cl_abap_behv=>flag_changed
                 quantityinentryunit     = cl_abap_behv=>flag_changed
                 entryunit               = cl_abap_behv=>flag_changed
                 batch                   = cl_abap_behv=>flag_changed
                 purchaseorder           = cl_abap_behv=>flag_changed
                 purchaseorderitem       = cl_abap_behv=>flag_changed
                 goodsmovementrefdoctype = cl_abap_behv=>flag_changed


                ) ) ) ).
        APPEND materialdocumenttp_item TO materialdocumenttps_item.
      ENDLOOP.

      MODIFY ENTITIES OF i_materialdocumenttp
      ENTITY materialdocument
      CREATE FROM materialdocumenttps
      ENTITY materialdocument
      CREATE BY \_materialdocumentitem
      FROM materialdocumenttps_item
      MAPPED DATA(ls_create_mapped)
      FAILED DATA(ls_create_failed)
      REPORTED DATA(ls_create_reported).

*    LOOP AT i_podata INTO member.
*
*      i += 1.
*
*      MODIFY ENTITIES OF i_materialdocumenttp
*       ENTITY materialdocument
*       CREATE FROM VALUE #( ( %cid =   |My%ItemCID_{ i }|
*       goodsmovementcode          = '01'
*       postingdate                = sy-datum "creation_date
*       documentdate               = sy-datum
*       %control-goodsmovementcode = cl_abap_behv=>flag_changed
*       %control-postingdate       = cl_abap_behv=>flag_changed
*       %control-documentdate      = cl_abap_behv=>flag_changed
*       ) )
*
*         ENTITY materialdocument
*         CREATE BY \_materialdocumentitem
*         FROM VALUE #( (
*         %cid_ref                   = |My%ItemCID_{ i }|
*         %target                    = UE #( ( %cid = |CID_ITM_{ i }|
*         plant                      = member-plant
*         material                   = member-material
*         goodsmovementtype          = '101'
*         storagelocation            = '94US'
*         quantityinentryunit        = member-netpricequantity
*         entryunit                  = space"member-ItemWeightUnit
*         goodsmovementrefdoctype    = 'B'
**         Batch                      = member-Batch
*         purchaseorder              = member-purchaseorder
*         purchaseorderitem          = member-purchaseorderitem "'00010'
*         %control-plant             = cl_abap_behv=>flag_changed
*         %control-material          = cl_abap_behv=>flag_changed
*         %control-goodsmovementtype = cl_abap_behv=>flag_changed
*         %control-storagelocation   = cl_abap_behv=>flag_changed
*         %control-quantityinentryunit     = cl_abap_behv=>flag_changed
*         %control-entryunit               = cl_abap_behv=>flag_changed
*         %control-batch                   = cl_abap_behv=>flag_changed
*         %control-purchaseorder           = cl_abap_behv=>flag_changed
*         %control-purchaseorderitem       = cl_abap_behv=>flag_changed
*         %control-goodsmovementrefdoctype = cl_abap_behv=>flag_changed
*         ) )
*
*         ) )
*         MAPPED DATA(ls_create_mapped)
*         FAILED DATA(ls_create_failed)
*         REPORTED DATA(ls_create_reported).
*
*      WAIT UP TO 2 SECONDS.
*    ENDLOOP.

      zbp_r_api_auto=>mapped_material_document-materialdocument = ls_create_mapped-materialdocument.

      LOOP AT keys INTO DATA(key).

        update_line-%tky                   = key-%tky.
        update_line-mblnr                  = 'X'.
        APPEND update_line TO update_lines.
      ENDLOOP.
      SORT update_lines BY %tky.
      DELETE ADJACENT DUPLICATES FROM update_lines COMPARING %tky.

      MODIFY ENTITIES OF zr_api_auto IN LOCAL MODE
            ENTITY zr_api_auto
              UPDATE
                FIELDS ( mblnr )
                WITH update_lines
                REPORTED reported
                FAILED failed
                MAPPED mapped.

      IF failed IS INITIAL.
        "Read the changed data for action result
        READ ENTITIES OF zr_api_auto IN LOCAL MODE
          ENTITY zr_api_auto
            ALL FIELDS WITH
            CORRESPONDING #( keys )
          RESULT DATA(result_read).
        "return result entities
        result = VALUE #( FOR result_order IN result_read ( %tky   = result_order-%tky
                                                            %param = result_order ) ).
      ENDIF.
    ELSE.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                              %msg = new_message_with_text(
                                       severity = if_abap_behv_message=>severity-error
                                       text     = msg
                                     )  )  TO reported-zr_api_auto.
    ENDIF.


  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_api_auto DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_api_auto IMPLEMENTATION.

  METHOD save_modified.
    DATA : lt_pr TYPE STANDARD TABLE OF ztt_so_api,
           ls_pr TYPE                   ztt_so_api,
           keys  TYPE TABLE OF zr_api_auto.



    IF zbp_r_api_auto=>mapped_purchase_requisition-purchaserequisition IS NOT INITIAL.
      IF update-zr_api_auto IS NOT INITIAL.
        lt_pr = CORRESPONDING #( update-zr_api_auto MAPPING FROM ENTITY ).
        INSERT ztt_so_api FROM TABLE @lt_pr.
      ENDIF.


      LOOP AT zbp_r_api_auto=>mapped_purchase_requisition-purchaserequisition ASSIGNING FIELD-SYMBOL(<fs_pr_mapped>).
        CONVERT KEY OF i_purchaserequisitiontp FROM <fs_pr_mapped>-%pid TO DATA(ls_pr_key).
        <fs_pr_mapped>-purchaserequisition = ls_pr_key-purchaserequisition.
      ENDLOOP.

      LOOP AT update-zr_api_auto INTO  DATA(ls_poadd). " WHERE %control-OverallStatus = if_abap_behv=>mk-on.
        " Creates internal table with instance data
*      DATA(creation_date) = cl_abap_context_info=>get_system_date(  ).
        UPDATE ztt_so_api SET banfn = @ls_pr_key-purchaserequisition
         WHERE salesorder = @ls_poadd-salesorder.
*         AND   salesorderitem = @ls_poadd-salesorderitem.

      ENDLOOP.

    ENDIF.

    IF zbp_r_api_auto=>mapped_purchase_order IS NOT INITIAL.
      LOOP AT zbp_r_api_auto=>mapped_purchase_order-purchaseorder ASSIGNING FIELD-SYMBOL(<fs_po_mapped>).
        CONVERT KEY OF i_purchaseordertp_2 FROM <fs_po_mapped>-%pid TO DATA(ls_po_key).
        <fs_po_mapped>-purchaseorder = ls_po_key-purchaseorder.
      ENDLOOP.
      LOOP AT update-zr_api_auto INTO  DATA(w_read).
        DATA(zuname) = cl_abap_context_info=>get_system_date( ).
        DATA(utime)  = cl_abap_context_info=>get_system_time( ).
        UPDATE ztt_so_api
        SET ebeln = @ls_po_key-purchaseorder,
            uname = @zuname,
            utime = @utime

        WHERE salesorder = @w_read-salesorder.
*        AND   salesorderitem = @w_read-salesorderitem.
      ENDLOOP.

    ENDIF.

    IF zbp_r_api_auto=>mapped_material_document IS NOT INITIAL.
      LOOP AT zbp_r_auto_view=>mapped_material_document-materialdocument ASSIGNING FIELD-SYMBOL(<fs_mat_mapped>).
        CONVERT KEY OF i_materialdocumenttp FROM <fs_mat_mapped>-%pid TO DATA(ls_mat_key).
        <fs_mat_mapped>-materialdocument = ls_mat_key-materialdocument.
      ENDLOOP.
      CLEAR:ls_poadd.

      LOOP AT update-zr_api_auto INTO  w_read.
        UPDATE ztt_so_api SET mblnr = @ls_mat_key-materialdocument
        WHERE salesorder = @w_read-salesorder.
*        AND   salesorderitem = @w_read-salesorderitem.
      ENDLOOP.

    ENDIF.



  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
