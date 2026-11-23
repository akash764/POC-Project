/**
 * @description Result Data Transfer Object for Property Review submissions.
 */
public inherited sharing class UNReviewResultDTO {
    @AuraEnabled public Boolean isSuccess { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public String reviewId { get; set; }

    public UNReviewResultDTO() {}

    public UNReviewResultDTO(Boolean isSuccess, String message) {
        this.isSuccess = isSuccess;
        this.message = message;
    }

    public UNReviewResultDTO(Boolean isSuccess, String message, String reviewId) {
        this.isSuccess = isSuccess;
        this.message = message;
        this.reviewId = reviewId;
    }
}