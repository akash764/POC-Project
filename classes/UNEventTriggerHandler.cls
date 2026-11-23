/**
 * @description Handler for Event triggers in UrbanNest.
 * Automates time synchronization, past-event completion, and Lead status transitions.
 */
public with sharing class UNEventTriggerHandler {

    public static void handleBeforeInsert(List<Event> newEvents) {
        syncSiteVisitTimes(newEvents);
        evaluateEventStatus(newEvents);
    }

    public static void handleBeforeUpdate(List<Event> newEvents) {
        syncSiteVisitTimes(newEvents);
        evaluateEventStatus(newEvents);
    }

    public static void handleAfterInsert(List<Event> newEvents) {
        updateLeadStatusOnEvent(newEvents);
    }

    public static void handleAfterUpdate(List<Event> newEvents, Map<Id, Event> oldEventMap) {
        updateLeadStatusOnEvent(newEvents);
    }

    /**
     * @description Synchronizes Site_Visit_Date_Time__c with standard StartDateTime and EndDateTime.
     */
    private static void syncSiteVisitTimes(List<Event> newEvents) {
        for (Event e : newEvents) {
            if (e.Site_Visit_Date_Time__c != null) {
                if (e.ActivityDateTime == null) {
                    e.ActivityDateTime = e.Site_Visit_Date_Time__c;
                }
                if (e.StartDateTime == null) {
                    e.StartDateTime = e.Site_Visit_Date_Time__c;
                }
                if (e.DurationInMinutes == null) {
                    e.DurationInMinutes = 120;
                }
                if (e.EndDateTime == null) {
                    e.EndDateTime = e.Site_Visit_Date_Time__c.addMinutes(120);
                }
            } else if (e.StartDateTime != null && e.Site_Visit_Date_Time__c == null) {
                e.Site_Visit_Date_Time__c = e.StartDateTime;
            } else if (e.ActivityDateTime != null && e.Site_Visit_Date_Time__c == null) {
                e.Site_Visit_Date_Time__c = e.ActivityDateTime;
            }
        }
    }

    /**
     * @description If the event is in the past, marks Site_Visit_Status__c as 'Completed'.
     */
    private static void evaluateEventStatus(List<Event> newEvents) {
        DateTime nowTime = System.now();
        for (Event e : newEvents) {
            DateTime checkTime = (e.EndDateTime != null) ? e.EndDateTime : e.StartDateTime;
            if (checkTime != null && checkTime <= nowTime && e.Site_Visit_Status__c != 'Cancelled') {
                e.Site_Visit_Status__c = 'Completed';
            } else if (checkTime != null && checkTime > nowTime && String.isBlank(e.Site_Visit_Status__c)) {
                e.Site_Visit_Status__c = 'Site Visit Scheduled';
            }
        }
    }

    /**
     * @description Updates Lead status based on the site visit timing and status.
     * If the event time is past or completed -> 'Site Visit Completed'.
     * If scheduled in the future -> 'Site Visit Scheduled'.
     */
    private static void updateLeadStatusOnEvent(List<Event> newEvents) {
        Map<Id, String> leadStatusMap = new Map<Id, String>();
        DateTime nowTime = System.now();

        for (Event e : newEvents) {
            if (e.WhoId != null && String.valueOf(e.WhoId).startsWith('00Q')) {
                DateTime checkTime = (e.EndDateTime != null) ? e.EndDateTime : e.StartDateTime;
                Boolean isPastOrCompleted = (e.Site_Visit_Status__c == 'Completed') || (checkTime != null && checkTime <= nowTime && e.Site_Visit_Status__c != 'Cancelled');

                if (isPastOrCompleted) {
                    leadStatusMap.put(e.WhoId, 'Site Visit Completed');
                } else if (e.Site_Visit_Status__c != 'Cancelled') {
                    if (!leadStatusMap.containsKey(e.WhoId) || leadStatusMap.get(e.WhoId) != 'Site Visit Completed') {
                        leadStatusMap.put(e.WhoId, 'Site Visit Scheduled');
                    }
                }
            }
        }

        if (leadStatusMap.isEmpty()) {
            return;
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead ld : [SELECT Id, Status FROM Lead WHERE Id IN :leadStatusMap.keySet()]) {
            String targetStatus = leadStatusMap.get(ld.Id);
            if (ld.Status != targetStatus) {
                if (ld.Status == 'Site Visit Completed' && targetStatus == 'Site Visit Scheduled') {
                    continue;
                }
                ld.Status = targetStatus;
                leadsToUpdate.add(ld);
            }
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}