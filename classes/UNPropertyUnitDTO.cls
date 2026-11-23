/**
 * @description Data Transfer Object for public Property Unit details across Apartments, Villas, and Commercial spaces.
 */
public inherited sharing class UNPropertyUnitDTO {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public Id phaseId { get; set; }
    @AuraEnabled public String unitNumber { get; set; }
    @AuraEnabled public String recordTypeName { get; set; }
    @AuraEnabled public String unitType { get; set; }
    @AuraEnabled public Integer floor { get; set; }
    @AuraEnabled public String bhk { get; set; }
    @AuraEnabled public Decimal carpetArea { get; set; }
    @AuraEnabled public Decimal superBuiltUpArea { get; set; }
    @AuraEnabled public Decimal plotArea { get; set; }
    @AuraEnabled public Decimal price { get; set; }
    @AuraEnabled public String facing { get; set; }
    @AuraEnabled public Integer bathrooms { get; set; }
    @AuraEnabled public Boolean parkingAvailable { get; set; }
    @AuraEnabled public String furnishingStatus { get; set; }
    @AuraEnabled public Date possessionDate { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public String samplePhotoContentKey { get; set; }

    // Backward-compatibility alias
    @AuraEnabled public Decimal area {
        get { return this.carpetArea != null ? this.carpetArea : this.superBuiltUpArea; }
        set { this.carpetArea = value; }
    }
}