/**
 * @description Schedulable & Batch job that marks past Site Visit Events as 'Completed'
 * and updates their associated Leads to 'Site Visit Completed'.
 */
public with sharing class UNSiteVisitCompletionSchedulable implements Schedulable, Database.Batchable<sObject> {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UNSiteVisitCompletionSchedulable(), 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime nowTime = System.now();
        return Database.getQueryLocator([
            SELECT Id, WhoId, StartDateTime, EndDateTime, Site_Visit_Status__c
            FROM Event
            WHERE WhoId != null
              AND (EndDateTime <= :nowTime OR (EndDateTime = null AND StartDateTime <= :nowTime))
              AND Site_Visit_Status__c != 'Completed'
              AND Site_Visit_Status__c != 'Cancelled'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Event> scope) {
        Set<Id> leadIdsToComplete = new Set<Id>();
        List<Event> eventsToUpdate = new List<Event>();

        for (Event e : scope) {
            e.Site_Visit_Status__c = 'Completed';
            eventsToUpdate.add(e);

            if (e.WhoId != null && String.valueOf(e.WhoId).startsWith('00Q')) {
                leadIdsToComplete.add(e.WhoId);
            }
        }

        if (!eventsToUpdate.isEmpty()) {
            update eventsToUpdate;
        }

        if (!leadIdsToComplete.isEmpty()) {
            List<Lead> leadsToUpdate = new List<Lead>();
            for (Lead ld : [SELECT Id, Status FROM Lead WHERE Id IN :leadIdsToComplete AND Status != 'Site Visit Completed']) {
                ld.Status = 'Site Visit Completed';
                leadsToUpdate.add(ld);
            }
            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    /**
     * @description Direct execution helper for immediate synchronization.
     */
    public static void runSync() {
        DateTime nowTime = System.now();
        List<Event> pastEvents = [
            SELECT Id, WhoId, StartDateTime, EndDateTime, Site_Visit_Status__c
            FROM Event
            WHERE WhoId != null
              AND (EndDateTime <= :nowTime OR (EndDateTime = null AND StartDateTime <= :nowTime))
              AND Site_Visit_Status__c != 'Completed'
              AND Site_Visit_Status__c != 'Cancelled'
        ];

        Set<Id> leadIds = new Set<Id>();
        for (Event e : pastEvents) {
            e.Site_Visit_Status__c = 'Completed';
            if (e.WhoId != null && String.valueOf(e.WhoId).startsWith('00Q')) {
                leadIds.add(e.WhoId);
            }
        }

        if (!pastEvents.isEmpty()) {
            update pastEvents;
        }

        if (!leadIds.isEmpty()) {
            List<Lead> leads = [SELECT Id, Status FROM Lead WHERE Id IN :leadIds AND Status != 'Site Visit Completed'];
            for (Lead ld : leads) {
                ld.Status = 'Site Visit Completed';
            }
            if (!leads.isEmpty()) {
                update leads;
            }
        }
    }
}