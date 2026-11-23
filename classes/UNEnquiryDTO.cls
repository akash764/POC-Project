/**
 * @description Input Data Transfer Object for public enquiry submissions.
 */
public inherited sharing class UNEnquiryDTO {
    @AuraEnabled public String submissionKey { get; set; }
    @AuraEnabled public String fullName { get; set; }
    @AuraEnabled public String email { get; set; }
    @AuraEnabled public String phone { get; set; }
    @AuraEnabled public Decimal budget { get; set; }
    @AuraEnabled public String bhkPreference { get; set; }
    @AuraEnabled public String locationPreference { get; set; }
    @AuraEnabled public Id projectId { get; set; }
    @AuraEnabled public Id campaignId { get; set; }
    @AuraEnabled public Boolean whatsAppOptIn { get; set; }
}