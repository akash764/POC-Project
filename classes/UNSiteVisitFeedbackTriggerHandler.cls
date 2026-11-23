/**
 * @description Handler for Site_Visit_Feedback__c trigger.
 * Automates Lead progression to 'Site Visit Completed' and synchronizes prospect preferences.
 */
public with sharing class UNSiteVisitFeedbackTriggerHandler {

    public static void handleAfterInsert(List<Site_Visit_Feedback__c> newFeedbacks) {
        updateParentLeads(newFeedbacks);
    }

    private static void updateParentLeads(List<Site_Visit_Feedback__c> newFeedbacks) {
        Map<Id, Site_Visit_Feedback__c> leadToFeedbackMap = new Map<Id, Site_Visit_Feedback__c>();

        for (Site_Visit_Feedback__c fb : newFeedbacks) {
            if (fb.Lead__c != null) {
                leadToFeedbackMap.put(fb.Lead__c, fb);
            }
        }

        if (leadToFeedbackMap.isEmpty()) {
            return;
        }

        List<Lead> leadsToUpdate = [
            SELECT Id, Status, Preferred_Project__c, BHK_Preference__c 
            FROM Lead 
            WHERE Id IN :leadToFeedbackMap.keySet()
        ];

        for (Lead ld : leadsToUpdate) {
            Site_Visit_Feedback__c fb = leadToFeedbackMap.get(ld.Id);
            ld.Status = 'Site Visit Completed';

            if (ld.Preferred_Project__c == null && fb.Project_Visited__c != null) {
                ld.Preferred_Project__c = fb.Project_Visited__c;
            }
            if (ld.BHK_Preference__c == null && fb.Preferred_BHK_or_Unit__c != null) {
                ld.BHK_Preference__c = fb.Preferred_BHK_or_Unit__c;
            }
        }

        update leadsToUpdate;
    }
}