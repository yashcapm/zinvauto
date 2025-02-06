CLASS lhc_zr_api_auto DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_api_auto RESULT result.

    METHODS autopost FOR DETERMINE ON SAVE
      IMPORTING keys FOR zr_api_auto~autopost.

ENDCLASS.

CLASS lhc_zr_api_auto IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD autopost.
*    READ ENTITIES OF zr_api_auto IN LOCAL MODE
*        ENTITY zr_api_auto
*         ALL FIELDS WITH CORRESPONDING #( keys )
*        RESULT DATA(data_read)
*        FAILED data(failed).


        select * FROM ZC_API_AUTO
        into table @data(data_read) UP TO 1 ROWS.

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
          n                          TYPE i.
    LOOP AT data_read ASSIGNING FIELD-SYMBOL(<fs_read>).
      n += 1.
      "purchase requisition
      DATA(cid) = 'My%CID_1' && '_' && n.
      purchase_requisition = VALUE #(   %cid                      = cid
                                        purchaserequisitiontype   = 'NB'
                               %control = VALUE #( purchaserequisitiontype = cl_abap_behv=>flag_changed )
                                        ) .
      APPEND purchase_requisition TO purchase_requisitions.

      purchase_requisition_item = VALUE #(
                                           %cid_ref = cid
                                           %target  = VALUE #(  (
                                                         %cid                         = |My%ItemCID_{ n }|
                                                         plant                        =  <fs_read>-plant "Plant 01 (DE)
                                                         accountassignmentcategory    = 'K'  "unknown
*                                                       purchasingdocumentitemcategory = '5'
*                                                       PurchaseRequisitionItemText =  . "retrieved automatically from maintained MaterialInfo
                                                         requestedquantity            = <fs_read>-requestedquantity
                                                         purchaserequisitionprice     = '1.00'
                                                         purreqnitemcurrency          = 'GBP'
                                                         material                     = '5M'
                                                         materialgroup               = '10001'
*                                                        Material                  = 'laptop'
*                                                       materialgroup              = 'system'
                                                         purchasinggroup             = '30'
                                                         purchasingorganization     = '9401'
                                                         deliverydate                = sy-datum   "delivery_date  "yyyy-mm-dd (at least 10 days)
                                                         createdbyuser               = sy-uname
                                                          %control = VALUE #(
                                                          plant                     = cl_abap_behv=>flag_changed
                                                          accountassignmentcategory = cl_abap_behv=>flag_changed
                                                          requestedquantity         = cl_abap_behv=>flag_changed
                                                          purchaserequisitionprice  = cl_abap_behv=>flag_changed
                                                          purreqnitemcurrency       = cl_abap_behv=>flag_changed
                                                          material                  = cl_abap_behv=>flag_changed
                                                          materialgroup             = cl_abap_behv=>flag_changed
                                                          purchasinggroup           = cl_abap_behv=>flag_changed
                                                          purchasingorganization    = cl_abap_behv=>flag_changed
                                                          deliverydate              = cl_abap_behv=>flag_changed
                                                          createdbyuser             = cl_abap_behv=>flag_changed
                                                          )


                                                         ) ) ).
      APPEND purchase_requisition_item TO purchase_requisition_items.

      "purchase requisition account assignment
      purchase_reqn_acct_assgmt = VALUE #(
                                           %cid_ref = 'My%ItemCID_1'
                                           %target  = VALUE #( (
                                                        %cid       = 'MyTargetCID_1'
                                                        costcenter = '0194727602'
                                                        glaccount  = '0000583940'
                            %control = VALUE #(
                                          costcenter = cl_abap_behv=>flag_changed
                                          glaccount  = cl_abap_behv=>flag_changed )
                                                         ) ) ) .
      APPEND purchase_reqn_acct_assgmt TO purchase_reqn_acct_assgmts .

      purchase_reqn_delivadd = VALUE #( %cid_ref = 'My%delCID_1'
                                        %target = VALUE #( (
                                                  %cid  = 'MydelitCID_1'
                                                  addressid = '0000000317'
                                                  manualdeliveryaddressid = '0000000317'
                                                  careofname = 'CareofNameUpdatedq'
                                                  plant     = '9401'
                                                  purchasingdeliveryaddresstype = 'C'
                                                  correspondencelanguage = 'E'
                                        ) ) ).
      APPEND  purchase_reqn_delivadd TO purchase_reqn_delivadds.
      .
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

*      DATA : update_lines TYPE TABLE FOR UPDATE zr_api_auto,
*             update_line  TYPE STRUCTURE FOR UPDATE zr_api_auto.
*
*
* zbp_r_api_auto=>mapped_purchase_requisition-purchaserequisition = mapped_create_pr-purchaserequisition.
*      LOOP AT keys INTO DATA(key).
*        update_line-%tky                   = key-%tky.
**        update_line-purchaserequisitio    = 'X'.
*        update_line-CreationDate   = cl_abap_context_info=>get_system_date(  ).
*        APPEND update_line TO update_lines.
*      ENDLOOP.
*
*      MODIFY ENTITIES OF zr_api_auto IN LOCAL MODE
*             ENTITY zr_api_auto
*               UPDATE
*               FIELDS ( CreationDate )
*               WITH update_lines
*               REPORTED reported
*               FAILED failed
*               MAPPED mapped.
*
*      IF failed IS INITIAL.
*
*        "Read the changed data for action result
*        READ ENTITIES OF zr_api_auto IN LOCAL MODE
*          ENTITY zr_api_auto
*            ALL FIELDS WITH
*            CORRESPONDING #( keys )
*          RESULT DATA(result_read).
*        "return result entities
*        result = VALUE #( FOR result_order IN result_read ( %tky   = result_order-%tky
*                                                            %param = result_order ) ).
*      ENDIF.


*      LOOP AT mapped_create_pr-purchaserequisition INTO DATA(mapped_pr).
**      out->write( |{  mapped_pr-%pid }| ).
*        CONVERT KEY OF i_purchaserequisitiontp from mapped_pr-%pid to data(ls_ctr).
*
*      ENDLOOP.


      .

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_api_auto DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_api_auto IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
