/**
 * @description Lightning Web Component controller handling public enquiries.
 * Follows strict secure execution patterns for unauthenticated guest users.
 */
public with sharing class UNEnquiryController {

    @AuraEnabled
    public static UNEnquiryResultDTO submitEnquiry(UNEnquiryDTO enquiry) {
        try {
            return UNEnquiryService.processEnquiry(enquiry);
        } catch (Exception e) {
            return new UNEnquiryResultDTO(false, 'An unexpected error occurred. Please try again.');
        }
    }
}