@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Master Data View'
@Metadata.allowExtensions: true
define root view entity ZC_INVNEW as select from ztt_customerbill

  association [1] to I_Customer           as _Customer           on $projection.Kunnr = _Customer.Customer
  association [1] to I_CustomerPriceGroup as _CustomerPriceGroup on $projection.Customerpricegroup = _CustomerPriceGroup.CustomerPriceGroup


{
   @EndUserText.label: 'Customer'
   @Consumption.valueHelpDefinition: [{ 
    entity.name: 'I_Customer',
    entity.element: 'Customer'
    }]
    key kunnr as Kunnr,
    
    key bukrs as Bukrs,
        @Consumption.valueHelpDefinition: [{ 
    entity.name: 'I_CustomerPriceGroup',
    entity.element: 'CustomerPriceGroup'
    }]
   @EndUserText.label: 'Order Type' 
    key customerpricegroup as Customerpricegroup,
   @EndUserText.label: 'Billing Cycle'
    billcycle as Billcycle,
    @EndUserText.label: 'Billing Status'
    billfre as Billfre,
    @EndUserText.label: 'Status'
    status,
    
    _Customer,
    _CustomerPriceGroup
  
}
