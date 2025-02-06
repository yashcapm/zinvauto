CLASS zcl_pr_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PR_CREATE IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
* MODIFY ENTITIES OF i_purchaserequisitiontp
*    ENTITY purchaserequisition
*       CREATE FIELDS ( purchaserequisitiontype )
*       WITH VALUE #(  ( %cid                    = 'My%CID_1'
*                        purchaserequisitiontype = 'NB' ) )
*
*      CREATE BY \_purchaserequisitionitem
*      FIELDS ( plant
**               purchaserequisitionitemtext
*               PurchasingDocumentItemCategory
*               accountassignmentcategory
*               requestedquantity
*               baseunit
**               purchaserequisitionprice
**               purreqnitemcurrency
*               Material
*               purchasinggroup
*               purchasingorganization
**               MultipleAcctAssgmtDistribution
*                   )
*      WITH VALUE #(
*                    (    %cid_ref = 'My%CID_1'
*                         %target = VALUE #(
*                                          (  %cid                        = 'My%ItemCID_1'
*                                             plant                       = '9401'
**                                             purchaserequisitionitemtext = 'created from PAAS API 23.6.2021 '
*                                             PurchasingDocumentItemCategory = '5'
*                                             accountassignmentcategory   = 'W'
*                                             requestedquantity           = '10.00'
*                                             baseunit                    = 'ZDO'
**                                             purchaserequisitionprice    = '10.00'
**                                             purreqnitemcurrency         = 'ZDO'
***                                             materialgroup               = 'L002'
*                                             Material                    = '5M'
*                                             purchasinggroup             = '30'
*                                             purchasingorganization      = '9401'
**                                             MultipleAcctAssgmtDistribution = '1'
*                                             )
*                                          )
*                     )
*                   )
*    REPORTED DATA(ls_reported)
*             MAPPED DATA(ls_mapped)
*             FAILED DATA(ls_failed).
*
*   LOOP AT ls_mapped-purchaserequisition ASSIGNING FIELD-SYMBOL(<fs_pr_mapped>).
*      CONVERT KEY OF i_purchaserequisitiontp FROM <fs_pr_mapped>-%key TO DATA(ls_pr_key).
*      <fs_pr_mapped>-purchaserequisition = ls_pr_key-purchaserequisition.
*    ENDLOOP.
*
*    COMMIT ENTITIES BEGIN RESPONSE OF i_purchaserequisitiontp FAILED DATA(lt_res_failed)
*    REPORTED DATA(lt_res_reported1).
*    COMMIT ENTITIES END.
*    out->write( ls_pr_key-PurchaseRequisition ).
**    out->write( ls_pri_key-PurchaseRequisitionItem ).

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

    n += 1.
    "purchase requisition
    DATA(cid) = 'My%CID_1' && '_' && n.
    purchase_requisition = VALUE #(   %cid                      = cid
                                      purchaserequisitiontype   = 'NB'  ) .
    APPEND purchase_requisition TO purchase_requisitions.

    purchase_requisition_item = VALUE #(
                                         %cid_ref = cid
                                         %target  = VALUE #(  (
                                                       %cid                         = |My%ItemCID_{ n }|
                                                       plant                        =  '9401' "Plant 01 (DE)
                                                       accountassignmentcategory    = 'K'  "unknown
*                                                       purchasingdocumentitemcategory = '5'
*                                                       PurchaseRequisitionItemText =  . "retrieved automatically from maintained MaterialInfo
                                                       requestedquantity            = '5.00'
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


                                                       ) ) ).
    APPEND purchase_requisition_item TO purchase_requisition_items.

    "purchase requisition account assignment
    purchase_reqn_acct_assgmt = VALUE #(
                                         %cid_ref = 'My%ItemCID_1'
                                         %target  = VALUE #( (
                                                      %cid       = 'MyTargetCID_1'
                                                      costcenter = '0194727602'
                                                      glaccount  = '0000583940' ) ) ) .
    APPEND purchase_reqn_acct_assgmt TO purchase_reqn_acct_assgmts .

    purchase_reqn_delivadd = VALUE #( %cid_ref = 'My%delCID_1'
                                      %target = VALUE #( (
                                                %cid  = 'MydelitCID_1'
                                                AddressID = '0000000317'
                                                ManualDeliveryAddressID = '0000000317'
                                                CareOfName = 'CareofNameUpdatedq'
                                                Plant     = '9401'
                                                PurchasingDeliveryAddressType = 'C'
                                                CorrespondenceLanguage = 'E'
                                      ) ) ).
   APPEND  purchase_reqn_delivadd TO purchase_reqn_delivaddS.
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
*ENTITY purchaserequisitionitem
*CREATE BY \_PurchaseReqnDelivAddress
*FIELDS  (         businesspartnername1
*                  businesspartnername2
*                  country
*                  region
*                  postalcode
*           )
*           WITH VALUE #(
*            (
**             %key-purchaserequisition = purchase_requisition-%key-PurchaseRequisition
*               %key-purchaserequisitionitem = '10'
*               %target = VALUE #( ( %cid        = 'My%addrCID_1'
**                                    %key-purchaserequisition = purchase_requisition-%key-PurchaseRequisition
*                                    %key-purchaserequisitionitem = '10'
*                                    businesspartnername1 = 'Name1'
*                                    businesspartnername2 = 'Name2'
*                                    country = 'GB'
*                                    region  = 'HAM'
*                                    postalcode = 'PO15 5TT' ) ) ) )
*        WITH purchase_reqn_delivaddS

    REPORTED DATA(reported_create_pr)
    MAPPED DATA(mapped_create_pr)
    FAILED DATA(failed_create_pr).
    READ ENTITIES OF i_purchaserequisitiontp
    ENTITY purchaserequisition
    ALL FIELDS WITH CORRESPONDING #( mapped_create_pr-purchaserequisition )
    RESULT DATA(pr_result)
    FAILED DATA(pr_failed)
    REPORTED DATA(pr_reported).

    LOOP AT mapped_create_pr-purchaserequisition INTO DATA(mapped_pr).
      out->write( |{  mapped_pr-%pid }| ).
    ENDLOOP.

    COMMIT ENTITIES BEGIN RESPONSE OF i_purchaserequisitiontp FAILED DATA(lt_res_failed)
  REPORTED DATA(lt_res_reported1).
*    COMMIT ENTITIES END.

    LOOP AT mapped_create_pr-purchaserequisition ASSIGNING FIELD-SYMBOL(<mapped>).
      CONVERT KEY OF i_purchaserequisitiontp FROM <mapped>-%pid TO DATA(ls_ctr).
      <mapped>-purchaserequisition = ls_ctr-purchaserequisition.
    ENDLOOP.

    IF sy-subrc = 0.
      out->write( | PurchaseRequisition:  { ls_ctr-purchaserequisition } | ).
    ELSE.
      out->write( | Error PurchaseRequisition sy-subrc:  { sy-subrc } | ).
    ENDIF.

    COMMIT ENTITIES END.



  ENDMETHOD.
ENDCLASS.
