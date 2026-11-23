/**
 * @description Controller exposing Property Reviews and Video Testimonials
 * endpoints for Lightning Web Components in Experience Cloud LWR.
 */
public with sharing class UNReviewController {

    /**
     * @description Returns the 3 featured customer video testimonials for Home Page.
     */
    @AuraEnabled(cacheable=true)
    public static List<UNPropertyReviewDTO> getFeaturedVideoTestimonials() {
        return UNReviewService.getFeaturedVideoTestimonials();
    }

    /**
     * @description Returns verified reviews and overall rating metrics for a project.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProjectReviews(Id projectId) {
        return UNReviewService.getProjectReviews(projectId);
    }

    /**
     * @description Ingests a new customer/visitor review for a project.
     */
    @AuraEnabled
    public static UNReviewResultDTO submitProjectReview(UNPropertyReviewDTO reviewInput) {
        return UNReviewService.submitProjectReview(reviewInput);
    }
}