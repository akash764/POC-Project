/**
 * @description Data Transfer Object for public Property Unit details.
 * Kept for full backward-compatibility.
 */
public inherited sharing class UNHouseUnitDTO {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public Id apartmentId { get; set; }
    @AuraEnabled public String unitNumber { get; set; }
    @AuraEnabled public Integer floor { get; set; }
    @AuraEnabled public String bhk { get; set; }
    @AuraEnabled public Decimal area { get; set; }
    @AuraEnabled public Decimal price { get; set; }
    @AuraEnabled public String facing { get; set; }
    @AuraEnabled public Integer bathrooms { get; set; }
    @AuraEnabled public Boolean parkingAvailable { get; set; }
    @AuraEnabled public Date possessionDate { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public String samplePhotoContentKey { get; set; }
}