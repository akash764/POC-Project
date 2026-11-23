/**
 * @description Neutral response DTO returned after enquiry processing.
 * Never reveals whether an existing customer was identified or provides Lead/Owner IDs.
 */
public inherited sharing class UNEnquiryResultDTO {
    @AuraEnabled public Boolean isSuccess { get; set; }
    @AuraEnabled public String message { get; set; }

    public UNEnquiryResultDTO(Boolean isSuccess, String message) {
        this.isSuccess = isSuccess;
        this.message = message;
    }
}