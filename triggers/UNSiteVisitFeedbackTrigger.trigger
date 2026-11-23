/**
 * @description Trigger on Site_Visit_Feedback__c to update Lead stages and preferences.
 */
trigger UNSiteVisitFeedbackTrigger on Site_Visit_Feedback__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        UNSiteVisitFeedbackTriggerHandler.handleAfterInsert(Trigger.new);
    }
}