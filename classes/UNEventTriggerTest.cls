/**
 * @description Unit test for UNEventTrigger and UNEventTriggerHandler.
 */
@IsTest
private class UNEventTriggerTest {

    @IsTest
    static void testAutomatedChauffeurDispatchAndStatusUpdate() {
        Project__c p = new Project__c(
            Name = 'Azure Palms Enclave',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Status__c = 'Active'
        );
        insert p;

        Lead ld = new Lead(
            FirstName = 'Vikram',
            LastName = 'Sharma',
            Company = 'Vikram Sharma (Individual Buyer)',
            Phone = '9840012345',
            Email = 'vikram.sharma@example.com',
            Preferred_Project__c = p.Id,
            LeadSource = 'Own Website',
            Status = 'New'
        );
        insert ld;

        Id siteVisitRtId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Site_Visit')?.getRecordTypeId();
        DateTime visitTime = DateTime.now().addDays(2);

        Test.startTest();
        Event visitEvent = new Event(
            RecordTypeId = siteVisitRtId,
            Subject = 'Site Visit - Azure Palms Enclave',
            WhoId = ld.Id,
            Project_Visited__c = p.Id,
            Site_Visit_Date_Time__c = visitTime,
            ActivityDateTime = visitTime,
            StartDateTime = visitTime,
            DurationInMinutes = 120,
            Transport_Required__c = true,
            Location = 'Indiranagar 100ft Road, Bengaluru'
        );
        insert visitEvent;
        Test.stopTest();

        // Verify Event times were auto-synchronized
        Event reloadedEvent = [
            SELECT Id, StartDateTime, EndDateTime, Site_Visit_Date_Time__c 
            FROM Event 
            WHERE Id = :visitEvent.Id
        ];
        System.assertEquals(visitTime, reloadedEvent.StartDateTime, 'StartDateTime should be auto-populated from Site_Visit_Date_Time__c');
        System.assertNotEquals(null, reloadedEvent.EndDateTime, 'EndDateTime should be auto-populated');

        // Verify Lead status was auto-advanced to Site Visit Scheduled
        Lead reloadedLead = [SELECT Id, Status FROM Lead WHERE Id = :ld.Id];
        System.assert(
            reloadedLead.Status == 'Site Visit Scheduled' || reloadedLead.Status == 'SIte_Visit_Scheduled',
            'Lead status should advance to Site Visit Scheduled: ' + reloadedLead.Status
        );

        // Verify Vehicle Booking was generated
        List<Vehicle_Booking__c> bookings = [
            SELECT Id, Site_Visit_Event_Id__c, Lead__c, Destination_Project__c, Status__c, Pickup_Address__c, Pickup_Time__c 
            FROM Vehicle_Booking__c 
            WHERE Site_Visit_Event_Id__c = :visitEvent.Id
        ];

        System.assertEquals(1, bookings.size(), 'Should automatically generate exactly one Vehicle_Booking__c record');
        System.assertEquals(ld.Id, bookings[0].Lead__c, 'Should relate to the prospective buyer Lead');
        System.assertEquals(p.Id, bookings[0].Destination_Project__c, 'Should relate to the destination Project');
        System.assertEquals('Requested', bookings[0].Status__c, 'Initial booking status must be Requested');
        System.assertEquals(visitTime, bookings[0].Pickup_Time__c, 'Pickup time should match site visit time');
    }
}