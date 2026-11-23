/**
 * @description Data Transfer Object for Property Reviews and Video Testimonials.
 */
public inherited sharing class UNPropertyReviewDTO {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String projectId { get; set; }
    @AuraEnabled public String projectName { get; set; }
    @AuraEnabled public String projectCity { get; set; }
    @AuraEnabled public String reviewerName { get; set; }
    @AuraEnabled public String reviewType { get; set; }
    @AuraEnabled public String videoUrl { get; set; }
    @AuraEnabled public String videoId { get; set; }
    @AuraEnabled public Integer rating { get; set; }
    @AuraEnabled public String reviewTitle { get; set; }
    @AuraEnabled public String feedback { get; set; }
    @AuraEnabled public Boolean isFeaturedHome { get; set; }
    @AuraEnabled public Boolean isVerifiedVisitor { get; set; }
    @AuraEnabled public String customerLocation { get; set; }
    @AuraEnabled public String unitPurchased { get; set; }
    @AuraEnabled public String formattedDate { get; set; }
}