/**
 * @description Data Transfer Object for Project Amenities with CMS Content Key and image resolution.
 */
public inherited sharing class UNAmenityDTO {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String amenityType { get; set; }
    @AuraEnabled public String description { get; set; }
    @AuraEnabled public String photoContentKey { get; set; }
    @AuraEnabled public Integer displayOrder { get; set; }
    @AuraEnabled public Boolean isFeatured { get; set; }

    public UNAmenityDTO() {
        this.displayOrder = 1;
        this.isFeatured = false;
    }
}